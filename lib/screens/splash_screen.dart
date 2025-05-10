import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/preferences_util.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/song_service.dart';
import '../services/artist_service.dart';
import '../services/collection_service.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _rotateAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  // Data loading progress
  double _loadingProgress = 0.0;
  String _loadingStatus = "Initializing...";

  // Services
  final SongService _songService = SongService();
  final ArtistService _artistService = ArtistService();
  final CollectionService _collectionService = CollectionService();

  @override
  void initState() {
    super.initState();

    // Set status bar to match splash screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Set up fade animation
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeAnimationController);

    // Set up pulse animation
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      reverseDuration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Set up rotation animation
    _rotateAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _rotateAnimationController,
        curve: Curves.linear,
      ),
    );

    // Start fade animation
    _fadeAnimationController.forward();

    // Initialize Firebase and preload data
    _initializeFirebaseAndPreloadData();
  }

  Future<void> _initializeFirebaseAndPreloadData() async {
    debugPrint('SplashScreen: Starting initialization and data preloading');
    try {
      // Update loading status
      _updateLoadingStatus('Initializing...', 0.05);

      // Test API connection
      try {
        debugPrint('SplashScreen: Testing API connection...');
        final isConnected = await ApiService.testApiConnection();
        debugPrint('SplashScreen: API connection test result: ${isConnected ? 'Connected' : 'Failed to connect'}');

        if (!isConnected) {
          _updateLoadingStatus('Network connection issues. Retrying...', 0.05);
          // Wait a moment and try again
          await Future.delayed(const Duration(seconds: 1));
          await ApiService.testApiConnection();
        }
      } catch (apiError) {
        debugPrint('SplashScreen: Error testing API connection: $apiError');
        _updateLoadingStatus('Network connection issues. Continuing...', 0.05);
        // Continue anyway
      }

      // Initialize Firebase
      _updateLoadingStatus('Initializing Firebase...', 0.1);
      debugPrint('SplashScreen: Starting Firebase initialization');
      final authService = AuthService();
      await authService.initializeFirebase();
      debugPrint('SplashScreen: Firebase initialization completed successfully');

      // Test Google Sign-In availability
      _updateLoadingStatus('Checking authentication services...', 0.15);
      try {
        debugPrint('SplashScreen: Testing Google Sign-In availability');
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: '481447097360-13s3qaeafrg1htmndilphq984komvbti.apps.googleusercontent.com',
        );

        // Just check if we can get the current user, don't actually sign in
        final isSignedIn = await googleSignIn.isSignedIn();
        debugPrint('SplashScreen: Google Sign-In is available, isSignedIn: $isSignedIn');
      } catch (googleError) {
        debugPrint('SplashScreen: Google Sign-In test failed: $googleError');
        // Continue anyway
      }

      // Initialize cache service
      _updateLoadingStatus('Initializing cache service...', 0.2);
      final cacheService = CacheService();
      await cacheService.initialize();

      // Preload data in parallel
      _updateLoadingStatus('Preloading app data...', 0.3);

      // Create a list of futures to execute in parallel
      List<Future> preloadTasks = [];

      // Preload songs
      preloadTasks.add(_preloadSongs());

      // Preload artists
      preloadTasks.add(_preloadArtists());

      // Preload collections
      preloadTasks.add(_preloadCollections());

      // Wait for all preload tasks to complete
      await Future.wait(preloadTasks);

      // Final loading status
      _updateLoadingStatus('Ready!', 1.0);

      // Navigate to next screen after a short delay
      debugPrint('SplashScreen: All data preloaded, navigating to next screen');
      Timer(const Duration(milliseconds: 500), () {
        debugPrint('SplashScreen: Timer completed, navigating to next screen');
        _navigateToNextScreen();
      });
    } catch (e) {
      debugPrint('SplashScreen: Error during initialization: $e');
      _updateLoadingStatus('Error occurred. Continuing...', 0.8);

      // Even if there's an error, try to navigate after a delay
      Timer(const Duration(seconds: 2), () {
        debugPrint('SplashScreen: Attempting to navigate despite error');
        _navigateToNextScreen();
      });
    }
  }

  // Helper method to update loading status with animation
  void _updateLoadingStatus(String status, double progress) {
    if (!mounted) return;

    setState(() {
      _loadingStatus = status;
      _loadingProgress = progress;
    });

    debugPrint('SplashScreen: Loading status: $status ($progress)');
  }

  // Preload songs data
  Future<void> _preloadSongs() async {
    try {
      _updateLoadingStatus('Loading songs...', 0.4);
      final songs = await _songService.getAllSongs(forceRefresh: true);
      debugPrint('SplashScreen: Preloaded ${songs.length} songs');

      // Also preload trending songs
      _updateLoadingStatus('Loading trending songs...', 0.5);
      final trendingSongs = songs.take(10).toList();
      debugPrint('SplashScreen: Preloaded ${trendingSongs.length} trending songs');

      return;
    } catch (e) {
      debugPrint('SplashScreen: Error preloading songs: $e');
      // Continue with other preloading tasks
    }
  }

  // Preload artists data
  Future<void> _preloadArtists() async {
    try {
      _updateLoadingStatus('Loading artists...', 0.6);
      final artists = await _artistService.getAllArtists(forceRefresh: true);
      debugPrint('SplashScreen: Preloaded ${artists.length} artists');

      // Also preload top artists
      _updateLoadingStatus('Loading top artists...', 0.7);
      final topArtists = artists.take(10).toList();
      debugPrint('SplashScreen: Preloaded ${topArtists.length} top artists');

      return;
    } catch (e) {
      debugPrint('SplashScreen: Error preloading artists: $e');
      // Continue with other preloading tasks
    }
  }

  // Preload collections data
  Future<void> _preloadCollections() async {
    try {
      _updateLoadingStatus('Loading collections...', 0.8);

      // Preload seasonal collections
      final seasonalCollections = await _collectionService.getSeasonalCollections(forceRefresh: true);
      debugPrint('SplashScreen: Preloaded ${seasonalCollections.length} seasonal collections');

      // Preload beginner friendly collections
      _updateLoadingStatus('Loading beginner collections...', 0.9);
      final beginnerCollections = await _collectionService.getBeginnerFriendlyCollections(forceRefresh: true);
      debugPrint('SplashScreen: Preloaded ${beginnerCollections.length} beginner collections');

      return;
    } catch (e) {
      debugPrint('SplashScreen: Error preloading collections: $e');
      // Continue with other preloading tasks
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    debugPrint('SplashScreen: Determining next screen...');

    try {
      // Check if onboarding has been completed (using persistent storage)
      final bool onboardingCompleted = await PreferencesUtil.isOnboardingCompleted();
      debugPrint('SplashScreen: Onboarding completed: $onboardingCompleted');

      // Get the UserProvider (safe to use context here as we've checked mounted)
      UserProvider? userProvider;
      if (mounted) {
        userProvider = Provider.of<UserProvider>(context, listen: false);
      } else {
        return; // Exit if widget is no longer mounted
      }

      // First check if we're already logged in (from memory)
      bool isLoggedIn = userProvider.isLoggedIn;

      // If not logged in from memory, check with the server
      if (!isLoggedIn) {
        debugPrint('SplashScreen: Not logged in from memory, checking with server...');
        try {
          // Add a timeout to prevent getting stuck
          isLoggedIn = await Future.any([
            userProvider.isAuthenticated(),
            Future.delayed(const Duration(seconds: 3), () {
              debugPrint('SplashScreen: Authentication check timed out');
              return false;
            }),
          ]);
          debugPrint('SplashScreen: Server authentication check result: $isLoggedIn');
        } catch (e) {
          debugPrint('SplashScreen: Error checking authentication: $e');
          isLoggedIn = false;
        }
      } else {
        debugPrint('SplashScreen: Already logged in from memory');
      }

      // Determine which screen to navigate to
      if (!onboardingCompleted) {
        debugPrint('SplashScreen: Navigating to onboarding screen');
        if (mounted) Navigator.of(context).pushReplacementNamed('/onboarding');
      } else if (isLoggedIn) {
        debugPrint('SplashScreen: Navigating to home screen (user is logged in)');
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else {
        debugPrint('SplashScreen: Navigating to auth screen (user is not logged in)');
        if (mounted) Navigator.of(context).pushReplacementNamed('/auth_test');
      }
    } catch (e) {
      debugPrint('SplashScreen: Error during navigation decision: $e');
      // Default to onboarding in case of error
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }



  @override
  void dispose() {
    // Dispose all animation controllers
    _fadeAnimationController.dispose();
    _pulseAnimationController.dispose();
    _rotateAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      body: Stack(
        children: [
          // Background pattern with subtle animation
          AnimatedBuilder(
            animation: _rotateAnimationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  image: DecorationImage(
                    image: const AssetImage('assets/images/pattern_bg.png'),
                    fit: BoxFit.cover,
                    opacity: 0.1,
                    // Apply subtle rotation to the background
                    alignment: Alignment.center,
                    scale: 1.0 + (_rotateAnimationController.value * 0.05),
                    onError: (exception, stackTrace) {}, // Ignore if pattern image doesn't exist
                  ),
                ),
              );
            },
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo image with pulse animation
                  AnimatedBuilder(
                    animation: _pulseAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Image.asset(
                      'assets/images/splash.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Loading status text
                  Text(
                    _loadingStatus,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Loading progress bar
                  Container(
                    width: 240,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      value: _loadingProgress, // Use actual progress value
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                    ),
                  ),

                  // Additional loading details
                  const SizedBox(height: 24),
                  AnimatedOpacity(
                    opacity: _loadingProgress > 0.3 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      'Preparing your music experience...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
