#!/bin/bash

# Script to add Firebase Crashlytics build phase to iOS project
# This script adds the necessary build phase for Crashlytics to upload dSYM files

echo "🔧 Adding Firebase Crashlytics build phase to iOS project..."

# Check if we're in the right directory
if [ ! -f "Runner.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Run this script from the ios/ directory"
    echo "Current directory: $(pwd)"
    exit 1
fi

# Backup the original project file
cp Runner.xcodeproj/project.pbxproj Runner.xcodeproj/project.pbxproj.backup
echo "✅ Created backup of project.pbxproj"

# Check if Crashlytics script already exists
if grep -q "firebase_crashlytics_symbols" Runner.xcodeproj/project.pbxproj; then
    echo "⚠️  Crashlytics build phase already exists"
    exit 0
fi

echo "📝 Adding Crashlytics build phase..."

# Note: This is a simplified approach. For production, you should use Xcode directly
# or a more sophisticated script that properly parses the pbxproj file

echo "⚠️  IMPORTANT: You need to manually add the Crashlytics build phase in Xcode:"
echo ""
echo "1. Open Runner.xcworkspace in Xcode"
echo "2. Select the Runner project in the navigator"
echo "3. Select the Runner target"
echo "4. Go to Build Phases tab"
echo "5. Click the + button and select 'New Run Script Phase'"
echo "6. Name it 'Firebase Crashlytics'"
echo "7. Add this script:"
echo ""
echo '${PODS_ROOT}/FirebaseCrashlytics/run'
echo ""
echo "8. In Input Files, add:"
echo '${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}'
echo '$(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)'
echo ""
echo "9. Make sure this script runs AFTER 'Compile Sources' but BEFORE 'Copy Bundle Resources'"
echo ""
echo "🚀 After adding this, clean and rebuild your project for Crashlytics to work properly on iOS"
