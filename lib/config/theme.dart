import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFFC19FFF); // Light Lavender
  static const Color secondaryColor = Color(0xFF9575CD); // Deeper Lavender
  static const Color backgroundColor = Color(0xFF121212); // Dark background
  static const Color surfaceColor = Color(0xFF1E1E1E); // Slightly lighter for cards
  static const Color textColor = Colors.white;
  static const Color subtitleColor = Color(0xFFAAAAAA); // Light gray for subtitles

  // Font family names
  static const String primaryFontFamily = 'DMSans';
  static const String monospaceFontFamily = 'RobotoMono';

  // Get the theme data
  static ThemeData getTheme() {
    return ThemeData(
      // Use DM Sans as the base font - clean, modern, and minimal
      textTheme: GoogleFonts.dmSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: textColor),
          displayMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: textColor),
          displaySmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: textColor),
          headlineMedium: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600, color: textColor),
          titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500, color: textColor),
          bodyLarge: TextStyle(fontSize: 16.0, color: textColor),
          bodyMedium: TextStyle(fontSize: 14.0, color: textColor),
          labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: textColor),
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
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,

      colorScheme: const ColorScheme.dark(
        surface: backgroundColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surfaceContainer: surfaceColor,
        onSurface: textColor,
        onPrimary: Colors.black,
        onSecondary: textColor,
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),

      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.dmSans(color: Colors.grey),
        errorStyle: GoogleFonts.dmSans(color: Colors.redAccent),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Helper method to get specific text styles
  static TextStyle songTitleStyle = GoogleFonts.dmSans(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static TextStyle artistNameStyle = GoogleFonts.dmSans(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: subtitleColor,
  );

  static TextStyle sectionTitleStyle = GoogleFonts.dmSans(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static TextStyle chordSheetStyle = GoogleFonts.robotoMono(
    fontSize: 14.0,
    height: 1.5,
    color: textColor,
  );

  static TextStyle chordStyle = GoogleFonts.robotoMono(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static TextStyle sectionHeaderStyle = GoogleFonts.robotoMono(
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
    color: Colors.grey,
    letterSpacing: 0.5,
  );

  static TextStyle tabLabelStyle = GoogleFonts.dmSans(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
  );

  static TextStyle bottomNavLabelStyle = GoogleFonts.dmSans(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
  );
}

/// Logo assets helper class
class AppLogos {
  // Logo asset paths
  static const String logoDark = 'assets/images/stuthi logo dark.png';
  static const String logoLight = 'assets/images/stuthi logo light.png';
  static const String logoPurple = 'assets/images/stuthi logo purple.png';

  /// Get the appropriate logo based on theme and context
  static String getLogoForTheme({bool isDarkTheme = true}) {
    return isDarkTheme ? logoLight : logoDark;
  }

  /// Get logo for splash screen (always use the purple/branded version)
  static String getSplashLogo() {
    return logoPurple;
  }

  /// Get logo for app bar (use light version for dark theme)
  static String getAppBarLogo() {
    return logoLight;
  }

  /// Get logo for drawer (use light version for dark theme)
  static String getDrawerLogo() {
    return logoLight;
  }
}
