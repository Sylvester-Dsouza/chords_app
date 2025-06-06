#!/bin/bash

# Script to update all deprecated theme colors to the new minimal theme system
echo "🎨 Updating theme colors throughout the app..."
echo "================================================"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Run this script from the Flutter project root directory"
    exit 1
fi

# Function to replace colors in files
replace_colors() {
    local file="$1"
    echo "📝 Updating: $file"
    
    # Replace deprecated color references with new ones
    sed -i '' 's/AppTheme\.primaryColor/AppTheme.primary/g' "$file"
    sed -i '' 's/AppTheme\.backgroundColor/AppTheme.background/g' "$file"
    sed -i '' 's/AppTheme\.surfaceColor/AppTheme.surface/g' "$file"
    sed -i '' 's/AppTheme\.textColor/AppTheme.text/g' "$file"
    sed -i '' 's/AppTheme\.subtitleColor/AppTheme.textMuted/g' "$file"
}

# Find all Dart files and update them
echo "🔍 Finding Dart files to update..."

# Update all .dart files in lib directory
find lib -name "*.dart" -type f | while read -r file; do
    # Skip the theme.dart file itself as we've already updated it manually
    if [[ "$file" != "lib/config/theme.dart" ]]; then
        replace_colors "$file"
    fi
done

echo ""
echo "✅ Color replacement complete!"
echo ""
echo "📋 Summary of changes:"
echo "• AppTheme.primaryColor → AppTheme.primary"
echo "• AppTheme.backgroundColor → AppTheme.background"
echo "• AppTheme.surfaceColor → AppTheme.surface"
echo "• AppTheme.textColor → AppTheme.text"
echo "• AppTheme.subtitleColor → AppTheme.textMuted"
echo ""
echo "🎯 New minimal theme colors:"
echo "• AppTheme.primary - Light blue (#37BCFE) - For buttons, links, highlights"
echo "• AppTheme.background - Almost black (#090909) - Main app background"
echo "• AppTheme.surface - Dark gray (#1A1A1A) - Cards, dialogs, elevated elements"
echo "• AppTheme.text - White (#FFFFFF) - Primary text content"
echo "• AppTheme.textMuted - Medium gray (#888888) - Secondary text, subtitles"
echo "• AppTheme.success - Green (#10B981) - Success states"
echo "• AppTheme.error - Red (#EF4444) - Error states"
echo ""
echo "🚀 Run 'flutter run' to see the updated theme!"
