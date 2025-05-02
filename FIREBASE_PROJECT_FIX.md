# Fixing Firebase Project Mismatch

## Issue: Wrong Firebase Project ID

The error you're seeing is because your Flutter app is generating Firebase tokens with the wrong project ID:
- Your backend expects tokens from: `chords-app-ecd47`
- But your app is generating tokens from: `react-native-firebase-testing`

## Solution

### 1. Clean Firebase Cache

Run the cleanup script to remove any cached Firebase data:

```bash
cd chords_app
./scripts/clean_firebase.sh
```

### 2. Verify Firebase Configuration

Make sure these files have the correct Firebase project ID (`chords-app-ecd47`):

1. **firebase_options.dart**
   - Check that all options use `projectId: 'chords-app-ecd47'`
   - Remove any references to `react-native-firebase-testing`

2. **firebase_config.dart**
   - Verify `projectId` is set to `chords-app-ecd47`

3. **google-services.json** (Android)
   - Verify `project_id` is set to `chords-app-ecd47`

4. **GoogleService-Info.plist** (iOS)
   - Verify `PROJECT_ID` is set to `chords-app-ecd47`

### 3. Rebuild and Test

After making these changes:

1. Completely uninstall the app from your device/emulator
2. Rebuild the app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. Check the logs for:
   ```
   Firebase initialized with project: chords-app-ecd47
   ```

### 4. Backend Setup

Make sure your backend has the correct Firebase service account:

1. Get the service account key for `chords-app-ecd47` from the Firebase Console
2. Save it as `firebase-service-account.json` in the `chords-api` directory
3. Restart your backend server

## Troubleshooting

If you still see the wrong project ID in the logs:

1. Check if you have multiple Firebase instances initialized
2. Look for any cached credentials in your app's storage
3. Make sure you're not using any test or development Firebase configurations

Remember: The Firebase project ID in your app must match the one in your backend service account.
