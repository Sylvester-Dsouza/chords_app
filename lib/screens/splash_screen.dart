import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/preferences_util.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set status bar to match splash screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Set up animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    // Start animation
    _animationController.forward();

    // Initialize Firebase and navigate to next screen
    _initializeFirebaseAndNavigate();
  }

  Future<void> _initializeFirebaseAndNavigate() async {
    // Initialize mock Firebase
    await FirebaseService.initializeFirebase();

    // Navigate to next screen after delay
    Timer(const Duration(seconds: 3), () {
      _navigateToNextScreen();
    });
  }

  Future<void> _navigateToNextScreen() async {
    // Check if onboarding has been completed
    final bool onboardingCompleted = await PreferencesUtil.isOnboardingCompleted();

    if (!mounted) return;

    // Check authentication status - only access context after mounted check
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isLoggedIn = userProvider.isLoggedIn;

    debugPrint('Splash screen: onboarding completed: $onboardingCompleted, logged in: $isLoggedIn');

    if (mounted) {
      if (!onboardingCompleted) {
        // Navigate to onboarding screen if not completed
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else if (isLoggedIn) {
        // Navigate to home screen if logged in
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Navigate to auth test screen if not logged in
        Navigator.of(context).pushReplacementNamed('/auth_test');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      body: Stack(
        children: [
          // Background pattern (optional)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              image: DecorationImage(
                image: const AssetImage('assets/images/pattern_bg.png'),
                fit: BoxFit.cover,
                opacity: 0.1,
                onError: (exception, stackTrace) {}, // Ignore if pattern image doesn't exist
              ),
            ),
          ),
          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo image
                  Image.asset(
                    'assets/images/splash.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 80),
                  // Loading text and indicator
                  const Text(
                    'Loading',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Loading progress bar
                  Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
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
