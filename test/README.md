# Testing Guide for Christian Chords App

This guide explains how to run and write tests for the Christian Chords app.

## Setup

Before running tests, make sure you have all the required dependencies:

```bash
flutter pub get
```

Generate the mock classes needed for testing:

```bash
flutter pub run build_runner build
```

## Running Tests

### Run All Tests

To run all tests:

```bash
flutter test
```

### Run Specific Test Files

To run a specific test file:

```bash
flutter test test/app_test.dart
```

### Run Tests with Coverage

To run tests with coverage:

```bash
flutter test --coverage
```

Generate a coverage report:

```bash
genhtml coverage/lcov.info -o coverage/html
```

Open the coverage report:

```bash
open coverage/html/index.html
```

## Test Files

### 1. widget_test.dart

A basic smoke test that verifies the app can be launched without errors.

### 2. app_test.dart

Tests for core app functionality:
- App initialization
- Navigation provider
- User provider

### 3. performance_test.dart

Tests for performance optimizations:
- OptimizedSection widget
- OptimizedListItem widget
- MemoryEfficientImage widget
- PerformanceMonitor
- OptimizedCacheService

## Writing New Tests

### Widget Tests

Use the `testWidgets` function to test widgets:

```dart
testWidgets('Widget test description', (WidgetTester tester) async {
  // Build the widget
  await tester.pumpWidget(
    MaterialApp(
      home: YourWidget(),
    ),
  );
  
  // Find widgets
  expect(find.text('Expected Text'), findsOneWidget);
  
  // Interact with widgets
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  
  // Verify results
  expect(find.text('New Text'), findsOneWidget);
});
```

### Unit Tests

Use the `test` function to test functions and classes:

```dart
test('Unit test description', () {
  // Arrange
  final yourClass = YourClass();
  
  // Act
  final result = yourClass.yourMethod();
  
  // Assert
  expect(result, expectedValue);
});
```

### Mocking Dependencies

Use Mockito to mock dependencies:

```dart
// Create a mock
@GenerateMocks([YourDependency])
import 'your_test.mocks.dart';

// Use the mock
final mockDependency = MockYourDependency();
when(mockDependency.someMethod()).thenReturn(expectedValue);
```

## Best Practices

1. **Test One Thing at a Time**: Each test should focus on testing one specific behavior.

2. **Use Descriptive Test Names**: Test names should clearly describe what is being tested.

3. **Arrange-Act-Assert**: Structure tests with clear arrangement, action, and assertion phases.

4. **Mock External Dependencies**: Use mocks for API services, databases, etc.

5. **Test Edge Cases**: Include tests for error conditions and edge cases.

6. **Keep Tests Independent**: Tests should not depend on each other.

7. **Clean Up After Tests**: Reset any global state modified by tests.

## Troubleshooting

### Common Issues

1. **Test Fails with "Widget Not Found"**:
   - Check if the widget is actually being rendered
   - Use `tester.pumpAndSettle()` to wait for animations

2. **Mock Generation Errors**:
   - Run `flutter pub run build_runner clean` and then `flutter pub run build_runner build`

3. **Test Hangs**:
   - Check for infinite animations or streams that never complete
   - Add timeouts to async operations

### Getting Help

If you encounter issues with tests, check:
- Flutter testing documentation: https://docs.flutter.dev/testing
- Mockito documentation: https://pub.dev/packages/mockito
