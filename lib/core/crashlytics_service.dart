import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'constants.dart';

/// Comprehensive Crashlytics service for error tracking and reporting
class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;
  bool _isEnabled = false;

  /// Initialize Crashlytics with proper configuration
  Future<void> initialize() async {
    debugPrint('🔍 Debug: Crashlytics initialize() called');
    debugPrint('🔍 Debug: Firebase.apps.length = ${Firebase.apps.length}');
    debugPrint('🔍 Debug: kDebugMode = $kDebugMode');
    debugPrint('🔍 Debug: AppConstants.enableCrashlyticsInDebug = ${AppConstants.enableCrashlyticsInDebug}');

    try {
      // Initialize if Firebase is available
      if (Firebase.apps.isNotEmpty) {
        debugPrint('🔍 Debug: Firebase apps found, initializing Crashlytics...');
        _crashlytics = FirebaseCrashlytics.instance;
        debugPrint('🔍 Debug: FirebaseCrashlytics.instance obtained');

        // Enable collection in both debug and release mode for testing
        await _crashlytics!.setCrashlyticsCollectionEnabled(true);
        debugPrint('🔍 Debug: setCrashlyticsCollectionEnabled(true) called');

        // In debug mode, also check the debug flag
        if (kDebugMode && AppConstants.enableCrashlyticsInDebug) {
          debugPrint('🧪 Crashlytics enabled in debug mode for testing');
        } else if (!kDebugMode) {
          debugPrint('🚀 Crashlytics enabled in release mode');
        } else {
          debugPrint('🔍 Debug: Debug mode but enableCrashlyticsInDebug = ${AppConstants.enableCrashlyticsInDebug}');
        }

        // Set up Flutter error handling
        FlutterError.onError = (FlutterErrorDetails details) {
          recordFlutterError(details);
        };

        // Set up platform error handling
        PlatformDispatcher.instance.onError = (error, stack) {
          recordError(error, stack, fatal: true);
          return true;
        };

        _isEnabled = true;
        _isInitialized = true;

        debugPrint('✅ Crashlytics initialized successfully');
        debugPrint('🔍 Debug: _isEnabled = $_isEnabled, _isInitialized = $_isInitialized');

        // Check if collection is enabled (this method doesn't exist, so we'll skip it)
        try {
          debugPrint('📊 Crashlytics collection is enabled');
        } catch (e) {
          debugPrint('⚠️ Could not check collection status: $e');
        }

        // Log successful initialization
        await logEvent('crashlytics_initialized', {
          'platform': Platform.operatingSystem,
          'app_version': AppConstants.appName,
          'debug_mode': kDebugMode.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        });

      } else {
        debugPrint('⚠️ Firebase not available - Crashlytics disabled');
        debugPrint('🔍 Debug: Firebase.apps.isEmpty, cannot initialize Crashlytics');
        _isEnabled = false;
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize Crashlytics: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      _isEnabled = false;
      _isInitialized = true;
    }
  }

  /// Force re-initialize Crashlytics (for debugging)
  Future<void> forceReinitialize() async {
    debugPrint('🔄 Force re-initializing Crashlytics...');
    _isEnabled = false;
    _isInitialized = false;
    _crashlytics = null;
    await initialize();
  }

  /// Record a Flutter framework error
  void recordFlutterError(FlutterErrorDetails details) {
    if (!_isEnabled || _crashlytics == null) {
      // Log to console in debug mode
      if (kDebugMode) {
        debugPrint('🐛 Flutter Error: ${details.exception}');
        debugPrint('Stack: ${details.stack}');
      }
      return;
    }

    try {
      _crashlytics!.recordFlutterError(details);
      
      if (EnvironmentConstants.enableLogging) {
        debugPrint('📊 Recorded Flutter error to Crashlytics: ${details.exception}');
      }
    } catch (e) {
      debugPrint('❌ Failed to record Flutter error: $e');
    }
  }

  /// Record a general error with context
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
    String? reason,
  }) async {
    if (!_isEnabled || _crashlytics == null) {
      // Log to console in debug mode
      if (kDebugMode) {
        debugPrint('🐛 Error: $error');
        debugPrint('Stack: $stackTrace');
        debugPrint('Context: $context');
        debugPrint('Reason: $reason');
      }
      return;
    }

    try {
      // Add context as custom keys
      if (context != null) {
        for (final entry in context.entries) {
          await _crashlytics!.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Add reason if provided
      if (reason != null) {
        await _crashlytics!.setCustomKey('error_reason', reason);
      }

      // Record the error
      await _crashlytics!.recordError(
        error,
        stackTrace,
        fatal: fatal,
        information: context?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
      );

      if (EnvironmentConstants.enableLogging) {
        debugPrint('📊 Recorded error to Crashlytics: $error');
      }
    } catch (e) {
      debugPrint('❌ Failed to record error: $e');
    }
  }

  /// Log a custom event for analytics
  Future<void> logEvent(String event, Map<String, dynamic> parameters) async {
    if (!_isEnabled || _crashlytics == null) {
      if (kDebugMode) {
        debugPrint('📝 Event: $event - $parameters');
      }
      return;
    }

    try {
      // Log as custom keys for context
      for (final entry in parameters.entries) {
        await _crashlytics!.setCustomKey('event_${entry.key}', entry.value.toString());
      }
      
      await _crashlytics!.log('Event: $event - ${parameters.toString()}');
      
      if (EnvironmentConstants.enableLogging) {
        debugPrint('📊 Logged event to Crashlytics: $event');
      }
    } catch (e) {
      debugPrint('❌ Failed to log event: $e');
    }
  }

  /// Set user information for crash reports
  Future<void> setUserInfo({
    required String userId,
    String? email,
    String? name,
    Map<String, dynamic>? customAttributes,
  }) async {
    if (!_isEnabled || _crashlytics == null) {
      if (kDebugMode) {
        debugPrint('👤 User Info: $userId, $email, $name');
      }
      return;
    }

    try {
      await _crashlytics!.setUserIdentifier(userId);
      
      if (email != null) {
        await _crashlytics!.setCustomKey('user_email', email);
      }
      
      if (name != null) {
        await _crashlytics!.setCustomKey('user_name', name);
      }

      // Set custom attributes
      if (customAttributes != null) {
        for (final entry in customAttributes.entries) {
          await _crashlytics!.setCustomKey('user_${entry.key}', entry.value.toString());
        }
      }

      if (EnvironmentConstants.enableLogging) {
        debugPrint('📊 Set user info in Crashlytics: $userId');
      }
    } catch (e) {
      debugPrint('❌ Failed to set user info: $e');
    }
  }

  /// Clear user information (for logout)
  Future<void> clearUserInfo() async {
    if (!_isEnabled || _crashlytics == null) return;

    try {
      await _crashlytics!.setUserIdentifier('');
      await _crashlytics!.setCustomKey('user_email', '');
      await _crashlytics!.setCustomKey('user_name', '');
      
      if (EnvironmentConstants.enableLogging) {
        debugPrint('📊 Cleared user info from Crashlytics');
      }
    } catch (e) {
      debugPrint('❌ Failed to clear user info: $e');
    }
  }

  /// Record API errors with detailed context
  Future<void> recordApiError(
    String endpoint,
    int? statusCode,
    dynamic error, {
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
  }) async {
    final context = <String, dynamic>{
      'api_endpoint': endpoint,
      'error_type': 'api_error',
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (statusCode != null) {
      context['status_code'] = statusCode;
    }

    if (requestData != null) {
      context['request_data'] = requestData.toString();
    }

    if (responseData != null) {
      context['response_data'] = responseData.toString();
    }

    await recordError(
      error,
      StackTrace.current,
      context: context,
      reason: 'API call failed for $endpoint',
    );
  }

  /// Record navigation errors
  Future<void> recordNavigationError(
    String route,
    dynamic error, {
    Map<String, dynamic>? routeArguments,
  }) async {
    final context = <String, dynamic>{
      'route': route,
      'error_type': 'navigation_error',
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (routeArguments != null) {
      context['route_arguments'] = routeArguments.toString();
    }

    await recordError(
      error,
      StackTrace.current,
      context: context,
      reason: 'Navigation failed for route $route',
    );
  }

  /// Record audio/media errors
  Future<void> recordMediaError(
    String mediaType,
    String mediaUrl,
    dynamic error, {
    Map<String, dynamic>? mediaInfo,
  }) async {
    final context = <String, dynamic>{
      'media_type': mediaType,
      'media_url': mediaUrl,
      'error_type': 'media_error',
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (mediaInfo != null) {
      context.addAll(mediaInfo);
    }

    await recordError(
      error,
      StackTrace.current,
      context: context,
      reason: 'Media operation failed for $mediaType',
    );
  }

  /// Record performance issues
  Future<void> recordPerformanceIssue(
    String operation,
    Duration duration, {
    Map<String, dynamic>? performanceData,
  }) async {
    // Only record if operation took longer than threshold
    if (duration.inMilliseconds < 2000) return;

    final context = <String, dynamic>{
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'error_type': 'performance_issue',
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (performanceData != null) {
      context.addAll(performanceData);
    }

    await logEvent('performance_issue', context);
  }

  /// Test crash (for testing purposes only)
  /// This will work in both debug and release mode for testing
  Future<void> testCrash() async {
    debugPrint('🔍 Debug: testCrash called');
    debugPrint('🔍 Debug: _isEnabled = $_isEnabled');
    debugPrint('🔍 Debug: _isInitialized = $_isInitialized');
    debugPrint('🔍 Debug: _crashlytics = $_crashlytics');
    debugPrint('🔍 Debug: Firebase.apps.length = ${Firebase.apps.length}');

    if (!_isEnabled || _crashlytics == null) {
      debugPrint('⚠️ Cannot test crash - Crashlytics not enabled');
      debugPrint('⚠️ _isEnabled: $_isEnabled, _crashlytics: $_crashlytics');
      return;
    }

    try {
      debugPrint('🧪 Triggering test crash...');
      _crashlytics!.crash();
    } catch (e) {
      debugPrint('❌ Failed to trigger test crash: $e');
    }
  }

  /// Check if Crashlytics is enabled and ready
  bool get isEnabled => _isEnabled && _isInitialized;

  /// Get Crashlytics instance (for advanced usage)
  FirebaseCrashlytics? get instance => _crashlytics;

  /// Force send any pending crash reports
  Future<void> sendUnsentReports() async {
    if (!_isEnabled || _crashlytics == null) return;

    try {
      await _crashlytics!.sendUnsentReports();
      if (EnvironmentConstants.enableLogging) {
        debugPrint('📊 Sent unsent crash reports');
      }
    } catch (e) {
      debugPrint('❌ Failed to send unsent reports: $e');
    }
  }

  /// Check for unsent reports
  Future<bool> checkForUnsentReports() async {
    if (!_isEnabled || _crashlytics == null) return false;

    try {
      return await _crashlytics!.checkForUnsentReports();
    } catch (e) {
      debugPrint('❌ Failed to check for unsent reports: $e');
      return false;
    }
  }
}
