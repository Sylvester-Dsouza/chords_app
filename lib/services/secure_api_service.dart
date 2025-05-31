import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// A secure API service with enhanced error handling, retry logic,
/// and proper HTTPS enforcement.
class SecureApiService {
  // Singleton instance
  static final SecureApiService _instance = SecureApiService._internal();
  factory SecureApiService() => _instance;
  SecureApiService._internal() {
    _initializeDio();
  }

  // Base URL based on environment
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://chords-api-jl8n.onrender.com/api';
    } else if (const bool.fromEnvironment('dart.vm.product')) {
      // Release mode - use production server
      return 'https://chords-api-jl8n.onrender.com/api';
    } else {
      // Debug mode
      if (Platform.isAndroid) {
        // For Android emulator and devices, use the actual IP address
        return 'http://192.168.249.155:3001/api';
      } else {
        // For iOS simulator or physical devices
        return 'http://192.168.249.155:3001/api';
      }
    }
  }

  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Rate limiting
  final Map<String, DateTime> _lastRequestTimes = {};
  static const Duration _minRequestInterval = Duration(milliseconds: 300);

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  // Initialize Dio with interceptors
  void _initializeDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Apply rate limiting
        final String requestKey = '${options.method}:${options.path}';
        final now = DateTime.now();
        if (_lastRequestTimes.containsKey(requestKey)) {
          final lastRequestTime = _lastRequestTimes[requestKey]!;
          final timeSinceLastRequest = now.difference(lastRequestTime);
          if (timeSinceLastRequest < _minRequestInterval) {
            final delayNeeded = _minRequestInterval - timeSinceLastRequest;
            await Future.delayed(delayNeeded);
          }
        }
        _lastRequestTimes[requestKey] = DateTime.now();

        // Add authorization header if token exists
        final token = await _secureStorage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Enforce HTTPS in production
        if (const bool.fromEnvironment('dart.vm.product')) {
          if (!options.path.startsWith('https://')) {
            options.path = options.path.replaceFirst('http://', 'https://');
          }
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Handle successful response
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        // Handle token refresh if unauthorized
        if (e.response?.statusCode == 401) {
          try {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request with the new token
              final token = await _secureStorage.read(key: 'access_token');
              final opts = Options(
                method: e.requestOptions.method,
                headers: {...e.requestOptions.headers, 'Authorization': 'Bearer $token'},
              );

              final response = await _dio.request(
                e.requestOptions.path,
                data: e.requestOptions.data,
                queryParameters: e.requestOptions.queryParameters,
                options: opts,
              );

              return handler.resolve(response);
            }
          } catch (refreshError) {
            debugPrint('Error refreshing token: $refreshError');
          }
        }

        return handler.next(e);
      },
    ));
  }

  // Refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        return false;
      }

      // Create a new Dio instance to avoid interceptors loop
      final refreshDio = Dio();
      final response = await refreshDio.post(
        '$baseUrl/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['accessToken'] != null) {
        await _storeTokens(response.data);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  // Store tokens securely
  Future<void> _storeTokens(Map<String, dynamic> data) async {
    try {
      if (data['accessToken'] != null) {
        await _secureStorage.write(
          key: 'access_token',
          value: data['accessToken'],
        );
        debugPrint('Stored access token');
      }

      if (data['refreshToken'] != null) {
        await _secureStorage.write(
          key: 'refresh_token',
          value: data['refreshToken'],
        );
        debugPrint('Stored refresh token');
      }
    } catch (e) {
      debugPrint('Error storing tokens: $e');
    }
  }

  // Register a new user with enhanced security
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required bool termsAccepted,
  }) async {
    try {
      debugPrint('Registering user with email: $email');

      // Validate input
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'All fields are required',
        };
      }

      if (!termsAccepted) {
        return {
          'success': false,
          'message': 'You must accept the terms and conditions',
        };
      }

      if (password.length < 8) {
        return {
          'success': false,
          'message': 'Password must be at least 8 characters long',
        };
      }

      // Use the correct endpoint with retry logic
      final response = await _requestWithRetry(
        () => _dio.post('/auth/register', data: {
          'name': name,
          'email': email,
          'password': password,
          'termsAccepted': termsAccepted,
        }),
      );

      debugPrint('Registration response: ${response.statusCode}');

      if (response.statusCode == 201) {
        await _storeTokens(response.data);
        return {
          'success': true,
          'data': response.data['user'] ?? response.data['customer'],
        };
      }

      return {
        'success': false,
        'message': 'Registration failed',
      };
    } catch (e) {
      debugPrint('Registration error: $e');
      return {
        'success': false,
        'message': e is DioException && e.response?.data['message'] != null
            ? e.response?.data['message']
            : 'Registration failed. Please try again.',
      };
    }
  }

  // Login with email and password with enhanced security
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Email and password are required',
        };
      }

      // Use the correct endpoint with retry logic
      final response = await _requestWithRetry(
        () => _dio.post('/auth/login', data: {
          'email': email,
          'password': password,
          'rememberMe': rememberMe,
        }),
      );

      debugPrint('Login response: ${response.statusCode}');

      if (response.statusCode == 200) {
        await _storeTokens(response.data);
        return {
          'success': true,
          'data': response.data['user'] ?? response.data['customer'],
        };
      }

      return {
        'success': false,
        'message': 'Login failed',
      };
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': e is DioException && e.response?.data['message'] != null
            ? e.response?.data['message']
            : 'Login failed. Please check your credentials and try again.',
      };
    }
  }

  // Get user profile with enhanced security
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _requestWithRetry(
        () => _dio.get('/customers/me'),
      );

      debugPrint('User profile response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
        };
      }

      return {
        'success': false,
        'message': 'Failed to get user profile',
      };
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return {
        'success': false,
        'message': e is DioException && e.response?.data['message'] != null
            ? e.response?.data['message']
            : 'Failed to get user profile. Please try again.',
      };
    }
  }

  // Logout with enhanced security
  Future<Map<String, dynamic>> logout() async {
    try {
      await _requestWithRetry(
        () => _dio.post('/auth/logout'),
      );

      // Clear tokens
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');

      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    } catch (e) {
      debugPrint('Logout error: $e');

      // Still clear tokens even if API call fails
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');

      return {
        'success': true, // Still consider it successful since tokens are cleared
        'message': 'Logged out successfully',
      };
    }
  }

  // Generic GET method with enhanced security
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _requestWithRetry(
        () => _dio.get(path, queryParameters: queryParameters),
      );

      return response.data;
    } catch (e) {
      _handleError(e, path);
      rethrow;
    }
  }

  // Generic POST method with enhanced security
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _requestWithRetry(
        () => _dio.post(path, data: data),
      );

      return response.data;
    } catch (e) {
      _handleError(e, path);
      rethrow;
    }
  }

  // Generic PUT method with enhanced security
  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _requestWithRetry(
        () => _dio.put(path, data: data),
      );

      return response.data;
    } catch (e) {
      _handleError(e, path);
      rethrow;
    }
  }

  // Generic PATCH method with enhanced security
  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await _requestWithRetry(
        () => _dio.patch(path, data: data),
      );

      return response.data;
    } catch (e) {
      _handleError(e, path);
      rethrow;
    }
  }

  // Generic DELETE method with enhanced security
  Future<dynamic> delete(String path) async {
    try {
      final response = await _requestWithRetry(
        () => _dio.delete(path),
      );

      return response.data;
    } catch (e) {
      _handleError(e, path);
      rethrow;
    }
  }

  // Request with retry logic
  Future<Response> _requestWithRetry(Future<Response> Function() requestFunc) async {
    int retryCount = 0;
    Duration delay = _initialRetryDelay;

    while (true) {
      try {
        return await requestFunc();
      } catch (e) {
        if (e is DioException) {
          // Don't retry for client errors (4xx) except for 429 (too many requests)
          if (e.response != null &&
              e.response!.statusCode != null &&
              e.response!.statusCode! >= 400 &&
              e.response!.statusCode! < 500 &&
              e.response!.statusCode! != 429) {
            rethrow;
          }

          // Don't retry if we've reached the max retries
          if (retryCount >= _maxRetries) {
            rethrow;
          }

          // Exponential backoff
          await Future.delayed(delay);
          delay *= 2;
          retryCount++;

          debugPrint('Retrying request ($retryCount/$_maxRetries)');
          continue;
        }

        // For non-Dio exceptions, don't retry
        rethrow;
      }
    }
  }

  // Handle API errors
  void _handleError(dynamic error, String path) {
    if (error is DioException) {
      debugPrint('API error for $path: ${error.message}');
      if (error.response != null) {
        debugPrint('Status code: ${error.response?.statusCode}');
        debugPrint('Response data: ${error.response?.data}');
      }
    } else {
      debugPrint('Unknown error for $path: $error');
    }
  }
}
