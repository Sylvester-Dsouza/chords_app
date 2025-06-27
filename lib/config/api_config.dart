import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;
import 'dart:async';
import 'package:dio/dio.dart';

/// Configuration for API endpoints and settings
class ApiConfig {
  // Regular IP address for development (physical devices)
  static const String devIpAddress = '192.168.1.3';
  
  // Special IP for Android emulator to access host machine
  static const String androidEmulatorIp = '10.0.2.2';
  
  // Production API URL
  static const String productionApiUrl = 'https://chords-api-jl8n.onrender.com';
  
  // API port for development
  static const int apiPort = 3001;

  // Track which URL is working
  static String? _workingBaseUrl;
  static bool _isTestingConnections = false;
  
  /// Get the appropriate base URL without the /api suffix
  static String get baseUrlWithoutSuffix {
    // If we're in production mode, always use the production URL
    if (const bool.fromEnvironment('dart.vm.product')) {
      return productionApiUrl;
    }
    
    // If we're in web, use the dev IP
    if (kIsWeb) {
      return 'http://$devIpAddress:$apiPort';
    }

    // If we already found a working URL, use it
    if (_workingBaseUrl != null) {
      return _workingBaseUrl!;
    }
    
    // Start testing connections if not already doing so
    if (!_isTestingConnections) {
      _testConnections();
    }
    
    // Default fallbacks while testing connections
    if (Platform.isAndroid) {
      // For Android, try the emulator IP first
      return 'http://$androidEmulatorIp:$apiPort';
    } else {
      // For iOS and other platforms
      return 'http://$devIpAddress:$apiPort';
    }
  }

  /// Test different connection methods and find the one that works
  static Future<void> _testConnections() async {
    if (_isTestingConnections) return;
    _isTestingConnections = true;
    
    debugPrint('🌐 Testing API connections...');
    
    // List of URLs to try
    final urlsToTry = [
      if (Platform.isAndroid) 'http://$androidEmulatorIp:$apiPort',
      'http://$devIpAddress:$apiPort',
      'http://localhost:$apiPort',
      'http://127.0.0.1:$apiPort',
    ];
    
    for (final url in urlsToTry) {
      debugPrint('🌐 Testing connection to $url');
      try {
        final dio = Dio();
        dio.options.connectTimeout = const Duration(seconds: 2);
        dio.options.sendTimeout = const Duration(seconds: 2);
        dio.options.receiveTimeout = const Duration(seconds: 2);
        
        final response = await dio.get(
          '$url/api/health',
          options: Options(validateStatus: (_) => true),
        );
        
        if (response.statusCode != null && response.statusCode! < 500) {
          debugPrint('✅ Successfully connected to $url');
          _workingBaseUrl = url;
          break;
        }
      } catch (e) {
        debugPrint('❌ Failed to connect to $url: ${e.toString()}');
      }
    }
    
    _isTestingConnections = false;
    if (_workingBaseUrl == null) {
      debugPrint('⚠️ No working connection found, using default');
    }
  }
  
  /// Base URL for the API with /api suffix
  static String get baseUrl {
    final url = baseUrlWithoutSuffix;
    debugPrint('🌐 Using API base URL: $url/api');
    return '$url/api';
  }
  
  /// Force a connection test - useful to call during app startup
  static Future<void> testConnections() async {
    await _testConnections();
  }

  /// Connection timeout in seconds
  static const int connectionTimeout = 10;

  /// Receive timeout in seconds
  static const int receiveTimeout = 10;
}
