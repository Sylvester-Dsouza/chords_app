import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:chords_app/providers/navigation_provider.dart';

void main() {
  // Initialize Flutter bindings for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavigationProvider', () {
    late NavigationProvider navigationProvider;

    setUp(() {
      navigationProvider = NavigationProvider();
    });

    group('Initialization', () {
      test('should create NavigationProvider instance successfully', () {
        expect(navigationProvider, isA<NavigationProvider>());
      });

      test('should have correct initial state', () {
        expect(navigationProvider.currentIndex, equals(0));
      });

      test('should be a ChangeNotifier', () {
        expect(navigationProvider, isA<ChangeNotifier>());
      });
    });

    group('Index Management', () {
      test('should update current index correctly', () {
        navigationProvider.updateIndex(2);
        
        expect(navigationProvider.currentIndex, equals(2));
      });

      test('should notify listeners when index changes', () {
        bool notified = false;
        
        navigationProvider.addListener(() {
          notified = true;
        });

        navigationProvider.updateIndex(1);

        expect(notified, isTrue);
        expect(navigationProvider.currentIndex, equals(1));
      });

      test('should not notify listeners when index remains the same', () {
        int notificationCount = 0;
        
        navigationProvider.addListener(() {
          notificationCount++;
        });

        // Set to same index multiple times
        navigationProvider.updateIndex(0);
        navigationProvider.updateIndex(0);
        navigationProvider.updateIndex(0);

        expect(notificationCount, equals(0));
        expect(navigationProvider.currentIndex, equals(0));
      });

      test('should handle multiple index changes', () {
        List<int> indexChanges = [];
        
        navigationProvider.addListener(() {
          indexChanges.add(navigationProvider.currentIndex);
        });

        navigationProvider.updateIndex(1);
        navigationProvider.updateIndex(3);
        navigationProvider.updateIndex(4);
        navigationProvider.updateIndex(2);

        expect(indexChanges, equals([1, 3, 4, 2]));
        expect(navigationProvider.currentIndex, equals(2));
      });

      test('should handle edge case indices', () {
        // Test negative index
        navigationProvider.updateIndex(-1);
        expect(navigationProvider.currentIndex, equals(-1));

        // Test large index
        navigationProvider.updateIndex(999);
        expect(navigationProvider.currentIndex, equals(999));
      });
    });

    group('Route to Index Mapping', () {
      test('should return correct index for home route', () {
        expect(navigationProvider.getIndexForRoute('/home'), equals(0));
      });

      test('should return correct index for setlist route', () {
        expect(navigationProvider.getIndexForRoute('/setlist'), equals(1));
      });

      test('should return correct index for search route', () {
        expect(navigationProvider.getIndexForRoute('/search'), equals(2));
      });

      test('should return correct index for vocals route', () {
        expect(navigationProvider.getIndexForRoute('/vocals'), equals(3));
      });

      test('should return correct index for profile route', () {
        expect(navigationProvider.getIndexForRoute('/profile'), equals(4));
      });

      test('should return default index for unknown route', () {
        expect(navigationProvider.getIndexForRoute('/unknown'), equals(0));
        expect(navigationProvider.getIndexForRoute('/invalid'), equals(0));
        expect(navigationProvider.getIndexForRoute(''), equals(0));
        expect(navigationProvider.getIndexForRoute('/'), equals(0));
      });

      test('should handle null route gracefully', () {
        // This would be handled by Dart's type system, but testing edge cases
        expect(navigationProvider.getIndexForRoute('/nonexistent'), equals(0));
      });

      test('should be case sensitive for routes', () {
        expect(navigationProvider.getIndexForRoute('/HOME'), equals(0)); // Should default to 0
        expect(navigationProvider.getIndexForRoute('/Home'), equals(0)); // Should default to 0
        expect(navigationProvider.getIndexForRoute('/SEARCH'), equals(0)); // Should default to 0
      });
    });

    group('Index to Route Mapping', () {
      test('should return correct route for index 0', () {
        expect(navigationProvider.getRouteForIndex(0), equals('/home'));
      });

      test('should return correct route for index 1', () {
        expect(navigationProvider.getRouteForIndex(1), equals('/setlist'));
      });

      test('should return correct route for index 2', () {
        expect(navigationProvider.getRouteForIndex(2), equals('/search'));
      });

      test('should return correct route for index 3', () {
        expect(navigationProvider.getRouteForIndex(3), equals('/vocals'));
      });

      test('should return correct route for index 4', () {
        expect(navigationProvider.getRouteForIndex(4), equals('/profile'));
      });

      test('should return default route for unknown index', () {
        expect(navigationProvider.getRouteForIndex(5), equals('/home'));
        expect(navigationProvider.getRouteForIndex(10), equals('/home'));
        expect(navigationProvider.getRouteForIndex(999), equals('/home'));
      });

      test('should return default route for negative index', () {
        expect(navigationProvider.getRouteForIndex(-1), equals('/home'));
        expect(navigationProvider.getRouteForIndex(-10), equals('/home'));
      });
    });

    group('Bidirectional Route-Index Mapping', () {
      test('should maintain consistency between route-to-index and index-to-route mapping', () {
        final routes = ['/home', '/setlist', '/search', '/vocals', '/profile'];
        
        for (int i = 0; i < routes.length; i++) {
          final route = routes[i];
          final indexFromRoute = navigationProvider.getIndexForRoute(route);
          final routeFromIndex = navigationProvider.getRouteForIndex(i);
          
          expect(indexFromRoute, equals(i));
          expect(routeFromIndex, equals(route));
        }
      });

      test('should handle round-trip conversions correctly', () {
        // Test route -> index -> route
        const testRoute = '/search';
        final index = navigationProvider.getIndexForRoute(testRoute);
        final backToRoute = navigationProvider.getRouteForIndex(index);
        
        expect(backToRoute, equals(testRoute));
        
        // Test index -> route -> index
        const testIndex = 3;
        final route = navigationProvider.getRouteForIndex(testIndex);
        final backToIndex = navigationProvider.getIndexForRoute(route);
        
        expect(backToIndex, equals(testIndex));
      });
    });

    group('Navigation State Management', () {
      test('should handle navigation flow simulation', () {
        List<int> navigationHistory = [];
        
        navigationProvider.addListener(() {
          navigationHistory.add(navigationProvider.currentIndex);
        });

        // Simulate user navigation flow
        navigationProvider.updateIndex(navigationProvider.getIndexForRoute('/search')); // Go to search
        navigationProvider.updateIndex(navigationProvider.getIndexForRoute('/vocals')); // Go to vocals
        navigationProvider.updateIndex(navigationProvider.getIndexForRoute('/profile')); // Go to profile
        navigationProvider.updateIndex(navigationProvider.getIndexForRoute('/home')); // Go back to home

        expect(navigationHistory, equals([2, 3, 4, 0]));
        expect(navigationProvider.currentIndex, equals(0));
      });

      test('should handle deep linking simulation', () {
        // Simulate deep link to vocals page
        const deepLinkRoute = '/vocals';
        final targetIndex = navigationProvider.getIndexForRoute(deepLinkRoute);
        
        navigationProvider.updateIndex(targetIndex);
        
        expect(navigationProvider.currentIndex, equals(3));
        expect(navigationProvider.getRouteForIndex(navigationProvider.currentIndex), equals(deepLinkRoute));
      });

      test('should handle navigation guards simulation', () {
        bool canNavigate = true;
        int blockedNavigationAttempts = 0;
        
        navigationProvider.addListener(() {
          if (!canNavigate) {
            blockedNavigationAttempts++;
          }
        });

        // Allow navigation
        navigationProvider.updateIndex(1);
        expect(navigationProvider.currentIndex, equals(1));

        // Block navigation (simulate guard)
        canNavigate = false;
        final currentIndex = navigationProvider.currentIndex;
        
        // This would normally be handled by navigation guards, but we can test the state
        if (canNavigate) {
          navigationProvider.updateIndex(2);
        }
        
        expect(navigationProvider.currentIndex, equals(currentIndex)); // Should remain unchanged
      });
    });

    group('Multiple Listeners', () {
      test('should notify all listeners when index changes', () {
        int listener1Count = 0;
        int listener2Count = 0;
        bool listener3Called = false;

        navigationProvider.addListener(() => listener1Count++);
        navigationProvider.addListener(() => listener2Count++);
        navigationProvider.addListener(() => listener3Called = true);

        navigationProvider.updateIndex(2);

        expect(listener1Count, equals(1));
        expect(listener2Count, equals(1));
        expect(listener3Called, isTrue);
      });

      test('should handle listener exceptions gracefully', () {
        // Add a listener that throws an exception
        navigationProvider.addListener(() {
          throw Exception('Listener error');
        });

        // Add a normal listener
        bool normalListenerCalled = false;
        navigationProvider.addListener(() {
          normalListenerCalled = true;
        });

        // Should not throw and should still call other listeners
        navigationProvider.updateIndex(1);

        expect(normalListenerCalled, isTrue);
        expect(navigationProvider.currentIndex, equals(1));
      });
    });

    group('Navigation History Management', () {
      test('should track navigation history through state changes', () {
        List<Map<String, dynamic>> navigationHistory = [];
        
        navigationProvider.addListener(() {
          navigationHistory.add({
            'index': navigationProvider.currentIndex,
            'route': navigationProvider.getRouteForIndex(navigationProvider.currentIndex),
            'timestamp': DateTime.now(),
          });
        });

        // Simulate navigation sequence
        navigationProvider.updateIndex(1); // Setlist
        navigationProvider.updateIndex(2); // Search
        navigationProvider.updateIndex(4); // Profile
        navigationProvider.updateIndex(0); // Home

        expect(navigationHistory.length, equals(4));
        expect(navigationHistory[0]['index'], equals(1));
        expect(navigationHistory[0]['route'], equals('/setlist'));
        expect(navigationHistory[1]['index'], equals(2));
        expect(navigationHistory[1]['route'], equals('/search'));
        expect(navigationHistory[2]['index'], equals(4));
        expect(navigationHistory[2]['route'], equals('/profile'));
        expect(navigationHistory[3]['index'], equals(0));
        expect(navigationHistory[3]['route'], equals('/home'));
      });
    });

    group('Authentication-based Routing Simulation', () {
      test('should handle authenticated vs unauthenticated navigation', () {
        bool isAuthenticated = false;
        List<String> allowedUnauthenticatedRoutes = ['/home', '/search'];
        
        // Simulate navigation with authentication check
        void navigateWithAuth(String route) {
          final index = navigationProvider.getIndexForRoute(route);
          
          if (isAuthenticated || allowedUnauthenticatedRoutes.contains(route)) {
            navigationProvider.updateIndex(index);
          }
          // If not authenticated and route not allowed, don't navigate
        }

        // Test unauthenticated navigation
        navigateWithAuth('/home'); // Should work
        expect(navigationProvider.currentIndex, equals(0));

        navigateWithAuth('/search'); // Should work
        expect(navigationProvider.currentIndex, equals(2));

        navigateWithAuth('/profile'); // Should not work (not authenticated)
        expect(navigationProvider.currentIndex, equals(2)); // Should remain on search

        // Test authenticated navigation
        isAuthenticated = true;
        navigateWithAuth('/profile'); // Should work now
        expect(navigationProvider.currentIndex, equals(4));

        navigateWithAuth('/vocals'); // Should work
        expect(navigationProvider.currentIndex, equals(3));
      });
    });

    group('Performance and Edge Cases', () {
      test('should handle rapid navigation changes', () {
        int finalIndex = 0;
        
        // Simulate rapid navigation changes
        for (int i = 0; i < 100; i++) {
          final targetIndex = i % 5; // Cycle through 0-4
          navigationProvider.updateIndex(targetIndex);
          finalIndex = targetIndex;
        }

        expect(navigationProvider.currentIndex, equals(finalIndex));
      });

      test('should maintain state consistency under stress', () {
        List<int> allChanges = [];
        
        navigationProvider.addListener(() {
          allChanges.add(navigationProvider.currentIndex);
        });

        // Perform many navigation operations (only unique changes will trigger notifications)
        final operations = [0, 1, 2, 3, 4, 2, 1, 0, 4, 3, 1, 2];
        for (final index in operations) {
          navigationProvider.updateIndex(index);
        }

        // Count only the actual changes (excluding duplicates)
        final expectedChanges = <int>[];
        int currentIndex = 0; // Starting index
        for (final index in operations) {
          if (index != currentIndex) {
            expectedChanges.add(index);
            currentIndex = index;
          }
        }

        expect(allChanges.length, equals(expectedChanges.length));
        expect(allChanges, equals(expectedChanges));
        expect(navigationProvider.currentIndex, equals(operations.last));
      });
    });

    group('Dispose and Cleanup', () {
      test('should dispose properly', () {
        // Add some listeners
        navigationProvider.addListener(() {});
        navigationProvider.addListener(() {});

        // Change state
        navigationProvider.updateIndex(2);
        expect(navigationProvider.currentIndex, equals(2));

        // Dispose should not throw
        navigationProvider.dispose();

        // After dispose, the provider should still maintain its last state
        expect(navigationProvider.currentIndex, equals(2));
      });
    });
  });
}