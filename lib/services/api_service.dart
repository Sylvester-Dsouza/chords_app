// API service for interacting with the backend
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../utils/performance_tracker.dart';

/// API service for making HTTP requests to the backend
class ApiService {
  /// Get the base URL from the centralized API config
  static String get baseUrl => ApiConfig.baseUrlWithoutSuffix;

  // Initialize and log the base URL
  static void _logBaseUrl() {
    debugPrint('🌐 ApiService using base URL: $baseUrl');
  }

  // Test API connection
  static Future<bool> testApiConnection() async {
    try {
      debugPrint('Testing API connection to $baseUrl...');
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 2);
      dio.options.sendTimeout = const Duration(seconds: 2);
      dio.options.receiveTimeout = const Duration(seconds: 2);

      final response = await dio.get(
        '$baseUrl/api/health',
        options: Options(validateStatus: (_) => true),
      );

      if (response.statusCode != null && response.statusCode! < 500) {
        debugPrint('Successfully connected to $baseUrl');
        return true;
      } else {
        debugPrint(
          'Failed to connect to $baseUrl: Status code ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Failed to connect to $baseUrl: $e');
      return false;
    }
  }

  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Request deduplication to prevent duplicate API calls
  final Map<String, Future<Response>> _pendingRequests = {};

  ApiService() {
    _logBaseUrl();
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(
      seconds: 30,
    ); // Mobile-friendly timeout
    _dio.options.receiveTimeout = const Duration(
      seconds: 30,
    ); // Mobile-friendly timeout
    _dio.options.sendTimeout = const Duration(
      seconds: 30,
    ); // Mobile-friendly timeout

    // Check if we need to use the /api prefix for all endpoints
    _checkApiPrefix();

    // Add logging interceptor for debugging (only in debug mode)
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false, // Reduced logging for performance
          responseBody: false, // Reduced logging for performance
          error: true,
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests if available
          final token = await _secureStorage.read(key: 'access_token');

          // First check for a stored Firebase token (most reliable)
          String? firebaseToken = await _secureStorage.read(
            key: 'firebase_token',
          );

          // If no stored Firebase token, try to get a fresh one
          if (firebaseToken == null) {
            try {
              final firebaseUser = FirebaseAuth.instance.currentUser;
              if (firebaseUser != null) {
                firebaseToken = await firebaseUser.getIdToken(true);
                // Store the fresh token for future use
                await _secureStorage.write(
                  key: 'firebase_token',
                  value: firebaseToken,
                );
                debugPrint('Got fresh Firebase token and stored it');
              }
            } catch (e) {
              debugPrint('Error getting fresh Firebase token: $e');
            }
          } else {
            debugPrint('Using stored Firebase token');
          }

          // Use Firebase token if available (preferred for Google login)
          if (firebaseToken != null) {
            options.headers['Authorization'] = 'Bearer $firebaseToken';
            options.headers['X-Auth-Type'] =
                'firebase'; // Add header to indicate token type

            // Log token for debugging (only first few characters)
            final previewLength =
                firebaseToken.length > 10 ? 10 : firebaseToken.length;
            debugPrint(
              'Added Firebase token to request: ${options.path} (${firebaseToken.substring(0, previewLength)}...)',
            );
          }
          // Fall back to access token if no Firebase token
          else if (token != null) {
            // Ensure the token is properly formatted
            final cleanToken = token.trim();
            options.headers['Authorization'] = 'Bearer $cleanToken';
            options.headers['X-Auth-Type'] =
                'jwt'; // Add header to indicate token type

            // Log token for debugging (only first few characters)
            final previewLength =
                cleanToken.length > 10 ? 10 : cleanToken.length;
            debugPrint(
              'Added JWT token to request: ${options.path} (${cleanToken.substring(0, previewLength)}...)',
            );
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

            // Check if the error is related to Firebase token
            final isFirebaseTokenError =
                errorMessage != null &&
                (errorMessage.toString().contains('Firebase') ||
                    errorMessage.toString().contains('firebase'));

            debugPrint(
              '401 error details: $errorMessage, isFirebaseTokenError: $isFirebaseTokenError',
            );

            // Try to get a fresh Firebase token and retry the request
            try {
              final firebaseUser = FirebaseAuth.instance.currentUser;
              if (firebaseUser != null) {
                // Force refresh the token
                final freshToken = await firebaseUser.getIdToken(true);
                debugPrint('Got fresh Firebase token, retrying request');

                // Store the fresh token
                await _secureStorage.write(
                  key: 'firebase_token',
                  value: freshToken,
                );

                // Create a new request with the fresh token
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: {
                    ...error.requestOptions.headers,
                    'Authorization': 'Bearer $freshToken',
                    'X-Auth-Type':
                        'firebase', // Add header to indicate token type
                  },
                );

                // Retry the request with the fresh token
                final response = await _dio.request(
                  error.requestOptions.path,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                  options: opts,
                );

                // Return the response if successful
                return handler.resolve(response);
              }
            } catch (e) {
              debugPrint('Error refreshing Firebase token: $e');
            }

            // If we couldn't refresh the token, clear tokens
            await _secureStorage.delete(key: 'access_token');
            await _secureStorage.delete(key: 'refresh_token');
            await _secureStorage.delete(key: 'firebase_token');
            debugPrint('Authentication error - cleared all tokens');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // We've removed the token refresh and retry methods as they're not being used

  // Check if we need to use the /api prefix for all endpoints
  Future<void> _checkApiPrefix() async {
    try {
      debugPrint('Checking if API requires /api prefix');

      // Try a simple health check endpoint without the /api prefix
      _dio.options.validateStatus =
          (status) => true; // Accept any status code for the test
      final response = await _dio.get('/health');

      if (response.statusCode == 404) {
        // If 404, try with /api prefix
        final apiResponse = await _dio.get('/api/health');

        if (apiResponse.statusCode == 200 || apiResponse.statusCode == 204) {
          debugPrint('API requires /api prefix for all endpoints');
          // We could modify the baseUrl here, but we'll handle it per-request instead
        }
      } else {
        debugPrint('API does not require /api prefix');
      }
    } catch (e) {
      debugPrint('Error checking API prefix: $e');
    } finally {
      // Reset validateStatus to default
      _dio.options.validateStatus =
          (status) => status != null && status >= 200 && status < 300;
    }
  }

  // Helper method to ensure endpoint has /api prefix
  String _ensureApiPrefix(String endpoint) {
    if (endpoint.startsWith('/api/')) {
      return endpoint; // Already has /api prefix
    } else if (endpoint.startsWith('/')) {
      return '/api$endpoint'; // Add /api prefix
    } else {
      return '/api/$endpoint'; // Add /api/ prefix
    }
  }

  // Override the get method to automatically add /api prefix with deduplication
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return PerformanceTracker.trackApiCall(path, () async {
      final apiPath = _ensureApiPrefix(path);
      final requestKey = '$apiPath${queryParameters?.toString() ?? ''}';

      // Check if same request is already pending
      if (_pendingRequests.containsKey(requestKey)) {
        if (kDebugMode) debugPrint('🔄 Deduplicating GET request to $apiPath');
        return await _pendingRequests[requestKey]!;
      }

      if (kDebugMode) debugPrint('GET request to $apiPath');

      // Create and store the request future
      final requestFuture = _dio.get(
        apiPath,
        queryParameters: queryParameters,
        options: options,
      );
      _pendingRequests[requestKey] = requestFuture;

      try {
        final response = await requestFuture;
        if (kDebugMode) {
          debugPrint('GET response status: ${response.statusCode}');
          debugPrint('GET response data type: ${response.data.runtimeType}');
        }
        return response;
      } catch (e) {
        if (kDebugMode) debugPrint('Error in GET request to $path: $e');
        rethrow;
      } finally {
        // Remove from pending requests
        _pendingRequests.remove(requestKey);
      }
    }, attributes: {'method': 'GET', 'endpoint': path});
  }

  // Override the post method to automatically add /api prefix
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return PerformanceTracker.trackApiCall(path, () async {
      final apiPath = _ensureApiPrefix(path);
      debugPrint('POST request to $apiPath');
      try {
        final response = await _dio.post(
          apiPath,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
        debugPrint('POST response status: ${response.statusCode}');
        return response;
      } catch (e) {
        debugPrint('Error in POST request to $path: $e');
        rethrow;
      }
    }, attributes: {'method': 'POST', 'endpoint': path});
  }

  // POST method without /api prefix (for endpoints excluded from global prefix)
  Future<Response> postWithoutApiPrefix(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final fullUrl = '${_dio.options.baseUrl}$path';
    debugPrint('🔍 POST request to $path (without /api prefix)');
    debugPrint('🔍 Full URL: $fullUrl');
    debugPrint('🔍 Base URL: ${_dio.options.baseUrl}');
    debugPrint('🔍 Request path: $path');
    debugPrint('🔍 Request data: $data');
    debugPrint(
      '🔍 Request headers: ${options?.headers ?? _dio.options.headers}',
    );

    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      debugPrint('✅ POST response status: ${response.statusCode}');
      debugPrint('✅ POST response data: ${response.data}');
      return response;
    } catch (e) {
      debugPrint('❌ Error in POST request to $path: $e');
      if (e is DioException) {
        debugPrint('❌ DioException type: ${e.type}');
        debugPrint('❌ DioException message: ${e.message}');
        debugPrint('❌ Response status: ${e.response?.statusCode}');
        debugPrint('❌ Response data: ${e.response?.data}');
        debugPrint('❌ Response headers: ${e.response?.headers}');
        debugPrint('❌ Request URL: ${e.requestOptions.uri}');
        debugPrint('❌ Request method: ${e.requestOptions.method}');
        debugPrint('❌ Request headers: ${e.requestOptions.headers}');
        debugPrint('❌ Request data: ${e.requestOptions.data}');
      }
      rethrow;
    }
  }

  // Override the put method to automatically add /api prefix
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final apiPath = _ensureApiPrefix(path);
    debugPrint('PUT request to $apiPath');
    try {
      final response = await _dio.put(
        apiPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      debugPrint('PUT response status: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('Error in PUT request to $path: $e');
      rethrow;
    }
  }

  // Override the delete method to automatically add /api prefix
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final apiPath = _ensureApiPrefix(path);
    debugPrint('DELETE request to $apiPath');
    try {
      final response = await _dio.delete(
        apiPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      debugPrint('DELETE response status: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('Error in DELETE request to $path: $e');
      rethrow;
    }
  }

  // Get auth options for authenticated requests
  Options getAuthOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // Override the patch method to automatically add /api prefix
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final apiPath = _ensureApiPrefix(path);
    debugPrint('PATCH request to $apiPath');
    try {
      final response = await _dio.patch(
        apiPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      debugPrint('PATCH response status: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('Error in PATCH request to $path: $e');
      rethrow;
    }
  }

  // Clear all cached data
  Future<void> clearCache() async {
    try {
      debugPrint('Clearing all cached data');

      // Clear all tokens
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: 'firebase_token');

      // Clear any other cached data
      // This would be a good place to clear any cached API responses
      // or other app data that should be refreshed on logout

      debugPrint('All cached data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      rethrow;
    }
  }

  // Store tokens from login/register response
  Future<void> _storeTokens(Map<String, dynamic> data) async {
    debugPrint('Storing tokens from data: $data');

    // Check for tokens in the response
    final String? accessToken = data['accessToken'];
    final String? refreshToken = data['refreshToken'];

    if (accessToken != null) {
      try {
        debugPrint(
          'Storing access token: ${accessToken.substring(0, accessToken.length > 20 ? 20 : accessToken.length)}...',
        );
        await _secureStorage.write(key: 'access_token', value: accessToken);

        // Verify token was stored correctly
        final storedToken = await _secureStorage.read(key: 'access_token');
        if (storedToken == accessToken) {
          debugPrint('Access token stored successfully');
        } else {
          debugPrint(
            'Warning: Access token may not have been stored correctly',
          );
        }
      } catch (e) {
        debugPrint('Error storing access token: $e');
      }
    } else {
      debugPrint('No access token found in response');
    }

    if (refreshToken != null) {
      try {
        debugPrint(
          'Storing refresh token: ${refreshToken.substring(0, refreshToken.length > 20 ? 20 : refreshToken.length)}...',
        );
        await _secureStorage.write(key: 'refresh_token', value: refreshToken);

        // Verify token was stored correctly
        final storedToken = await _secureStorage.read(key: 'refresh_token');
        if (storedToken == refreshToken) {
          debugPrint('Refresh token stored successfully');
        } else {
          debugPrint(
            'Warning: Refresh token may not have been stored correctly',
          );
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

      // Get Firebase token for registration
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return {
          'success': false,
          'message': 'Firebase user not found. Please try again.',
        };
      }

      final idToken = await firebaseUser.getIdToken(true);

      // Determine which endpoint to use
      String endpoint;
      // Try with and without the /api prefix
      try {
        // First try without /api prefix
        endpoint = '/customers/register';
        // Make a test request to check if the endpoint exists
        _dio.options.validateStatus =
            (status) => true; // Accept any status code for the test
        final testResponse = await _dio.head(endpoint);
        debugPrint(
          'Test request to $endpoint returned status: ${testResponse.statusCode}',
        );

        if (testResponse.statusCode == 404) {
          // If 404, try with /api prefix
          endpoint = '/api/customers/register';
          debugPrint('Endpoint not found, trying with /api prefix: $endpoint');
        }
      } catch (e) {
        // If error, default to /api prefix
        endpoint = '/api/customers/register';
        debugPrint('Error testing endpoint, using /api prefix: $endpoint');
      } finally {
        // Reset validateStatus to default
        _dio.options.validateStatus =
            (status) => status != null && status >= 200 && status < 300;
      }

      debugPrint('Sending request to endpoint: $endpoint');
      final response = await _dio.post(
        endpoint,
        data: {
          'firebaseToken': idToken,
          'idToken': idToken, // Send both field names for compatibility
          'name': name,
          'email': email,
          'authProvider': 'EMAIL',
          'termsAccepted': termsAccepted,
          'rememberMe': false,
        },
      );

      debugPrint(
        'Registration response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _storeTokens(response.data);
        return {
          'success': true,
          'data': response.data['customer'],
          'message': response.data['message'] ?? 'Registration successful',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Registration failed',
      };
    } catch (e) {
      debugPrint('Registration error: $e');

      String errorMessage = 'Registration failed. Please try again.';

      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');

        if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage =
              'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage =
              'Connection error. Please check if the server is running.';
        } else if (e.response?.data is Map &&
            e.response?.data['message'] != null) {
          errorMessage = e.response?.data['message'];

          // Make error messages more user-friendly
          if (errorMessage.contains('already exists')) {
            errorMessage =
                'An account with this email already exists. Please try logging in instead.';
          }
        }
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // Login with email and password
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      // For email/password login, we should use Firebase Authentication first
      // and then use the Firebase token to authenticate with our backend
      try {
        // Sign in with Firebase
        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        // Get the Firebase ID token
        final String? idToken = await userCredential.user?.getIdToken(true);

        if (idToken != null) {
          // Use the Firebase token to authenticate with our backend
          return await loginWithFirebase(
            firebaseToken: idToken,
            authProvider: 'EMAIL',
            name: userCredential.user?.displayName,
            rememberMe: rememberMe,
          );
        }
      } catch (firebaseError) {
        debugPrint('Firebase login error: $firebaseError');
        // Continue with direct backend login as fallback
      }

      // Fallback to direct backend login (though this path should rarely be used)
      // Determine which endpoint to use
      String endpoint;
      // Try with and without the /api prefix
      try {
        // First try without /api prefix
        endpoint = '/customers/login';
        // Make a test request to check if the endpoint exists
        _dio.options.validateStatus =
            (status) => true; // Accept any status code for the test
        final testResponse = await _dio.head(endpoint);
        debugPrint(
          'Test request to $endpoint returned status: ${testResponse.statusCode}',
        );

        if (testResponse.statusCode == 404) {
          // If 404, try with /api prefix
          endpoint = '/api/customers/login';
          debugPrint('Endpoint not found, trying with /api prefix: $endpoint');
        }
      } catch (e) {
        // If error, default to /api prefix
        endpoint = '/api/customers/login';
        debugPrint('Error testing endpoint, using /api prefix: $endpoint');
      } finally {
        // Reset validateStatus to default
        _dio.options.validateStatus =
            (status) => status != null && status >= 200 && status < 300;
      }

      debugPrint('Sending request to endpoint: $endpoint');
      final response = await _dio.post(
        endpoint,
        data: {'email': email, 'password': password, 'rememberMe': rememberMe},
      );

      debugPrint('Login response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        await _storeTokens(response.data);
        return {
          'success': true,
          'data': response.data['customer'],
          'message': response.data['message'] ?? 'Login successful',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Login failed',
      };
    } catch (e) {
      debugPrint('Login error: $e');

      String errorMessage =
          'Login failed. Please check your credentials and try again.';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email address.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is invalid.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled.';
            break;
          default:
            errorMessage =
                e.message ?? 'Authentication failed. Please try again.';
        }
      } else if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage =
              'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage =
              'Connection error. Please check if the server is running.';
        } else if (e.response?.data is Map &&
            e.response?.data['message'] != null) {
          errorMessage = e.response?.data['message'];
        }
      }

      return {'success': false, 'message': errorMessage};
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
      // Ensure the token is properly formatted
      final cleanToken = firebaseToken.trim();

      // Log the token for debugging
      final previewLength = cleanToken.length > 20 ? 20 : cleanToken.length;
      debugPrint(
        'Sending Firebase token: ${cleanToken.substring(0, previewLength)}...',
      );
      debugPrint('Token length: ${cleanToken.length}');

      // Use our post method which automatically adds the /api prefix
      String endpoint;
      if (authProvider == 'GOOGLE' ||
          authProvider == 'FACEBOOK' ||
          authProvider == 'APPLE') {
        debugPrint('Using social-login endpoint for $authProvider login');
        endpoint = '/customers/social-login';
      } else {
        debugPrint('Using regular login endpoint for $authProvider login');
        endpoint = '/customers/login';
      }

      debugPrint('Sending request to endpoint: $endpoint');
      final response = await post(
        endpoint,
        data: {
          'firebaseToken': cleanToken,
          'idToken': cleanToken, // Send both field names for compatibility
          'authProvider': authProvider,
          'name': name,
          'rememberMe': rememberMe,
        },
      );

      debugPrint(
        'Firebase auth response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _storeTokens(response.data);
        return {
          'success': true,
          'data': response.data['customer'],
          'message': response.data['message'] ?? 'Authentication successful',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Authentication failed',
      };
    } catch (e) {
      debugPrint('Firebase authentication error: $e');

      // Check if the error response contains user data
      if (e is DioException && e.response != null) {
        final response = e.response!;
        debugPrint('Error response data: ${response.data}');

        // If the response contains user data, consider it a partial success
        if (response.data is Map &&
            (response.data['user'] != null ||
                response.data['customer'] != null)) {
          debugPrint(
            'Found user data in error response, treating as partial success',
          );
          return {
            'success': true,
            'data': response.data['user'] ?? response.data['customer'],
            'message': 'Authentication successful with warnings',
          };
        }
      }

      String errorMessage = 'Authentication failed. Please try again.';

      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage =
              'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage =
              'Connection error. Please check if the server is running.';
        } else if (e.response?.data is Map &&
            e.response?.data['message'] != null) {
          errorMessage = e.response?.data['message'];
        }
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      // Call logout endpoint to invalidate refresh token
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          // Use our post method which automatically adds the /api prefix
          debugPrint('Logging out user with refresh token');
          await post('/customers/logout', data: {'refreshToken': refreshToken});
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
      // Use our get method which automatically adds the /api prefix
      debugPrint('Getting current user profile');
      final response = await get('/customers/me');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }

      return {'success': false, 'message': 'Failed to get user profile'};
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return {
        'success': false,
        'message':
            e is DioException && e.response?.data['message'] != null
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
      final data = {'name': name};

      if (email != null) data['email'] = email;
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      if (profilePicture != null) data['profilePicture'] = profilePicture;

      // Use our patch method which automatically adds the /api prefix
      debugPrint('Updating user profile');
      final response = await patch('/customers/me', data: data);

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }

      return {'success': false, 'message': 'Failed to update profile'};
    } catch (e) {
      debugPrint('Update profile error: $e');
      return {
        'success': false,
        'message':
            e is DioException && e.response?.data['message'] != null
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
      // Use our post method which automatically adds the /api prefix
      debugPrint('Sending password reset email');
      final response = await post(
        '/customers/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password reset email sent'};
      }

      return {
        'success': false,
        'message': 'Failed to send password reset email',
      };
    } catch (e) {
      debugPrint('Password reset error: $e');
      return {
        'success': false,
        'message':
            e is DioException && e.response?.data['message'] != null
                ? e.response?.data['message']
                : 'Failed to send password reset email. Please try again.',
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      // Use our get method which automatically adds the /api prefix
      debugPrint('Getting user profile');
      final response = await get('/customers/me');

      debugPrint(
        'User profile response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }

      return {'success': false, 'message': 'Failed to get user profile'};
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return {
        'success': false,
        'message':
            e is DioException && e.response?.data['message'] != null
                ? e.response?.data['message']
                : 'Failed to get user profile. Please try again.',
      };
    }
  }

  // No duplicate methods here
}
