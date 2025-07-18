import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/preferences_util.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;
  late AnimationController _progressAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  // Data loading progress
  double _loadingProgress = 0.0;
  String _loadingStatus = "Initializing...";

  @override
  void initState() {
    super.initState();

    // Set status bar to match splash screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _setupAnimations();
    _startAnimations();

    // Initialize Firebase and preload data
    _initializeFirebaseAndPreloadData();
  }

  void _setupAnimations() {
    // Fade animation for overall content - optimized duration
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOut,
    ));

    // Scale animation for logo with optimized bounce effect
    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.elasticOut,
    ));

    // Progress animation for smooth loading bar
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    // Start fade animation immediately
    _fadeAnimationController.forward();
    
    // Start scale animation with slight delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _scaleAnimationController.forward();
      }
    });

    // Start progress animation after logo appears
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _progressAnimationController.forward();
      }
    });
  }

  Future<void> _initializeFirebaseAndPreloadData() async {
    debugPrint('SplashScreen: Starting initialization');
    try {
      // Optimized loading simulation with fewer setState calls
      final loadingSteps = [
        ('Initializing...', 0.2),
        ('Loading app...', 0.4),
        ('Preparing resources...', 0.6),
        ('Almost ready...', 0.8),
        ('Ready!', 1.0),
      ];

      for (final (status, progress) in loadingSteps) {
        if (!mounted) return;
        _updateLoadingStatus(status, progress);
        await Future.delayed(const Duration(milliseconds: 200));
      }

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
      final bool onboardingCompleted =
          await PreferencesUtil.isOnboardingCompleted();
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
        debugPrint(
          'SplashScreen: Not logged in from memory, checking with server...',
        );
        try {
          // Add a shorter timeout to prevent getting stuck
          isLoggedIn = await Future.any([
            userProvider.isAuthenticated(),
            Future.delayed(const Duration(seconds: 2), () {
              debugPrint('SplashScreen: Authentication check timed out');
              return false;
            }),
          ]);
          debugPrint(
            'SplashScreen: Server authentication check result: $isLoggedIn',
          );
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
        debugPrint(
          'SplashScreen: Navigating to home screen (user is logged in)',
        );
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else {
        debugPrint(
          'SplashScreen: Navigating to login screen (user is not logged in)',
        );
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
    _scaleAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010), // Use #101010 background color
      body: Stack(
        children: [
          // Solid background
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF101010),
            ),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo image with scale animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      AppLogos.getSplashLogo(),
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Loading status text
                  Text(
                    _loadingStatus,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Loading progress bar with animation
                  Container(
                    width: 240,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF202020),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          value: _loadingProgress * _progressAnimation.value,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
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
