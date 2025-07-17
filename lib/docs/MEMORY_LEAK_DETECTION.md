# Memory Management System

This document explains the memory management and monitoring system implemented in the Stuthi app.

## Overview

The memory management system helps monitor and optimize memory usage in the Flutter app. It consists of several components:

1. **MemoryManager**: Core service for memory monitoring and optimization (registered in service locator)
2. **MemoryLeakDetector**: Utility for tracking objects and detecting potential leaks
3. **MemoryMonitorOverlay**: Debug widget that displays memory usage and provides tools for analysis
4. **MemoryLeakPatterns**: Utility for detecting common memory leak patterns

## Architecture Changes

**Note**: As of the latest update, the `MemoryLeakService` has been removed from the service locator to streamline the architecture. Memory management is now handled by the `MemoryManager` service, which provides centralized memory monitoring and optimization.

## Features

- Real-time memory usage monitoring
- Detection of growing object counts over time
- Tracking of widget lifecycles to detect undisposed widgets
- Tracking of stream subscriptions and timers to ensure proper cancellation
- Memory pressure handling with automatic cleanup
- Debug overlay with memory usage information and analysis tools

## How to Use

### Basic Usage

The memory leak detection system is automatically enabled in debug mode. The app is wrapped with the `MemoryMonitorOverlay` widget in the main.dart file:

```dart
// In main.dart
Widget app = MaterialApp(
  // MaterialApp configuration...
);

// Wrap with MemoryMonitorOverlay in debug mode
return MemoryMonitorOverlay(child: app);
```

You'll see a small memory usage indicator in the bottom-right corner of the app. This shows the current memory usage of the app.

- **Tap** the indicator to expand it and show additional options
- **Double-tap** to hide/show the indicator
- **Tap "Report"** to see a detailed memory report
- **Tap "Analyze"** to run a memory leak analysis
- **Tap "Cleanup"** to force a memory cleanup

### Tracking Resources

To track resources that might cause memory leaks, use the `MemoryLeakService`:

```dart
// Track a stream subscription
final subscription = stream.listen((_) {});
MemoryLeakService().trackSubscription(subscription, debugLabel: 'MyWidget');

// Track a timer
final timer = Timer.periodic(Duration(seconds: 1), (_) {});
MemoryLeakService().trackTimer(timer, debugLabel: 'MyWidget');

// Track an object
final controller = AnimationController();
MemoryLeakService().trackObject(controller, 'AnimationController');
```

### Using the MemoryLeakDetectorMixin

For StatefulWidgets, you can use the `MemoryLeakDetectorMixin` to automatically track widget lifecycles:

```dart
class MyWidgetState extends State<MyWidget> with MemoryLeakDetectorMixin {
  @override
  void initState() {
    super.initState();
    // Your initialization code
  }

  @override
  void dispose() {
    // Your cleanup code
    super.dispose();
  }
}
```

### Safe Resource Wrappers

Use the safe wrappers provided by `MemoryLeakPatterns` to automatically track and clean up resources:

```dart
// Safe subscription that's automatically tracked
final subscription = MemoryLeakPatterns.safeSubscription(
  stream.listen((_) {}),
  'MyWidget',
);

// Safe timer that's automatically tracked
final timer = MemoryLeakPatterns.safeTimer(
  Timer.periodic(Duration(seconds: 1), (_) {}),
  'MyWidget',
);
```

### Checking for Common Memory Leak Patterns

Use the `MemoryLeakPatterns.checkStatefulWidget` method to check for common memory leak patterns:

```dart
@override
void initState() {
  super.initState();
  
  final subscription = stream.listen((_) {});
  final timer = Timer.periodic(Duration(seconds: 1), (_) {});
  
  MemoryLeakPatterns.checkStatefulWidget(
    this,
    'MyWidget',
    [subscription, timer],
  );
}
```

## Interpreting Results

When a memory leak analysis is run, the system will look for:

1. **Significant memory growth**: If memory usage has increased significantly over time
2. **Growing object counts**: If certain object types are increasing in count over time
3. **Undisposed widgets**: If widgets are not being properly disposed
4. **Uncancelled resources**: If stream subscriptions or timers are not being cancelled

The analysis results will be printed to the debug console with recommendations for fixing the issues.

## Best Practices

1. Always dispose resources in the `dispose()` method of StatefulWidgets
2. Use `MemoryLeakDetectorMixin` for complex widgets with many resources
3. Track all stream subscriptions and timers using `MemoryLeakService`
4. Run memory leak analysis periodically during development
5. Check the memory report when the app feels sluggish or is using too much memory

## Troubleshooting

If you're experiencing memory issues:

1. Check the memory report for growing object counts
2. Look for uncancelled stream subscriptions and timers
3. Verify that all StatefulWidgets are properly disposing resources
4. Check for global singletons that might be holding references to objects
5. Use the "Cleanup" button to force a memory cleanup and see if it helps

## Implementation Details

The memory leak detection system works by:

1. Taking periodic snapshots of memory usage and object counts
2. Comparing snapshots over time to detect growth patterns
3. Tracking widget lifecycles to detect undisposed widgets
4. Monitoring stream subscriptions and timers to ensure proper cancellation
5. Providing tools for analysis and cleanup

The system is designed to have minimal impact on performance and is only enabled in debug mode.

### Internationalization Support

The memory monitor overlay uses explicit `Directionality` with `TextDirection.ltr` to ensure consistent left-to-right display of memory information and debug controls, regardless of the app's text direction. This makes the overlay readable even in apps that support right-to-left languages.