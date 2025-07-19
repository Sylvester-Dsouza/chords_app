# Navigation Patterns and Screen Management

This document outlines the navigation patterns and screen management strategies used throughout the Stuthi app.

## Overview

The app uses Flutter's navigation system with custom patterns for handling back navigation, data synchronization, and state management across screens.

## PopScope Navigation Pattern

### Background

Starting with Flutter 3.12, the `WillPopScope` widget was deprecated in favor of `PopScope`. The app has been updated to use the new `PopScope` widget with custom navigation handling patterns.

### Implementation Pattern

The standard pattern for handling back navigation with data synchronization:

```dart
PopScope(
  canPop: false, // Prevent automatic back navigation
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop) {
      // Handle the back navigation manually
      _handleBackNavigation();
    }
  },
  child: Scaffold(
    // Screen content
  ),
)
```

### Key Components

1. **canPop: false** - Prevents automatic back navigation, allowing custom handling
2. **onPopInvokedWithResult** - Callback that fires when user attempts to navigate back
3. **Manual Navigation Handler** - Custom method that handles the actual navigation

## Data Synchronization on Navigation

### Modification Tracking

Screens that allow data modification implement a modification tracking pattern:

```dart
class _ScreenState extends State<Screen> {
  bool _hasModifiedData = false; // Track if data was modified
  
  void _onDataModified() {
    setState(() {
      _hasModifiedData = true;
    });
  }
  
  void _handleBackNavigation() {
    // Return modification status to parent screen
    Navigator.of(context).pop(_hasModifiedData);
  }
}
```

## Screen-Specific Navigation Patterns

### Setlist Detail Screen

The `SetlistDetailScreen` implements the full navigation pattern with modification tracking and data synchronization.

#### Key Features

- **Modification Tracking**: Tracks when setlist is modified (songs added/removed/reordered)
- **Manual Back Navigation**: Custom `_handleBackNavigation()` method
- **Data Synchronization**: Returns modification status to parent screens
- **Conflict Resolution**: Handles collaborative editing conflicts

#### Implementation Details

```dart
class _SetlistDetailScreenState extends State<SetlistDetailScreen> {
  bool _hasModifiedSetlist = false; // Track modifications
  
  void _handleBackNavigation() {
    debugPrint('Navigating back with result: $_hasModifiedSetlist');
    Navigator.of(context).pop(_hasModifiedSetlist);
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent automatic back navigation
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(/* ... */),
    );
  }
}
```

### Login Screen

The `LoginScreen` uses PopScope to prevent users from navigating back after logout and shows an exit confirmation dialog.

#### Key Features

- **Exit Prevention**: Prevents back navigation to maintain security
- **Exit Confirmation**: Shows dialog to confirm app exit
- **Security**: Ensures users can't navigate back to authenticated screens

### Practice Mode Screen

The `PracticeMode Screen` uses PopScope to clean up resources when the user navigates away.

#### Key Features

- **Resource Cleanup**: Stops metronome and audio when screen is popped
- **Automatic Cleanup**: Handles cleanup on both manual and system-initiated navigation

### QR Scanner Screen

The `QRScannerScreen` implements a double-pop pattern for navigation after successful scans.

#### Key Features

- **Double Navigation**: Pops scanner screen and triggers refresh in parent
- **Success Handling**: Returns success status to trigger data refresh

## Best Practices

### 1. Consistent Navigation Handling

- Always use the same pattern for screens that modify data
- Implement `_handleBackNavigation()` method for custom logic
- Use `canPop: false` with `PopScope` for manual control

### 2. Data Synchronization

- Track modification state throughout the screen lifecycle
- Return modification status to parent screens
- Implement refresh logic in parent screens

### 3. User Experience

- Provide visual feedback for unsaved changes
- Handle network errors gracefully during navigation
- Maintain consistent back button behavior

## Migration from WillPopScope

When migrating from the deprecated `WillPopScope`:

### Old Pattern (Deprecated)
```dart
WillPopScope(
  onWillPop: () async {
    _handleBackNavigation();
    return false; // Prevent default pop
  },
  child: Scaffold(/* ... */),
)
```

### New Pattern (Current)
```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop) {
      _handleBackNavigation();
    }
  },
  child: Scaffold(/* ... */),
)
```
## Er
ror Handling

### Navigation Errors

Handle potential navigation errors gracefully:

```dart
void _handleBackNavigation() {
  try {
    Navigator.of(context).pop(_hasModifiedData);
  } catch (e) {
    debugPrint('Navigation error: $e');
    // Fallback navigation
    Navigator.of(context).pop();
  }
}
```

### Context Validation

Always check if the widget is still mounted:

```dart
void _handleBackNavigation() {
  if (!mounted) return;
  
  Navigator.of(context).pop(_hasModifiedData);
}
```

## Testing Navigation Patterns

### Unit Testing

Test navigation handlers in isolation:

```dart
testWidgets('should handle back navigation correctly', (tester) async {
  // Test implementation
});
```

### Integration Testing

Test complete navigation flows:

```dart
testWidgets('should sync data between screens', (tester) async {
  // Test data synchronization
});
```

## Recent Changes

### PopScope Migration (January 2025)

The app has been updated to use Flutter's modern `PopScope` widget, replacing the deprecated `WillPopScope`. This change affects several screens:

#### Breaking Changes

- **SetlistDetailScreen**: Now uses manual navigation control with `canPop: false`
- **LoginScreen**: Updated to use PopScope for exit confirmation
- **PracticeMode Screen**: Updated for proper resource cleanup
- **QR Scanner Screen**: Maintains double-pop pattern with new API

#### Migration Benefits

- **Better Performance**: More efficient navigation handling
- **Future Compatibility**: Uses Flutter's recommended navigation patterns
- **Improved Control**: Better handling of system back gestures
- **Enhanced UX**: More predictable navigation behavior

### Data Synchronization Improvements

The navigation system now provides better data synchronization between screens:

- **Modification Tracking**: Screens track when data is modified
- **Automatic Refresh**: Parent screens refresh when child screens make changes
- **Conflict Resolution**: Better handling of collaborative editing scenarios

## Future Considerations

- Consider implementing a navigation service for complex flows
- Evaluate state management solutions for cross-screen data sync
- Monitor Flutter updates for navigation API changes
- Consider implementing navigation guards for unsaved changes

## Related Documentation

- [Error Handling System](ERROR_HANDLING_SYSTEM.md)
- [Data Models API](DATA_MODELS_API.md)
- [Performance Utils API](PERFORMANCE_UTILS_API.md)