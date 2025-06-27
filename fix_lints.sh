#!/bin/bash

# Fix linting issues in Flutter app

echo "Fixing Flutter linting issues..."

# Fix deprecated withOpacity usage - replace with withValues
find lib -name "*.dart" -exec sed -i '' 's/\.withOpacity(\([^)]*\))/\.withValues(alpha: \1)/g' {} \;

echo "Fixed deprecated withOpacity usage"

# Remove unused imports
echo "Removing unused imports..."

# Remove unused dart:io imports
sed -i '' '/^import.*dart:io.*;$/d' lib/services/connectivity_service.dart
sed -i '' '/^import.*dart:io.*;$/d' lib/services/performance_service.dart

# Remove unused flutter/foundation import
sed -i '' '/^import.*package:flutter\/foundation\.dart.*;$/d' lib/widgets/app_drawer.dart

# Remove unused inner_screen_app_bar imports
sed -i '' '/^import.*\.\.\/widgets\/inner_screen_app_bar\.dart.*;$/d' lib/screens/vocal_exercise_category_detail_screen.dart
sed -i '' '/^import.*\.\.\/widgets\/inner_screen_app_bar\.dart.*;$/d' lib/screens/vocal_warmup_category_detail_screen.dart

# Remove unused connectivity_service import
sed -i '' '/^import.*\.\.\/services\/connectivity_service\.dart.*;$/d' lib/screens/home_screen.dart

# Remove unused incremental_sync_service import
sed -i '' '/^import.*\.\.\/\.\.\/services\/incremental_sync_service\.dart.*;$/d' lib/screens/debug/performance_debug_screen.dart

echo "Removed unused imports"

echo "Linting fixes applied. Run 'flutter analyze' to verify."
