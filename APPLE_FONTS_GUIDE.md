# 🍎 Apple San Francisco-like Font System

## 🎯 Overview
Your app now uses fonts that closely match Apple's San Francisco font family, giving it a clean, modern, and professional appearance similar to iOS and macOS apps.

## 🔤 Font Selection

### Why These Fonts Look Like Apple Fonts

#### **Inter** (Primary Font)
- **Replaces**: DM Sans
- **Matches**: Apple San Francisco (SF Pro)
- **Why it's perfect**:
  - Specifically designed for user interfaces
  - Excellent readability at all screen sizes
  - Clean, minimal letterforms
  - Optimized for digital displays
  - Used by many major tech companies
  - Very similar character shapes to SF Pro

#### **JetBrains Mono** (Monospace Font)
- **Replaces**: Roboto Mono
- **Matches**: Apple SF Mono
- **Why it's perfect**:
  - Clean, readable monospace design
  - Great for code and chord sheets
  - Similar aesthetic to SF Mono
  - Excellent character distinction
  - Optimized for programming and technical content

## 📱 Font Usage Throughout the App

### Primary Font (Inter) - Used For:
- ✅ All UI text (buttons, labels, navigation)
- ✅ Song titles and headings
- ✅ Artist names and descriptions
- ✅ Body text and paragraphs
- ✅ Form inputs and placeholders
- ✅ Menu items and lists

### Monospace Font (JetBrains Mono) - Used For:
- ✅ Chord sheets and chord notation
- ✅ Song lyrics with chord markings
- ✅ Code blocks (if any)
- ✅ Technical content that needs fixed-width characters

## 🎨 Font Weights and Styles

### Inter Font Weights Available:
```dart
FontWeight.w300  // Light
FontWeight.w400  // Regular (default)
FontWeight.w500  // Medium
FontWeight.w600  // Semi-bold
FontWeight.w700  // Bold
FontWeight.w800  // Extra-bold
```

### Common Usage Patterns:
```dart
// Headings and titles
GoogleFonts.inter(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: AppTheme.text,
)

// Body text
GoogleFonts.inter(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: AppTheme.text,
)

// Subtitles and secondary text
GoogleFonts.inter(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: AppTheme.textMuted,
)

// Button text
GoogleFonts.inter(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: Colors.black,
)
```

## 🔧 Implementation Details

### Theme Configuration
The fonts are configured in `lib/config/theme.dart`:

```dart
// Font family constants
static const String primaryFontFamily = 'Inter';
static const String monospaceFontFamily = 'JetBrains Mono';

// Theme uses Inter as base font
textTheme: GoogleFonts.interTextTheme(...)

// Predefined styles use Inter
static TextStyle songTitleStyle = GoogleFonts.inter(...)
static TextStyle artistNameStyle = GoogleFonts.inter(...)
```

### Using Fonts in Your Code

#### Method 1: Use Theme Constants (Recommended)
```dart
Text(
  'Song Title',
  style: TextStyle(
    fontFamily: AppTheme.primaryFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  ),
)
```

#### Method 2: Use Google Fonts Directly
```dart
Text(
  'Song Title',
  style: GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppTheme.text,
  ),
)
```

#### Method 3: Use Predefined Styles
```dart
Text(
  'Song Title',
  style: AppTheme.songTitleStyle,
)

Text(
  'Artist Name',
  style: AppTheme.artistNameStyle,
)
```

## 🍎 Apple-like Design Principles

### Typography Hierarchy
Following Apple's design principles:

1. **Large Title** (32px, Bold) - Main screen titles
2. **Title 1** (24px, Bold) - Section headers
3. **Title 2** (20px, Semi-bold) - Subsection headers
4. **Headline** (18px, Semi-bold) - Card titles
5. **Body** (16px, Regular) - Main content
6. **Callout** (14px, Regular) - Secondary content
7. **Caption** (12px, Regular) - Metadata, timestamps

### Font Weight Guidelines
- **Light (300)**: Large display text only
- **Regular (400)**: Body text, descriptions
- **Medium (500)**: Button text, emphasized content
- **Semi-bold (600)**: Headings, important labels
- **Bold (700)**: Titles, strong emphasis
- **Extra-bold (800)**: Display text, hero titles

## 📊 Comparison with Apple Fonts

| Characteristic | Apple SF Pro | Inter | Match Quality |
|----------------|--------------|-------|---------------|
| Readability | Excellent | Excellent | ✅ Perfect |
| Screen optimization | Yes | Yes | ✅ Perfect |
| Character spacing | Optimized | Optimized | ✅ Perfect |
| Weight variety | 9 weights | 9 weights | ✅ Perfect |
| UI suitability | Designed for UI | Designed for UI | ✅ Perfect |
| Overall aesthetic | Clean, minimal | Clean, minimal | ✅ Perfect |

## 🚀 Benefits of This Font System

1. **🍎 Apple-like Appearance**: Users will feel familiar with the interface
2. **📱 Cross-platform Consistency**: Looks great on both iOS and Android
3. **👁️ Excellent Readability**: Optimized for all screen sizes and resolutions
4. **🎨 Professional Look**: Clean, modern typography
5. **⚡ Performance**: Google Fonts are optimized and cached
6. **🔧 Maintainable**: Easy to update fonts across the entire app

## 💡 Pro Tips

1. **Stick to the font weights**: Use the predefined weights for consistency
2. **Use appropriate sizes**: Follow the typography hierarchy
3. **Consider line height**: Inter works best with 1.2-1.5 line height
4. **Test on devices**: Always test fonts on actual devices
5. **Use theme styles**: Prefer predefined styles over custom ones

---

**🎉 Your app now has beautiful, Apple San Francisco-like typography that will make users feel right at home!**
