import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Utility class to help enforce consistent font usage throughout the app
class FontUtils {
  // =============================================================================
  // CORE FONT UTILITIES
  // =============================================================================
  
  /// Ensures that a TextStyle has the primary font family applied
  /// If the style already has a fontFamily, it will be replaced
  static TextStyle withPrimaryFont(TextStyle style) {
    return style.copyWith(fontFamily: AppTheme.primaryFontFamily);
  }

  /// Ensures that a TextStyle has the display font family applied
  /// If the style already has a fontFamily, it will be replaced
  static TextStyle withDisplayFont(TextStyle style) {
    return style.copyWith(fontFamily: AppTheme.displayFontFamily);
  }

  /// Ensures that a TextStyle has the monospace font family applied
  /// If the style already has a fontFamily, it will be replaced
  static TextStyle withMonospaceFont(TextStyle style) {
    return style.copyWith(fontFamily: AppTheme.monospaceFontFamily);
  }

  /// Creates a TextStyle with the primary font family and the specified properties
  static TextStyle createPrimaryStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: AppTheme.primaryFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  /// Creates a TextStyle with the display font family and the specified properties
  static TextStyle createDisplayStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: AppTheme.displayFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  /// Creates a TextStyle with the monospace font family and the specified properties
  static TextStyle createMonospaceStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: AppTheme.monospaceFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  // =============================================================================
  // FONT WEIGHT UTILITIES
  // =============================================================================
  
  /// Standard font weights based on the vocal and profile screens
  static const FontWeight primary = FontWeight.w600;    // For main headings and titles
  static const FontWeight secondary = FontWeight.w500;  // For secondary headings and emphasized text
  static const FontWeight regular = FontWeight.w400;    // For regular body text
  static const FontWeight light = FontWeight.w300;      // For de-emphasized text
  
  /// Only use for very special cases where extreme emphasis is needed
  static const FontWeight emphasis = FontWeight.w700;   // Use very sparingly
  
  /// Creates a TextStyle with the primary heading weight
  static TextStyle primaryHeading({
    required double fontSize,
    Color? color,
    String? fontFamily,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? AppTheme.primaryFontFamily,
      fontWeight: primary,
      fontSize: fontSize,
      color: color ?? AppTheme.textPrimary,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
  
  /// Creates a TextStyle with the secondary heading weight
  static TextStyle secondaryHeading({
    required double fontSize,
    Color? color,
    String? fontFamily,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? AppTheme.primaryFontFamily,
      fontWeight: secondary,
      fontSize: fontSize,
      color: color ?? AppTheme.textPrimary,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
  
  /// Creates a TextStyle with the regular body text weight
  static TextStyle bodyText({
    required double fontSize,
    Color? color,
    String? fontFamily,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? AppTheme.primaryFontFamily,
      fontWeight: regular,
      fontSize: fontSize,
      color: color ?? AppTheme.textPrimary,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
  
  /// Creates a TextStyle with the light weight for de-emphasized text
  static TextStyle lightText({
    required double fontSize,
    Color? color,
    String? fontFamily,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? AppTheme.primaryFontFamily,
      fontWeight: light,
      fontSize: fontSize,
      color: color ?? AppTheme.textSecondary,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
  
  /// Converts a bold TextStyle to use the standardized weights
  /// This is useful for updating existing TextStyles
  static TextStyle standardizeWeight(TextStyle style) {
    // If the weight is too bold (w700+), reduce it
    if (style.fontWeight == FontWeight.w700 || 
        style.fontWeight == FontWeight.w800 || 
        style.fontWeight == FontWeight.w900 ||
        style.fontWeight == FontWeight.bold) {
      return style.copyWith(fontWeight: primary);
    }
    
    // If no weight is specified, use regular
    if (style.fontWeight == null) {
      return style.copyWith(fontWeight: regular);
    }
    
    // Otherwise, keep the existing weight
    return style;
  }

  // =============================================================================
  // FONT AUDIT UTILITIES (Development Only)
  // =============================================================================
  
  /// Check if a TextStyle uses one of the app's standard font families
  static bool usesStandardFont(TextStyle? style) {
    if (style == null || style.fontFamily == null) return false;
    
    return style.fontFamily == AppTheme.primaryFontFamily ||
           style.fontFamily == AppTheme.displayFontFamily ||
           style.fontFamily == AppTheme.monospaceFontFamily;
  }
  
  /// Get a description of the font usage for a TextStyle
  static String describeFontUsage(TextStyle? style) {
    if (style == null) return 'No style defined';
    if (style.fontFamily == null) return 'No font family specified';
    
    if (style.fontFamily == AppTheme.primaryFontFamily) {
      return 'Using primary font (SF Pro Display)';
    } else if (style.fontFamily == AppTheme.displayFontFamily) {
      return 'Using display font (SF Pro Display)';
    } else if (style.fontFamily == AppTheme.monospaceFontFamily) {
      return 'Using monospace font (JetBrains Mono)';
    } else {
      return 'Using non-standard font: ${style.fontFamily}';
    }
  }
  
  /// A widget wrapper that can be used during development to highlight
  /// text widgets that don't use standard fonts
  static Widget auditText(Widget child) {
    // Only works with Text widgets
    if (child is! Text) return child;
    
    final Text textWidget = child;
    final TextStyle? style = textWidget.style;
    
    if (usesStandardFont(style)) {
      return child;
    }
    
    // Highlight text with non-standard fonts
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

/// Extension method to make it easier to audit text widgets
extension TextAuditExtension on Text {
  /// Returns a copy of this Text widget with font auditing applied
  Widget withFontAudit() {
    return FontUtils.auditText(this);
  }
}