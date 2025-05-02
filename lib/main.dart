import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/page_transitions.dart';
import 'services/cache_service.dart';
import 'providers/navigation_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_test_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/playlist_detail_screen.dart';
import 'screens/search_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tools_screen.dart';
import 'screens/tools/tuner_screen.dart';
import 'screens/tools/metronome_screen.dart';
import 'screens/tools/chord_library_screen.dart';
import 'screens/tools/scale_explorer_screen.dart';
import 'screens/tools/capo_calculator_screen.dart';
import 'screens/tools/circle_of_fifths_screen.dart';
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
import 'services/firebase_service.dart';
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

  // Initialize Firebase with the correct project
  await FirebaseService.initializeFirebase();

  // Log Firebase initialization status
  debugPrint('Firebase initialized with project: ${FirebaseConfig.projectId}');

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize cache service
  await CacheService().initialize();
  debugPrint('Cache service initialized');

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
      case '/tools':
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
          '/tools': (context) => const MainNavigation(),
          '/resources': (context) => const ResourcesScreen(),
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
          } else if (settings.name == '/tools/tuner') {
            return FadeSlidePageRoute(
              page: const TunerScreen(),
            );
          } else if (settings.name == '/tools/metronome') {
            return FadeSlidePageRoute(
              page: const MetronomeScreen(),
            );
          } else if (settings.name == '/tools/chords') {
            return FadeSlidePageRoute(
              page: const ChordLibraryScreen(),
            );
          } else if (settings.name == '/tools/scales') {
            return FadeSlidePageRoute(
              page: const ScaleExplorerScreen(),
            );
          } else if (settings.name == '/tools/capo') {
            return FadeSlidePageRoute(
              page: const CapoCalculatorScreen(),
            );
          } else if (settings.name == '/tools/circle-of-fifths') {
            return FadeSlidePageRoute(
              page: const CircleOfFifthsScreen(),
            );
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
          primaryColor: const Color(0xFFFFC701), // Main accent - Yellow
          colorScheme: ColorScheme.dark(
            // Using surface instead of deprecated background
            surface: const Color(0xFF121212),      // Dark background color
            primary: const Color(0xFFFFC701),      // Main accent - Yellow
            secondary: const Color(0xFFFF8C00),    // Secondary accent - Orange
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
              backgroundColor: const Color(0xFFFFC701),
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
