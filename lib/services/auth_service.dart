import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'api_service.dart';
import 'firebase_service.dart';

enum AuthProvider {
  email,
  google,
  facebook,
  apple,
}

class AuthService {
  final ApiService _apiService = ApiService();

  // Register with email and password
  Future<Map<String, dynamic>> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required bool termsAccepted,
  }) async {
    try {
      debugPrint('Starting registration process for $email');

      // Create user in Firebase Authentication
      try {
        debugPrint('Attempting to create user in Firebase');
        final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        debugPrint('Firebase user created successfully');

        // Update display name
        await userCredential.user?.updateDisplayName(name);
        debugPrint('Display name updated: $name');

        // Get Firebase ID token
        final String? idToken = await userCredential.user?.getIdToken();
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
              final Map<String, dynamic> decodedToken = jsonDecode(payload);
              final String? audience = decodedToken['aud'];

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
          final result = await _apiService.loginWithFirebase(
            firebaseToken: idToken,
            authProvider: 'EMAIL',
            name: name,
            rememberMe: false,
          );

          debugPrint('Backend registration result: ${result['success']}');

          // If we got a response with user data but success is false, consider it a success
          if (result['success'] == false && result['data'] != null) {
            debugPrint('Registration appears successful despite success=false');
            return {
              ...result,
              'success': true,
            };
          }

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

            // Try to sign in with this email instead
            try {
              // Attempt to sign in with Firebase using the provided credentials
              final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email,
                password: password,
              );

              // If sign-in is successful, get the Firebase ID token
              final String? idToken = await userCredential.user?.getIdToken();

              if (idToken != null) {
                // Register with backend using Firebase token
                final result = await _apiService.loginWithFirebase(
                  firebaseToken: idToken,
                  authProvider: 'EMAIL',
                  name: name,
                  rememberMe: false,
                );

                return result;
              }
            } catch (signInError) {
              debugPrint('Error signing in with existing email: $signInError');
              return {
                'success': false,
                'message': 'This email is already registered. Please use the login screen with the correct password.',
              };
            }
          }

          // Handle other Firebase errors
          return {
            'success': false,
            'message': 'Firebase error: ${firebaseError.message}',
          };
        }

        // Fallback to direct registration with backend
        debugPrint('Falling back to direct backend registration');
        return await _apiService.register(
          name: name,
          email: email,
          password: password,
          termsAccepted: termsAccepted,
        );
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

      try {
        // Try to sign in with Firebase first
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Get a fresh Firebase ID token with forceRefresh=true
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
              final Map<String, dynamic> decodedToken = jsonDecode(payload);
              final String? audience = decodedToken['aud'];

              debugPrint('Token audience (project ID): $audience');
              if (audience != 'chords-app-ecd47') {
                debugPrint('WARNING: Token has incorrect project ID: $audience');
                debugPrint('Expected project ID: chords-app-ecd47');
              }
            } catch (e) {
              debugPrint('Error decoding token: $e');
            }
          }

          // Login with backend using Firebase token
          return await _apiService.loginWithFirebase(
            firebaseToken: idToken,
            authProvider: 'EMAIL',
            name: userCredential.user?.displayName,
            rememberMe: rememberMe,
          );
        } else {
          throw Exception('Failed to get Firebase ID token');
        }
      } catch (firebaseError) {
        debugPrint('Firebase login error: $firebaseError');

        // If Firebase login fails, try direct backend login
        debugPrint('Falling back to direct backend login');
        return await _apiService.loginWithEmail(
          email: email,
          password: password,
          rememberMe: rememberMe,
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': 'An error occurred during login: ${e.toString()}',
      };
    }
  }

  // Login with Google
  Future<Map<String, dynamic>> loginWithGoogle({
    required bool rememberMe,
  }) async {
    try {
      // Sign in with Google using Firebase
      final UserCredential userCredential = await FirebaseService.signInWithGoogle();
      final User? user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'message': 'Failed to sign in with Google',
        };
      }

      // Get a fresh Firebase ID token with forceRefresh=true
      final String? idToken = await user.getIdToken(true);
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
            final Map<String, dynamic> decodedToken = jsonDecode(payload);
            final String? audience = decodedToken['aud'];

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
        return {
          'success': false,
          'message': 'Failed to get authentication token',
        };
      }

      // Send token to backend
      final result = await _apiService.loginWithFirebase(
        firebaseToken: idToken,
        authProvider: 'GOOGLE',
        name: user.displayName,
        rememberMe: rememberMe,
      );

      // If we got a response with user data but success is false, consider it a success
      if (result['success'] == false && result['data'] != null) {
        debugPrint('Google login appears successful despite success=false');
        return {
          ...result,
          'success': true,
        };
      }

      return result;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return {
        'success': false,
        'message': 'An error occurred during Google sign in: ${e.toString()}',
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

  // Logout
  Future<bool> logout() async {
    try {
      // Sign out from Firebase
      await FirebaseService.signOut();

      // Logout from backend
      return await _apiService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
      return false;
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
