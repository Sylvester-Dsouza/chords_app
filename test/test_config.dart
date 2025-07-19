/// Test configuration and constants for the Flutter app tests
class TestConfig {
  /// Default timeout for async operations in tests
  static const Duration defaultTimeout = Duration(seconds: 5);
  
  /// Short timeout for quick operations
  static const Duration shortTimeout = Duration(milliseconds: 500);
  
  /// Long timeout for complex operations
  static const Duration longTimeout = Duration(seconds: 10);
  
  /// Test API base URL
  static const String testApiBaseUrl = 'https://test-api.example.com';
  
  /// Test user credentials
  static const String testUserEmail = 'test@example.com';
  static const String testUserPassword = 'testpassword123';
  
  /// Test Firebase project configuration
  static const String testFirebaseProjectId = 'test-project';
  
  /// Mock data configuration
  static const int defaultMockDataCount = 10;
  static const int smallMockDataCount = 3;
  static const int largeMockDataCount = 50;
  
  /// Test coverage thresholds
  static const double minimumCoverageThreshold = 80.0;
  static const double targetCoverageThreshold = 90.0;
  
  /// Test environment variables
  static const Map<String, String> testEnvironment = {
    'FLUTTER_TEST': 'true',
    'API_BASE_URL': testApiBaseUrl,
  };
  
  /// Common test tags for organizing tests
  static const String unitTestTag = 'unit';
  static const String widgetTestTag = 'widget';
  static const String integrationTestTag = 'integration';
  static const String slowTestTag = 'slow';
  static const String fastTestTag = 'fast';
  
  /// Test file patterns
  static const List<String> testFilePatterns = [
    'test/**/*_test.dart',
    'test/**/*_test_*.dart',
  ];
  
  /// Excluded files from coverage
  static const List<String> coverageExclusions = [
    'lib/main.dart',
    'lib/firebase_options.dart',
    'lib/**/*.g.dart',
    'lib/**/*.freezed.dart',
    'lib/**/*.mocks.dart',
  ];
}