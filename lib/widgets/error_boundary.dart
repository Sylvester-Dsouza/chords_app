import 'package:flutter/material.dart';
import '../core/crashlytics_service.dart';

/// A widget that catches and handles errors in its child widget tree
/// Prevents app crashes by showing a user-friendly error screen
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // Set up global error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log the error
      debugPrint('🚨 ErrorBoundary caught error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');

      // Call custom error handler if provided
      widget.onError?.call(details);

      // Update state to show error UI
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _buildDefaultErrorWidget();
    }

    // Wrap child in error catching widget
    return _ErrorCatcher(
      onError: (error, stackTrace) {
        debugPrint('🚨 ErrorBoundary caught runtime error: $error');
        debugPrint('Stack trace: $stackTrace');

        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      },
      child: widget.child,
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 24),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'We encountered an unexpected error. Don\'t worry, your data is safe.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _retry,
                  child: const Text('Try Again'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _goToHome,
                  child: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _retry() {
    setState(() {
      _hasError = false;
    });
  }

  void _goToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }
}

/// Internal widget to catch runtime errors
class _ErrorCatcher extends StatelessWidget {
  final Widget child;
  final Function(Object, StackTrace?) onError;

  const _ErrorCatcher({required this.child, required this.onError});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Global error boundary for the entire app
class GlobalErrorBoundary extends StatelessWidget {
  final Widget child;

  const GlobalErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (details) {
        // Log to analytics or crash reporting service
        debugPrint('🚨 Global error caught: ${details.exception}');

        // Send to crash reporting service if available
        try {
          final crashlytics = CrashlyticsService();
          crashlytics.recordError(
            details.exception,
            details.stack,
            reason: 'UI error caught by ErrorBoundary',
            fatal: false,
          );
        } catch (e) {
          // Ignore errors from crash reporting
          debugPrint('Failed to record error to crashlytics: $e');
        }
      },
      child: child,
    );
  }
}
