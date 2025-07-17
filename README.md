# Stuthi - Christian Worship App

A comprehensive Flutter application for Christian worship songs, chords, and worship tools.

## Getting Started

This project is built with Flutter and follows modern app development practices.

### Prerequisites
- Flutter 3.7.2+
- Dart SDK
- Android Studio / Xcode for mobile deployment

### Installation
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase (see Firebase setup section)
4. Run `flutter run` to start the app

## Architecture

The app follows a clean architecture approach with:
- **lib/config/** - App configuration and theming
- **lib/core/** - Core utilities, service locator, and error handling
- **lib/data/** - Data layer with repositories and data sources
- **lib/models/** - Data models
- **lib/providers/** - State management
- **lib/screens/** - UI screens
- **lib/services/** - Business logic and services
- **lib/utils/** - Utility functions
- **lib/widgets/** - Reusable UI components

### Service Architecture

The app uses a centralized service locator pattern (GetIt) for dependency injection. All services are registered in `lib/core/service_locator.dart` and follow a lazy singleton pattern for memory efficiency.

#### Core Services
- **ErrorHandler**: Centralized error handling and recovery
- **RetryService**: Automatic retry logic for failed operations
- **CrashlyticsService**: Error reporting and crash analytics
- **PerformanceService**: App performance monitoring
- **ConnectivityService**: Network connectivity management

#### Data Services
- **ApiService**: HTTP client for backend communication
- **AuthService**: Firebase authentication integration
- **CacheService**: Intelligent caching for offline support
- **MemoryManager**: Memory usage monitoring and optimization

#### Business Logic Services
- **SongService**: Song data management
- **ArtistService**: Artist information handling
- **SetlistService**: User setlist management
- **AudioService**: Media playback and audio processing
- **NotificationService**: Push notifications via Firebase

## Theming System

The app uses a comprehensive theming system defined in `lib/config/theme.dart`. The theme is designed with a single source of truth for the primary color, making it easy to rebrand the entire app by changing just one value.

### Key Theme Features

#### Color System
- **Primary Color**: The main brand color used throughout the app
- **Background Colors**: True black for OLED efficiency and contrast
- **Surface Colors**: Dark grays for cards and elevated elements
- **Text Colors**: High contrast white and grays for readability
- **Semantic Colors**: Success, error, warning, and info colors
- **Accent Colors**: Used sparingly for visual interest

#### Typography
- Uses Apple San Francisco Pro fonts for a premium look
- Consistent text styles with proper hierarchy
- Monospace font (JetBrains Mono) for chord sheets

#### Component Styling
- Consistent styling for buttons, inputs, cards
- Flat design with minimal shadows
- High contrast for readability
- Dark theme optimized for OLED screens

### Customizing the Theme

To change the app's primary color:
1. Open `lib/config/theme.dart`
2. Locate the `primary` color constant (around line 22)
3. Change the color value to your desired color
4. The entire app will automatically update with the new color scheme

```dart
/// ⭐ PRIMARY BRAND COLOR - SINGLE SOURCE OF TRUTH ⭐
static const Color primary = Color.fromARGB(255, 59, 255, 203);
```

### Predefined Text Styles

The theme includes predefined text styles for common use cases:
- `songTitleStyle` - For song titles
- `artistNameStyle` - For artist names
- `sectionTitleStyle` - For section titles
- `chordSheetStyle` - For chord sheet text
- `chordStyle` - For chord notations
- And more...

### Font System

The app includes a comprehensive font management system:

#### FontUtils Class
- **Font Family Management**: Apply standard fonts to existing styles
- **Style Creation**: Create new TextStyles with proper font families
- **Development Tools**: Font audit utilities to identify inconsistencies

```dart
// Apply fonts to existing styles
final style = FontUtils.withPrimaryFont(existingStyle);
final displayStyle = FontUtils.withDisplayFont(existingStyle);
final monoStyle = FontUtils.withMonospaceFont(existingStyle);

// Create new styles with proper fonts
final newStyle = FontUtils.createPrimaryStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: AppTheme.textPrimary,
);
```

#### Font Weight Standardization
- **Standardized Weights**: Consistent font weights across the app
- **Helper Methods**: Easy creation of properly weighted text styles
- **Weight Conversion**: Standardize existing styles

```dart
// Use standardized font weights
FontUtils.primary    // w600 - Primary headings
FontUtils.secondary  // w500 - Secondary headings  
FontUtils.regular    // w400 - Body text
FontUtils.light      // w300 - De-emphasized text
FontUtils.emphasis   // w700 - Special emphasis (use sparingly)
```

#### Development Audit Tools
- **Font Consistency Checking**: Identify non-standard font usage
- **Visual Debugging**: Highlight problematic text widgets
- **Usage Reporting**: Generate font usage descriptions

### Utility Methods

Helper methods for consistent styling:
- `withOpacity()` - Get a color with reduced opacity
- `getTextColorForBackground()` - Get appropriate text color based on background
- `cardDecoration` - Get consistent card decoration
- `elevatedCardDecoration` - Get elevated card decoration

## Resources

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
