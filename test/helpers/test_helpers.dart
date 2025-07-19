import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Base test helper class providing common testing utilities
class TestHelpers {
  /// Sets up mock SharedPreferences for testing
  static void setupMockSharedPreferences([Map<String, Object>? values]) {
    SharedPreferences.setMockInitialValues(values ?? {});
  }

  /// Creates a mock FlutterSecureStorage
  static MockFlutterSecureStorage createMockSecureStorage() {
    return MockFlutterSecureStorage();
  }

  /// Waits for async operations to complete in tests
  static Future<void> waitForAsync([int milliseconds = 100]) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// Pumps and settles widget tests with a reasonable timeout
  static Future<void> pumpAndSettle(WidgetTester tester, [Duration? timeout]) async {
    await tester.pumpAndSettle(timeout ?? const Duration(seconds: 5));
  }

  /// Finds a widget by its key in tests
  static Finder findByKey(String key) {
    return find.byKey(Key(key));
  }

  /// Finds a widget by its text content
  static Finder findByText(String text) {
    return find.text(text);
  }

  /// Finds a widget by its type
  static Finder findByType<T extends Widget>() {
    return find.byType(T);
  }

  /// Verifies that a widget exists in the widget tree
  static void expectWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verifies that a widget does not exist in the widget tree
  static void expectWidgetNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verifies that multiple widgets exist in the widget tree
  static void expectWidgetsExist(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// Taps on a widget and waits for the action to complete
  static Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enters text into a text field and waits for the action to complete
  static Future<void> enterTextAndWait(WidgetTester tester, Finder finder, String text) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Scrolls a widget and waits for the action to complete
  static Future<void> scrollAndWait(WidgetTester tester, Finder finder, Offset offset) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle();
  }

  /// Creates a test-specific BuildContext (simplified for testing)
  static BuildContext? createTestContext() {
    // Return null for now - tests should use actual widget contexts
    return null;
  }

  /// Verifies that an exception is thrown during test execution
  static void expectException<T extends Exception>(Function() testFunction) {
    expect(() => testFunction(), throwsA(isA<T>()));
  }

  /// Creates a mock HTTP response for testing
  static Map<String, dynamic> createMockHttpResponse({
    required dynamic data,
    int statusCode = 200,
    String statusMessage = 'OK',
  }) {
    return {
      'data': data,
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'headers': <String, String>{},
    };
  }

  /// Creates a mock error response for testing
  static Map<String, dynamic> createMockErrorResponse({
    String message = 'Test error',
    int statusCode = 500,
  }) {
    return {
      'error': message,
      'statusCode': statusCode,
      'statusMessage': 'Internal Server Error',
    };
  }
}

/// Mock class for FlutterSecureStorage
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }
}

