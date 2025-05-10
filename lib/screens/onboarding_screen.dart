import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../utils/preferences_util.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  @override
  void initState() {
    super.initState();
    // Set preferred orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _numPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _getStarted() async {
    // Mark onboarding as completed
    await PreferencesUtil.setOnboardingCompleted();

    // Navigate to login screen
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _getStarted,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const ClampingScrollPhysics(),
                children: [
                  _buildPage(
                    title: 'Find Christian Songs',
                    description: 'Discover thousands of worship songs with chords and lyrics for your church service.',
                    icon: Icons.music_note,
                    color: Theme.of(context).colorScheme.primary,
                    imagePath: 'assets/images/onboarding1.png',
                  ),
                  _buildPage(
                    title: 'Create Playlists',
                    description: 'Organize your favorite songs into playlists for easy access during worship.',
                    icon: Icons.playlist_add,
                    color: Theme.of(context).colorScheme.secondary,
                    imagePath: 'assets/images/onboarding2.png',
                  ),
                  _buildPage(
                    title: 'Practice Anywhere',
                    description: 'Take your songs offline and practice anywhere, anytime with your band.',
                    icon: Icons.headphones,
                    color: Colors.green,
                    imagePath: 'assets/images/onboarding3.png',
                  ),
                ],
              ),
            ),

            // Page indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _numPages,
                  (index) => _buildPageIndicator(index == _currentPage),
                ),
              ),
            ),

            // Next or Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: ElevatedButton(
                onPressed: _currentPage == _numPages - 1 ? _getStarted : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC701),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  _currentPage == _numPages - 1 ? 'GET STARTED' : 'NEXT',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    String? imagePath,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: imagePath != null
                ? Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to icon if image fails to load
                        return Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: color.withAlpha(50),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: math.pi / 10.0,
                              child: Icon(
                                icon,
                                size: 80,
                                color: color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: color.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: math.pi / 10.0,
                        child: Icon(
                          icon,
                          size: 80,
                          color: color,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            description,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFC701) : Colors.grey,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}
