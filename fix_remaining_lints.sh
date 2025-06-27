#!/bin/bash

echo "Fixing remaining linting issues..."

# Remove unused service fields from app_data_provider.dart
echo "Removing unused service fields..."
sed -i '' '/final HomeSectionService _homeSectionService = HomeSectionService();/d' lib/providers/app_data_provider.dart
sed -i '' '/final SongService _songService = SongService();/d' lib/providers/app_data_provider.dart
sed -i '' '/final ArtistService _artistService = ArtistService();/d' lib/providers/app_data_provider.dart
sed -i '' '/final CollectionService _collectionService = CollectionService();/d' lib/providers/app_data_provider.dart
sed -i '' '/final SetlistService _setlistService = SetlistService();/d' lib/providers/app_data_provider.dart

# Remove unused fields from practice_mode_screen.dart
echo "Removing unused fields from practice mode screen..."
sed -i '' '/String _currentChord = "";/d' lib/screens/practice_mode_screen.dart
sed -i '' '/final double _chordSheetOpacity = 0.8;/d' lib/screens/practice_mode_screen.dart

# Fix unnecessary toList in spread operator
echo "Fixing unnecessary toList in spread..."
sed -i '' 's/\.toList(),$/,/' lib/screens/about_us_screen.dart

echo "Manual fixes completed. Some issues require code context changes."
