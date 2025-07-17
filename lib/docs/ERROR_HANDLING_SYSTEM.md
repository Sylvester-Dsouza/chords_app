# Error Handling System

This document outlines the error handling architecture in the Stuthi app, including the smart error detection and user-friendly error presentation system.

## Overview

The app implements a comprehensive error handling system that:
1. Catches errors at different levels of the application
2. Categorizes errors by type (network, authentication, permission, server)
3. Presents user-friendly error messages with appropriate actions
4. Provides recovery paths for different error scenarios

## Components

### 1. ErrorMessageHelper

Located in `lib/utils/ui_helpers.dart`, this class analyzes error messages and categorizes them into specific types:

- **Network Errors**: Connection problems, socket errors, host lookup failures
- **Authentication Errors**: Unauthorized access, authentication failures, token expiration
- **Permission Errors**: Access denied, insufficient permissions
- **Server Errors**: 5xx errors, internal server errors, service unavailability

For each error type, it provides appropriate:
- Title
- Message
- Icon
- Icon color
- Primary action
- Secondary action (when applicable)

### 2. ErrorBoundary Widget

Located in `lib/widgets/error_boundary.dart`, this widget:
- Catches errors in the widget tree
- Prevents app crashes by showing a user-friendly error screen
- Logs errors to the console and crash reporting service
- Provides retry and navigation options

Usage:
```dart
ErrorBoundary(
  child: YourWidget(),
  onError: (details) {
    // Custom error handling
  },
)
```

### 3. Error View Components

Located in `lib/widgets/error_view.dart`, these widgets provide consistent error UI:

- **ErrorView**: Base component for displaying errors with customizable styling
- **FullScreenErrorView**: Full-screen error presentation for critical errors
- **NetworkErrorView**: Specialized view for network connectivity issues
- **LoadingErrorView**: Specialized view for resource loading failures

### 4. Integration with Service Locator

The error handling system integrates with the app's dependency injection system in `lib/core/service_locator.dart`, providing:

- Centralized error handling through the `ErrorHandler` service
- Integration with crash reporting via `CrashlyticsService`
- Retry mechanisms through the `RetryService`

## Error Recovery Paths

The system provides different recovery paths based on error type:

1. **Network Errors**:
   - Primary: Retry the operation
   - Secondary: Switch to offline mode

2. **Authentication Errors**:
   - Primary: Re-authenticate
   - Secondary: Cancel operation

3. **Permission Errors**:
   - Primary: Open settings to grant permissions
   - Secondary: Cancel operation

4. **Server Errors**:
   - Primary: Retry the operation
   - Secondary: Switch to offline mode

5. **Generic Errors**:
   - Primary: Acknowledge (OK)

## Best Practices

When working with the error handling system:

1. Use `ErrorBoundary` to wrap components that might throw errors
2. Use `ErrorView.fromError()` to create error views from error objects
3. Use `UIHelpers.showSmartErrorDialog()` for dialog-based error presentation
4. Use appropriate snackbar methods from `UIHelpers` for transient errors

## Example Usage

### Wrapping a Component with ErrorBoundary

```dart
ErrorBoundary(
  child: SongListView(),
  fallback: const Center(child: Text("Something went wrong loading songs")),
  onError: (details) {
    serviceLocator.crashlyticsService.recordError(
      details.exception,
      details.stack,
      reason: 'Error in SongListView',
    );
  },
)
```

### Showing a Smart Error Dialog

```dart
try {
  await songService.loadSong(id);
} catch (error) {
  UIHelpers.showSmartErrorDialog(
    context,
    error,
    onPrimaryAction: () => songService.loadSong(id),
    onSecondaryAction: () => Navigator.pop(context),
  );
}
```

### Using ErrorView in a Widget

```dart
FutureBuilder<Song>(
  future: songService.getSong(id),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return ErrorView.fromError(
        snapshot.error,
        onRetry: () => setState(() {}),
      );
    }
    
    if (!snapshot.hasData) {
      return const LoadingIndicator();
    }
    
    return SongDetailView(song: snapshot.data!);
  },
)
```