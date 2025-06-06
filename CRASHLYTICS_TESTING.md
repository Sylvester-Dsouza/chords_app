# 🧪 Firebase Crashlytics Testing Guide - UPDATED

## 🎯 Overview
This guide will help you test Firebase Crashlytics integration and send test crashes to Firebase Console.

## ✅ **RECENT FIXES APPLIED:**
- ✅ Added Firebase Crashlytics Gradle plugin to Android build
- ✅ Added Crashlytics classpath to project-level build.gradle
- ✅ Enabled Crashlytics collection in debug mode for testing
- ✅ Fixed CrashlyticsService initialization logic
- ✅ Created firebase.json configuration file
- ✅ Updated Firebase project connection

## 🔧 Prerequisites

### 1. Firebase Project Setup
- ✅ Firebase project `chords-app-ecd47` is properly configured
- ✅ App is connected to Firebase with correct configuration files
- ✅ `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in place

### 2. Firebase Console Access
- Go to [Firebase Console](https://console.firebase.google.com)
- Select your project: **chords-app-ecd47**
- Navigate to **Crashlytics** in the left sidebar

## 🚀 Testing Steps

### Step 1: Clean and Rebuild the App
1. **Clean the project first**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **For Android - Clean Gradle cache**:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   ```

3. **Run the app in debug mode**:
   ```bash
   flutter run
   ```

2. **Open the app drawer** (hamburger menu)

3. **Look for the "Debug" section** at the bottom of the drawer
   - This section only appears in debug mode
   - You should see "Crashlytics Test" option

4. **Tap on "Crashlytics Test"** to open the test screen

### Step 2: Check Console Output
Look for these messages in the Flutter console:
```
✅ Crashlytics initialized successfully
📊 Crashlytics collection is enabled
✅ Service locator initialized successfully
```

### Step 3: Access the Test Screen
1. **Open the app drawer** (hamburger menu)
2. **Scroll down** to find debug options
3. **Look for "Crashlytics Test"** (only visible in debug mode)
4. **Tap on "Crashlytics Test"** to open the test screen

### Step 4: Verify Crashlytics Status
On the test screen, you should see:
- ✅ **Crashlytics Status**: Should show "enabled and ready"
- **Debug Mode**: Should show "ON"
- **Release Mode**: Should show "OFF"

### Step 5: Test Non-Fatal Events

#### A. Log Test Event
1. Tap **"Log Test Event"**
2. You should see a success message
3. This sends a custom event to Firebase

#### B. Record Test Error
1. Tap **"Record Test Error"**
2. You should see a success message
3. This sends a non-fatal error to Firebase

#### C. Set Test User Info
1. Tap **"Test User Info"**
2. You should see a success message
3. This associates user information with crash reports

### Step 6: Test Fatal Crash (CAREFUL!)

⚠️ **WARNING**: This will crash the app immediately!

1. Tap **"Force Crash (DANGER)"**
2. Read the warning dialog carefully
3. Tap **"Force Crash"** to confirm
4. **The app will crash and close immediately**
5. Restart the app manually

## 📊 Viewing Results in Firebase Console

### 1. Navigate to Crashlytics
- Go to [Firebase Console](https://console.firebase.google.com)
- Select your project
- Click **"Crashlytics"** in the left menu

### 2. Check for Events
- **Non-fatal errors** appear in the "Non-fatals" tab
- **Fatal crashes** appear in the "Crashes" tab
- **Custom events** appear in the logs section

### 3. Timeline
- Events may take **5-15 minutes** to appear in the console
- Fatal crashes usually appear faster than non-fatal events
- In debug mode, some events might be delayed

## 🔍 What to Look For

### In Firebase Console:
1. **Crash Reports**: Should show the forced crash with stack trace
2. **Non-Fatal Errors**: Should show the test error you triggered
3. **User Information**: Should show the test user data you set
4. **Custom Events**: Should show the test events you logged

### Expected Data:
- **User ID**: `test_user_[timestamp]`
- **Email**: `test@example.com`
- **Custom Keys**: Various test-related metadata
- **Stack Traces**: Detailed error information

## 🐛 Troubleshooting

### Events Not Appearing?
1. **Check Internet Connection**: Ensure device has internet
2. **Wait Longer**: Events can take up to 15 minutes
3. **Check Firebase Project**: Verify you're looking at the correct project
4. **Restart App**: Close and reopen the app to force upload

### Crashlytics Not Enabled?
1. **Check Firebase Setup**: Verify `google-services.json` is correct
2. **Check Dependencies**: Ensure `firebase_crashlytics` is installed
3. **Check Initialization**: Verify service is initialized in `main.dart`

### Debug Mode Issues?
1. **Use Release Mode**: Some features work better in release mode
2. **Build Release APK**: 
   ```bash
   flutter build apk --release
   flutter install
   ```

## 📱 Production Testing

### For Real Testing:
1. **Build in release mode**:
   ```bash
   flutter build apk --release
   ```

2. **Install on device**:
   ```bash
   flutter install
   ```

3. **Test crashes in release mode** for most accurate results

## 📱 iOS-Specific Setup (IMPORTANT!)

### Required: Add Crashlytics Build Phase
For iOS Crashlytics to work properly, you MUST add a build phase script:

1. **Open Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Add Build Phase**:
   - Select the **Runner** project in navigator
   - Select the **Runner** target
   - Go to **Build Phases** tab
   - Click **+** and select **"New Run Script Phase"**
   - Name it **"Firebase Crashlytics"**

3. **Add Script**:
   ```bash
   ${PODS_ROOT}/FirebaseCrashlytics/run
   ```

4. **Add Input Files**:
   ```
   ${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}
   $(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)
   ```

5. **Order**: Make sure this script runs AFTER "Compile Sources" but BEFORE "Copy Bundle Resources"

6. **Clean and rebuild** your iOS project

### Alternative: Use the provided script
```bash
cd ios
./add_crashlytics_script.sh
```

## 🔒 Security Notes

- **Test screen only appears in debug mode**
- **Production builds won't show the test screen**
- **User data is anonymized in production**
- **Test crashes are clearly marked as intentional**

## 📈 Best Practices

### 1. Regular Testing
- Test Crashlytics integration after major changes
- Verify events are reaching Firebase Console
- Test both fatal and non-fatal scenarios

### 2. User Privacy
- Don't include sensitive information in crash reports
- Use anonymized user identifiers
- Follow GDPR/privacy guidelines

### 3. Error Categorization
- Use meaningful error categories
- Include relevant context in crash reports
- Set up proper user identification

## 🎯 Success Criteria

You've successfully integrated Crashlytics when:
- ✅ Test events appear in Firebase Console
- ✅ Fatal crashes are properly reported
- ✅ Non-fatal errors are tracked
- ✅ User context is included in reports
- ✅ Stack traces are detailed and helpful

## 🔧 Troubleshooting

### Issue: "Crashlytics not enabled" or crashes not appearing

#### Check 1: Console Output
Look for these messages when app starts:
```
✅ Crashlytics initialized successfully
📊 Crashlytics collection is enabled
```

If you see:
```
⚠️ Firebase not available - Crashlytics disabled
```
**Solution**: Run `flutter clean && flutter pub get` and rebuild

#### Check 2: Android Build Issues
If Android build fails:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

#### Check 3: iOS Build Issues
1. Ensure you added the Crashlytics build phase (see iOS section above)
2. Clean iOS build:
   ```bash
   cd ios
   rm -rf Pods
   pod install
   cd ..
   flutter clean
   flutter run
   ```

#### Check 4: Firebase Console
1. Go to Firebase Console → Crashlytics
2. If you see "Waiting for data", it means:
   - Crashlytics is set up but no crashes have been sent yet
   - Try the test crash button in the app

#### Check 5: Network Issues
- Ensure device has internet connection
- Check if corporate firewall blocks Firebase domains
- Try on different network (mobile data vs WiFi)

### Issue: Test crashes not appearing in console

#### Wait Time
- **Non-fatal errors**: Appear within 5-10 minutes
- **Fatal crashes**: May take up to 24 hours in debug mode
- **Release builds**: Usually appear within 1-2 hours

#### Force Upload
In the test screen, try:
1. Record multiple test errors
2. Force close and restart the app
3. Wait 10-15 minutes
4. Check Firebase Console

## 🆘 Need Help?

If you encounter issues:
1. Check the [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
2. Verify your Firebase project configuration
3. Check the Flutter console for error messages
4. Ensure all dependencies are properly installed
5. Try testing on a release build: `flutter run --release`

---

**Happy Testing! 🚀**

Remember: The goal is to catch and fix issues before your users encounter them!
