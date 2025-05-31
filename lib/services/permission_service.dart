import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Singleton pattern
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Track if permissions have been requested
  bool _storagePermissionRequested = false;

  // Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit storage permission for app's documents directory
      return true;
    }
    return false;
  }

  // Request storage permission
  Future<bool> requestStoragePermission() async {
    if (_storagePermissionRequested) {
      // Check if we already have the permission
      final hasPermission = await hasStoragePermission();
      if (hasPermission) {
        return true;
      }
      // If we don't have permission despite requesting before, we'll try again
    }

    _storagePermissionRequested = true;
    debugPrint('Requesting storage permission...');

    if (Platform.isAndroid) {
      // First, request the basic storage permission
      final status = await Permission.storage.request();
      debugPrint('Storage permission status: ${status.toString()}');

      // For Android 11+ (API level 30+), we need to use a different approach
      if (Platform.isAndroid) {
        try {
          // Check Android version
          final sdkInt = await _getAndroidSdkVersion();
          debugPrint('Android SDK version: $sdkInt');

          if (sdkInt >= 30) { // Android 11+
            debugPrint('Android 11+ detected, requesting MANAGE_EXTERNAL_STORAGE');
            // For Android 11+, we need to request MANAGE_EXTERNAL_STORAGE
            // This requires the user to go to Settings
            final manageStatus = await Permission.manageExternalStorage.status;
            if (!manageStatus.isGranted) {
              final result = await Permission.manageExternalStorage.request();
              debugPrint('MANAGE_EXTERNAL_STORAGE status: ${result.toString()}');

              // On Android 11+, we need both permissions
              return status.isGranted && result.isGranted;
            }
          }
        } catch (e) {
          debugPrint('Error checking Android version or requesting permissions: $e');
        }
      }

      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit storage permission for app's documents directory
      return true;
    }

    return false;
  }

  // Helper method to get Android SDK version
  Future<int> _getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      // Use platform channels to get the SDK version
      const platform = MethodChannel('com.example.chords_app/platform');
      final int sdkInt = await platform.invokeMethod('getAndroidSdkVersion');
      return sdkInt;
    } catch (e) {
      debugPrint('Error getting Android SDK version: $e');
      // Default to a high version to be safe
      return 30;
    }
  }

  // Check if we already have storage permission without requesting
  Future<bool> checkStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit storage permission for app's documents directory
      return true;
    }
    return false;
  }

  // Show a dialog explaining why we need storage permission
  Future<bool> showStoragePermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission'),
        content: const Text(
          'This app needs storage permission to save chord sheets as PDF files to your device. '
          'Would you like to grant this permission now?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('LATER'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('GRANT'),
          ),
        ],
      ),
    );

    if (result == true) {
      return await requestStoragePermission();
    }

    return false;
  }
}
