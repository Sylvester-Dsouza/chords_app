#!/bin/bash

# Apply patch to flutter_local_notifications plugin
PLUGIN_PATH="$HOME/.pub-cache/hosted/pub.dev/flutter_local_notifications-13.0.0"

if [ -d "$PLUGIN_PATH" ]; then
  echo "Applying patch to flutter_local_notifications plugin..."
  patch -p1 -d "$PLUGIN_PATH" < "$(dirname "$0")/flutter_local_notifications.patch"
  echo "Patch applied successfully!"
else
  echo "flutter_local_notifications plugin not found at $PLUGIN_PATH"
  echo "Please run 'flutter pub get' first to download the plugin."
  exit 1
fi
