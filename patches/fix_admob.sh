#!/bin/bash

echo "Fixing AdMob integration issues..."

# Path to the google_mobile_ads plugin
PLUGIN_PATH="$HOME/.pub-cache/hosted/pub.dev/google_mobile_ads-4.0.0"
ANDROID_MANIFEST="$PLUGIN_PATH/android/src/main/AndroidManifest.xml"
BUILD_GRADLE="$PLUGIN_PATH/android/build.gradle"

# Check if the plugin exists
if [ ! -d "$PLUGIN_PATH" ]; then
  echo "google_mobile_ads plugin not found at $PLUGIN_PATH"
  echo "Running flutter pub get to download the plugin..."
  flutter pub get
  
  # Check again after pub get
  if [ ! -d "$PLUGIN_PATH" ]; then
    echo "Failed to download google_mobile_ads plugin. Please run 'flutter pub get' manually."
    exit 1
  fi
fi

# Fix namespace in build.gradle
if [ -f "$BUILD_GRADLE" ]; then
  echo "Checking for namespace in build.gradle..."
  
  # Check if the file already contains namespace
  if grep -q "namespace" "$BUILD_GRADLE"; then
    echo "Namespace already exists in build.gradle"
  else
    echo "Adding namespace to build.gradle..."
    # Create a backup
    cp "$BUILD_GRADLE" "${BUILD_GRADLE}.bak"
    
    # Add namespace to defaultConfig block
    sed -i '' 's/defaultConfig {/defaultConfig {\n        namespace "io.flutter.plugins.googlemobileads"/g' "$BUILD_GRADLE"
    echo "Namespace added to build.gradle"
  fi
fi

# Fix AndroidManifest.xml
if [ -f "$ANDROID_MANIFEST" ]; then
  echo "Checking AndroidManifest.xml..."
  
  # Check if the manifest has the correct package attribute
  if grep -q 'package="io.flutter.plugins.googlemobileads"' "$ANDROID_MANIFEST"; then
    echo "Package attribute already exists in AndroidManifest.xml"
  else
    echo "Adding package attribute to AndroidManifest.xml..."
    # Create a backup
    cp "$ANDROID_MANIFEST" "${ANDROID_MANIFEST}.bak"
    
    # Add package attribute to manifest tag
    sed -i '' 's/<manifest/<manifest package="io.flutter.plugins.googlemobileads"/g' "$ANDROID_MANIFEST"
    echo "Package attribute added to AndroidManifest.xml"
  fi
fi

# Fix app/build.gradle.kts
APP_BUILD_GRADLE="android/app/build.gradle.kts"
if [ -f "$APP_BUILD_GRADLE" ]; then
  echo "Checking app/build.gradle.kts..."
  
  # Check if multidex is enabled
  if grep -q "multiDexEnabled" "$APP_BUILD_GRADLE"; then
    echo "Multidex already enabled in app/build.gradle.kts"
  else
    echo "Enabling multidex in app/build.gradle.kts..."
    # Create a backup
    cp "$APP_BUILD_GRADLE" "${APP_BUILD_GRADLE}.bak"
    
    # Add multidex enabled to defaultConfig block
    sed -i '' 's/defaultConfig {/defaultConfig {\n        multiDexEnabled = true/g' "$APP_BUILD_GRADLE"
    echo "Multidex enabled in app/build.gradle.kts"
  fi
  
  # Check if multidex dependency is added
  if grep -q "androidx.multidex:multidex" "$APP_BUILD_GRADLE"; then
    echo "Multidex dependency already added to app/build.gradle.kts"
  else
    echo "Adding multidex dependency to app/build.gradle.kts..."
    # Add multidex dependency
    sed -i '' 's/dependencies {/dependencies {\n    implementation("androidx.multidex:multidex:2.0.1")/g' "$APP_BUILD_GRADLE"
    echo "Multidex dependency added to app/build.gradle.kts"
  fi
fi

# Create a MultiDexApplication class if it doesn't exist
MULTIDEX_APP_PATH="android/app/src/main/java/com/wpchords/app/MultiDexApplication.java"
if [ ! -f "$MULTIDEX_APP_PATH" ]; then
  echo "Creating MultiDexApplication class..."
  
  # Create the directory if it doesn't exist
  mkdir -p "$(dirname "$MULTIDEX_APP_PATH")"
  
  # Create the MultiDexApplication class
  cat > "$MULTIDEX_APP_PATH" << 'EOF'
package com.wpchords.app;

import androidx.multidex.MultiDexApplication;

public class MultiDexApplication extends androidx.multidex.MultiDexApplication {
}
EOF
  
  echo "MultiDexApplication class created at $MULTIDEX_APP_PATH"
  
  # Update AndroidManifest.xml to use MultiDexApplication
  APP_MANIFEST="android/app/src/main/AndroidManifest.xml"
  if [ -f "$APP_MANIFEST" ]; then
    echo "Updating AndroidManifest.xml to use MultiDexApplication..."
    
    # Create a backup
    cp "$APP_MANIFEST" "${APP_MANIFEST}.bak"
    
    # Add android:name attribute to application tag
    sed -i '' 's/<application/<application android:name=".MultiDexApplication"/g' "$APP_MANIFEST"
    echo "AndroidManifest.xml updated to use MultiDexApplication"
  fi
fi

echo "AdMob integration fixes completed!"
echo "Now run 'flutter clean' and 'flutter pub get' to apply the changes."
