import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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
  FlutterErrorDetails? _errorDetails;

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
          _errorDetails = details;
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
            _errorDetails = FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'ErrorBoundary',
              context: ErrorDescription('Runtime error caught by ErrorBoundary'),
            );
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),
              
              // Error title
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Error description
              Text(
                'We encountered an unexpected error. Don\'t worry, your data is safe.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Retry button
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              
              // Go to home button
              TextButton(
                onPressed: _goToHome,
                child: const Text('Go to Home'),
              ),
              
              // Debug info (only in debug mode)
              if (kDebugMode && _errorDetails != null) ...[
                const SizedBox(height: 32),
                ExpansionTile(
                  title: const Text('Debug Info'),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorDetails!.exception.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorDetails = null;
    });
  }

  void _goToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
  }
}

/// Internal widget to catch runtime errors
class _ErrorCatcher extends StatelessWidget {
  final Widget child;
  final Function(Object, StackTrace?) onError;

  const _ErrorCatcher({
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Global error boundary for the entire app
class GlobalErrorBoundary extends StatelessWidget {
  final Widget child;

  const GlobalErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (details) {
        // Log to analytics or crash reporting service
        debugPrint('🚨 Global error caught: ${details.exception}');
        
        // In production, you could send this to a crash reporting service
        // like Firebase Crashlytics or Sentry
      },
      child: child,
    );
  }
}
