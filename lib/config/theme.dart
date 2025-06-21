import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ============================================================================
  // MINIMAL THEME COLORS - Only 5 essential colors for the entire app
  // ============================================================================

  /// Primary brand color - Used for buttons, links, highlights, and interactive elements
  static const Color primary = Color(0xFF37BCFE); // Your preferred light blue

  /// Background color - Main app background (very dark)
  static const Color background = Color.fromARGB(255, 12, 12, 12); // Dark gray

  /// Surface color - Cards, dialogs, elevated elements (slightly lighter than background)
  static const Color surface = Color(0xFF1A1A1A); // Dark gray

  /// App bar color - Independent color for app bars and status bar
  static const Color appBar = Color(0xFF090909); // Slightly lighter than surface for distinction

  /// Text color - Primary text content (white for dark theme)
  static const Color text = Color(0xFFFFFFFF); // Pure white

  /// Muted text color - Secondary text, subtitles, placeholders
  static const Color textMuted = Color(0xFF888888); // Medium gray

  // ============================================================================
  // SEMANTIC COLORS - For specific use cases
  // ============================================================================

  /// Success color - For positive actions, confirmations
  static const Color success = Color(0xFF10B981); // Green

  /// Error color - For errors, warnings, destructive actions
  static const Color error = Color(0xFFEF4444); // Red

  // ============================================================================
  // DEPRECATED - Use the new minimal colors above
  // ============================================================================
  @Deprecated('Use AppTheme.primary instead')
  static const Color primaryColor = primary;

  @Deprecated('Use AppTheme.background instead')
  static const Color backgroundColor = background;

  @Deprecated('Use AppTheme.surface instead')
  static const Color surfaceColor = surface;

  @Deprecated('Use AppTheme.text instead')
  static const Color textColor = text;

  @Deprecated('Use AppTheme.textMuted instead')
  static const Color subtitleColor = textMuted;

  // ============================================================================
  // FONT CONFIGURATION - Apple San Francisco-like fonts
  // ============================================================================

  /// Primary font family - Inter (closest to Apple San Francisco)
  /// Inter is specifically designed for UI and closely matches SF Pro characteristics
  static const String primaryFontFamily = 'Inter';

  /// Monospace font family - SF Mono alternative
  /// JetBrains Mono is the closest open-source alternative to SF Mono
  static const String monospaceFontFamily = 'JetBrains Mono';

  // Get the theme data
  static ThemeData getTheme() {
    // Set system UI overlay style to match app bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: appBar, // Use app bar color for status bar
        statusBarIconBrightness:
            Brightness.light, // Light icons for dark background
        statusBarBrightness: Brightness.dark, // For Android
        systemNavigationBarColor: appBar, // Match app bar color
        systemNavigationBarIconBrightness:
            Brightness.light, // Light icons for dark background
      ),
    );

    return ThemeData(
      // Use Inter as the base font - closest to Apple San Francisco
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 28.0, // Reduced from 32.0
            fontWeight: FontWeight.bold,
            color: text,
          ),
          displayMedium: TextStyle(
            fontSize: 24.0, // Reduced from 28.0
            fontWeight: FontWeight.bold,
            color: text,
          ),
          displaySmall: TextStyle(
            fontSize: 20.0, // Reduced from 24.0
            fontWeight: FontWeight.bold,
            color: text,
          ),
          headlineMedium: TextStyle(
            fontSize: 18.0, // Reduced from 20.0
            fontWeight: FontWeight.w600,
            color: text,
          ),
          titleLarge: TextStyle(
            fontSize: 16.0, // Reduced from 18.0
            fontWeight: FontWeight.w500,
            color: text,
          ),
          bodyLarge: TextStyle(fontSize: 14.0, color: text), // Reduced from 16.0
          bodyMedium: TextStyle(fontSize: 13.0, color: text), // Reduced from 14.0
          labelLarge: TextStyle(
            fontSize: 13.0, // Reduced from 14.0
            fontWeight: FontWeight.w500,
            color: text,
          ),
        ),
      ),

      // Custom page transitions for the entire app
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Dark background color
      scaffoldBackgroundColor: background,
      primaryColor: primary,

      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: primary,
        secondary: primary, // Use primary for secondary too (simplified)
        surfaceContainer: surface,
        onSurface: text,
        onPrimary: Colors.black,
        onSecondary: text,
      ),

      // AppBar theme - Uses independent app bar color
      appBarTheme: AppBarTheme(
        backgroundColor: appBar,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevents elevation change when scrolling
        surfaceTintColor:
            Colors.transparent, // Prevents blue tinting from primary color
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16.0, // Reduced from 18.0
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),

      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          textStyle: GoogleFonts.inter(
            fontSize: 13.0, // Reduced from 14.0
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
            fontSize: 13.0, // Reduced from 14.0
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.inter(color: textMuted),
        errorStyle: GoogleFonts.inter(color: error),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
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
  // PREDEFINED TEXT STYLES - Using the minimal color system
  // ============================================================================

  static TextStyle songTitleStyle = GoogleFonts.inter(
    fontSize: 20.0, // Reduced from 24.0
    fontWeight: FontWeight.bold,
    color: text,
  );

  static TextStyle artistNameStyle = GoogleFonts.inter(
    fontSize: 14.0, // Reduced from 16.0
    fontWeight: FontWeight.w400,
    color: textMuted,
  );

  static TextStyle sectionTitleStyle = GoogleFonts.inter(
    fontSize: 14.0, // Reduced from 16.0
    fontWeight: FontWeight.w600,
    color: text,
  );

  static TextStyle chordSheetStyle = GoogleFonts.jetBrainsMono(
    fontSize: 13.0, // Reduced from 14.0
    height: 1.5,
    color: text,
  );

  static TextStyle chordStyle = GoogleFonts.jetBrainsMono(
    fontSize: 13.0, // Reduced from 14.0
    fontWeight: FontWeight.w600,
    color: primary,
  );

  static TextStyle sectionHeaderStyle = GoogleFonts.jetBrainsMono(
    fontSize: 13.0, // Reduced from 14.0
    fontWeight: FontWeight.bold,
    color: textMuted,
    letterSpacing: 0.5,
  );

  static TextStyle tabLabelStyle = GoogleFonts.inter(
    fontSize: 13.0, // Reduced from 14.0
    fontWeight: FontWeight.w500,
  );

  static TextStyle bottomNavLabelStyle = GoogleFonts.inter(
    fontSize: 11.0, // Reduced from 12.0
    fontWeight: FontWeight.w500,
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
