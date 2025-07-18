import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session management service to detect app restarts vs resumes
/// Only refreshes data on new sessions to improve performance and prevent blank screens
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const String _keyLastSessionTime = 'last_session_time';
  static const String _keyAppStartTime = 'app_start_time';
  
  // Session timeout - if app was paused for more than this time, consider it a new session
  static const Duration _sessionTimeout = Duration(minutes: 30);
  
  DateTime? _currentSessionStart;
  DateTime? _lastSessionTime;
  bool _isNewSession = true;

  /// Initialize session manager and detect if this is a new session
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentSessionStart = DateTime.now();
      
      // Get last session time
      final lastSessionTimestamp = prefs.getInt(_keyLastSessionTime);
      if (lastSessionTimestamp != null) {
        _lastSessionTime = DateTime.fromMillisecondsSinceEpoch(lastSessionTimestamp);
        
        // Check if this is a new session (app was closed for more than session timeout)
        final timeSinceLastSession = _currentSessionStart!.difference(_lastSessionTime!);
        _isNewSession = timeSinceLastSession > _sessionTimeout;
        
        debugPrint('📱 Session Manager: Time since last session: ${timeSinceLastSession.inMinutes} minutes');
        debugPrint('📱 Session Manager: Is new session: $_isNewSession');
      } else {
        // First time app launch
        _isNewSession = true;
        debugPrint('📱 Session Manager: First app launch detected');
      }
      
      // Store current session start time
      await prefs.setInt(_keyAppStartTime, _currentSessionStart!.millisecondsSinceEpoch);
      
      debugPrint('📱 Session Manager initialized - New session: $_isNewSession');
    } catch (e) {
      debugPrint('❌ Error initializing session manager: $e');
      // Default to new session on error
      _isNewSession = true;
    }
  }

  /// Check if this is a new session (app restart vs app resume)
  bool get isNewSession => _isNewSession;

  /// Check if data should be refreshed (only on new sessions)
  bool shouldRefreshData() {
    return _isNewSession;
  }

  /// Mark that data has been refreshed for this session
  void markDataRefreshed() {
    _isNewSession = false;
    debugPrint('📱 Session Manager: Data refreshed, session marked as active');
  }

  /// Called when app goes to background
  Future<void> onAppPaused() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastSessionTime, DateTime.now().millisecondsSinceEpoch);
      debugPrint('📱 Session Manager: App paused, session time saved');
    } catch (e) {
      debugPrint('❌ Error saving session time: $e');
    }
  }

  /// Called when app comes to foreground
  Future<void> onAppResumed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSessionTimestamp = prefs.getInt(_keyLastSessionTime);
      
      if (lastSessionTimestamp != null) {
        final lastSessionTime = DateTime.fromMillisecondsSinceEpoch(lastSessionTimestamp);
        final timeSinceLastSession = DateTime.now().difference(lastSessionTime);
        
        // Check if we should treat this as a new session
        final wasNewSession = _isNewSession;
        _isNewSession = timeSinceLastSession > _sessionTimeout;
        
        if (_isNewSession && !wasNewSession) {
          debugPrint('📱 Session Manager: App resumed after ${timeSinceLastSession.inMinutes} minutes - treating as NEW SESSION');
        } else {
          debugPrint('📱 Session Manager: App resumed after ${timeSinceLastSession.inMinutes} minutes - continuing session');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking session on resume: $e');
    }
  }

  /// Force a new session (useful for testing or manual refresh)
  void forceNewSession() {
    _isNewSession = true;
    debugPrint('📱 Session Manager: Forced new session');
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    return {
      'isNewSession': _isNewSession,
      'currentSessionStart': _currentSessionStart?.toIso8601String(),
      'lastSessionTime': _lastSessionTime?.toIso8601String(),
      'sessionTimeoutMinutes': _sessionTimeout.inMinutes,
    };
  }

  /// Reset session data (useful for logout)
  Future<void> resetSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastSessionTime);
      await prefs.remove(_keyAppStartTime);
      
      _currentSessionStart = null;
      _lastSessionTime = null;
      _isNewSession = true;
      
      debugPrint('📱 Session Manager: Session data reset');
    } catch (e) {
      debugPrint('❌ Error resetting session: $e');
    }
  }
}
