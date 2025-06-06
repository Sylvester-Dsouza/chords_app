# 🎨 Minimal Theme System Guide

## 🎯 Overview
This app now uses a **minimal, simplified theme system** with only **5 essential colors** that cover all use cases. This makes the design consistent, maintainable, and easy to understand.

## 🌈 Color Palette

### Core Colors (Use these 99% of the time)

| Color | Hex Code | Usage | Example |
|-------|----------|-------|---------|
| `AppTheme.primary` | `#37BCFE` | Buttons, links, highlights, interactive elements | Login button, active tabs, progress bars |
| `AppTheme.background` | `#090909` | Main app background | Scaffold background, screen backgrounds |
| `AppTheme.surface` | `#1A1A1A` | Cards, dialogs, elevated elements | Song cards, bottom sheets, app bars |
| `AppTheme.text` | `#FFFFFF` | Primary text content | Song titles, main headings, body text |
| `AppTheme.textMuted` | `#888888` | Secondary text, subtitles, placeholders | Artist names, descriptions, hints |

### Semantic Colors (Use sparingly for specific states)

| Color | Hex Code | Usage | Example |
|-------|----------|-------|---------|
| `AppTheme.success` | `#10B981` | Success states, confirmations | Download complete, save success |
| `AppTheme.error` | `#EF4444` | Errors, warnings, destructive actions | Error messages, delete buttons |

## 📋 Usage Guidelines

### ✅ DO Use These Colors For:

#### `AppTheme.primary`
- Primary buttons (Login, Save, Create)
- Active states (selected tabs, focused inputs)
- Links and interactive text
- Progress indicators and loading states
- Icons that need emphasis
- Chord highlighting in songs

#### `AppTheme.background`
- Scaffold backgrounds
- Main screen backgrounds
- Full-screen overlays

#### `AppTheme.surface`
- Cards (song cards, setlist cards)
- Bottom sheets and dialogs
- App bars and navigation bars
- Input fields and form elements
- Elevated containers

#### `AppTheme.text`
- Song titles and main headings
- Primary body text
- Button labels
- Navigation labels

#### `AppTheme.textMuted`
- Artist names and subtitles
- Descriptions and secondary text
- Placeholder text in inputs
- Timestamps and metadata
- Disabled text

### ❌ DON'T Use Hardcoded Colors

Instead of:
```dart
color: Color(0xFF37BCFE)  // ❌ Hardcoded
color: Colors.blue        // ❌ Material colors
color: Color(0xFF1A1A1A)  // ❌ Hardcoded
```

Use:
```dart
color: AppTheme.primary   // ✅ Theme color
color: AppTheme.surface   // ✅ Theme color
```

## 🔧 Implementation Examples

### Button Styling
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primary,
    foregroundColor: Colors.black, // Black text on blue button
  ),
  child: Text('Save Setlist'),
)
```

### Card Styling
```dart
Container(
  decoration: BoxDecoration(
    color: AppTheme.surface,
    borderRadius: BorderRadius.circular(5),
    border: Border.all(
      color: AppTheme.primary.withAlpha(80), // Subtle primary border
    ),
  ),
  child: Text(
    'Song Title',
    style: TextStyle(color: AppTheme.text),
  ),
)
```

### Text Styling
```dart
Column(
  children: [
    Text(
      'Amazing Grace',
      style: TextStyle(
        color: AppTheme.text,        // Primary text
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    Text(
      'by John Newton',
      style: TextStyle(
        color: AppTheme.textMuted,   // Secondary text
        fontSize: 14,
      ),
    ),
  ],
)
```

## 🎨 Color Variations

### Creating Variations
When you need lighter/darker versions of colors:

```dart
// Lighter versions (for backgrounds, subtle highlights)
AppTheme.primary.withAlpha(20)   // Very light blue background
AppTheme.primary.withAlpha(80)   // Light blue border

// Darker versions (for pressed states, shadows)
AppTheme.surface.withAlpha(200)  // Slightly lighter surface
```

### Common Patterns
```dart
// Subtle card with primary accent
decoration: BoxDecoration(
  color: AppTheme.surface,
  border: Border.all(color: AppTheme.primary.withAlpha(60)),
)

// Highlighted container
decoration: BoxDecoration(
  color: AppTheme.primary.withAlpha(15),
  border: Border.all(color: AppTheme.primary.withAlpha(80)),
)

// Success state
decoration: BoxDecoration(
  color: AppTheme.success.withAlpha(20),
  border: Border.all(color: AppTheme.success),
)
```

## 🚀 Benefits of This System

1. **Consistency**: All UI elements use the same color palette
2. **Maintainability**: Change one color value to update the entire app
3. **Simplicity**: Only 5 colors to remember and use
4. **Accessibility**: High contrast ratios for better readability
5. **Scalability**: Easy to add new features with consistent styling

## 🔄 Migration from Old System

The old complex color system has been automatically updated:

| Old Color | New Color |
|-----------|-----------|
| `AppTheme.primaryColor` | `AppTheme.primary` |
| `AppTheme.backgroundColor` | `AppTheme.background` |
| `AppTheme.surfaceColor` | `AppTheme.surface` |
| `AppTheme.textColor` | `AppTheme.text` |
| `AppTheme.subtitleColor` | `AppTheme.textMuted` |

## 💡 Pro Tips

1. **Use `AppTheme.primary` sparingly** - Only for elements that need user attention
2. **Stick to the 5 core colors** - Avoid creating custom colors unless absolutely necessary
3. **Use alpha variations** - Create depth with `withAlpha()` instead of new colors
4. **Test in both light and dark** - Ensure colors work in different lighting conditions
5. **Consider accessibility** - Maintain good contrast ratios for text readability

---

**Remember**: When in doubt, use `AppTheme.text` for text and `AppTheme.surface` for backgrounds. Keep it simple! 🎨
