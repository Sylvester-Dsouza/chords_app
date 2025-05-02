// API service for interacting with the backend
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // For Android emulator, use 10.0.2.2 instead of localhost
  // For physical devices, use your computer's IP address
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
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5); // Reduced timeout
    _dio.options.receiveTimeout = const Duration(seconds: 5); // Reduced timeout

    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests if available
        final token = await _secureStorage.read(key: 'access_token');
        if (token != null) {
          // Ensure the token is properly formatted
          final cleanToken = token.trim();
          options.headers['Authorization'] = 'Bearer $cleanToken';
          debugPrint('Added token to request: ${options.path}');

          // For debugging
          if (options.path.contains('playlists')) {
            final previewLength = cleanToken.length > 20 ? 20 : cleanToken.length;
            debugPrint('Token used for playlist request: ${cleanToken.substring(0, previewLength)}...');
          }
        } else {
          debugPrint('No token available for request: ${options.path}');
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Handle token refresh if 401 error
        if (error.response?.statusCode == 401) {
          // Check if the error is related to Firebase token or authentication
          final errorData = error.response?.data;
          final errorMessage = errorData is Map ? errorData['message'] : null;

          // Log the error for debugging
          debugPrint('401 error: $errorMessage');
          debugPrint('Request path: ${error.requestOptions.path}');

          // Clear tokens for any authentication error
          await _secureStorage.delete(key: 'access_token');
          await _secureStorage.delete(key: 'refresh_token');
          debugPrint('Authentication error - cleared tokens');

          // We're not refreshing tokens for now, just clearing them
        }
        return handler.next(error);
      },
    ));
  }

  // We've removed the token refresh and retry methods as they're not being used

  // Store tokens from login/register response
  Future<void> _storeTokens(Map<String, dynamic> data) async {
    debugPrint('Storing tokens from data: $data');

    // Check for tokens in the response
    final String? accessToken = data['accessToken'];
    final String? refreshToken = data['refreshToken'];

    if (accessToken != null) {
      try {
        debugPrint('Storing access token: ${accessToken.substring(0, accessToken.length > 20 ? 20 : accessToken.length)}...');
        await _secureStorage.write(key: 'access_token', value: accessToken);

        // Verify token was stored correctly
        final storedToken = await _secureStorage.read(key: 'access_token');
        if (storedToken == accessToken) {
          debugPrint('Access token stored successfully');
        } else {
          debugPrint('Warning: Access token may not have been stored correctly');
        }
      } catch (e) {
        debugPrint('Error storing access token: $e');
      }
    } else {
      debugPrint('No access token found in response');
    }

    if (refreshToken != null) {
      try {
        debugPrint('Storing refresh token: ${refreshToken.substring(0, refreshToken.length > 20 ? 20 : refreshToken.length)}...');
        await _secureStorage.write(key: 'refresh_token', value: refreshToken);

        // Verify token was stored correctly
        final storedToken = await _secureStorage.read(key: 'refresh_token');
        if (storedToken == refreshToken) {
          debugPrint('Refresh token stored successfully');
        } else {
          debugPrint('Warning: Refresh token may not have been stored correctly');
        }
      } catch (e) {
        debugPrint('Error storing refresh token: $e');
      }
    } else {
      debugPrint('No refresh token found in response');
    }
  }

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required bool termsAccepted,
  }) async {
    try {
      debugPrint('Registering user with email: $email');

      // Use the correct endpoint
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'termsAccepted': termsAccepted,
      });

      debugPrint('Registration response: ${response.statusCode} - ${response.data}');

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
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');

        if (e.type == DioExceptionType.connectionTimeout) {
          return {
            'success': false,
            'message': 'Connection timeout. Please check your internet connection.',
          };
        } else if (e.type == DioExceptionType.connectionError) {
          return {
            'success': false,
            'message': 'Connection error. Please check if the server is running.',
          };
        }
      }

      return {
        'success': false,
        'message': e is DioException && e.response?.data['message'] != null
            ? e.response?.data['message']
            : 'Registration failed. Please try again.',
      };
    }
  }

  // Login with email and password
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      // Use the correct endpoint
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'rememberMe': rememberMe,
      });

      debugPrint('Login response: ${response.statusCode} - ${response.data}');

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

  // Login with Firebase token
  Future<Map<String, dynamic>> loginWithFirebase({
    required String firebaseToken,
    required String authProvider,
    String? name,
    required bool rememberMe,
  }) async {
    try {
      // Use the correct endpoint
      // Ensure the token is properly formatted
      final cleanToken = firebaseToken.trim();

      // Log the token for debugging
      final previewLength = cleanToken.length > 20 ? 20 : cleanToken.length;
      debugPrint('Sending Firebase token: ${cleanToken.substring(0, previewLength)}...');
      debugPrint('Token length: ${cleanToken.length}');

      final response = await _dio.post('/auth/firebase', data: {
        'firebaseToken': cleanToken,
        'idToken': cleanToken, // Send both field names for compatibility
        'authProvider': authProvider,
        'name': name,
        'rememberMe': rememberMe,
      });

      debugPrint('Firebase login response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _storeTokens(response.data);
        return {
          'success': true,
          'data': response.data['user'] ?? response.data['customer'],
          'message': response.data['message'] ?? 'Firebase login successful',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Firebase login failed',
      };
    } catch (e) {
      debugPrint('Firebase login error: $e');

      // Check if the error response contains user data
      if (e is DioException && e.response != null) {
        final response = e.response!;
        debugPrint('Error response data: ${response.data}');

        // If the response contains user data, consider it a partial success
        if (response.data is Map && response.data['user'] != null) {
          debugPrint('Found user data in error response, treating as partial success');
          return {
            'success': true,
            'data': response.data['user'],
            'message': 'Login successful with warnings',
          };
        }
      }

      return {
        'success': false,
        'message': e is DioException && e.response?.data['message'] != null
            ? e.response?.data['message']
            : 'Firebase login failed. Please try again.',
      };
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      // Call logout endpoint to invalidate refresh token
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          // Use the correct endpoint
          await _dio.post('/auth/logout', data: {
            'refreshToken': refreshToken,
          });
        } catch (e) {
          // Ignore errors during logout
          debugPrint('Logout API error: $e');
        }
      }

      // Clear tokens regardless of API call result
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');

      return true;
    } catch (e) {
      debugPrint('Logout error: $e');
      // Still clear tokens even if API call fails
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      return true;
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/customers/me');

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

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    String? phoneNumber,
    String? profilePicture,
  }) async {
    try {
      final data = {
        'name': name,
      };

      if (email != null) data['email'] = email;
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      if (profilePicture != null) data['profilePicture'] = profilePicture;

      final response = await _dio.patch('/customers/me', data: data);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
        };
      }

      return {
        'success': false,
        'message': 'Failed to update profile',
      };
    } catch (e) {
      debugPrint('Update profile error: $e');
      return {
        'success': false,
        'message': e is DioException && e.response?.data['message'] != null
            ? e.response?.data['message']
            : 'Failed to update profile. Please try again.',
      };
    }
  }

  // Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      final response = await _dio.post('/auth/forgot-password', data: {
        'email': email,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password reset email sent',
        };
      }

      return {
        'success': false,
        'message': 'Failed to send password reset email',
      };
    } catch (e) {
      debugPrint('Password reset error: $e');
      return {
        'success': false,
        'message': e is DioException && e.response?.data['message'] != null
            ? e.response?.data['message']
            : 'Failed to send password reset email. Please try again.',
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/customers/me');

      debugPrint('User profile response: ${response.statusCode} - ${response.data}');

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

  // Generic HTTP methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      debugPrint('Making GET request to: $path');

      // Log the headers for debugging
      final token = await _secureStorage.read(key: 'access_token');
      if (token != null) {
        final previewLength = token.length > 20 ? 20 : token.length;
        debugPrint('Using token: ${token.substring(0, previewLength)}...');
      } else {
        debugPrint('No token available for GET request');
      }

      final response = await _dio.get(path, queryParameters: queryParameters);
      debugPrint('GET response status: ${response.statusCode}');
      debugPrint('GET response data type: ${response.data.runtimeType}');
      if (response.data is List) {
        debugPrint('GET response data length: ${(response.data as List).length}');
      }
      return response;
    } catch (e) {
      debugPrint('Error in GET request to $path: $e');
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      debugPrint('Making PATCH request to: $path');
      final response = await _dio.patch(path, data: data);
      debugPrint('PATCH response status: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('Error in PATCH request to $path: $e');
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');
      }
      rethrow;
    }
  }
}
