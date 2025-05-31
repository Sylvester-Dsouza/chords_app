import 'dart:async';
import 'package:flutter/foundation.dart';

enum ScreenType { home, setlist, search, resources, profile }

class ScreenState {
  final ScreenType type;
  final bool isInitialized;
  final bool isVisible;
  final DateTime? lastVisited;
  final DateTime? lastDataRefresh;

  ScreenState({
    required this.type,
    this.isInitialized = false,
    this.isVisible = false,
    this.lastVisited,
    this.lastDataRefresh,
  });

  ScreenState copyWith({
    bool? isInitialized,
    bool? isVisible,
    DateTime? lastVisited,
    DateTime? lastDataRefresh,
  }) {
    return ScreenState(
      type: type,
      isInitialized: isInitialized ?? this.isInitialized,
      isVisible: isVisible ?? this.isVisible,
      lastVisited: lastVisited ?? this.lastVisited,
      lastDataRefresh: lastDataRefresh ?? this.lastDataRefresh,
    );
  }
}

class ScreenStateProvider extends ChangeNotifier {
  static final ScreenStateProvider _instance = ScreenStateProvider._internal();
  factory ScreenStateProvider() => _instance;
  ScreenStateProvider._internal() {
    _initializeScreenStates();
  }

  // Notification throttling
  Timer? _notificationTimer;
  bool _hasPendingNotification = false;
  static const Duration _notificationDelay = Duration(milliseconds: 50);

  @override
  void notifyListeners() {
    // Throttle notifications to prevent loops
    if (_notificationTimer?.isActive == true) {
      _hasPendingNotification = true;
      return;
    }

    super.notifyListeners();

    _notificationTimer = Timer(_notificationDelay, () {
      if (_hasPendingNotification) {
        _hasPendingNotification = false;
        super.notifyListeners();
      }
    });
  }

  final Map<ScreenType, ScreenState> _screenStates = {};
  ScreenType _currentScreen = ScreenType.home;

  // Initialize all screen states
  void _initializeScreenStates() {
    for (ScreenType type in ScreenType.values) {
      _screenStates[type] = ScreenState(type: type);
    }
  }

  // Getters
  ScreenType get currentScreen => _currentScreen;
  Map<ScreenType, ScreenState> get screenStates => Map.unmodifiable(_screenStates);

  // Get specific screen state
  ScreenState getScreenState(ScreenType type) {
    return _screenStates[type] ?? ScreenState(type: type);
  }

  // Check if screen is initialized
  bool isScreenInitialized(ScreenType type) {
    return _screenStates[type]?.isInitialized ?? false;
  }

  // Check if screen needs data refresh (based on last visit and data refresh time)
  bool needsDataRefresh(ScreenType type, {int maxMinutes = 5}) {
    final state = _screenStates[type];
    if (state == null || state.lastDataRefresh == null) return true;

    final now = DateTime.now();
    final timeSinceRefresh = now.difference(state.lastDataRefresh!).inMinutes;

    return timeSinceRefresh >= maxMinutes;
  }

  // Check if screen should preload data (user is likely to visit soon)
  bool shouldPreloadData(ScreenType type) {
    final state = _screenStates[type];
    if (state == null) return false;

    // Preload if screen was visited recently but data is getting stale
    if (state.lastVisited != null) {
      final timeSinceVisit = DateTime.now().difference(state.lastVisited!).inMinutes;
      return timeSinceVisit < 30 && needsDataRefresh(type, maxMinutes: 3);
    }

    return false;
  }

  // Navigate to screen
  void navigateToScreen(ScreenType type) {
    final previousScreen = _currentScreen;
    _currentScreen = type;

    // Update previous screen visibility
    if (_screenStates.containsKey(previousScreen)) {
      _screenStates[previousScreen] = _screenStates[previousScreen]!.copyWith(
        isVisible: false,
      );
    }

    // Update current screen state
    _screenStates[type] = _screenStates[type]!.copyWith(
      isVisible: true,
      lastVisited: DateTime.now(),
    );

    debugPrint('📱 Screen navigation: $previousScreen → $type');
    notifyListeners();
  }

  // Mark screen as initialized
  void markScreenInitialized(ScreenType type) {
    _screenStates[type] = _screenStates[type]!.copyWith(
      isInitialized: true,
    );

    debugPrint('✅ Screen initialized: $type');
    notifyListeners();
  }

  // Mark screen data as refreshed
  void markDataRefreshed(ScreenType type) {
    _screenStates[type] = _screenStates[type]!.copyWith(
      lastDataRefresh: DateTime.now(),
    );

    debugPrint('🔄 Data refreshed for screen: $type');
    notifyListeners();
  }

  // Get screens that should be preloaded
  List<ScreenType> getScreensToPreload() {
    return ScreenType.values
        .where((type) => type != _currentScreen && shouldPreloadData(type))
        .toList();
  }

  // Reset screen state (useful for logout or app reset)
  void resetScreenState(ScreenType type) {
    _screenStates[type] = ScreenState(type: type);
    debugPrint('🔄 Reset screen state: $type');
    notifyListeners();
  }

  // Reset all screen states
  void resetAllScreenStates() {
    _initializeScreenStates();
    _currentScreen = ScreenType.home;
    debugPrint('🔄 Reset all screen states');
    notifyListeners();
  }

  // Get navigation analytics
  Map<String, dynamic> getNavigationAnalytics() {
    final analytics = <String, dynamic>{};

    for (final entry in _screenStates.entries) {
      final type = entry.key;
      final state = entry.value;

      analytics[type.toString()] = {
        'isInitialized': state.isInitialized,
        'isVisible': state.isVisible,
        'lastVisited': state.lastVisited?.toIso8601String(),
        'lastDataRefresh': state.lastDataRefresh?.toIso8601String(),
        'needsRefresh': needsDataRefresh(type),
        'shouldPreload': shouldPreloadData(type),
      };
    }

    analytics['currentScreen'] = _currentScreen.toString();
    analytics['screensToPreload'] = getScreensToPreload().map((e) => e.toString()).toList();

    return analytics;
  }
}
