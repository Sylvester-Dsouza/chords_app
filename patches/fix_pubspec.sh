#!/bin/bash

# Path to the flutter_local_notifications plugin
PLUGIN_PATH="$HOME/.pub-cache/hosted/pub.dev/flutter_local_notifications-13.0.0"
PUBSPEC="$PLUGIN_PATH/pubspec.yaml"

if [ -f "$PUBSPEC" ]; then
  echo "Fixing pubspec.yaml in flutter_local_notifications plugin..."
  
  # Create a backup
  cp "$PUBSPEC" "${PUBSPEC}.bak"
  
  # Remove the linux platform reference
  sed -i '' '/linux:/,/flutter_local_notifications_linux/d' "$PUBSPEC"
  
  echo "Linux platform reference removed from pubspec.yaml"
  echo "Fix completed!"
else
  echo "flutter_local_notifications pubspec.yaml not found at $PUBSPEC"
  echo "Please run 'flutter pub get' first to download the plugin."
  exit 1
fi
