# Font Weight Standardization Guide

This guide outlines the standardized font weights to be used throughout the Stuthi app, based on the preferred styling seen in the vocal and profile screens.

## Font Weight Standards

### Headings and Titles
- **Primary Headings**: `FontWeight.w600` (Semi-bold)
  - Screen titles
  - Section headers
  - Dialog titles
  
- **Secondary Headings**: `FontWeight.w500` (Medium)
  - Subsection titles
  - Card titles
  - List item titles

### Body Text
- **Regular Body Text**: `FontWeight.w400` (Regular)
  - Paragraphs
  - Descriptions
  - General content
  
- **Emphasized Body Text**: `FontWeight.w500` (Medium)
  - Important information
  - Interactive elements
  - Labels

### Special Cases
- **Very Limited Use**: `FontWeight.w700` (Bold)
  - Only for extreme emphasis
  - Critical alerts
  - Call-to-action buttons
  
- **Never Use**: `FontWeight.w800` or `FontWeight.w900`
  - These weights are too heavy for our design language
  - Replace with w600 or w700 as appropriate

## Using the FontWeightUtils Class

The app now includes a `FontWeightUtils` class that provides standardized font weights and helper methods to create consistent text styles. This is the preferred way to apply font weights throughout the app.

### Standard Font Weight Constants

```dart
// Import the utility class
import '../utils/font_weight_utils.dart';

// Use the standardized font weights
FontWeightUtils.primary    // w600 - For main headings and titles
FontWeightUtils.secondary  // w500 - For secondary headings and emphasized text
FontWeightUtils.regular    // w400 - For regular body text
FontWeightUtils.light      // w300 - For de-emphasized text
FontWeightUtils.emphasis   // w700 - Use very sparingly for extreme emphasis
```

### Helper Methods for Creating Text Styles

```dart
// Create a primary heading style
Text(
  'Screen Title',
  style: FontWeightUtils.primaryHeading(
    fontSize: 18,
    color: AppTheme.textPrimary,
    letterSpacing: -0.3,
  ),
)

// Create a secondary heading style
Text(
  'Section Header',
  style: FontWeightUtils.secondaryHeading(
    fontSize: 16,
    color: AppTheme.textPrimary,
  ),
)

// Create a regular body text style
Text(
  'Regular body text content',
  style: FontWeightUtils.bodyText(
    fontSize: 14,
    color: AppTheme.textPrimary,
  ),
)

// Create a light text style for de-emphasized content
Text(
  'Secondary information',
  style: FontWeightUtils.lightText(
    fontSize: 12,
    color: AppTheme.textSecondary,
  ),
)
```

### Standardizing Existing Text Styles

The `FontWeightUtils` class also provides a method to standardize existing text styles:

```dart
// Convert an existing style to use standardized weights
final existingStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w800, // Too bold
  color: Colors.white,
);

// Standardize the weight (will convert w800 to w600)
final standardizedStyle = FontWeightUtils.standardizeWeight(existingStyle);
```

## Implementation Guidelines

### 1. Update AppTheme Text Styles

Update the predefined text styles in `AppTheme` class to use the standardized weights:

```dart
// In theme.dart
static const TextStyle songTitleStyle = TextStyle(
  fontSize: 18.0,
  fontWeight: FontWeight.w600, // Changed from w700
  fontFamily: displayFontFamily,
  color: textPrimary,
  letterSpacing: -0.3,
);

static const TextStyle sectionTitleStyle = TextStyle(
  fontSize: 16.0,
  fontWeight: FontWeight.w600, // Correct weight
  fontFamily: primaryFontFamily,
  color: textPrimary,
  letterSpacing: -0.2,
);

// Add more standardized styles...
```

### 2. Screen-by-Screen Updates

When updating each screen, follow these guidelines:

1. **Screen Titles**: Use `FontWeightUtils.primaryHeading()`
   ```dart
   Text(
     'Screen Title',
     style: FontWeightUtils.primaryHeading(
       fontSize: 18,
       color: AppTheme.textPrimary,
     ),
   )
   ```

2. **Section Headers**: Use `FontWeightUtils.primaryHeading()`
   ```dart
   Text(
     'Section Header',
     style: FontWeightUtils.primaryHeading(
       fontSize: 16,
       color: AppTheme.textPrimary,
     ),
   )
   ```

3. **Body Text**: Use `FontWeightUtils.bodyText()`
   ```dart
   Text(
     'Regular body text content',
     style: FontWeightUtils.bodyText(
       fontSize: 14,
       color: AppTheme.textPrimary,
     ),
   )
   ```

4. **Buttons and Interactive Elements**: Use `FontWeightUtils.secondaryHeading()`
   ```dart
   ElevatedButton(
     child: Text(
       'Button Text',
       style: FontWeightUtils.secondaryHeading(
         fontSize: 14,
         color: AppTheme.background,
       ),
     ),
     onPressed: () {},
   )
   ```

## Priority Screens to Update

The following screens have been identified as having inconsistent (too bold) font weights and should be updated first:

1. Home Screen
2. Course Detail Screen
3. Song Detail Screen
4. Community Screen
5. Artist Detail Screen

## Testing

After updating font weights:

1. Compare screens side by side with vocal/profile screens
2. Ensure readability is maintained
3. Check for visual hierarchy consistency
4. Verify that emphasis is properly conveyed without excessive boldness

## Benefits of Standardization

1. **Improved Readability**: Less bold text is easier to read, especially on mobile devices
2. **Consistent Visual Language**: Creates a more cohesive user experience
3. **Modern Aesthetic**: Lighter font weights align with contemporary design trends
4. **Better Accessibility**: More moderate font weights improve readability for users with visual impairments