#!/bin/bash

# Script to verify Firebase Crashlytics setup
echo "🔍 Verifying Firebase Crashlytics Setup..."
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Run this script from the Flutter project root directory"
    exit 1
fi

echo "📱 Checking Flutter project structure..."

# Check pubspec.yaml for Firebase dependencies
echo "🔍 Checking pubspec.yaml dependencies..."
if grep -q "firebase_crashlytics:" pubspec.yaml; then
    echo "✅ firebase_crashlytics dependency found"
else
    echo "❌ firebase_crashlytics dependency missing"
fi

if grep -q "firebase_core:" pubspec.yaml; then
    echo "✅ firebase_core dependency found"
else
    echo "❌ firebase_core dependency missing"
fi

# Check Firebase configuration files
echo ""
echo "🔍 Checking Firebase configuration files..."

if [ -f "android/app/google-services.json" ]; then
    echo "✅ Android google-services.json found"
    # Check project ID
    if grep -q "chords-app-ecd47" android/app/google-services.json; then
        echo "✅ Correct project ID in Android config"
    else
        echo "⚠️  Check project ID in Android config"
    fi
else
    echo "❌ Android google-services.json missing"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✅ iOS GoogleService-Info.plist found"
    # Check project ID
    if grep -q "chords-app-ecd47" ios/Runner/GoogleService-Info.plist; then
        echo "✅ Correct project ID in iOS config"
    else
        echo "⚠️  Check project ID in iOS config"
    fi
else
    echo "❌ iOS GoogleService-Info.plist missing"
fi

# Check Android build configuration
echo ""
echo "🔍 Checking Android build configuration..."

if [ -f "android/build.gradle.kts" ]; then
    if grep -q "firebase-crashlytics-gradle" android/build.gradle.kts; then
        echo "✅ Crashlytics Gradle plugin classpath found"
    else
        echo "❌ Crashlytics Gradle plugin classpath missing"
    fi
else
    echo "❌ Android build.gradle.kts not found"
fi

if [ -f "android/app/build.gradle.kts" ]; then
    if grep -q "com.google.firebase.crashlytics" android/app/build.gradle.kts; then
        echo "✅ Crashlytics plugin applied in app build.gradle"
    else
        echo "❌ Crashlytics plugin not applied in app build.gradle"
    fi
    
    if grep -q "com.google.gms.google-services" android/app/build.gradle.kts; then
        echo "✅ Google Services plugin applied"
    else
        echo "❌ Google Services plugin not applied"
    fi
else
    echo "❌ Android app build.gradle.kts not found"
fi

# Check Firebase project configuration
echo ""
echo "🔍 Checking Firebase project configuration..."

if [ -f "firebase.json" ]; then
    echo "✅ firebase.json found"
    if grep -q "chords-app-ecd47" firebase.json; then
        echo "✅ Correct project ID in firebase.json"
    else
        echo "⚠️  Check project ID in firebase.json"
    fi
else
    echo "❌ firebase.json missing"
fi

# Check Crashlytics service implementation
echo ""
echo "🔍 Checking Crashlytics service implementation..."

if [ -f "lib/core/crashlytics_service.dart" ]; then
    echo "✅ CrashlyticsService found"
    
    if grep -q "setCrashlyticsCollectionEnabled(true)" lib/core/crashlytics_service.dart; then
        echo "✅ Crashlytics collection enabled"
    else
        echo "⚠️  Check Crashlytics collection setting"
    fi
else
    echo "❌ CrashlyticsService not found"
fi

# Check test screen
if [ -f "lib/screens/crashlytics_test_screen.dart" ]; then
    echo "✅ Crashlytics test screen found"
else
    echo "⚠️  Crashlytics test screen not found"
fi

echo ""
echo "🎯 Summary:"
echo "=========="
echo "✅ = Working correctly"
echo "⚠️  = Needs attention"
echo "❌ = Missing/broken"
echo ""
echo "📋 Next steps:"
echo "1. Fix any ❌ issues above"
echo "2. Run: flutter clean && flutter pub get"
echo "3. For Android: cd android && ./gradlew clean && cd .."
echo "4. For iOS: Add Crashlytics build phase (see CRASHLYTICS_TESTING.md)"
echo "5. Run: flutter run"
echo "6. Test using the Crashlytics test screen in the app"
echo ""
echo "🚀 Happy testing!"
