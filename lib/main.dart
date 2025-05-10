import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/page_transitions.dart';
import 'services/cache_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/ad_service.dart';
import 'providers/navigation_provider.dart';
import 'screens/auth_test_screen.dart';
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
import 'screens/contribute_screen.dart';
import 'screens/personal_details_screen.dart';
import 'screens/rate_app_screen.dart';
import 'screens/support_screen.dart';
import 'screens/remove_ads_screen.dart';
import 'screens/premium_content_screen.dart';
import 'services/notification_service.dart';
import 'config/firebase_config.dart';
import 'providers/user_provider.dart';
import 'models/song.dart';

// Removed flutter_local_notifications due to compatibility issues

void main() async {
  // This ensures the Flutter binding is initialized before anything else
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize AdMob
  await AdService().initialize();
  debugPrint('AdMob service initialized');

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
      case '/auth_test':
        return const AuthTestScreen();
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
          '/auth_test': (context) => const AuthTestScreen(),
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
          } else if (settings.name == '/contribute') {
            return FadeSlidePageRoute(
              page: const ContributeScreen(),
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
          } else if (settings.name == '/premium-content') {
            return FadeSlidePageRoute(
              page: const PremiumContentScreen(),
            );
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
        theme: ThemeData(
          // Custom page transitions for the entire app
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          // Dark background color
          scaffoldBackgroundColor: const Color(0xFF121212),
          primaryColor: const Color(0xFFB388FF), // Main accent - Light Lavender
          colorScheme: ColorScheme.dark(
            // Using surface instead of deprecated background
            surface: const Color(0xFF121212),      // Dark background color
            primary: const Color(0xFFB388FF),      // Main accent - Light Lavender
            secondary: const Color(0xFF9575CD),    // Secondary accent - Deeper Lavender
            surfaceContainer: const Color(0xFF1E1E1E), // Slightly lighter than background for cards
            // Using onSurface instead of deprecated onBackground
            onSurface: Colors.white,              // Text color on surface/background
            onPrimary: Colors.black,              // Text color on primary color
            onSecondary: Colors.white,            // Text color on secondary color
          ),
          // AppBar theme
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF121212),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          // Text theme with white text
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
            displayMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.white),
            displaySmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
            headlineMedium: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600, color: Colors.white),
            titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500, color: Colors.white),
            bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white),
            bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white),
          ),
          // Button theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB388FF), // Light Lavender
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          // Input decoration theme
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            hintStyle: const TextStyle(color: Colors.grey),
            errorStyle: const TextStyle(color: Colors.redAccent),
          ),
        ),
    );
  }
}
