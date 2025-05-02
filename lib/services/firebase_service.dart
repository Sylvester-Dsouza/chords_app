import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/firebase_config.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get GoogleSignIn instance
  static GoogleSignIn getGoogleSignIn() {
    return GoogleSignIn(
      clientId: kIsWeb ? FirebaseConfig.webClientId : null,
      serverClientId: FirebaseConfig.webClientId,
      scopes: ['email', 'profile'],
    );
  }

  // Initialize Firebase (called from main.dart)
  static Future<void> initializeFirebase() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        debugPrint('Firebase already initialized');
        return;
      }

      // Initialize Firebase with the default options
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
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
      // Don't rethrow to prevent app from crashing if Firebase isn't set up
    }
  }

  // Sign in with Google
  static Future<UserCredential> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await getGoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await getGoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get ID token
  static Future<String?> getIdToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      debugPrint('Get ID token error: $e');
      return null;
    }
  }
}