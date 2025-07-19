# Flutter Testing Infrastructure

This directory contains the comprehensive testing infrastructure for the Chords App Flutter application.

## Directory Structure

```
test/
├── unit/                    # Unit tests for services, providers, models, and utilities
│   ├── services/           # Service layer unit tests
│   ├── providers/          # Provider/state management unit tests
│   ├── models/             # Model class unit tests
│   └── utils/              # Utility function unit tests
├── widget/                 # Widget tests for UI components
│   ├── screens/            # Screen widget tests
│   └── widgets/            # Individual widget tests
├── integration/            # Integration tests for complete user flows
├── helpers/                # Test helper classes and utilities
│   ├── test_helpers.dart   # General testing utilities
│   ├── mock_data.dart      # Mock data factories
│   ├── widget_test_helpers.dart # Widget testing utilities
│   └── mock_services.dart  # Mock service implementations
├── test_config.dart        # Test configuration constants
├── infrastructure_test.dart # Infrastructure verification tests
└── README.md              # This file
```

## Getting Started

### Prerequisites

1. Flutter SDK installed
2. All project dependencies installed (`flutter pub get`)
3. (Optional) lcov installed for HTML coverage reports:
   ```bash
   # macOS
   brew install lcov
   
   # Ubuntu/Debian
   sudo apt-get install lcov
   ```

### Running Tests

#### Run All Tests
```bash
flutter test
```

#### Run Specific Test File
```bash
flutter test test/infrastructure_test.dart
```

#### Run Tests with Coverage
```bash
flutter test --coverage
```

#### Run Tests with Coverage and Generate HTML Report
```bash
./test_coverage.sh
```

#### Run Tests by Tag
```bash
# Run only unit tests
flutter test --tags unit

# Run only widget tests  
flutter test --tags widget

# Run only fast tests
flutter test --tags fast
```

## Test Helpers

### TestHelpers Class

Provides general testing utilities:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'helpers/test_helpers.dart';

void main() {
  test('example test', () {
    // Setup mock SharedPreferences
    TestHelpers.setupMockSharedPreferences({'key': 'value'});
    
    // Create mock HTTP response
    final response = TestHelpers.createMockHttpResponse(
      data: {'result': 'success'},
      statusCode: 200,
    );
    
    // Use finder utilities
    final finder = TestHelpers.findByKey('my-widget-key');
    TestHelpers.expectWidgetExists(finder);
  });
}
```

### MockData Class

Provides factory methods for creating test data:

```dart
import 'helpers/mock_data.dart';

void main() {
  test('example with mock data', () {
    // Create mock objects
    final song = MockData.createSong(title: 'Test Song');
    final user = MockData.createUser(email: 'test@example.com');
    final artist = MockData.createArtist(name: 'Test Artist');
    final collection = MockData.createCollection(title: 'Test Collection');
    
    // Create lists of mock objects
    final songs = MockData.createSongList(count: 5);
    final users = MockData.createUserList(count: 3);
    
    // Create API responses
    final apiResponse = MockData.createApiResponse(data: songs);
    final errorResponse = MockData.createErrorResponse(message: 'Test error');
    final paginatedResponse = MockData.createPaginatedResponse(
      data: songs,
      page: 1,
      limit: 10,
    );
  });
}
```

### WidgetTestHelpers Class

Provides utilities for widget testing:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'helpers/widget_test_helpers.dart';

void main() {
  testWidgets('example widget test', (tester) async {
    // Create test app wrapper
    await WidgetTestHelpers.pumpWidgetMinimal(
      tester,
      MyWidget(),
    );
    
    // Use finder utilities
    final textFinder = WidgetTestHelpers.findByTestKey('my-text');
    final buttonFinder = WidgetTestHelpers.findButtonByText('Click Me');
    
    // Perform interactions
    await WidgetTestHelpers.tapAndSettle(tester, buttonFinder);
    await WidgetTestHelpers.enterTextAndSettle(tester, textFinder, 'Hello');
    
    // Verify expectations
    WidgetTestHelpers.expectLoadingIndicator();
    WidgetTestHelpers.expectSnackBar('Success message');
  });
}
```

### ServiceMockFactory Class

Provides configured mock services:

```dart
import 'helpers/mock_services.dart';

void main() {
  test('example with mock services', () {
    // Create individual mock services
    final mockApiService = ServiceMockFactory.createMockApiService();
    final mockAuthService = ServiceMockFactory.createMockAuthService();
    final mockAudioService = ServiceMockFactory.createMockAudioService();
    
    // Create all mock services at once
    final allMocks = ServiceMockFactory.createAllMockServices();
    
    // Configure specific scenarios
    MockServiceConfigurator.configureAuthenticatedUser(mockAuthService);
    MockServiceConfigurator.configureApiError(mockApiService);
    MockServiceConfigurator.configureOfflineMode(mockOfflineService);
  });
}
```

## Writing Tests

### Unit Tests

Create unit tests in the `test/unit/` directory:

```dart
// test/unit/services/song_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../../helpers/mock_data.dart';
import '../../helpers/mock_services.dart';
import '../../../lib/services/song_service.dart';

void main() {
  group('SongService', () {
    late SongService songService;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = ServiceMockFactory.createMockApiService();
      songService = SongService(apiService: mockApiService);
    });

    test('should fetch songs successfully', () async {
      // Arrange
      final mockSongs = MockData.createSongList(count: 3);
      when(mockApiService.get('/songs'))
          .thenAnswer((_) async => MockData.createApiResponse(data: mockSongs));

      // Act
      final result = await songService.fetchSongs();

      // Assert
      expect(result.length, equals(3));
      verify(mockApiService.get('/songs')).called(1);
    });

    test('should handle API errors gracefully', () async {
      // Arrange
      when(mockApiService.get('/songs'))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(() => songService.fetchSongs(), throwsException);
    });
  });
}
```

### Widget Tests

Create widget tests in the `test/widget/` directory:

```dart
// test/widget/widgets/song_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../helpers/mock_data.dart';
import '../../../lib/widgets/song_card.dart';

void main() {
  group('SongCard Widget', () {
    testWidgets('should display song information', (tester) async {
      // Arrange
      final song = MockData.createSong(
        title: 'Amazing Grace',
        artist: 'John Newton',
      );

      // Act
      await WidgetTestHelpers.pumpWidgetMinimal(
        tester,
        SongCard(song: song),
      );

      // Assert
      expect(find.text('Amazing Grace'), findsOneWidget);
      expect(find.text('John Newton'), findsOneWidget);
    });

    testWidgets('should handle tap events', (tester) async {
      // Arrange
      final song = MockData.createSong();
      bool tapped = false;

      await WidgetTestHelpers.pumpWidgetMinimal(
        tester,
        SongCard(
          song: song,
          onTap: () => tapped = true,
        ),
      );

      // Act
      await WidgetTestHelpers.tapAndSettle(tester, find.byType(SongCard));

      // Assert
      expect(tapped, isTrue);
    });
  });
}
```

### Integration Tests

Create integration tests in the `test/integration/` directory:

```dart
// test/integration/auth_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/widget_test_helpers.dart';
import '../helpers/mock_data.dart';
import '../../lib/main.dart' as app;

void main() {
  group('Authentication Flow Integration', () {
    testWidgets('complete login flow', (tester) async {
      // Arrange
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Act - Navigate to login
      await WidgetTestHelpers.tapAndSettle(
        tester,
        find.text('Login'),
      );

      // Enter credentials
      await WidgetTestHelpers.enterTextAndSettle(
        tester,
        find.byKey(Key('email-field')),
        'test@example.com',
      );
      
      await WidgetTestHelpers.enterTextAndSettle(
        tester,
        find.byKey(Key('password-field')),
        'password123',
      );

      // Submit login
      await WidgetTestHelpers.tapAndSettle(
        tester,
        find.text('Sign In'),
      );

      // Assert - Should navigate to home screen
      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
```

## Test Configuration

### Coverage Thresholds

The following coverage thresholds are configured:

- **Minimum Coverage**: 80% overall
- **Target Coverage**: 90% overall
- **Critical Paths**: 95% coverage required
- **Services/Business Logic**: 90% coverage required
- **UI Components**: 75% coverage required

### Test Tags

Use tags to organize and run specific test suites:

- `@Tags(['unit'])` - Unit tests
- `@Tags(['widget'])` - Widget tests  
- `@Tags(['integration'])` - Integration tests
- `@Tags(['slow'])` - Tests that take longer to run
- `@Tags(['fast'])` - Quick tests for rapid feedback

### Environment Variables

Test-specific environment variables are configured in `TestConfig`:

```dart
static const Map<String, String> testEnvironment = {
  'FLUTTER_TEST': 'true',
  'API_BASE_URL': 'https://test-api.example.com',
};
```

## Best Practices

### 1. Test Structure

Follow the **Arrange-Act-Assert** pattern:

```dart
test('should do something', () {
  // Arrange - Set up test data and mocks
  final input = 'test input';
  final expected = 'expected output';
  
  // Act - Execute the code under test
  final result = functionUnderTest(input);
  
  // Assert - Verify the results
  expect(result, equals(expected));
});
```

### 2. Mock Management

- Use `ServiceMockFactory` for consistent mock creation
- Configure mocks for specific test scenarios
- Reset mocks between tests using `setUp()` and `tearDown()`

### 3. Test Data

- Use `MockData` factory methods for consistent test data
- Create specific test data for edge cases
- Keep test data simple and focused

### 4. Widget Testing

- Use `WidgetTestHelpers` for consistent widget test setup
- Test user interactions, not implementation details
- Verify UI state changes and navigation

### 5. Coverage

- Aim for high coverage on critical business logic
- Don't chase 100% coverage at the expense of test quality
- Focus on testing behavior, not just code paths

## Troubleshooting

### Common Issues

1. **Tests failing due to async operations**
   ```dart
   // Use pumpAndSettle for animations
   await tester.pumpAndSettle();
   
   // Use waitForAsync for custom delays
   await TestHelpers.waitForAsync();
   ```

2. **Mock not being called**
   ```dart
   // Verify mock interactions
   verify(mockService.method()).called(1);
   verifyNever(mockService.otherMethod());
   ```

3. **Widget not found**
   ```dart
   // Use keys for reliable widget finding
   const Key('my-widget-key')
   
   // Wait for widgets to appear
   await WidgetTestHelpers.waitForWidget(tester, finder);
   ```

### Debugging Tests

1. Use `debugPrint()` to output test information
2. Use `tester.binding.debugPaintSizeEnabled = true` to visualize widget bounds
3. Use `await tester.pump(Duration.zero)` to advance animations frame by frame

## Contributing

When adding new tests:

1. Follow the existing directory structure
2. Use the provided test helpers and mock factories
3. Add appropriate test tags
4. Update this README if adding new testing utilities
5. Ensure tests are deterministic and don't depend on external services

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Flutter Test API Reference](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)