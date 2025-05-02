#!/bin/bash

# Path to the flutter_local_notifications plugin
PLUGIN_PATH="$HOME/.pub-cache/hosted/pub.dev/flutter_local_notifications-13.0.0"
JAVA_FILE="$PLUGIN_PATH/android/src/main/java/com/dexterous/flutterlocalnotifications/FlutterLocalNotificationsPlugin.java"

if [ -f "$JAVA_FILE" ]; then
  echo "Fixing Java code in flutter_local_notifications plugin..."
  
  # Create a backup
  cp "$JAVA_FILE" "${JAVA_FILE}.bak"
  
  # Fix the ambiguous method reference
  sed -i '' 's/bigPictureStyle.bigLargeIcon(null);/bigPictureStyle.bigLargeIcon((android.graphics.Bitmap)null);/g' "$JAVA_FILE"
  
  echo "Java code fixed"
  echo "Fix completed!"
else
  echo "flutter_local_notifications Java file not found at $JAVA_FILE"
  echo "Please run 'flutter pub get' first to download the plugin."
  exit 1
fi
