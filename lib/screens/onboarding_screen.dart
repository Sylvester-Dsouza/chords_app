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
                    color: const Color(0xFF6C5CE7), // Vibrant purple
                    imagePath: 'assets/images/onboarding1.png',
                  ),
                  _buildPage(
                    title: 'Create Setlists',
                    description: 'Organize your favorite songs into setlists for easy access during worship.',
                    icon: Icons.playlist_add,
                    color: const Color(0xFF00D2D3), // Bright cyan/teal
                    imagePath: 'assets/images/onboarding2.png',
                  ),
                  _buildPage(
                    title: 'Practice Anywhere',
                    description: 'Take your songs offline and practice anywhere, anytime with your band.',
                    icon: Icons.headphones,
                    color: const Color(0xFFFF6B6B), // Coral pink/red
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
                  backgroundColor: Colors.white,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get screen dimensions
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;

        // Calculate responsive sizes
        final imageSize = math.min(screenWidth * 0.5, screenHeight * 0.3).clamp(120.0, 240.0);
        final titleFontSize = (screenWidth * 0.07).clamp(20.0, 28.0);
        final descriptionFontSize = (screenWidth * 0.04).clamp(14.0, 16.0);

        // Calculate spacing based on available height
        final availableHeight = screenHeight - imageSize - 100; // Reserve space for image and padding
        final titleDescriptionSpace = (availableHeight * 0.15).clamp(16.0, 24.0);
        final imageTextSpace = (availableHeight * 0.2).clamp(24.0, 48.0);

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: math.max(24.0, screenWidth * 0.08),
              vertical: 16.0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - 32, // Account for vertical padding
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated icon/image
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
                            width: imageSize,
                            height: imageSize,
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
                                  width: imageSize * 0.7,
                                  height: imageSize * 0.7,
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(50),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Transform.rotate(
                                      angle: math.pi / 10.0,
                                      child: Icon(
                                        icon,
                                        size: imageSize * 0.35,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: imageSize * 0.7,
                            height: imageSize * 0.7,
                            decoration: BoxDecoration(
                              color: color.withAlpha(50),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle: math.pi / 10.0,
                                child: Icon(
                                  icon,
                                  size: imageSize * 0.35,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: imageTextSpace),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: titleDescriptionSpace),

                  // Description
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: descriptionFontSize,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}
