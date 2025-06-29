import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/service_locator.dart';
import '../core/crashlytics_service.dart';
import '../config/theme.dart';
import '../widgets/inner_screen_app_bar.dart';

/// Debug-only screen for testing Crashlytics functionality
/// This screen should only be accessible in debug builds
class CrashlyticsTestScreen extends StatefulWidget {
  const CrashlyticsTestScreen({super.key});

  @override
  State<CrashlyticsTestScreen> createState() => _CrashlyticsTestScreenState();
}

class _CrashlyticsTestScreenState extends State<CrashlyticsTestScreen> {
  final CrashlyticsService _crashlytics = serviceLocator.crashlyticsService;
  bool _isLoading = false;
  String _lastAction = '';

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (kReleaseMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Available')),
        body: const Center(
          child: Text('Crashlytics testing is only available in debug mode'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          const InnerScreenAppBar(title: 'Crashlytics Test'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  _buildStatusCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Test Actions
                  _buildTestSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Last Action
                  if (_lastAction.isNotEmpty) _buildLastActionCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: _crashlytics.isEnabled 
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _crashlytics.isEnabled ? Icons.check_circle : Icons.error,
                color: _crashlytics.isEnabled ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Crashlytics Status',
                style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _crashlytics.isEnabled
                ? '✅ Crashlytics is enabled and ready'
                : '❌ Crashlytics is not enabled',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Debug Mode: ${kDebugMode ? 'ON' : 'OFF'}',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          Text(
            'Release Mode: ${kReleaseMode ? 'ON' : 'OFF'}',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          Text(
            'Instance: ${_crashlytics.instance != null ? 'Available' : 'NULL'}',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          Text(
            'Firebase Apps: ${Firebase.apps.length}',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Actions',
          style: TextStyle(
            color: AppTheme.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
        const SizedBox(height: 16),
        
        // Test Buttons
        _buildTestButton(
          title: 'Log Test Event',
          description: 'Send a custom test event to Crashlytics',
          icon: Icons.event_note,
          color: AppTheme.primary,
          onPressed: _logTestEvent,
        ),
        
        const SizedBox(height: 12),
        
        _buildTestButton(
          title: 'Record Test Error',
          description: 'Send a non-fatal error to Crashlytics',
          icon: Icons.error_outline,
          color: AppTheme.warning,
          onPressed: _recordTestError,
        ),
        
        const SizedBox(height: 12),
        
        _buildTestButton(
          title: 'Test User Info',
          description: 'Set test user information',
          icon: Icons.person,
          color: Colors.green,
          onPressed: _setTestUserInfo,
        ),

        const SizedBox(height: 12),

        _buildTestButton(
          title: 'Test Local Notification',
          description: 'Test if local notifications appear in system drawer',
          icon: Icons.notifications,
          color: Colors.purple,
          onPressed: _testLocalNotification,
        ),

        const SizedBox(height: 12),

        _buildTestButton(
          title: 'Re-initialize Crashlytics',
          description: 'Force re-initialize Crashlytics service',
          icon: Icons.refresh,
          color: Colors.blue,
          onPressed: _reinitializeCrashlytics,
        ),

        const SizedBox(height: 12),

        _buildTestButton(
          title: 'Force Crash (DANGER)',
          description: 'Force a fatal crash - USE CAREFULLY!',
          icon: Icons.warning,
          color: Colors.red,
          onPressed: _showCrashConfirmation,
        ),
      ],
    );
  }

  Widget _buildTestButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.textMuted,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLastActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Action',
            style: TextStyle(
              color: AppTheme.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _lastAction,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logTestEvent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _crashlytics.logEvent('test_event', {
        'test_type': 'manual_test',
        'screen': 'crashlytics_test',
        'timestamp': DateTime.now().toIso8601String(),
        'user_action': 'log_test_event',
      });

      setState(() {
        _lastAction = '✅ Test event logged successfully at ${DateTime.now().toString().substring(11, 19)}';
      });

      _showSuccessSnackBar('Test event sent to Crashlytics');
    } catch (e) {
      _showErrorSnackBar('Failed to log test event: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _recordTestError() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _crashlytics.recordError(
        Exception('This is a test error from Crashlytics Test Screen'),
        StackTrace.current,
        context: {
          'test_type': 'manual_error_test',
          'screen': 'crashlytics_test',
          'error_category': 'test',
          'timestamp': DateTime.now().toIso8601String(),
        },
        reason: 'Manual test error triggered by user',
        fatal: false,
      );

      setState(() {
        _lastAction = '✅ Test error recorded successfully at ${DateTime.now().toString().substring(11, 19)}';
      });

      _showSuccessSnackBar('Test error sent to Crashlytics');
    } catch (e) {
      _showErrorSnackBar('Failed to record test error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setTestUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _crashlytics.setUserInfo(
        userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'test@example.com',
        name: 'Test User',
        customAttributes: {
          'test_mode': 'true',
          'app_version': '1.0.0',
          'test_timestamp': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _lastAction = '✅ Test user info set successfully at ${DateTime.now().toString().substring(11, 19)}';
      });

      _showSuccessSnackBar('Test user info sent to Crashlytics');
    } catch (e) {
      _showErrorSnackBar('Failed to set test user info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLocalNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get notification service from service locator
      final notificationService = serviceLocator.notificationService;

      // Test local notification
      await notificationService.testLocalNotification();

      setState(() {
        _lastAction = '✅ Test notification sent at ${DateTime.now().toString().substring(11, 19)} - Check notification drawer!';
      });

      _showSuccessSnackBar('Test notification sent! Check your notification drawer.');
    } catch (e) {
      _showErrorSnackBar('Failed to send test notification: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reinitializeCrashlytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _crashlytics.forceReinitialize();

      setState(() {
        _lastAction = '✅ Crashlytics re-initialized at ${DateTime.now().toString().substring(11, 19)}';
      });

      _showSuccessSnackBar('Crashlytics re-initialized successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to re-initialize Crashlytics: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCrashConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          '⚠️ Force Crash',
          style: TextStyle(
            color: Colors.red,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
        content: Text(
          'This will force the app to crash and send a crash report to Firebase Crashlytics.\n\nThe app will close immediately.\n\nAre you sure you want to continue?',
          style: TextStyle(
            color: AppTheme.text,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _forceCrash();
            },
            child: Text(
              'Force Crash',
              style: TextStyle(
                color: Colors.red,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _forceCrash() async {
    try {
      // Log that we're about to crash
      await _crashlytics.logEvent('force_crash_initiated', {
        'test_type': 'manual_crash_test',
        'screen': 'crashlytics_test',
        'timestamp': DateTime.now().toIso8601String(),
        'warning': 'This is an intentional test crash',
      });

      // Wait a moment for the log to be sent
      await Future.delayed(const Duration(milliseconds: 500));

      // Force crash
      _crashlytics.testCrash();
    } catch (e) {
      _showErrorSnackBar('Failed to force crash: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
