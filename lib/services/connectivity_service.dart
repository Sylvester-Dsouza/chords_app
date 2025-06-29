import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service for monitoring internet connectivity and API reachability
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Connection state - Start optimistic, verify later
  bool _isConnected = true;
  bool _hasInternetAccess = true;
  bool _isApiReachable = true;
  ConnectivityResult _connectionType = ConnectivityResult.wifi;
  DateTime? _lastConnectivityCheck;
  DateTime? _lastApiCheck;

  // Check intervals
  static const Duration _connectivityCheckInterval = Duration(seconds: 30);
  static const Duration _apiCheckInterval = Duration(minutes: 2);
  static const Duration _apiTimeout = Duration(seconds: 10);

  // Getters
  bool get isConnected => _isConnected;
  bool get hasInternetAccess => _hasInternetAccess;
  bool get isApiReachable => _isApiReachable;
  bool get isFullyOnline =>
      _isConnected && _hasInternetAccess && _isApiReachable;
  ConnectivityResult get connectionType => _connectionType;

  /// Initialize the connectivity service
  Future<void> initialize() async {
    debugPrint('🌐 Initializing ConnectivityService...');

    try {
      // Check initial connectivity
      await _checkInitialConnectivity();

      // Start listening to connectivity changes
      _startConnectivityListener();

      // Start periodic checks
      _startPeriodicChecks();

      debugPrint('✅ ConnectivityService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize ConnectivityService: $e');
    }
  }

  /// Check initial connectivity state
  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectivityResult =
          connectivityResults.isNotEmpty
              ? connectivityResults.first
              : ConnectivityResult.none;

      await _updateConnectivityState(connectivityResult);

      // Also check internet access and API reachability
      await _checkInternetAccess();
      await _checkApiReachability();
    } catch (e) {
      debugPrint('❌ Error checking initial connectivity: $e');
      _setOfflineState();
    }
  }

  /// Start listening to connectivity changes
  void _startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final result =
            results.isNotEmpty ? results.first : ConnectivityResult.none;
        await _updateConnectivityState(result);

        // Check internet access when connectivity changes
        if (_isConnected) {
          await _checkInternetAccess();
          await _checkApiReachability();
        }
      },
      onError: (error) {
        debugPrint('❌ Connectivity listener error: $error');
        _setOfflineState();
      },
    );
  }

  /// Start periodic connectivity checks
  void _startPeriodicChecks() {
    // Check internet access periodically
    Timer.periodic(_connectivityCheckInterval, (timer) async {
      if (_isConnected) {
        await _checkInternetAccess();
      }
    });

    // Check API reachability less frequently
    Timer.periodic(_apiCheckInterval, (timer) async {
      if (_hasInternetAccess) {
        await _checkApiReachability();
      }
    });
  }

  /// Update connectivity state based on connectivity result
  Future<void> _updateConnectivityState(ConnectivityResult result) async {
    final wasConnected = _isConnected;
    _connectionType = result;
    _isConnected = result != ConnectivityResult.none;
    _lastConnectivityCheck = DateTime.now();

    if (wasConnected != _isConnected) {
      debugPrint(
        '🌐 Connectivity changed: ${_isConnected ? "Connected" : "Disconnected"} ($result)',
      );

      if (!_isConnected) {
        _setOfflineState();
      }

      notifyListeners();
    }
  }

  /// Check if device has actual internet access (not just network connection)
  Future<void> _checkInternetAccess() async {
    if (!_isConnected) {
      _hasInternetAccess = false;
      return;
    }

    try {
      // Try to reach a reliable internet service with longer timeout
      final response = await http
          .get(
            Uri.parse('https://www.google.com'),
            headers: {'Cache-Control': 'no-cache'},
          )
          .timeout(
            const Duration(seconds: 10),
          ); // Increased timeout for mobile networks

      final hadInternetAccess = _hasInternetAccess;
      _hasInternetAccess = response.statusCode == 200;

      if (hadInternetAccess != _hasInternetAccess) {
        debugPrint(
          '🌐 Internet access changed: ${_hasInternetAccess ? "Available" : "Unavailable"}',
        );
        notifyListeners();
      }
    } catch (e) {
      if (_hasInternetAccess) {
        debugPrint('🌐 Lost internet access: $e');
        _hasInternetAccess = false;
        notifyListeners();
      }
    }
  }

  /// Check if the app's API is reachable
  Future<void> _checkApiReachability() async {
    if (!_hasInternetAccess) {
      _isApiReachable = false;
      return;
    }

    try {
      // Try to reach the app's API ping endpoint (lighter than full health check)
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/health/ping'),
            headers: {'Cache-Control': 'no-cache'},
          )
          .timeout(_apiTimeout);

      final wasApiReachable = _isApiReachable;
      // Be more lenient - accept any response that's not a server error or timeout
      _isApiReachable = response.statusCode >= 200 && response.statusCode < 500;
      _lastApiCheck = DateTime.now();

      if (wasApiReachable != _isApiReachable) {
        debugPrint(
          '🌐 API reachability changed: ${_isApiReachable ? "Reachable" : "Unreachable"} (Status: ${response.statusCode})',
        );
        notifyListeners();
      } else if (_isApiReachable) {
        // Don't spam logs when everything is working
        debugPrint('🌐 API health check passed (Status: ${response.statusCode})');
      }
    } catch (e) {
      // Only mark as unreachable if we were previously reachable
      // This prevents false negatives during app startup
      if (_isApiReachable) {
        debugPrint('🌐 API became unreachable: $e');
        _isApiReachable = false;
        notifyListeners();
      }
    }
  }

  /// Set all connectivity states to offline
  void _setOfflineState() {
    final wasFullyOnline = isFullyOnline;
    _isConnected = false;
    _hasInternetAccess = false;
    _isApiReachable = false;

    if (wasFullyOnline) {
      debugPrint('🌐 Device is now fully offline');
      notifyListeners();
    }
  }

  /// Force refresh all connectivity checks
  Future<void> refreshConnectivity() async {
    debugPrint('🌐 Refreshing connectivity status...');

    try {
      await _checkInitialConnectivity();
    } catch (e) {
      debugPrint('❌ Error refreshing connectivity: $e');
    }
  }

  /// Get detailed connectivity status
  Map<String, dynamic> getConnectivityStatus() {
    return {
      'isConnected': _isConnected,
      'hasInternetAccess': _hasInternetAccess,
      'isApiReachable': _isApiReachable,
      'isFullyOnline': isFullyOnline,
      'connectionType': _connectionType.toString(),
      'lastConnectivityCheck': _lastConnectivityCheck?.toIso8601String(),
      'lastApiCheck': _lastApiCheck?.toIso8601String(),
    };
  }

  /// Get user-friendly connectivity message
  String getConnectivityMessage() {
    if (!_isConnected) {
      return 'No network connection. Please check your WiFi or mobile data.';
    } else if (!_hasInternetAccess) {
      return 'Connected to network but no internet access. Please check your connection.';
    } else if (!_isApiReachable) {
      return 'Internet available but our servers are unreachable. Please try again later.';
    } else {
      return 'Connected and online';
    }
  }

  /// Get connectivity issue type for specific handling
  ConnectivityIssueType getConnectivityIssueType() {
    if (!_isConnected) {
      return ConnectivityIssueType.noNetwork;
    } else if (!_hasInternetAccess) {
      return ConnectivityIssueType.noInternet;
    } else if (!_isApiReachable) {
      return ConnectivityIssueType.apiUnreachable;
    } else {
      return ConnectivityIssueType.none;
    }
  }

  /// Dispose the service
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    debugPrint('🌐 ConnectivityService disposed');
    super.dispose();
  }
}

/// Types of connectivity issues
enum ConnectivityIssueType { none, noNetwork, noInternet, apiUnreachable }
