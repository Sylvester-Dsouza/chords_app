import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

// Error message helper class to handle different types of errors
class ErrorMessageHelper {
  static ErrorData getMessageForError(dynamic error, BuildContext context) {
    final String errorString = error.toString().toLowerCase();
    
    // Network connectivity errors
    if (_isNetworkError(errorString)) {
      return ErrorData(
        title: 'Connection Problem',
        message: 'Please check your internet connection and try again.',
        icon: Icons.signal_wifi_off,
        iconColor: Colors.orange,
        primaryAction: 'Retry',
        secondaryAction: 'Go Offline',
      );
    }
    
    // Authentication errors
    if (_isAuthError(errorString)) {
      return ErrorData(
        title: 'Authentication Required',
        message: 'Please sign in again to continue.',
        icon: Icons.lock_outline,
        iconColor: Colors.red[700],
        primaryAction: 'Sign In',
        secondaryAction: 'Cancel',
      );
    }
    
    // Permission errors
    if (_isPermissionError(errorString)) {
      return ErrorData(
        title: 'Permission Required',
        message: 'Permission denied. Please grant required permissions.',
        icon: Icons.no_accounts,
        iconColor: Colors.red[700],
        primaryAction: 'Settings',
        secondaryAction: 'Cancel',
      );
    }
    
    // Server errors
    if (_isServerError(errorString)) {
      return ErrorData(
        title: 'Server Problem',
        message: 'Server error occurred. Please try again later.',
        icon: Icons.cloud_off,
        iconColor: Colors.grey[700],
        primaryAction: 'Retry',
        secondaryAction: 'Go Offline',
      );
    }
    
    // Default error handling
    return ErrorData(
      title: 'Error',
      message: error?.toString() ?? 'An unknown error occurred',
      icon: Icons.error_outline,
      iconColor: Colors.red,
      primaryAction: 'OK',
    );
  }
  
  /// Check if the error is network-related
  static bool _isNetworkError(String errorString) {
    return errorString.contains('socket') ||
           errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('internet') ||
           errorString.contains('host') ||
           errorString.contains('lookup') ||
           errorString.contains('connect');
  }
  
  /// Check if the error is authentication-related
  static bool _isAuthError(String errorString) {
    return errorString.contains('unauthorized') ||
           errorString.contains('unauthenticated') ||
           errorString.contains('authentication') ||
           errorString.contains('auth') ||
           errorString.contains('login') ||
           errorString.contains('permission') ||
           errorString.contains('forbidden') ||
           errorString.contains('401') ||
           errorString.contains('403');
  }
  
  /// Check if the error is permission-related
  static bool _isPermissionError(String errorString) {
    return errorString.contains('permission') ||
           errorString.contains('access denied') ||
           errorString.contains('not allowed');
  }
  
  /// Check if the error is server-related
  static bool _isServerError(String errorString) {
    return errorString.contains('server') ||
           errorString.contains('500') ||
           errorString.contains('502') ||
           errorString.contains('503') ||
           errorString.contains('504') ||
           errorString.contains('internal');
  }
}

// Data class for error information
class ErrorData {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final String primaryAction;
  final String? secondaryAction;

  ErrorData({
    required this.title,
    required this.message,
    required this.icon,
    this.iconColor,
    required this.primaryAction,
    this.secondaryAction,
  });
}

class UIHelpers {
  // Show a success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 20,
          right: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Show an error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 20,
          right: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Show an enhanced error snackbar with action
  static void showEnhancedErrorSnackBar(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 20,
          right: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: actionLabel ?? 'RETRY',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onAction?.call();
          },
        ),
      ),
    );
  }

  // Show a smart error dialog based on error type
  static Future<void> showSmartErrorDialog(
    BuildContext context,
    dynamic error, {
    VoidCallback? onPrimaryAction,
    VoidCallback? onSecondaryAction,
  }) async {
    final errorData = ErrorMessageHelper.getMessageForError(error, context);
    
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                errorData.icon,
                color: errorData.iconColor ?? Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                errorData.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              errorData.message,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
          actions: <Widget>[
            if (errorData.secondaryAction != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSecondaryAction?.call();
                },
                child: Text(errorData.secondaryAction!),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onPrimaryAction?.call();
              },
              child: Text(errorData.primaryAction),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          elevation: 4,
        );
      },
    );
  }

  // Show a toast message
  static void showToast(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    bool isError = false,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height * 0.15,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isError ? Colors.red.shade700 : Colors.black87,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  // Copy text to clipboard and show a snackbar
  static void copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    showSuccessSnackBar(context, message);
  }
}