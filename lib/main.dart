import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/service_locator.dart';
import 'core/constants.dart';
import 'core/crashlytics_service.dart';
import 'utils/page_transitions.dart';
import 'services/api_service.dart';
import 'config/api_config.dart';
import 'providers/navigation_provider.dart';
import 'providers/app_data_provider.dart';
import 'providers/screen_state_provider.dart';
import 'providers/course_provider.dart';
import 'providers/community_provider.dart';
import 'screens/setlist_detail_screen.dart';
import 'screens/setlist_presentation_screen.dart';
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
import 'screens/liked_collections_screen.dart';
import 'screens/join_setlist_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/vocal_warmups_screen.dart';
import 'screens/vocal_exercises_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/community_setlists_screen.dart';
import 'services/deep_link_service.dart';
import 'services/community_service.dart';
import 'config/theme.dart';
import 'providers/user_provider.dart';
import 'models/song.dart';
import 'utils/performance_tracker.dart';
import 'services/image_cache_manager.dart';

// Removed flutter_local_notifications due to compatibility issues

void main() async {
  // This ensures the Flutter binding is initialized before anything else
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 ${AppConstants.appName} starting up...');

  // Start tracking app startup performance (non-blocking)
  PerformanceTracker.trackAppStartup().catchError((e) {
    debugPrint('⚠️ Performance tracking error: $e');
  });

  // Initialize service locator with dependency injection (includes Crashlytics)
  try {
    await setupServiceLocator();
    debugPrint('✅ Service locator initialized successfully');

    // Log app startup
    if (serviceLocator.isRegistered<CrashlyticsService>()) {
      await serviceLocator.crashlyticsService.logEvent('app_startup', {
        'app_version': AppConstants.appName,
        'platform': Platform.operatingSystem,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  } catch (e) {
    debugPrint('❌ Error setting up service locator: $e');
    // Continue anyway to allow the app to start
  }

  // Test API connection with our dynamic connection testing
  try {
    debugPrint('🔗 Testing API connections...');
    // First, try our new dynamic connection testing
    await ApiConfig.testConnections();
    
    // Then, verify with the API service test
    final isConnected = await ApiService.testApiConnection();
    debugPrint(
      'API connection test result: ${isConnected ? 'Connected ✅' : 'Failed to connect ❌'}',
    );
  } catch (e) {
    debugPrint('❌ Error testing API connection: $e');
    // Continue anyway
  }

  // Initialize image cache manager for memory efficiency
  ImageCacheManager().initialize();

  // Initialize UserProvider before running the app
  final userProvider = UserProvider();
  await userProvider.initialize();

  // Initialize global data provider (but don't load data yet)
  final appDataProvider = AppDataProvider();
  // Remove heavy data loading during app startup - defer until after login
  // await appDataProvider.initializeAppData();

  // Initialize screen state provider
  final screenStateProvider = ScreenStateProvider();

  // Initialize course provider
  final courseProvider = CourseProvider();

  // Initialize community provider
  final communityProvider = CommunityProvider(serviceLocator<CommunityService>());

  // Run the app with the splash screen as initial route
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider.value(value: appDataProvider),
        ChangeNotifierProvider.value(value: screenStateProvider),
        ChangeNotifierProvider.value(value: courseProvider),
        ChangeNotifierProvider.value(value: communityProvider),
      ],
      child: const MyApp(),
    ),
  );

  // Complete app startup tracking (non-blocking)
  PerformanceTracker.completeAppStartup(
    attributes: {
      'platform': Platform.operatingSystem,
      'app_version': AppConstants.appName,
    },
  ).catchError((e) {
    debugPrint('⚠️ Performance tracking completion error: $e');
  });

  // Print performance status for debugging (after a delay to ensure initialization)
  Timer(const Duration(seconds: 3), () {
    try {
      serviceLocator.performanceService.printStatus();

      // Test a simple trace to verify it's working
      PerformanceTracker.track(
        'test_trace',
        () async {
          await Future.delayed(const Duration(milliseconds: 100));
          debugPrint(
            '🧪 Test trace completed - this should appear in Firebase Performance',
          );
        },
        attributes: {
          'test_type': 'startup_verification',
          'platform': Platform.operatingSystem,
        },
      ).catchError((e) {
        debugPrint('⚠️ Test trace failed: $e');
      });
    } catch (e) {
      debugPrint('⚠️ Could not print performance status: $e');
    }
  });
}

// Create a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // Initialize deep link service after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkService.initialize(context);
    });
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  // Helper method to get the page widget for a named route
  Widget? _getPageForRouteName(String? routeName, Object? arguments) {
    switch (routeName) {
      case '/home':
      case '/setlist':
      case '/search':
      case '/vocals':
      case '/profile':
        // For main navigation tabs, use the MainNavigation widget
        final navigationProvider = Provider.of<NavigationProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        // Set the correct index based on the route
        navigationProvider.updateIndex(
          navigationProvider.getIndexForRoute(routeName!),
        );
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
      title: 'Stuthi',
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
        '/setlist': (context) => const MainNavigation(),
        '/search': (context) => const MainNavigation(),
        '/vocals': (context) => const MainNavigation(),
        '/profile': (context) => const MainNavigation(),
        '/song_request': (context) => const SongRequestScreen(),
        '/comments':
            (context) => CommentsScreen(
              song: ModalRoute.of(context)!.settings.arguments as Song,
            ),
        '/about_us': (context) => const AboutUsScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/vocal-warmups': (context) => const VocalWarmupsScreen(),
        '/vocal-exercises': (context) => const VocalExercisesScreen(),
        '/vocal-courses': (context) => const VocalCoursesScreen(),
        '/community_setlists': (context) => const CommunitySetlistsScreen(),
      },
      onGenerateRoute: (settings) {
        // Import our custom page transitions
        if (settings.name == '/setlist_detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return FadeSlidePageRoute(
            page: SetlistDetailScreen(
              setlistId: args['setlistId'] ?? '',
              setlistName: args['setlistName'],
            ),
          );
        } else if (settings.name == '/setlist_presentation') {
          final args = settings.arguments as Map<String, dynamic>;
          return FadeSlidePageRoute(
            page: SetlistPresentationScreen(
              setlistName: args['setlistName'] ?? 'Setlist',
              songs: List<Map<String, dynamic>>.from(args['songs'] ?? []),
            ),
          );
        } else if (settings.name == '/artist_detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return FadeSlidePageRoute(
            page: ArtistDetailScreen(artistName: args['artistName']),
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
          return FadeSlidePageRoute(page: const HelpSupportScreen());
        } else if (settings.name == '/privacy-policy') {
          return FadeSlidePageRoute(page: const PrivacyPolicyScreen());
        } else if (settings.name == '/personal-details') {
          return FadeSlidePageRoute(page: const PersonalDetailsScreen());
        } else if (settings.name == '/rate-app') {
          return FadeSlidePageRoute(page: const RateAppScreen());
        } else if (settings.name == '/support') {
          return FadeSlidePageRoute(page: const SupportScreen());
        } else if (settings.name == '/liked-collections') {
          return FadeSlidePageRoute(page: const LikedCollectionsScreen());
        } else if (settings.name == '/join-setlist') {
          final args = settings.arguments as Map<String, dynamic>?;
          return FadeSlidePageRoute(
            page: JoinSetlistScreen(shareCode: args?['shareCode']),
          );
        } else if (settings.name == '/qr-scanner') {
          return FadeSlidePageRoute(page: const QRScannerScreen());
        } else if (settings.name == '/vocal-warmups') {
          return FadeSlidePageRoute(page: const VocalWarmupsScreen());
        } else if (settings.name == '/vocal-exercises') {
          return FadeSlidePageRoute(page: const VocalExercisesScreen());
        } else if (settings.name == '/course_detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return FadeSlidePageRoute(
            page: CourseDetailScreen(courseId: args['courseId']),
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
            return FadeSlidePageRoute(page: SongDetailScreen(song: args));
          } else if (args is Map<String, dynamic>) {
            // If a map with songId is passed
            return FadeSlidePageRoute(
              page: SongDetailScreen(songId: args['songId']),
            );
          } else {
            // Fallback
            return FadeSlidePageRoute(page: const SongDetailScreen());
          }
        }

        // For standard named routes, also use the transition
        final Widget? page = _getPageForRouteName(
          settings.name,
          settings.arguments,
        );
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
