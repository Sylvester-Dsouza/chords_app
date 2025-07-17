# Font Usage Guide for Stuthi App

This guide explains how to use fonts consistently throughout the Stuthi app to maintain a cohesive visual identity.

## Font Families

The app uses three main font families:

1. **SF Pro Display** (`AppTheme.primaryFontFamily`) - The primary font used for most text in the app
2. **SF Pro Display** (`AppTheme.displayFontFamily`) - Used for headings and large text
3. **JetBrains Mono** (`AppTheme.monospaceFontFamily`) - Used for chord sheets, code blocks, and other monospaced content

## How to Use Fonts Correctly

### 1. Always Reference Font Constants

Never hardcode font family names. Instead, always use the constants from `AppTheme`:

```dart
// CORRECT
Text(
  'Hello World',
  style: TextStyle(
    fontFamily: AppTheme.primaryFontFamily,
    fontSize: 16,
  ),
)

// INCORRECT
Text(
  'Hello World',
  style: TextStyle(
    fontFamily: 'SF Pro Display', // Don't hardcode font names
    fontSize: 16,
  ),
)
```

### 2. Use Predefined Text Styles

The `AppTheme` class provides many predefined text styles for common use cases:

```dart
// Use predefined styles when possible
Text(
  'Song Title',
  style: AppTheme.songTitleStyle,
)

// For dialog titles
Text(
  'Settings',
  style: AppTheme.dialogTitleStyle,
)
```

### 3. Use the FontUtils Helper Class

The `FontUtils` class provides comprehensive helper methods to ensure consistent font usage:

```dart
// Apply primary font to an existing style
final style = FontUtils.withPrimaryFont(
  TextStyle(fontSize: 16, color: Colors.white)
);

// Apply display font to an existing style
final displayStyle = FontUtils.withDisplayFont(
  TextStyle(fontSize: 18, color: Colors.white)
);

// Apply monospace font to an existing style
final monoStyle = FontUtils.withMonospaceFont(
  TextStyle(fontSize: 14, color: Colors.white)
);

// Create a new style with the primary font
final style = FontUtils.createPrimaryStyle(
  fontSize: 16,
  color: Colors.white,
  fontWeight: FontWeight.w600,
);

// Create a new style with the display font
final displayStyle = FontUtils.createDisplayStyle(
  fontSize: 18,
  color: Colors.white,
  fontWeight: FontWeight.w600,
);

// Create a new style with the monospace font
final monoStyle = FontUtils.createMonospaceStyle(
  fontSize: 14,
  color: Colors.white,
  fontWeight: FontWeight.w400,
);
```

### 4. Use the FontWeightUtils Class for Consistent Font Weights

The `FontWeightUtils` class provides standardized font weights and helper methods:

```dart
// Use standardized font weight constants
Text(
  'Heading',
  style: TextStyle(
    fontFamily: AppTheme.primaryFontFamily,
    fontWeight: FontWeightUtils.primary, // w600
    fontSize: 18,
  ),
)

// Or use the helper methods for complete text styles
Text(
  'Heading',
  style: FontWeightUtils.primaryHeading(
    fontSize: 18,
    color: AppTheme.textPrimary,
  ),
)

// Standardize an existing text style
final standardizedStyle = FontWeightUtils.standardizeWeight(existingStyle);
```

### 5. Font Weight Guidelines

Use the standardized font weights from `FontWeightUtils`:

- **Primary headings**: Use `FontWeightUtils.primary` (w600)
- **Secondary headings**: Use `FontWeightUtils.secondary` (w500)
- **Regular text**: Use `FontWeightUtils.regular` (w400)
- **De-emphasized text**: Use `FontWeightUtils.light` (w300)
- **Special emphasis**: Use `FontWeightUtils.emphasis` (w700) very sparingly

### 6. When to Use Each Font Family

- **Primary Font (SF Pro Display)**: Use for most text in the app, including body text, buttons, labels, etc.
- **Display Font (SF Pro Display)**: Use for headings, titles, and other prominent text elements
- **Monospace Font (JetBrains Mono)**: Use for chord sheets, code blocks, and other content requiring fixed-width characters

## Font Audit Utilities (Development Only)

The `FontUtils` class includes development tools to help identify and fix font inconsistencies:

```dart
// Check if a TextStyle uses standard fonts
bool isStandard = FontUtils.usesStandardFont(textStyle);

// Get a description of font usage
String description = FontUtils.describeFontUsage(textStyle);

// Wrap a Text widget to highlight non-standard fonts (development only)
Widget auditedText = FontUtils.auditText(
  Text('Some text', style: someStyle)
);

// Using the extension method for easier auditing
Widget auditedText = Text('Some text', style: someStyle).withFontAudit();
```

These utilities help during development to:
- Identify text widgets using non-standard fonts
- Provide visual feedback by highlighting problematic text with red borders
- Generate descriptive reports of font usage

## Common Mistakes to Avoid

1. Don't use `fontFamily: 'monospace'` - use `AppTheme.monospaceFontFamily` instead
2. Don't create TextStyles without specifying a font family
3. Don't mix different font families inconsistently
4. Don't use Google Fonts or other external font packages unless specifically required
5. Don't use font weights heavier than w700 (use `FontUtils.standardizeWeight()` to fix)
6. Don't hardcode font family names - always use `AppTheme` constants

## Example Usage

```dart
import '../config/theme.dart';
import '../utils/font_utils.dart';
import '../utils/font_weight_utils.dart';

// Using predefined styles
Text(
  'Song Title',
  style: AppTheme.songTitleStyle,
)

// Creating custom styles with FontUtils
Text(
  'Custom Text',
  style: FontUtils.createPrimaryStyle(
    fontSize: 16,
    color: AppTheme.textSecondary,
    fontWeight: FontWeightUtils.secondary, // Use standardized weight
  ),
)

// Using FontWeightUtils helper methods
Text(
  'Heading',
  style: FontWeightUtils.primaryHeading(
    fontSize: 18,
    color: AppTheme.textPrimary,
  ),
)

// Standardizing existing styles
final baseStyle = TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w800);
final standardizedStyle = FontWeightUtils.standardizeWeight(baseStyle);
final styledText = Text(
  'Styled Text',
  style: standardizedStyle,
)
```

By following these guidelines, we ensure a consistent typography system throughout the app, enhancing the user experience and maintaining visual coherence.

## Additional Resources

For more detailed information about font weight standardization, refer to:
- [Font Weight Standardization Guide](./FONT_WEIGHT_STANDARDIZATION.md)
- [Font Consistency Changes](./FONT_CONSISTENCY_CHANGES.md)