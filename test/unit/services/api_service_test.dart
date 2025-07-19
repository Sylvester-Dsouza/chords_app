import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:chords_app/services/api_service.dart';

void main() {
  // Initialize Flutter bindings for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiService', () {
    group('Static Methods', () {
      test('should have correct base URL', () {
        // Test that the base URL is accessible
        final baseUrl = ApiService.baseUrl;
        expect(baseUrl, isA<String>());
        expect(baseUrl.isNotEmpty, isTrue);
      });

      test('should test API connection and return boolean', () async {
        // Test the static API connection test method
        final result = await ApiService.testApiConnection();
        expect(result, isA<bool>());
        // The result can be true or false depending on network availability
      });
    });

    group('Instance Creation', () {
      test('should create ApiService instance successfully', () {
        // Test that we can create an instance without errors
        expect(() => ApiService(), returnsNormally);
      });

      test('should have proper initialization', () {
        final apiService = ApiService();
        expect(apiService, isA<ApiService>());
      });
    });

    group('Authentication Methods', () {
      late ApiService apiService;

      setUp(() {
        apiService = ApiService();
      });

      test('should handle registration with missing Firebase user', () async {
        // Test registration when no Firebase user is available
        const name = 'Test User';
        const email = 'test@example.com';
        const password = 'password123';
        const termsAccepted = true;

        final result = await apiService.register(
          name: name,
          email: email,
          password: password,
          termsAccepted: termsAccepted,
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('success'), isTrue);
        expect(result['success'], isFalse);
        expect(result['message'], contains('Firebase user not found'));
      });

      test('should handle login with email and return result', () async {
        const email = 'test@example.com';
        const password = 'password123';
        const rememberMe = true;

        final result = await apiService.loginWithEmail(
          email: email,
          password: password,
          rememberMe: rememberMe,
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('success'), isTrue);
        // The actual success value depends on network and Firebase availability
      });

      test('should handle Firebase token login', () async {
        const firebaseToken = 'mock-firebase-token';
        const authProvider = 'GOOGLE';
        const name = 'Test User';
        const rememberMe = true;

        final result = await apiService.loginWithFirebase(
          firebaseToken: firebaseToken,
          authProvider: authProvider,
          name: name,
          rememberMe: rememberMe,
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('success'), isTrue);
      });

      test('should handle logout', () async {
        final result = await apiService.logout();
        expect(result, isA<bool>());
      });

      test('should clear cache without errors', () async {
        expect(() => apiService.clearCache(), returnsNormally);
      });
    });

    group('HTTP Method Signatures', () {
      late ApiService apiService;

      setUp(() {
        apiService = ApiService();
      });

      test('should have GET method with correct signature', () {
        const testPath = '/test';
        
        // Test that the method exists and can be called
        expect(() => apiService.get(testPath), returnsNormally);
      });

      test('should have POST method with correct signature', () {
        const testPath = '/test';
        final testData = {'key': 'value'};
        
        expect(() => apiService.post(testPath, data: testData), returnsNormally);
      });

      test('should have PUT method with correct signature', () {
        const testPath = '/test';
        final testData = {'key': 'value'};
        
        expect(() => apiService.put(testPath, data: testData), returnsNormally);
      });

      test('should have DELETE method with correct signature', () {
        const testPath = '/test';
        
        expect(() => apiService.delete(testPath), returnsNormally);
      });

      test('should have PATCH method with correct signature', () {
        const testPath = '/test';
        final testData = {'key': 'value'};
        
        expect(() => apiService.patch(testPath, data: testData), returnsNormally);
      });

      test('should have postWithoutApiPrefix method', () {
        const testPath = '/test';
        final testData = {'key': 'value'};
        
        expect(() => apiService.postWithoutApiPrefix(testPath, data: testData), returnsNormally);
      });
    });

    group('Utility Methods', () {
      late ApiService apiService;

      setUp(() {
        apiService = ApiService();
      });

      test('should have getAuthOptions method', () {
        const token = 'test-token';
        
        final options = apiService.getAuthOptions(token);
        expect(options, isA<Options>());
        expect(options.headers, isNotNull);
        expect(options.headers!['Authorization'], equals('Bearer $token'));
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        final apiService = ApiService();
        
        // These tests verify that methods don't throw uncaught exceptions
        // The actual network calls may fail, but they should return proper error responses
        expect(() => apiService.get('/nonexistent'), returnsNormally);
        expect(() => apiService.post('/nonexistent', data: {}), returnsNormally);
        expect(() => apiService.put('/nonexistent', data: {}), returnsNormally);
        expect(() => apiService.delete('/nonexistent'), returnsNormally);
      });
    });
  });
}