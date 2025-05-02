#!/bin/bash

echo "Running all fixes for flutter_local_notifications plugin..."

# Run all the fix scripts
./patches/fix_namespace.sh
./patches/fix_pubspec.sh
./patches/fix_java_code.sh

echo "All fixes completed!"
echo "Now run 'flutter clean' and 'flutter pub get' to apply the changes."
