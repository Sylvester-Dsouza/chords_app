#!/bin/bash

# Function to fix namespace in a plugin
fix_namespace() {
  local plugin_path="$1"
  local package_name="$2"
  local build_gradle="$plugin_path/android/build.gradle"
  
  if [ -f "$build_gradle" ]; then
    echo "Checking $plugin_path..."
    
    # Check if the file already contains namespace
    if grep -q "namespace" "$build_gradle"; then
      echo "  Namespace already exists in build.gradle"
    else
      # Add namespace to defaultConfig block
      sed -i '' 's/defaultConfig {/defaultConfig {\n        namespace "'"$package_name"'"/g' "$build_gradle"
      echo "  Namespace added to build.gradle"
    fi
  fi
}

# Path to the pub cache
PUB_CACHE="$HOME/.pub-cache/hosted/pub.dev"

# Fix flutter_local_notifications
fix_namespace "$PUB_CACHE/flutter_local_notifications-13.0.0" "com.dexterous.flutterlocalnotifications"

# Fix firebase_messaging if needed
if [ -d "$PUB_CACHE/firebase_messaging-14.7.10" ]; then
  fix_namespace "$PUB_CACHE/firebase_messaging-14.7.10" "io.flutter.plugins.firebase.messaging"
fi

# Fix firebase_core if needed
if [ -d "$PUB_CACHE/firebase_core-2.24.2" ]; then
  fix_namespace "$PUB_CACHE/firebase_core-2.24.2" "io.flutter.plugins.firebase.core"
fi

# Fix firebase_auth if needed
if [ -d "$PUB_CACHE/firebase_auth-4.15.3" ]; then
  fix_namespace "$PUB_CACHE/firebase_auth-4.15.3" "io.flutter.plugins.firebase.auth"
fi

echo "All fixes completed!"
