import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Utilities for API requests
class ApiUtils {
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Get common headers for API requests, including authentication token if available
  static Future<Map<String, String>> getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      // Add auth token to headers if available
      final token = await _secureStorage.read(key: 'access_token');
      if (token != null && token.isNotEmpty) {
        // Ensure the token is properly formatted
        final cleanToken = token.trim();
        headers['Authorization'] = 'Bearer $cleanToken';
        debugPrint('Added token to request headers');
      } else {
        debugPrint('No token available for request');
      }
    } catch (e) {
      debugPrint('Error getting auth token: $e');
    }

    return headers;
  }

  /// Handle API errors and return a user-friendly message
  static String handleApiError(dynamic error) {
    debugPrint('API error: $error');
    return 'An error occurred. Please try again later.';
  }
}
