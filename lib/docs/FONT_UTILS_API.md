# FontUtils API Reference

This document provides complete API reference for the `FontUtils` class, which is the central utility for managing consistent font usage throughout the Stuthi app.

## Overview

The `FontUtils` class provides three main categories of functionality:
1. **Core Font Utilities** - Apply and create text styles with standard fonts
2. **Font Weight Utilities** - Standardized font weights and helper methods
3. **Font Audit Utilities** - Development tools for identifying font inconsistencies

> **Note:** All font utilities have been consolidated into a single `FontUtils` class for better maintainability and consistency.

## Core Font Utilities

### Font Family Application Methods

#### `withPrimaryFont(TextStyle style)`
Applies the primary font family to an existing TextStyle, replacing any existing fontFamily.

**Parameters:**
- `style` (TextStyle): The existing TextStyle to modify

**Returns:** TextStyle with primary font family applied

**Example:**
```dart
final originalStyle = TextStyle(fontSize: 16, color: Colors.white);
final styledText = FontUtils.withPrimaryFont(originalStyle);
```

#### `withDisplayFont(TextStyle style)`
Applies the display font family to an existing TextStyle, replacing any existing fontFamily.

**Parameters:**
- `style` (TextStyle): The existing TextStyle to modify

**Returns:** TextStyle with display font family applied

**Example:**
```dart
final headingStyle = FontUtils.withDisplayFont(
  TextStyle(fontSize: 24, fontWeight: FontWeight.w600)
);
```

#### `withMonospaceFont(TextStyle style)`
Applies the monospace font family to an existing TextStyle, replacing any existing fontFamily.

**Parameters:**
- `style` (TextStyle): The existing TextStyle to modify

**Returns:** TextStyle with monospace font family applied

**Example:**
```dart
final chordStyle = FontUtils.withMonospaceFont(
  TextStyle(fontSize: 14, color: AppTheme.textPrimary)
);
```

### Font Family Creation Methods

#### `createPrimaryStyle({...})`
Creates a new TextStyle with the primary font family and specified properties.

**Parameters:**
- `fontSize` (double?): Font size in logical pixels
- `fontWeight` (FontWeight?): Font weight
- `color` (Color?): Text color
- `letterSpacing` (double?): Letter spacing
- `height` (double?): Line height multiplier
- `decoration` (TextDecoration?): Text decoration
- `fontStyle` (FontStyle?): Font style (italic, normal)

**Returns:** TextStyle with primary font family

**Example:**
```dart
final bodyStyle = FontUtils.createPrimaryStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: AppTheme.textPrimary,
  letterSpacing: 0.1,
);
```

#### `createDisplayStyle({...})`
Creates a new TextStyle with the display font family and specified properties.

**Parameters:** Same as `createPrimaryStyle`

**Returns:** TextStyle with display font family

**Example:**
```dart
final titleStyle = FontUtils.createDisplayStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  color: AppTheme.textPrimary,
  letterSpacing: -0.5,
);
```

#### `createMonospaceStyle({...})`
Creates a new TextStyle with the monospace font family and specified properties.

**Parameters:** Same as `createPrimaryStyle`

**Returns:** TextStyle with monospace font family

**Example:**
```dart
final codeStyle = FontUtils.createMonospaceStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: AppTheme.textSecondary,
);
```

## Font Weight Utilities

### Standardized Font Weight Constants

#### `FontUtils.primary`
**Value:** `FontWeight.w600`
**Usage:** Main headings and titles

#### `FontUtils.secondary`
**Value:** `FontWeight.w500`
**Usage:** Secondary headings and emphasized text

#### `FontUtils.regular`
**Value:** `FontWeight.w400`
**Usage:** Regular body text

#### `FontUtils.light`
**Value:** `FontWeight.w300`
**Usage:** De-emphasized text

#### `FontUtils.emphasis`
**Value:** `FontWeight.w700`
**Usage:** Very special cases requiring extreme emphasis (use sparingly)

### Font Weight Helper Methods

#### `primaryHeading({...})`
Creates a TextStyle with primary heading weight (w600).

**Parameters:**
- `fontSize` (double, required): Font size in logical pixels
- `color` (Color?): Text color (defaults to AppTheme.textPrimary)
- `fontFamily` (String?): Font family (defaults to AppTheme.primaryFontFamily)
- `letterSpacing` (double?): Letter spacing
- `height` (double?): Line height multiplier

**Returns:** TextStyle with primary heading weight

**Example:**
```dart
Text(
  'Screen Title',
  style: FontUtils.primaryHeading(
    fontSize: 18,
    color: AppTheme.textPrimary,
    letterSpacing: -0.3,
  ),
)
```

#### `secondaryHeading({...})`
Creates a TextStyle with secondary heading weight (w500).

**Parameters:** Same as `primaryHeading`

**Returns:** TextStyle with secondary heading weight

**Example:**
```dart
Text(
  'Section Header',
  style: FontUtils.secondaryHeading(
    fontSize: 16,
    color: AppTheme.textPrimary,
  ),
)
```

#### `bodyText({...})`
Creates a TextStyle with regular body text weight (w400).

**Parameters:** Same as `primaryHeading`

**Returns:** TextStyle with regular body text weight

**Example:**
```dart
Text(
  'Regular body text content',
  style: FontUtils.bodyText(
    fontSize: 14,
    color: AppTheme.textPrimary,
  ),
)
```

#### `lightText({...})`
Creates a TextStyle with light weight (w300) for de-emphasized text.

**Parameters:** Same as `primaryHeading` (color defaults to AppTheme.textSecondary)

**Returns:** TextStyle with light weight

**Example:**
```dart
Text(
  'Secondary information',
  style: FontUtils.lightText(
    fontSize: 12,
    color: AppTheme.textSecondary,
  ),
)
```

#### `standardizeWeight(TextStyle style)`
Converts a TextStyle to use standardized font weights.

**Parameters:**
- `style` (TextStyle): The TextStyle to standardize

**Returns:** TextStyle with standardized font weight

**Conversion Rules:**
- w700, w800, w900, or FontWeight.bold → w600 (primary)
- null weight → w400 (regular)
- Other weights → unchanged

**Example:**
```dart
final boldStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w800);
final standardized = FontUtils.standardizeWeight(boldStyle);
// Result: fontSize: 16, fontWeight: FontWeight.w600
```

## Font Audit Utilities (Development Only)

### Font Validation Methods

#### `usesStandardFont(TextStyle? style)`
Checks if a TextStyle uses one of the app's standard font families.

**Parameters:**
- `style` (TextStyle?): The TextStyle to check

**Returns:** bool - true if using standard font, false otherwise

**Example:**
```dart
final style = TextStyle(fontFamily: AppTheme.primaryFontFamily);
bool isStandard = FontUtils.usesStandardFont(style); // true

final badStyle = TextStyle(fontFamily: 'Arial');
bool isStandard = FontUtils.usesStandardFont(badStyle); // false
```

#### `describeFontUsage(TextStyle? style)`
Provides a human-readable description of font usage for a TextStyle.

**Parameters:**
- `style` (TextStyle?): The TextStyle to describe

**Returns:** String description of font usage

**Possible Return Values:**
- `'No style defined'` - when style is null
- `'No font family specified'` - when fontFamily is null
- `'Using primary font (SF Pro Display)'` - when using primary font
- `'Using display font (SF Pro Display)'` - when using display font
- `'Using monospace font (JetBrains Mono)'` - when using monospace font
- `'Using non-standard font: [fontName]'` - when using non-standard font

**Example:**
```dart
final style = TextStyle(fontFamily: AppTheme.primaryFontFamily);
String description = FontUtils.describeFontUsage(style);
// Returns: "Using primary font (SF Pro Display)"
```

### Development Debugging Tools

#### `auditText(Widget child)`
Wraps a widget to visually highlight text that doesn't use standard fonts.

**Parameters:**
- `child` (Widget): The widget to audit (must be a Text widget)

**Returns:** Widget - original widget if using standard fonts, or wrapped with red border if not

**Behavior:**
- If child is not a Text widget, returns child unchanged
- If Text widget uses standard fonts, returns child unchanged
- If Text widget uses non-standard fonts, wraps with red border overlay

**Example:**
```dart
// This will show a red border if the text uses non-standard fonts
Widget auditedText = FontUtils.auditText(
  Text('Some text', style: TextStyle(fontFamily: 'Arial'))
);
```

### Extension Methods

#### `TextAuditExtension.withFontAudit()`
Extension method on Text widgets for easier font auditing.

**Usage:**
```dart
Text('Some text', style: someStyle).withFontAudit()
```

**Equivalent to:**
```dart
FontUtils.auditText(Text('Some text', style: someStyle))
```

## Usage Patterns

### Common Usage Patterns

#### 1. Creating Consistent Headings
```dart
// Screen title
Text(
  'Settings',
  style: FontUtils.primaryHeading(
    fontSize: 18,
    letterSpacing: -0.3,
  ),
)

// Section header
Text(
  'Account Information',
  style: FontUtils.secondaryHeading(
    fontSize: 16,
  ),
)
```

#### 2. Standardizing Existing Styles
```dart
// Convert theme styles to use standard weights
final standardizedSongTitle = FontUtils.standardizeWeight(
  AppTheme.songTitleStyle
);

// Apply standard fonts to custom styles
final customStyle = TextStyle(fontSize: 14, color: Colors.blue);
final styledCustom = FontUtils.withPrimaryFont(customStyle);
```

#### 3. Development Auditing
```dart
// During development, wrap text to identify font issues
Widget buildText(String text, TextStyle? style) {
  return FontUtils.auditText(
    Text(text, style: style)
  );
}

// Or use the extension method
Text('Debug text', style: someStyle).withFontAudit()
```

#### 4. Creating Chord Sheet Styles
```dart
// For chord sheets and code blocks
final chordStyle = FontUtils.createMonospaceStyle(
  fontSize: 14,
  fontWeight: FontUtils.regular,
  color: AppTheme.textPrimary,
  letterSpacing: 0.5,
);
```

## Best Practices

1. **Always use FontUtils methods** instead of creating TextStyles directly
2. **Use standardized font weights** from FontUtils constants
3. **Apply font audit tools** during development to catch inconsistencies
4. **Prefer helper methods** like `primaryHeading()` over manual TextStyle creation
5. **Use `standardizeWeight()`** when updating existing theme styles
6. **Test with audit tools** before removing them from production builds

## Integration with AppTheme

The FontUtils class works seamlessly with the AppTheme system:

```dart
// FontUtils uses AppTheme constants internally
FontUtils.createPrimaryStyle(...) // Uses AppTheme.primaryFontFamily
FontUtils.createDisplayStyle(...) // Uses AppTheme.displayFontFamily
FontUtils.createMonospaceStyle(...) // Uses AppTheme.monospaceFontFamily

// Default colors come from AppTheme
FontUtils.primaryHeading(...) // Defaults to AppTheme.textPrimary
FontUtils.lightText(...) // Defaults to AppTheme.textSecondary
```

This ensures that all font utilities automatically respect the app's theming system and will update automatically when theme colors change.