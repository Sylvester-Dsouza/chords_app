import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Configuration for API endpoints and settings
class ApiConfig {
  /// Base URL for the API
  /// For Android emulator, use 10.0.2.2 instead of localhost
  /// For physical devices, use your computer's IP address
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://192.168.1.3:3001/api';
    } else if (const bool.fromEnvironment('dart.vm.product')) {
      // Release mode - use production server
      return 'https://chords-api-jl8n.onrender.com/api';
    } else {
      // Debug mode
      if (Platform.isAndroid) {
        // For Android emulator and devices, use the actual IP address
        return 'http://192.168.1.3:3001/api';
      } else {
        // For iOS simulator or physical devices
        return 'http://192.168.1.3.155:3001/api';
      }
    }
  }

  /// Connection timeout in seconds
  static const int connectionTimeout = 10;

  /// Receive timeout in seconds
  static const int receiveTimeout = 10;
}
