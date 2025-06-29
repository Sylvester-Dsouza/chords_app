import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================================
/// APP THEME CONFIGURATION
/// ============================================================================
///
/// TO CHANGE THE APP'S PRIMARY COLOR:
/// 1. Update the 'primary' color constant below (line ~11)
/// 2. That's it! The entire app will use the new color automatically
///
/// The theme uses a single primary color source to ensure consistency
/// across all UI elements, buttons, highlights, and interactive components.
/// ============================================================================

class AppTheme {
  // ============================================================================
  // MOISES-INSPIRED THEME COLORS - Clean, minimal, professional
  // ============================================================================

  /// ⭐ PRIMARY BRAND COLOR - SINGLE SOURCE OF TRUTH ⭐
  /// 🎨 CHANGE THIS ONE LINE TO UPDATE THE ENTIRE APP'S PRIMARY COLOR 🎨
  /// This color is used for buttons, highlights, active states, and key UI elements
  static const Color primary = Color.fromARGB(255, 253, 156, 37);

  /// Examples of other colors you can use:
  /// static const Color primary = Color(0xFF007AFF); // iOS Blue
  /// static const Color primary = Color(0xFF34C759); // iOS Green
  /// static const Color primary = Color(0xFFFF3B30); // iOS Red
  /// static const Color primary = Color(0xFF5856D6); // iOS Purple
  /// static const Color primary = Color(0xFFFF9500); // iOS Orange

  /// Background colors - True black for maximum contrast and battery efficiency
  static const Color background = Color(0xFF000000); // Pure black
  static const Color backgroundSecondary = Color(0xFF0A0A0A); // Slightly lighter black for depth

  /// Surface colors - Dark grays for cards, dialogs, and elevated elements
  static const Color surface = Color.fromARGB(255, 17, 17, 17); // iOS dark surface
  static const Color surfaceSecondary = Color(0xFF2C2C2E); // Slightly lighter surface
  static const Color surfaceTertiary = Color(0xFF3A3A3C); // Even lighter for hierarchy

  /// App bar and navigation - Consistent with background
  static const Color appBar = Color(0xFF000000); // Pure black to match background
  static const Color navigationBar = Color(0xFF000000); // Pure black

  /// Text colors - High contrast white and grays
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white for primary text
  static const Color textSecondary = Color(0xFF8E8E93); // iOS secondary text gray
  static const Color textTertiary = Color(0xFF48484A); // iOS tertiary text gray
  static const Color textPlaceholder = Color(0xFF636366); // iOS placeholder gray

  /// Border and separator colors
  static const Color border = Color(0xFF38383A); // iOS border color
  static const Color separator = Color(0xFF38383A); // Same as border for consistency

  // ============================================================================
  // SEMANTIC COLORS - For specific use cases (used sparingly)
  // ============================================================================

  /// Success color - For positive actions, confirmations
  static const Color success = Color(0xFF30D158); // iOS green

  /// Error color - For errors, warnings, destructive actions
  static const Color error = Color(0xFFFF453A); // iOS red

  /// Warning color - For warnings and cautions
  static const Color warning = Color(0xFFFF9F0A); // iOS orange

  /// Info color - For informational messages
  static const Color info = Color(0xFF64D2FF); // iOS light blue

  // ============================================================================
  // ACCENT COLORS - Used very sparingly for visual interest
  // ============================================================================

  /// Accent colors for visual variety (use only when necessary)
  /// These are derived from semantic colors to maintain consistency
  static const Color accent1 = primary; // Use primary for main accent
  static const Color accent2 = success; // Green for positive actions
  static const Color accent3 = warning; // Orange for warnings
  static const Color accent4 = error; // Red for errors/destructive actions
  static const Color accent5 = info; // Light blue for information

  // ============================================================================
  // DEPRECATED - Use the new color system above
  // ============================================================================
  @Deprecated('Use AppTheme.primary instead')
  static const Color primaryColor = primary;

  @Deprecated('Use AppTheme.background instead')
  static const Color backgroundColor = background;

  @Deprecated('Use AppTheme.surface instead')
  static const Color surfaceColor = surface;

  @Deprecated('Use AppTheme.textPrimary instead')
  static const Color textColor = textPrimary;

  @Deprecated('Use AppTheme.textSecondary instead')
  static const Color subtitleColor = textSecondary;

  // Legacy aliases for backward compatibility
  static const Color text = textPrimary;
  static const Color textMuted = textSecondary;

  // ============================================================================
  // FONT CONFIGURATION - Apple San Francisco Pro fonts
  // ============================================================================

  /// Primary font family - SF Pro Text (for body text and UI elements)
  static const String primaryFontFamily = 'SF Pro Text';

  /// Display font family - SF Pro Display (for headings and large text)
  static const String displayFontFamily = 'SF Pro Display';

  /// Monospace font family - For chord sheets and code-like content
  static const String monospaceFontFamily = 'JetBrains Mono';

  // Get the theme data
  static ThemeData getTheme() {
    // Set system UI overlay style to match app bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: appBar, // Pure black status bar
        statusBarIconBrightness: Brightness.light, // Light icons for dark background
        statusBarBrightness: Brightness.dark, // For Android
        systemNavigationBarColor: navigationBar, // Pure black navigation bar
        systemNavigationBarIconBrightness: Brightness.light, // Light icons for dark background
      ),
    );

    return ThemeData(
      // Use SF Pro fonts - Apple's system fonts
      fontFamily: primaryFontFamily, // Default to SF Pro Text
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          fontFamily: displayFontFamily,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          fontFamily: displayFontFamily,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          fontFamily: displayFontFamily,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          fontFamily: displayFontFamily,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          fontFamily: primaryFontFamily,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14.0,
          fontFamily: primaryFontFamily,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13.0,
          fontFamily: primaryFontFamily,
          color: textPrimary,
        ),
        labelLarge: TextStyle(
          fontSize: 13.0,
          fontWeight: FontWeight.w500,
          fontFamily: primaryFontFamily,
          color: textPrimary,
        ),
      ),

      // Custom page transitions for the entire app
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Pure black background for maximum contrast and battery efficiency
      scaffoldBackgroundColor: background,
      primaryColor: primary,

      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: primary,
        secondary: textSecondary, // Use secondary text color for secondary elements
        surfaceContainer: surfaceSecondary,
        onSurface: textPrimary,
        onPrimary: background, // Black text on primary blue
        onSecondary: textPrimary,
        error: error,
        onError: textPrimary,
        outline: border,
        outlineVariant: separator,
      ),

      // AppBar theme - Pure black for seamless integration
      appBarTheme: const AppBarTheme(
        backgroundColor: appBar,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevents elevation change when scrolling
        surfaceTintColor: Colors.transparent, // Prevents blue tinting from primary color
        titleTextStyle: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          fontFamily: primaryFontFamily,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(
          color: textPrimary,
          size: 24.0,
        ),
      ),

      // Button theme - Primary color used sparingly
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background, // Black text on blue background
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            fontFamily: primaryFontFamily,
          ),
        ),
      ),

      // Text button theme - Minimal styling
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            fontFamily: primaryFontFamily,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            fontFamily: primaryFontFamily,
          ),
        ),
      ),

      // Input decoration theme - Clean and minimal
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: error, width: 1),
        ),
        hintStyle: TextStyle(
          color: textPlaceholder,
          fontFamily: primaryFontFamily,
          fontSize: 14.0,
        ),
        labelStyle: TextStyle(
          color: textSecondary,
          fontFamily: primaryFontFamily,
          fontSize: 14.0,
        ),
        errorStyle: TextStyle(
          color: error,
          fontFamily: primaryFontFamily,
          fontSize: 12.0,
        ),
      ),

      // Card theme - Dark cards with proper contrast for black background
      cardTheme: const CardTheme(
        color: surface, // Dark surface color for cards
        elevation: 0, // Flat design
        shadowColor: Colors.transparent, // No shadow
        surfaceTintColor: Colors.transparent, // Prevents color tinting
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: border, width: 0.5),
        ),
        margin: EdgeInsets.all(0),
      ),

      // Container theme for consistent card-like containers
      // Note: Flutter doesn't have ContainerTheme, but we'll use this pattern in widgets
    );
  }

  /// Updates the status bar color to match the app bar color
  /// Call this method whenever you want to ensure status bar synchronization
  static void updateStatusBarColor({Color? customAppBarColor}) {
    final Color statusBarColor = customAppBarColor ?? appBar;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: statusBarColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // ============================================================================
  // PREDEFINED TEXT STYLES - Clean, consistent typography
  // ============================================================================

  static const TextStyle songTitleStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    fontFamily: displayFontFamily,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle artistNameStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    fontFamily: primaryFontFamily,
    color: textSecondary,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    fontFamily: primaryFontFamily,
    color: textPrimary,
    letterSpacing: -0.1,
  );

  static const TextStyle chordSheetStyle = TextStyle(
    fontSize: 14.0,
    height: 1.6,
    fontFamily: monospaceFontFamily,
    color: textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle chordStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    fontFamily: monospaceFontFamily,
    color: primary, // One of the few places we use primary color
    letterSpacing: 0.2,
  );

  static const TextStyle sectionHeaderStyle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    fontFamily: primaryFontFamily,
    color: textSecondary,
    letterSpacing: 0.8,
  );

  static const TextStyle tabLabelStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    fontFamily: primaryFontFamily,
    color: textPrimary,
  );

  static const TextStyle bottomNavLabelStyle = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    fontFamily: primaryFontFamily,
    color: textSecondary,
  );

  // ============================================================================
  // UTILITY METHODS - For consistent color application
  // ============================================================================

  /// Get a color with reduced opacity for subtle effects
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get appropriate text color based on background
  static Color getTextColorForBackground(Color backgroundColor) {
    // Calculate luminance to determine if background is light or dark
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? background : textPrimary;
  }

  /// Get a subtle border color
  static Color get subtleBorder => withOpacity(border, 0.3);

  /// Get a hover color for interactive elements
  static Color get hoverColor => withOpacity(textPrimary, 0.05);

  /// Get a pressed color for interactive elements
  static Color get pressedColor => withOpacity(textPrimary, 0.1);

  // ============================================================================
  // CARD AND CONTAINER STYLING HELPERS
  // ============================================================================

  /// Get consistent card decoration for the app
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: border, width: 0.5),
  );

  /// Get card decoration with custom border radius
  static BoxDecoration cardDecorationWithRadius(double radius) => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border, width: 0.5),
  );

  /// Get elevated card decoration (for important cards)
  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: border, width: 0.5),
    boxShadow: [
      BoxShadow(
        color: background.withValues(alpha: 0.3),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Get list item decoration (for list cards)
  static BoxDecoration get listItemDecoration => BoxDecoration(
    color: surface,
    border: Border(
      bottom: BorderSide(color: separator, width: 0.5),
    ),
  );
}

/// Logo assets helper class
class AppLogos {
  // Logo asset paths
  static const String logoDark = 'assets/images/stuthi logo dark.png';
  static const String logoLight = 'assets/images/stuthi logo light.png';
  static const String logoPrimary = 'assets/images/logo-primary.png';

  /// Get the appropriate logo based on theme and context
  static String getLogoForTheme({bool isDarkTheme = true}) {
    return isDarkTheme ? logoLight : logoDark;
  }

  /// Get logo for splash screen (use the primary logo)
  static String getSplashLogo() {
    return logoPrimary;
  }

  /// Get logo for app bar (use light version for dark theme)
  static String getAppBarLogo() {
    return logoLight;
  }

  /// Get logo for drawer (use primary logo)
  static String getDrawerLogo() {
    return logoPrimary;
  }
}
