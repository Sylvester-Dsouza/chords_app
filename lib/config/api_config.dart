import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuration for API endpoints and settings
class ApiConfig {
  /// Base URL for the API
  /// For Android emulator, use 10.0.2.2 instead of localhost
  /// For physical devices, use your computer's IP address
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3001/api';
    } else if (const bool.fromEnvironment('dart.vm.product')) {
      // Release mode - use production server
      return 'https://api.yourapp.com/api';
    } else {
      // Debug mode - use special IP for Android emulator
      return 'http://10.0.2.2:3001/api';
    }
  }

  /// Connection timeout in seconds
  static const int connectionTimeout = 10;

  /// Receive timeout in seconds
  static const int receiveTimeout = 10;
}
