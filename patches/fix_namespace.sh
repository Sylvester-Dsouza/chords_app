#!/bin/bash

# Path to the flutter_local_notifications plugin
PLUGIN_PATH="$HOME/.pub-cache/hosted/pub.dev/flutter_local_notifications-13.0.0"
BUILD_GRADLE="$PLUGIN_PATH/android/build.gradle"

if [ -f "$BUILD_GRADLE" ]; then
  echo "Fixing namespace in flutter_local_notifications plugin..."
  
  # Check if the file already contains namespace
  if grep -q "namespace" "$BUILD_GRADLE"; then
    echo "Namespace already exists in build.gradle"
  else
    # Add namespace to defaultConfig block
    sed -i '' 's/defaultConfig {/defaultConfig {\n        namespace "com.dexterous.flutterlocalnotifications"/g' "$BUILD_GRADLE"
    echo "Namespace added to build.gradle"
  fi
  
  echo "Fix completed!"
else
  echo "flutter_local_notifications build.gradle not found at $BUILD_GRADLE"
  echo "Please run 'flutter pub get' first to download the plugin."
  exit 1
fi
