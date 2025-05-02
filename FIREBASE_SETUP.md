# Firebase Setup for Christian Chords App

This document provides instructions for setting up Firebase for the Christian Chords app.

## Prerequisites

1. A Google account
2. Firebase account (free tier is sufficient)

## Step 1: Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter "Christian Chords" as the project name
4. Follow the prompts to complete project creation

## Step 2: Add Android App to Firebase

1. In the Firebase Console, click on the Android icon (➕) to add an app
2. Enter the package name: `com.wpchords.app`
3. Enter "Christian Chords Android" as the app nickname
4. Register the app
5. Download the `google-services.json` file
6. Place the file in the `android/app/` directory of your Flutter project

## Step 3: Add iOS App to Firebase

1. In the Firebase Console, click on the iOS icon (➕) to add an app
2. Enter the bundle ID: `com.wpchords.app`
3. Enter "Christian Chords iOS" as the app nickname
4. Register the app
5. Download the `GoogleService-Info.plist` file
6. Place the file in the `ios/Runner/` directory of your Flutter project

## Step 4: Enable Google Sign-In

1. In the Firebase Console, go to Authentication
2. Click on the "Sign-in method" tab
3. Enable Google as a sign-in provider
4. Save the changes

## Step 5: Update Firebase Configuration

1. Open `lib/config/firebase_config.dart`
2. Replace the placeholder values with your actual Firebase configuration:

```dart
// Android configuration
static const FirebaseOptions androidOptions = FirebaseOptions(
  apiKey: "YOUR_ANDROID_API_KEY", // From google-services.json
  appId: "YOUR_ANDROID_APP_ID", // From google-services.json
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID", // From google-services.json
  projectId: "YOUR_PROJECT_ID", // From google-services.json
  storageBucket: "YOUR_STORAGE_BUCKET", // From google-services.json
);

// iOS configuration
static const FirebaseOptions iosOptions = FirebaseOptions(
  apiKey: "YOUR_IOS_API_KEY", // From GoogleService-Info.plist
  appId: "YOUR_IOS_APP_ID", // From GoogleService-Info.plist
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID", // From GoogleService-Info.plist
  projectId: "YOUR_PROJECT_ID", // From GoogleService-Info.plist
  storageBucket: "YOUR_STORAGE_BUCKET", // From GoogleService-Info.plist
  iosClientId: "YOUR_IOS_CLIENT_ID", // From GoogleService-Info.plist
);

// Web client ID for Google Sign-In
static const String webClientId = "YOUR_WEB_CLIENT_ID"; // From Firebase Console
```

## Step 6: Update iOS URL Scheme

1. Open `ios/Runner/Info.plist`
2. Find the `CFBundleURLSchemes` section
3. Replace `YOUR_CLIENT_ID` with your actual reversed client ID from `GoogleService-Info.plist`

## Step 7: Generate SHA-1 Certificate Fingerprint (Android)

1. Run the following command in your project directory:
   ```bash
   cd android && ./gradlew signingReport
   ```
2. Look for the SHA-1 fingerprint in the output
3. Add this fingerprint to your Firebase project:
   - Go to Project Settings > Your Apps > Android app
   - Click "Add fingerprint" and enter the SHA-1 value

## Step 8: Test Google Sign-In

1. Run the app on a device or emulator
2. Try signing in with Google
3. Verify that the authentication flow works correctly

## Troubleshooting

If you encounter issues with Google Sign-In:

1. Verify that the package name/bundle ID matches exactly
2. Check that the SHA-1 fingerprint is correctly added to Firebase
3. Ensure the `google-services.json` and `GoogleService-Info.plist` files are in the correct locations
4. Verify that the Firebase configuration values are correctly copied
5. Check the Firebase Authentication console for any error messages
