import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'api_service.dart';
import '../firebase_options.dart';
import '../core/service_locator.dart';
import '../core/crashlytics_service.dart';

// Constants for secure storage keys
const String _tokenKey = 'firebase_token'; // Changed to match API service
const String _userIdKey = 'user_id';
const String _userEmailKey = 'user_email';
const String _userNameKey = 'user_name';

enum AuthProvider {
  email,
  google,
  facebook,
  apple,
}

class AuthService {
  final ApiService _apiService = ApiService();
  late FirebaseAuth _auth;
  late GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  // Constructor doesn't initialize Firebase-dependent fields
  AuthService() {
    // These will be initialized after Firebase.initializeApp() is called
  }

  // Initialize Firebase (called from main.dart and splash_screen.dart)
  Future<void> initializeFirebase() async {
    // If already initialized, don't do it again
    if (_isInitialized) {
      debugPrint('Firebase already initialized by this service instance');
      return;
    }

    try {
      // Check if Firebase is already initialized at the app level
      if (Firebase.apps.isNotEmpty) {
        debugPrint('Firebase already initialized at app level');
      } else {
        // Initialize Firebase with the default options
        debugPrint('Initializing Firebase with default options');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Verify the project ID
        final FirebaseApp app = Firebase.app();
        final String projectId = app.options.projectId;

        if (projectId != 'chords-app-ecd47') {
          debugPrint('WARNING: Firebase initialized with incorrect project ID: $projectId');
          debugPrint('Expected project ID: chords-app-ecd47');

          // Force re-initialization with the correct project
          await Firebase.app().delete();
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          debugPrint('Firebase re-initialized with project: ${Firebase.app().options.projectId}');
        } else {
          debugPrint('Firebase initialized successfully with project: $projectId');
        }
      }

      // Initialize Firebase-dependent fields after Firebase is initialized
      debugPrint('Initializing Firebase Auth and GoogleSignIn');
      _auth = FirebaseAuth.instance;

      // Initialize GoogleSignIn with the correct client ID
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: '481447097360-13s3qaeafrg1htmndilphq984komvbti.apps.googleusercontent.com',
      );

      debugPrint('GoogleSignIn initialized with client ID');

      // Mark as initialized
      _isInitialized = true;

      debugPrint('Firebase Auth and GoogleSignIn initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
      // Don't rethrow to prevent app from crashing if Firebase isn't set up
    }
  }

  // Register with email and password
  Future<Map<String, dynamic>> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required bool termsAccepted,
  }) async {
    try {
      debugPrint('Starting registration process for $email');

      // Ensure Firebase is initialized
      if (!_isInitialized) {
        debugPrint('Firebase not initialized for registration, initializing now...');
        await initializeFirebase();
      }

      // Create user in Firebase Authentication
      try {
        debugPrint('Attempting to create user in Firebase');
        final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        debugPrint('Firebase user created successfully');

        // Update display name
        await userCredential.user?.updateDisplayName(name);
        debugPrint('Display name updated: $name');

        // Get Firebase ID token
        final String? idToken = await userCredential.user?.getIdToken(true);
        debugPrint('Got Firebase ID token: ${idToken != null}');

        // Log the token length for debugging
        if (idToken != null) {
          debugPrint('Firebase ID token length: ${idToken.length}');
          debugPrint('Firebase ID token first 20 chars: ${idToken.substring(0, 20)}...');

          // Verify the token contains the correct project ID
          final tokenParts = idToken.split('.');
          if (tokenParts.length == 3) {
            try {
              final payload = String.fromCharCodes(
                base64Decode(base64.normalize(tokenParts[1]))
              );
              final Map<String, dynamic> decodedToken = jsonDecode(payload) as Map<String, dynamic>;
              final String? audience = decodedToken['aud'] as String?;

              debugPrint('Token audience (project ID): $audience');
              if (audience != 'chords-app-ecd47') {
                debugPrint('WARNING: Token has incorrect project ID: $audience');
                debugPrint('Expected project ID: chords-app-ecd47');
              }
            } catch (e) {
              debugPrint('Error decoding token: $e');
            }
          }
        }

        if (idToken != null) {
          debugPrint('Registering with backend using Firebase token');
          // Register with backend using Firebase token
          final result = await _apiService.register(
            name: name,
            email: email,
            password: password,
            termsAccepted: termsAccepted,
          );

          debugPrint('Backend registration result: ${result['success']}');
          return result;
        } else {
          debugPrint('Firebase ID token is null');
          throw Exception('Failed to get Firebase ID token');
        }
      } catch (firebaseError) {
        debugPrint('Firebase registration error: $firebaseError');

        // If Firebase registration fails, try to handle specific errors
        if (firebaseError is FirebaseAuthException) {
          if (firebaseError.code == 'email-already-in-use') {
            debugPrint('Email already in use in Firebase');
            return {
              'success': false,
              'message': 'This email is already registered. Please use the login screen with the correct password.',
            };
          } else if (firebaseError.code == 'weak-password') {
            return {
              'success': false,
              'message': 'The password is too weak. Please use a stronger password.',
            };
          } else if (firebaseError.code == 'invalid-email') {
            return {
              'success': false,
              'message': 'The email address is invalid.',
            };
          }

          // Handle other Firebase errors
          return {
            'success': false,
            'message': firebaseError.message ?? 'Firebase error occurred during registration.',
          };
        }

        // Generic error
        return {
          'success': false,
          'message': 'An error occurred during registration. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      return {
        'success': false,
        'message': 'An error occurred during registration: ${e.toString()}',
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
      debugPrint('Attempting to login with Firebase first');

      // Validate input
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Email and password are required',
        };
      }

      try {
        // Try to sign in with Firebase first with timeout
        debugPrint('Signing in with Firebase with timeout');
        final UserCredential userCredential = await Future.any([
          FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
          Future.delayed(const Duration(seconds: 15), () {
            throw TimeoutException('Firebase sign-in timed out after 15 seconds');
          }),
        ]);

        // Check if user is null (rare but possible)
        if (userCredential.user == null) {
          debugPrint('Firebase login succeeded but user is null');
          return {
            'success': false,
            'message': 'Authentication error: User is null after successful login',
          };
        }

        // Store Firebase user info for session management
        await _storeFirebaseUserInfo(userCredential.user!);
        debugPrint('Stored Firebase user info for session management');

        // Get a fresh Firebase ID token with forceRefresh=true and timeout
        debugPrint('Getting Firebase ID token with timeout');
        final String? idToken = await Future.any([
          userCredential.user!.getIdToken(true),
          Future.delayed(const Duration(seconds: 10), () {
            throw TimeoutException('Getting Firebase token timed out after 10 seconds');
          }),
        ]);

        debugPrint('Got Firebase ID token: ${idToken != null}');

        // Log the token length for debugging
        if (idToken != null) {
          debugPrint('Firebase ID token length: ${idToken.length}');
          debugPrint('Firebase ID token first 20 chars: ${idToken.substring(0, 20)}...');

          // Verify the token contains the correct project ID
          final tokenParts = idToken.split('.');
          if (tokenParts.length == 3) {
            try {
              final payload = String.fromCharCodes(
                base64Decode(base64.normalize(tokenParts[1]))
              );
              final Map<String, dynamic> decodedToken = jsonDecode(payload) as Map<String, dynamic>;
              final String? audience = decodedToken['aud'] as String?;

              debugPrint('Token audience (project ID): $audience');
              if (audience != 'chords-app-ecd47') {
                debugPrint('WARNING: Token has incorrect project ID: $audience');
                debugPrint('Expected project ID: chords-app-ecd47');
              }
            } catch (e) {
              debugPrint('Error decoding token: $e');
            }
          }

          // Login with backend using Firebase token with shorter timeout
          debugPrint('Sending token to backend API with timeout');
          final result = await Future.any([
            _apiService.loginWithFirebase(
              firebaseToken: idToken,
              authProvider: 'EMAIL',
              name: userCredential.user?.displayName,
              rememberMe: rememberMe,
            ),
            Future.delayed(const Duration(seconds: 8), () {
              // If API call times out, return a partial success with Firebase user data
              return {
                'success': true,
                'message': 'Logged in to Firebase but API connection timed out. Some features may be limited.',
                'data': {
                  'id': userCredential.user!.uid,
                  'email': userCredential.user!.email,
                  'name': userCredential.user!.displayName,
                  'isActive': true,
                }
              };
            }),
          ]);

          // If backend login fails, sign out from Firebase to maintain consistent state
          if (result['success'] != true) {
            debugPrint('Backend login failed, signing out from Firebase for consistency');
            await FirebaseAuth.instance.signOut();

            // Log authentication failure to Crashlytics
            if (serviceLocator.isRegistered<CrashlyticsService>()) {
              await serviceLocator.crashlyticsService.logEvent('auth_backend_failure', {
                'auth_method': 'email',
                'error_type': 'backend_login_failed',
                'firebase_success': true,
                'timestamp': DateTime.now().toIso8601String(),
              });
            }
          } else {
            // Log successful login
            if (serviceLocator.isRegistered<CrashlyticsService>()) {
              await serviceLocator.crashlyticsService.setUserInfo(
                userId: userCredential.user!.uid,
                email: userCredential.user!.email,
                name: userCredential.user!.displayName,
                customAttributes: {
                  'auth_method': 'email',
                  'login_timestamp': DateTime.now().toIso8601String(),
                },
              );
            }
          }

          return result;
        } else {
          debugPrint('Failed to get Firebase ID token after successful login');

          // Even if we failed to get the token, we're still logged in to Firebase
          // Return a partial success so the UI can proceed
          return {
            'success': true,
            'message': 'Logged in to Firebase but failed to get authentication token. Some features may be limited.',
            'data': {
              'id': userCredential.user!.uid,
              'email': userCredential.user!.email,
              'name': userCredential.user!.displayName,
              'isActive': true,
            }
          };
        }
      } catch (firebaseError) {
        debugPrint('Firebase login error: $firebaseError');

        // Handle timeout specifically
        if (firebaseError is TimeoutException) {
          debugPrint('Login timed out: ${firebaseError.message}');

          // Check if we have a Firebase user despite the timeout
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            debugPrint('Firebase user exists despite timeout: ${firebaseUser.email}');

            // Return a partial success with the Firebase user data
            return {
              'success': true,
              'message': 'Logged in to Firebase but connection timed out. Some features may be limited.',
              'data': {
                'id': firebaseUser.uid,
                'email': firebaseUser.email,
                'name': firebaseUser.displayName,
                'isActive': true,
              }
            };
          }

          return {
            'success': false,
            'message': 'Sign in timed out. Please check your internet connection and try again.',
            'errorCode': 'timeout',
          };
        }

        // Handle specific Firebase errors
        if (firebaseError is FirebaseAuthException) {
          switch (firebaseError.code) {
            case 'user-not-found':
              return {
                'success': false,
                'message': 'No account found with this email. Please check your email or register.',
                'errorCode': 'user-not-found',
              };
            case 'wrong-password':
              return {
                'success': false,
                'message': 'Incorrect password. Please try again.',
                'errorCode': 'wrong-password',
              };
            case 'user-disabled':
              return {
                'success': false,
                'message': 'This account has been disabled. Please contact support.',
                'errorCode': 'user-disabled',
              };
            case 'too-many-requests':
              return {
                'success': false,
                'message': 'Too many failed login attempts. Please try again later or reset your password.',
                'errorCode': 'too-many-requests',
              };
            case 'network-request-failed':
              return {
                'success': false,
                'message': 'Network error. Please check your internet connection and try again.',
                'errorCode': 'network-error',
              };
            default:
              // For other Firebase errors, try direct backend login as fallback
              debugPrint('Falling back to direct backend login');
              try {
                final result = await Future.any([
                  _apiService.loginWithEmail(
                    email: email,
                    password: password,
                    rememberMe: rememberMe,
                  ),
                  Future.delayed(const Duration(seconds: 8), () {
                    throw TimeoutException('Direct backend login timed out after 8 seconds');
                  }),
                ]);
                return result;
              } catch (directLoginError) {
                if (directLoginError is TimeoutException) {
                  return {
                    'success': false,
                    'message': 'Login timed out. Please check your internet connection and try again.',
                    'errorCode': 'timeout',
                  };
                }
                return {
                  'success': false,
                  'message': 'Login failed: ${directLoginError.toString()}',
                };
              }
          }
        } else {
          // For non-Firebase errors, try direct backend login as fallback
          debugPrint('Falling back to direct backend login');
          try {
            final result = await Future.any([
              _apiService.loginWithEmail(
                email: email,
                password: password,
                rememberMe: rememberMe,
              ),
              Future.delayed(const Duration(seconds: 15), () {
                throw TimeoutException('Direct backend login timed out after 15 seconds');
              }),
            ]);
            return result;
          } catch (directLoginError) {
            if (directLoginError is TimeoutException) {
              return {
                'success': false,
                'message': 'Login timed out. Please check your internet connection and try again.',
                'errorCode': 'timeout',
              };
            }
            return {
              'success': false,
              'message': 'Login failed: ${directLoginError.toString()}',
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');

      if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Login timed out. Please check your internet connection and try again.',
          'errorCode': 'timeout',
        };
      }

      return {
        'success': false,
        'message': 'An error occurred during login: ${e.toString()}',
      };
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Ensure Firebase is initialized before using Firebase services
      if (!_isInitialized) {
        debugPrint('Firebase not initialized, initializing now...');
        await initializeFirebase();

        if (!_isInitialized) {
          throw Exception('Failed to initialize Firebase before Google sign-in');
        }
      }

      debugPrint('Starting Google sign-in process');

      // Force sign out first to ensure we get the account picker dialog
      try {
        await _googleSignIn.signOut();
        debugPrint('Signed out of previous Google session');
      } catch (e) {
        debugPrint('No previous Google session to sign out from: $e');
      }

      // Begin interactive sign-in process with explicit options
      debugPrint('Showing Google sign-in popup');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      debugPrint('Google sign-in result: ${googleUser != null ? 'Success' : 'Cancelled/Failed'}');

      if (googleUser == null) {
        debugPrint('Google sign-in was cancelled by user or failed');
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      debugPrint('Google sign-in successful for: ${googleUser.email}, getting authentication details');

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('Got Google authentication tokens');

      // Create new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Created Firebase credential, signing in with credential');

      // Sign in with credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      // Check if we have a token in secure storage
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: _tokenKey);
      return token != null;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // Get the authentication token with automatic refresh
  Future<String?> getToken() async {
    try {
      // First check if user is still authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No current user, cannot get token');
        return null;
      }

      // Try to get a fresh token from Firebase (this will automatically refresh if needed)
      debugPrint('Getting fresh Firebase ID token');
      final String? freshToken = await currentUser.getIdToken(true); // Force refresh

      if (freshToken != null) {
        // Store the fresh token
        final storage = FlutterSecureStorage();
        await storage.write(key: _tokenKey, value: freshToken);
        debugPrint('Fresh token obtained and stored');
        return freshToken;
      } else {
        debugPrint('Failed to get fresh token from Firebase');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting fresh token: $e');

      // Fallback: try to get stored token
      try {
        final storage = FlutterSecureStorage();
        final storedToken = await storage.read(key: _tokenKey);
        debugPrint('Fallback to stored token: ${storedToken != null}');
        return storedToken;
      } catch (storageError) {
        debugPrint('Error getting stored token: $storageError');
        return null;
      }
    }
  }

  // Force refresh the authentication token
  Future<String?> refreshToken() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No current user, cannot refresh token');
        return null;
      }

      debugPrint('Force refreshing Firebase ID token');
      final String? freshToken = await currentUser.getIdToken(true); // Force refresh

      if (freshToken != null) {
        // Store the fresh token
        final storage = FlutterSecureStorage();
        await storage.write(key: _tokenKey, value: freshToken);
        debugPrint('Token refreshed and stored successfully');
        return freshToken;
      } else {
        debugPrint('Failed to refresh token');
        return null;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return null;
    }
  }

  // This method is intentionally removed to avoid duplication with the existing _storeFirebaseUserInfo method

  // Login with Google
  Future<Map<String, dynamic>> loginWithGoogle({
    required bool rememberMe,
  }) async {
    try {
      debugPrint('Starting Google login process');

      // Ensure Firebase is initialized
      if (!_isInitialized) {
        debugPrint('Firebase not initialized for Google login, initializing now...');
        await initializeFirebase();
      }

      // Sign in with Google using Firebase with timeout
      debugPrint('Calling signInWithGoogle method with timeout');
      final UserCredential userCredential = await Future.any([
        signInWithGoogle(),
        Future.delayed(const Duration(seconds: 15), () {
          throw TimeoutException('Google sign-in timed out after 15 seconds');
        }),
      ]);

      final User? user = userCredential.user;

      if (user == null) {
        debugPrint('User is null after Google sign-in');
        return {
          'success': false,
          'message': 'Failed to sign in with Google',
        };
      }

      debugPrint('Google sign-in successful, user: ${user.displayName}');

      // Store Firebase user info for session management
      await _storeFirebaseUserInfo(user);
      debugPrint('Stored Firebase user info for session management');

      // Get a fresh Firebase ID token with forceRefresh=true and timeout
      debugPrint('Getting Firebase ID token with timeout');
      final String? idToken = await Future.any([
        user.getIdToken(true),
        Future.delayed(const Duration(seconds: 10), () {
          throw TimeoutException('Getting Firebase token timed out after 10 seconds');
        }),
      ]);

      debugPrint('Got Firebase ID token from Google login: ${idToken != null}');

      // Log the token length for debugging
      if (idToken != null) {
        debugPrint('Firebase ID token length: ${idToken.length}');
        debugPrint('Firebase ID token first 20 chars: ${idToken.substring(0, 20)}...');

        // Verify the token contains the correct project ID
        final tokenParts = idToken.split('.');
        if (tokenParts.length == 3) {
          try {
            final payload = String.fromCharCodes(
              base64Decode(base64.normalize(tokenParts[1]))
            );
            final Map<String, dynamic> decodedToken = jsonDecode(payload) as Map<String, dynamic>;
            final String? audience = decodedToken['aud'] as String?;

            debugPrint('Token audience (project ID): $audience');
            if (audience != 'chords-app-ecd47') {
              debugPrint('WARNING: Token has incorrect project ID: $audience');
              debugPrint('Expected project ID: chords-app-ecd47');
            }
          } catch (e) {
            debugPrint('Error decoding token: $e');
          }
        }
      }

      if (idToken == null) {
        debugPrint('Failed to get ID token from Firebase');

        // Even if we failed to get the token, we're still logged in to Firebase
        // Return a partial success so the UI can proceed
        return {
          'success': true,
          'message': 'Logged in to Firebase but failed to get authentication token. Some features may be limited.',
          'data': {
            'id': user.uid,
            'email': user.email,
            'name': user.displayName,
            'isActive': true,
          }
        };
      }

      // Send token to backend with shorter timeout
      debugPrint('Sending token to backend API with timeout');
      final result = await Future.any([
        _apiService.loginWithFirebase(
          firebaseToken: idToken,
          authProvider: 'GOOGLE',
          name: user.displayName,
          rememberMe: rememberMe,
        ),
        Future.delayed(const Duration(seconds: 8), () {
          // If API call times out, return a partial success with Firebase user data
          return {
            'success': true,
            'message': 'Logged in to Firebase but API connection timed out. Some features may be limited.',
            'data': {
              'id': user.uid,
              'email': user.email,
              'name': user.displayName,
              'isActive': true,
            }
          };
        }),
      ]);

      debugPrint('Google login API result: $result');
      return result;
    } catch (e) {
      debugPrint('Google login error: $e');

      String errorMessage = 'An error occurred during Google sign in.';

      if (e is TimeoutException) {
        // Handle timeout specifically
        debugPrint('Login timed out: ${e.message}');

        // Check if we have a Firebase user despite the timeout
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          debugPrint('Firebase user exists despite timeout: ${firebaseUser.email}');

          // Return a partial success with the Firebase user data
          return {
            'success': true,
            'message': 'Logged in to Firebase but connection timed out. Some features may be limited.',
            'data': {
              'id': firebaseUser.uid,
              'email': firebaseUser.email,
              'name': firebaseUser.displayName,
              'isActive': true,
            }
          };
        }

        errorMessage = 'Sign in timed out. Please check your internet connection and try again.';
      } else if (e is FirebaseAuthException) {
        if (e.code == 'ERROR_ABORTED_BY_USER') {
          errorMessage = 'Sign in was cancelled by the user.';
        } else {
          errorMessage = e.message ?? 'Authentication failed. Please try again.';
        }
      } else if (e is Exception) {
        // More specific error handling for other types of exceptions
        errorMessage = 'Error: ${e.toString()}';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Login with Facebook
  Future<Map<String, dynamic>> loginWithFacebook({
    required bool rememberMe,
  }) async {
    try {
      // For now, we'll use a mock implementation
      // In a real app, you would use the Facebook SDK
      debugPrint('Facebook login not implemented yet');
      return {
        'success': false,
        'message': 'Facebook login is not implemented yet',
      };
    } catch (e) {
      debugPrint('Facebook login error: $e');
      return {
        'success': false,
        'message': 'An error occurred during Facebook login: ${e.toString()}',
      };
    }
  }

  // Login with Apple
  Future<Map<String, dynamic>> loginWithApple({
    required bool rememberMe,
  }) async {
    try {
      // For now, we'll use a mock implementation
      // In a real app, you would use the Apple Sign In SDK
      debugPrint('Apple login not implemented yet');
      return {
        'success': false,
        'message': 'Apple login is not implemented yet',
      };
    } catch (e) {
      debugPrint('Apple login error: $e');
      return {
        'success': false,
        'message': 'An error occurred during Apple login: ${e.toString()}',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Ensure Firebase is initialized
      if (!_isInitialized) {
        debugPrint('Firebase not initialized for sign out, initializing now...');
        await initializeFirebase();
      }

      debugPrint('Signing out from Google');
      await _googleSignIn.signOut();

      debugPrint('Signing out from Firebase');
      await _auth.signOut();

      debugPrint('Sign out completed successfully');
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      debugPrint('Starting logout process');

      // Clear all stored Firebase user info
      try {
        final secureStorage = const FlutterSecureStorage();
        await secureStorage.delete(key: 'firebase_uid');
        await secureStorage.delete(key: 'firebase_email');
        await secureStorage.delete(key: 'firebase_display_name');
        await secureStorage.delete(key: 'last_login_time');
        debugPrint('Cleared stored Firebase user info');
      } catch (e) {
        debugPrint('Error clearing stored Firebase user info: $e');
      }

      // Sign out from Firebase
      await signOut();

      // Logout from backend
      final result = await _apiService.logout();

      // Clear any cached data
      try {
        // Clear any cached user data
        await _apiService.clearCache();
        debugPrint('Cleared API cache during logout');
      } catch (e) {
        debugPrint('Error clearing API cache: $e');
      }

      return {
        'success': true, // Always return success to ensure user is logged out locally
        'message': result ? 'Logged out successfully' : 'Failed to log out from the server, but logged out from the device',
      };
    } catch (e) {
      debugPrint('Logout error: $e');

      // Even if there's an error, we should still consider the user logged out locally
      return {
        'success': true,
        'message': 'Logged out from the device, but there was an error communicating with the server',
      };
    }
  }

  // Store Firebase user info for session management
  Future<void> _storeFirebaseUserInfo(User user) async {
    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await user.getIdToken();

      await secureStorage.write(key: _tokenKey, value: token);
      await secureStorage.write(key: _userIdKey, value: user.uid);
      await secureStorage.write(key: _userEmailKey, value: user.email);
      await secureStorage.write(key: _userNameKey, value: user.displayName);
      await secureStorage.write(key: 'last_login_time', value: DateTime.now().toIso8601String());

      debugPrint('Stored Firebase user info for session management');
    } catch (e) {
      debugPrint('Error storing Firebase user info: $e');
    }
  }

  // Send password reset email using Firebase
  Future<Map<String, dynamic>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      debugPrint('Sending password reset email to: $email');

      // Use Firebase Auth to send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      debugPrint('Password reset email sent successfully');

      return {
        'success': true,
        'message': 'Password reset email sent',
      };
    } catch (e) {
      debugPrint('Password reset error: $e');

      // Handle specific Firebase errors
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            return {
              'success': false,
              'message': 'No user found with this email address.',
            };
          case 'invalid-email':
            return {
              'success': false,
              'message': 'The email address is invalid.',
            };
          default:
            return {
              'success': false,
              'message': 'Failed to send password reset email: ${e.message}',
            };
        }
      }

      return {
        'success': false,
        'message': 'Failed to send password reset email. Please try again.',
      };
    }
  }
}
