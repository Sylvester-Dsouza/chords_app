// import 'dart:async' - removed unused import
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'utils/page_transitions.dart';
import 'services/cache_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
// AdMob service removed to fix crashing issues
// import 'services/ad_service.dart';
import 'providers/navigation_provider.dart';
import 'screens/playlist_detail_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/artist_detail_screen.dart';
import 'screens/collection_detail_screen.dart';
import 'screens/song_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/song_request_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/comments_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/personal_details_screen.dart';
import 'screens/rate_app_screen.dart';
import 'screens/support_screen.dart';
import 'screens/remove_ads_screen.dart';
import 'screens/liked_collections_screen.dart';
// Premium content screen removed to fix crashing issues
// import 'screens/premium_content_screen.dart';
import 'services/notification_service.dart';
import 'config/firebase_config.dart';
import 'config/theme.dart';
import 'providers/user_provider.dart';
import 'models/song.dart';

// Removed flutter_local_notifications due to compatibility issues

void main() async {
  // This ensures the Flutter binding is initialized before anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize YouTube player iframe
  try {
    debugPrint('Initializing YouTube player iframe...');
    // No static initialization needed for the latest version
    debugPrint('YouTube player iframe will be initialized when used');
  } catch (e) {
    debugPrint('Error initializing YouTube player iframe: $e');
    // Continue anyway
  }

  // We'll initialize the Flutter Local Notifications plugin in the NotificationService

  // We'll create the notification channel in the NotificationService

  // Test API connection
  try {
    debugPrint('Testing API connection...');
    final isConnected = await ApiService.testApiConnection();
    debugPrint('API connection test result: ${isConnected ? 'Connected' : 'Failed to connect'}');
  } catch (e) {
    debugPrint('Error testing API connection: $e');
    // Continue anyway
  }

  // Initialize Firebase with the correct project
  try {
    final authService = AuthService();
    await authService.initializeFirebase();

    // Log Firebase initialization status
    debugPrint('Firebase initialized with project: ${FirebaseConfig.projectId}');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Continue anyway to allow the app to start
  }

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize cache service
  await CacheService().initialize();
  debugPrint('Cache service initialized');

  // AdMob initialization removed to fix crashing issues
  debugPrint('AdMob has been completely removed from the app');

  // Initialize UserProvider before running the app
  final userProvider = UserProvider();
  await userProvider.initialize();

  // Run the app with the splash screen as initial route
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// Create a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Helper method to get the page widget for a named route
  Widget? _getPageForRouteName(String? routeName, Object? arguments) {
    switch (routeName) {
      case '/home':
      case '/playlist':
      case '/search':
      case '/resources':
      case '/profile':
        // For main navigation tabs, use the MainNavigation widget
        final navigationProvider = Provider.of<NavigationProvider>(navigatorKey.currentContext!, listen: false);
        // Set the correct index based on the route
        navigationProvider.updateIndex(navigationProvider.getIndexForRoute(routeName!));
        return const MainNavigation();
      case '/onboarding':
        return const OnboardingScreen();
      case '/login':
        return const LoginScreen();
      case '/register':
        return const RegisterScreen();
      case '/forgot-password':
        return const ForgotPasswordScreen();
      case '/song_request':
        return const SongRequestScreen();
      case '/about_us':
        return const AboutUsScreen();
      case '/notifications':
        return const NotificationScreen();
      case '/comments':
        if (arguments is Song) {
          return CommentsScreen(song: arguments);
        }
        return null;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Christian Chords',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        home: const SplashScreen(),
        // Add a navigation observer to handle back button presses
        navigatorObservers: [NavigatorObserver()],
        routes: {
          '/home': (context) => const MainNavigation(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/playlist': (context) => const MainNavigation(),
          '/search': (context) => const MainNavigation(),
          '/resources': (context) => const MainNavigation(),
          '/profile': (context) => const MainNavigation(),
          '/song_request': (context) => const SongRequestScreen(),
          '/comments': (context) => CommentsScreen(song: ModalRoute.of(context)!.settings.arguments as Song),
          '/about_us': (context) => const AboutUsScreen(),
          '/notifications': (context) => const NotificationScreen(),
        },
        onGenerateRoute: (settings) {
          // Import our custom page transitions
          if (settings.name == '/playlist_detail') {
            final args = settings.arguments as Map<String, dynamic>;
            return FadeSlidePageRoute(
              page: PlaylistDetailScreen(
                playlistId: args['playlistId'] ?? '',
                playlistName: args['playlistName'],
              ),
            );
          } else if (settings.name == '/artist_detail') {
            final args = settings.arguments as Map<String, dynamic>;
            return FadeSlidePageRoute(
              page: ArtistDetailScreen(
                artistName: args['artistName'],
              ),
            );
          } else if (settings.name == '/collection_detail') {
            final args = settings.arguments as Map<String, dynamic>;
            return FadeSlidePageRoute(
              page: CollectionDetailScreen(
                collectionName: args['collectionName'],
                collectionId: args['collectionId'],
              ),
            );
          // Tools routes removed
          } else if (settings.name == '/help-support') {
            return FadeSlidePageRoute(
              page: const HelpSupportScreen(),
            );
          } else if (settings.name == '/privacy-policy') {
            return FadeSlidePageRoute(
              page: const PrivacyPolicyScreen(),
            );
          } else if (settings.name == '/personal-details') {
            return FadeSlidePageRoute(
              page: const PersonalDetailsScreen(),
            );
          } else if (settings.name == '/rate-app') {
            return FadeSlidePageRoute(
              page: const RateAppScreen(),
            );
          } else if (settings.name == '/support') {
            return FadeSlidePageRoute(
              page: const SupportScreen(),
            );
          } else if (settings.name == '/remove-ads') {
            return FadeSlidePageRoute(
              page: const RemoveAdsScreen(),
            );
          } else if (settings.name == '/liked-collections') {
            return FadeSlidePageRoute(
              page: const LikedCollectionsScreen(),
            );
          // Premium content screen removed to fix crashing issues
          // } else if (settings.name == '/premium-content') {
          //   return FadeSlidePageRoute(
          //     page: const PremiumContentScreen(),
          //   );
          } else if (settings.name == '/song_detail') {
            final args = settings.arguments;
            if (args is Song) {
              // If a Song object is passed directly
              return FadeSlidePageRoute(
                page: SongDetailScreen(song: args),
              );
            } else if (args is Map<String, dynamic>) {
              // If a map with songId is passed
              return FadeSlidePageRoute(
                page: SongDetailScreen(songId: args['songId']),
              );
            } else {
              // Fallback
              return FadeSlidePageRoute(
                page: const SongDetailScreen(),
              );
            }
          }

          // For standard named routes, also use the transition
          final Widget? page = _getPageForRouteName(settings.name, settings.arguments);
          if (page != null) {
            return FadeSlidePageRoute(page: page);
          }

          return null;
        },
        // Use our custom theme from AppTheme class
        theme: AppTheme.getTheme(),
    );
  }
}
