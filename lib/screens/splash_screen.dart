import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/preferences_util.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

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

  // Data loading progress
  double _loadingProgress = 0.0;
  String _loadingStatus = "Initializing...";

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

    // Start fade animation
    _fadeAnimationController.forward();

    // Initialize Firebase and preload data
    _initializeFirebaseAndPreloadData();
  }

  Future<void> _initializeFirebaseAndPreloadData() async {
    debugPrint('SplashScreen: Starting initialization');
    try {
      // Update loading status
      _updateLoadingStatus('Initializing...', 0.2);

      // Simulate loading with a simple timer
      // This gives a smooth loading experience without actually preloading data
      for (int i = 2; i <= 10; i++) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 150));
        _updateLoadingStatus('Loading...', i * 0.1);
      }

      // Final loading status
      _updateLoadingStatus('Ready!', 1.0);

      // Navigate to next screen after a short delay
      debugPrint('SplashScreen: Loading complete, navigating to next screen');
      Timer(const Duration(milliseconds: 300), () {
        debugPrint('SplashScreen: Timer completed, navigating to next screen');
        _navigateToNextScreen();
      });
    } catch (e) {
      debugPrint('SplashScreen: Error during initialization: $e');
      _updateLoadingStatus('Error occurred. Continuing...', 0.8);

      // Even if there's an error, try to navigate after a delay
      Timer(const Duration(seconds: 1), () {
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
        debugPrint('SplashScreen: Navigating to login screen (user is not logged in)');
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
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

                  // Additional spacing at the bottom
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
