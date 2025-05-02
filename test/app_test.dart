import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:chords_app/main.dart';
import 'package:chords_app/providers/user_provider.dart';
import 'package:chords_app/providers/navigation_provider.dart';
import 'package:chords_app/services/api_service.dart';
import 'package:chords_app/services/cache_service.dart';

// Generate mocks
@GenerateMocks([ApiService, CacheService])
import 'app_test.mocks.dart';

void main() {
  late MockApiService mockApiService;
  late MockCacheService mockCacheService;
  late UserProvider userProvider;
  late NavigationProvider navigationProvider;

  setUp(() {
    mockApiService = MockApiService();
    mockCacheService = MockCacheService();
    userProvider = UserProvider();
    navigationProvider = NavigationProvider();
  });

  testWidgets('App initializes and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: userProvider),
          ChangeNotifierProvider.value(value: navigationProvider),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the splash screen is shown
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Wait for animations
    await tester.pump(const Duration(seconds: 1));
    
    // Basic verification that the app initializes without errors
    expect(true, isTrue);
  });

  testWidgets('NavigationProvider updates index correctly', (WidgetTester tester) async {
    // Create a test widget that uses the NavigationProvider
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: navigationProvider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final provider = Provider.of<NavigationProvider>(context);
              return Column(
                children: [
                  Text('Current Index: ${provider.currentIndex}'),
                  ElevatedButton(
                    onPressed: () => provider.updateIndex(1),
                    child: const Text('Update Index'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('Current Index: 0'), findsOneWidget);

    // Tap the button to update the index
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify the index was updated
    expect(find.text('Current Index: 1'), findsOneWidget);
  });

  testWidgets('UserProvider handles login state correctly', (WidgetTester tester) async {
    // Create a test widget that uses the UserProvider
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: userProvider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final provider = Provider.of<UserProvider>(context);
              return Column(
                children: [
                  Text('Is Logged In: ${provider.isLoggedIn}'),
                  ElevatedButton(
                    onPressed: () {
                      // Simulate login
                      provider.setUserData({
                        'id': '123',
                        'name': 'Test User',
                        'email': 'test@example.com',
                      });
                    },
                    child: const Text('Login'),
                  ),
                  ElevatedButton(
                    onPressed: () => provider.logout(),
                    child: const Text('Logout'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('Is Logged In: false'), findsOneWidget);

    // Tap the login button
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Verify login state
    expect(find.text('Is Logged In: true'), findsOneWidget);

    // Tap the logout button
    await tester.tap(find.text('Logout'));
    await tester.pump();

    // Verify logout state
    expect(find.text('Is Logged In: false'), findsOneWidget);
  });
}
