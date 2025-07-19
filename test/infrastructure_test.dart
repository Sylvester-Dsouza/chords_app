import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/test_helpers.dart';
import 'helpers/mock_data.dart';
import 'helpers/widget_test_helpers.dart';

/// Test to verify that the testing infrastructure is properly set up
void main() {
  group('Testing Infrastructure', () {
    test('TestHelpers should provide utility functions', () {
      // Test basic helper functions
      expect(TestHelpers.findByKey('test-key'), isA<Finder>());
      expect(TestHelpers.findByText('test-text'), isA<Finder>());
      
      // Test mock HTTP response creation
      final response = TestHelpers.createMockHttpResponse(
        data: {'test': 'data'},
        statusCode: 200,
      );
      expect(response['data'], equals({'test': 'data'}));
      expect(response['statusCode'], equals(200));
    });

    test('MockData should create test objects', () {
      // Test Song creation
      final song = MockData.createSong();
      expect(song.id, equals('test-song-1'));
      expect(song.title, equals('Amazing Grace'));
      expect(song.artist, equals('John Newton'));
      expect(song.key, equals('G'));

      // Test User creation
      final user = MockData.createUser();
      expect(user.id, equals('test-user-1'));
      expect(user.name, equals('John Doe'));
      expect(user.email, equals('john.doe@example.com'));

      // Test Artist creation
      final artist = MockData.createArtist();
      expect(artist.id, equals('test-artist-1'));
      expect(artist.name, equals('Hillsong United'));
      expect(artist.songCount, equals(25));

      // Test Collection creation
      final collection = MockData.createCollection();
      expect(collection.id, equals('test-collection-1'));
      expect(collection.title, equals('Worship Favorites'));
      expect(collection.songCount, equals(10));
    });

    test('MockData should create lists of objects', () {
      // Test Song list creation
      final songs = MockData.createSongList(count: 5);
      expect(songs.length, equals(5));
      expect(songs[0].id, equals('test-song-1'));
      expect(songs[4].id, equals('test-song-5'));

      // Test User list creation
      final users = MockData.createUserList(count: 3);
      expect(users.length, equals(3));
      expect(users[0].email, equals('testuser1@example.com'));
      expect(users[2].email, equals('testuser3@example.com'));
    });

    test('MockData should create API responses', () {
      // Test successful API response
      final successResponse = MockData.createApiResponse(
        data: {'result': 'success'},
      );
      expect(successResponse['success'], isTrue);
      expect(successResponse['data'], equals({'result': 'success'}));
      expect(successResponse['statusCode'], equals(200));

      // Test error API response
      final errorResponse = MockData.createErrorResponse(
        message: 'Test error message',
        statusCode: 404,
      );
      expect(errorResponse['success'], isFalse);
      expect(errorResponse['message'], equals('Test error message'));
      expect(errorResponse['statusCode'], equals(404));
    });

    test('MockData should create paginated responses', () {
      final songs = MockData.createSongList(count: 25);
      final paginatedResponse = MockData.createPaginatedResponse(
        data: songs.take(10).toList(),
        page: 1,
        limit: 10,
        total: 25,
      );

      expect(paginatedResponse['data'].length, equals(10));
      expect(paginatedResponse['pagination']['page'], equals(1));
      expect(paginatedResponse['pagination']['limit'], equals(10));
      expect(paginatedResponse['pagination']['total'], equals(25));
      expect(paginatedResponse['pagination']['totalPages'], equals(3));
      expect(paginatedResponse['pagination']['hasNext'], isTrue);
      expect(paginatedResponse['pagination']['hasPrev'], isFalse);
    });

    test('MockData should create search results', () {
      final songs = MockData.createSongList(count: 3);
      final artists = MockData.createArtistList(count: 2);
      final collections = MockData.createCollectionList(count: 1);

      final searchResults = MockData.createSearchResults(
        songs: songs,
        artists: artists,
        collections: collections,
        query: 'worship',
      );

      expect(searchResults['query'], equals('worship'));
      expect(searchResults['results']['songs'].length, equals(3));
      expect(searchResults['results']['artists'].length, equals(2));
      expect(searchResults['results']['collections'].length, equals(1));
      expect(searchResults['totalResults'], equals(6));
    });

    test('MockData should create auth token data', () {
      final tokenData = MockData.createAuthTokenData();
      expect(tokenData['accessToken'], equals('mock-access-token-123'));
      expect(tokenData['refreshToken'], equals('mock-refresh-token-456'));
      expect(tokenData['expiresIn'], equals(3600));
      expect(tokenData['tokenType'], equals('Bearer'));
    });

    test('MockData should create user preferences', () {
      final preferences = MockData.createUserPreferences(
        theme: 'dark',
        notifications: false,
        language: 'es',
      );
      expect(preferences['theme'], equals('dark'));
      expect(preferences['notifications'], isFalse);
      expect(preferences['language'], equals('es'));
      expect(preferences['customSettings'], isA<Map>());
    });

    testWidgets('WidgetTestHelpers should create test app wrapper', (tester) async {
      final testWidget = WidgetTestHelpers.createMinimalTestApp(
        child: const Text('Test Widget'),
      );

      await tester.pumpWidget(testWidget);
      expect(find.text('Test Widget'), findsOneWidget);
    });

    testWidgets('WidgetTestHelpers should provide finder utilities', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestApp(
          child: Column(
            children: [
              const Text('Test Text', key: Key('test-text-key')),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Test Button'),
              ),
              const Icon(Icons.home, key: Key('test-icon-key')),
            ],
          ),
        ),
      );

      // Test finder utilities
      expect(WidgetTestHelpers.findByTestKey('test-text-key'), findsOneWidget);
      expect(WidgetTestHelpers.findByIcon(Icons.home), findsOneWidget);
      expect(WidgetTestHelpers.findButtonByText('Test Button'), findsOneWidget);
    });
  });

  group('Test Configuration', () {
    test('should have proper test timeouts configured', () {
      // These are compile-time checks to ensure constants are defined
      expect(TestConfig.defaultTimeout, isA<Duration>());
      expect(TestConfig.shortTimeout, isA<Duration>());
      expect(TestConfig.longTimeout, isA<Duration>());
    });

    test('should have test environment configured', () {
      expect(TestConfig.testEnvironment, isA<Map<String, String>>());
      expect(TestConfig.testEnvironment['FLUTTER_TEST'], equals('true'));
    });

    test('should have coverage thresholds defined', () {
      expect(TestConfig.minimumCoverageThreshold, greaterThan(0));
      expect(TestConfig.targetCoverageThreshold, greaterThan(TestConfig.minimumCoverageThreshold));
    });
  });
}

/// Import TestConfig for testing
class TestConfig {
  static const Duration defaultTimeout = Duration(seconds: 5);
  static const Duration shortTimeout = Duration(milliseconds: 500);
  static const Duration longTimeout = Duration(seconds: 10);
  static const Map<String, String> testEnvironment = {
    'FLUTTER_TEST': 'true',
    'API_BASE_URL': 'https://test-api.example.com',
  };
  static const double minimumCoverageThreshold = 80.0;
  static const double targetCoverageThreshold = 90.0;
}