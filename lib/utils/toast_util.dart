import 'package:flutter/material.dart';
import '../config/theme.dart';

/// A utility class to show modern toast messages using SnackBar
/// This provides a more visually appealing toast notification experience
class ToastUtil {
  /// Shows a toast message using SnackBar with modern styling
  ///
  /// [context] - BuildContext to show the SnackBar
  /// [message] - Message to display
  /// [duration] - Duration to show the message (default: 3 seconds)
  /// [type] - Type of toast (info, success, error, warning)
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    ToastType type = ToastType.info,
  }) {
    // Clear any existing snackbars to prevent stacking
    ScaffoldMessenger.of(context).clearSnackBars();

    // Get toast configuration based on type
    final config = _getToastConfig(type);

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            config.icon,
            color: config.iconColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600, // Slightly bolder
                letterSpacing: 0.2, // Slightly increased letter spacing for better readability
              ),
            ),
          ),
        ],
      ),
      duration: duration,
      backgroundColor: config.backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      action: SnackBarAction(
        label: 'DISMISS',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Shows a success toast message
  static void showSuccess(BuildContext context, String message) {
    show(context, message, type: ToastType.success);
  }

  /// Shows an error toast message
  static void showError(BuildContext context, String message) {
    show(context, message, type: ToastType.error);
  }

  /// Shows a warning toast message
  static void showWarning(BuildContext context, String message) {
    show(context, message, type: ToastType.warning);
  }

  /// Shows an info toast message
  static void showInfo(BuildContext context, String message) {
    show(context, message, type: ToastType.info);
  }

  /// Get toast configuration based on type
  static ToastConfig _getToastConfig(ToastType type) {
    switch (type) {
      case ToastType.success:
        return ToastConfig(
          backgroundColor: AppTheme.success,
          icon: Icons.check_circle_outline,
          iconColor: AppTheme.textPrimary,
        );
      case ToastType.error:
        return ToastConfig(
          backgroundColor: AppTheme.error,
          icon: Icons.error_outline,
          iconColor: AppTheme.textPrimary,
        );
      case ToastType.warning:
        return ToastConfig(
          backgroundColor: AppTheme.warning,
          icon: Icons.warning_amber_outlined,
          iconColor: Colors.white,
        );
      case ToastType.info:
        return ToastConfig(
          backgroundColor: const Color(0xFF0D47A1), // Darker blue for better contrast
          icon: Icons.info_outline,
          iconColor: Colors.white,
        );
    }
  }
}

/// Toast types for different notification purposes
enum ToastType {
  info,
  success,
  error,
  warning,
}

/// Configuration for toast appearance
class ToastConfig {
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;

  ToastConfig({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
  });
}
