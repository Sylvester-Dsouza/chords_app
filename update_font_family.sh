#!/bin/bash

# Script to update all font family references to use Apple San Francisco-like fonts
echo "🔤 Updating font families throughout the app..."
echo "================================================"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Run this script from the Flutter project root directory"
    exit 1
fi

# Function to replace font families in files
replace_fonts() {
    local file="$1"
    echo "📝 Updating: $file"
    
    # Replace font family references with new ones
    sed -i '' 's/AppTheme\.primaryFontFamily/AppTheme.primaryFontFamily/g' "$file"
    sed -i '' 's/AppTheme\.monospaceFontFamily/AppTheme.monospaceFontFamily/g' "$file"
    
    # Replace hardcoded font family strings
    sed -i '' "s/'DMSans'/'Inter'/g" "$file"
    sed -i '' 's/"DMSans"/"Inter"/g' "$file"
    sed -i '' "s/'RobotoMono'/'JetBrains Mono'/g" "$file"
    sed -i '' 's/"RobotoMono"/"JetBrains Mono"/g' "$file"
    
    # Replace any remaining DM Sans references
    sed -i '' 's/DM Sans/Inter/g' "$file"
    sed -i '' 's/dmSans/inter/g' "$file"
    sed -i '' 's/robotoMono/jetBrainsMono/g' "$file"
}

# Find all Dart files and update them
echo "🔍 Finding Dart files to update..."

# Update all .dart files in lib directory
find lib -name "*.dart" -type f | while read -r file; do
    # Skip the theme.dart file itself as we've already updated it manually
    if [[ "$file" != "lib/config/theme.dart" ]]; then
        replace_fonts "$file"
    fi
done

echo ""
echo "✅ Font family replacement complete!"
echo ""
echo "📋 Summary of changes:"
echo "• 'DMSans' → 'Inter'"
echo "• 'RobotoMono' → 'JetBrains Mono'"
echo "• dmSans → inter (Google Fonts method names)"
echo "• robotoMono → jetBrainsMono (Google Fonts method names)"
echo ""
echo "🎯 New Apple San Francisco-like fonts:"
echo "• Inter - Primary font (closest to Apple San Francisco)"
echo "  - Clean, modern sans-serif"
echo "  - Excellent readability at all sizes"
echo "  - Optimized for digital screens"
echo "  - Used for: UI text, headings, body text"
echo ""
echo "• JetBrains Mono - Monospace font (closest to SF Mono)"
echo "  - Clean, readable monospace"
echo "  - Great for code and chord sheets"
echo "  - Used for: chord sheets, code blocks"
echo ""
echo "🍎 Why these fonts look like Apple fonts:"
echo "• Inter was specifically designed to match system UI fonts"
echo "• JetBrains Mono has similar characteristics to SF Mono"
echo "• Both fonts have the clean, minimal aesthetic of Apple fonts"
echo "• Optimized for screen reading and user interfaces"
echo ""
echo "🚀 Run 'flutter run' to see the new Apple-like fonts!"
