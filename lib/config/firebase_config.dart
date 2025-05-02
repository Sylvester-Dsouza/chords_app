// Firebase configuration constants
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseConfig {
  // Android configuration
  static const String androidApiKey = "AIzaSyAwZJ_vJBUR8ROm15XzC3gsU0ZrH5QEt1s";
  static const String androidAppId = "1:481447097360:android:6bc5b649641f11a8e5c695";
  static const String messagingSenderId = "481447097360";
  static const String projectId = "chords-app-ecd47";
  static const String storageBucket = "chords-app-ecd47.firebasestorage.app";

  // iOS configuration
  static const String iosApiKey = "AIzaSyCGoLuo8urFpvsR_ZPOZQl39U-0a5tvonk";
  static const String iosAppId = "1:481447097360:ios:efeac889ed1f21d1e5c695";
  static const String iosClientId = "481447097360-vrqfvovk8lc10niqd0nl6prbnnsoff8u.apps.googleusercontent.com";

  // Web client ID for Google Sign-In (this is the client_type 3 from google-services.json)
  static const String webClientId = "481447097360-13s3qaeafrg1htmndilphq984komvbti.apps.googleusercontent.com";

  // Android client ID for Google Sign-In
  static const String androidClientId = "481447097360-tmov0ihajnp6n5edb0lmmciu3kv16miq.apps.googleusercontent.com";

  // Get the appropriate API key based on platform
  static String get apiKey {
    if (kIsWeb) {
      return androidApiKey; // Use Android key for web
    } else if (Platform.isIOS) {
      return iosApiKey;
    } else {
      return androidApiKey;
    }
  }

  // Get the appropriate App ID based on platform
  static String get appId {
    if (kIsWeb) {
      return androidAppId; // Use Android ID for web
    } else if (Platform.isIOS) {
      return iosAppId;
    } else {
      return androidAppId;
    }
  }
}
