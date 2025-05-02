import 'package:flutter/material.dart';

/// A utility class to show toast messages using SnackBar
/// This replaces the functionality of fluttertoast package
class ToastUtil {
  /// Shows a toast message using SnackBar
  /// 
  /// [context] - BuildContext to show the SnackBar
  /// [message] - Message to display
  /// [duration] - Duration to show the message (default: 2 seconds)
  /// [isError] - Whether this is an error message (changes background color)
  static void show(
    BuildContext context, 
    String message, {
    Duration duration = const Duration(seconds: 2),
    bool isError = false,
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: isError ? Colors.red : null,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  /// Shows a success toast message
  static void showSuccess(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  /// Shows an error toast message
  static void showError(BuildContext context, String message) {
    show(context, message, isError: true);
  }
}
