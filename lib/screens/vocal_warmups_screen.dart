import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/inner_screen_app_bar.dart';
import 'vocal_warmup_player_screen.dart';

class VocalWarmupsScreen extends StatefulWidget {
  const VocalWarmupsScreen({super.key});

  @override
  State<VocalWarmupsScreen> createState() => _VocalWarmupsScreenState();
}

class _VocalWarmupsScreenState extends State<VocalWarmupsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Custom App Bar
          InnerScreenAppBar(
            title: 'Course Warmups',
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero Section
                  _buildHeroSection(),

                  // Quick Start Section
                  _buildQuickStartSection(),

                  // Warmup Categories
                  _buildWarmupsSection(),

                  // Bottom padding
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Hero Section
  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Animated Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.mic_rounded,
              color: AppTheme.primaryColor,
              size: 40,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Ready to Warm Up?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.primaryFontFamily,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Prepare your voice with guided exercises\ndesigned for every skill level',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              fontFamily: AppTheme.primaryFontFamily,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Quick Start Section
  Widget _buildQuickStartSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Start',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),

          const SizedBox(height: 16),

          // Quick Start Button
          Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _startQuickWarmup(),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.flash_on_rounded,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '5-Minute Express',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppTheme.primaryFontFamily,
                              ),
                            ),
                            Text(
                              'Perfect for quick sessions',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.7),
                                fontSize: 14,
                                fontFamily: AppTheme.primaryFontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Warmups Section
  Widget _buildWarmupsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Choose Your Warmup',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Warmup Grid
          _buildWarmupGrid(),
        ],
      ),
    );
  }

  Widget _buildWarmupGrid() {
    final warmups = [
      {
        'name': 'Daily Flow',
        'description': 'Perfect daily routine',
        'duration': 10,
        'difficulty': 'Medium',
        'type': 'standard',
        'color': const Color(0xFF6366F1),
        'emoji': '🎯',
        'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      },
      {
        'name': 'Quick Boost',
        'description': 'Fast vocal prep',
        'duration': 5,
        'difficulty': 'Easy',
        'type': 'quick',
        'color': const Color(0xFF00D4AA),
        'emoji': '⚡',
        'gradient': [const Color(0xFF00D4AA), const Color(0xFF34D399)],
      },
      {
        'name': 'Stage Ready',
        'description': 'Performance prep',
        'duration': 15,
        'difficulty': 'Pro',
        'type': 'performance',
        'color': const Color(0xFFEC4899),
        'emoji': '🚀',
        'gradient': [const Color(0xFFEC4899), const Color(0xFFF472B6)],
      },
      {
        'name': 'Chill Mode',
        'description': 'Gentle recovery',
        'duration': 8,
        'difficulty': 'Easy',
        'type': 'recovery',
        'color': const Color(0xFF8B5CF6),
        'emoji': '🌙',
        'gradient': [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: warmups.length,
        itemBuilder: (context, index) => _buildModernWarmupCard(warmups[index]),
      ),
    );
  }

  // Modern Warmup Card Design
  Widget _buildModernWarmupCard(Map<String, dynamic> warmup) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: warmup['gradient'] as List<Color>,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (warmup['color'] as Color).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startWarmup(warmup),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row - Emoji and Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          warmup['emoji'] as String,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${warmup['duration']}m',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  warmup['name'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),

                const SizedBox(height: 4),

                // Description
                Text(
                  warmup['description'] as String,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),

                const Spacer(),

                // Bottom Row - Difficulty and Play Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        warmup['difficulty'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startQuickWarmup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WarmupPlayerScreen(
          warmupName: '5-Minute Express Warmup',
          warmupType: 'quick',
        ),
      ),
    );
  }

  void _startWarmup(Map<String, dynamic> warmup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WarmupPlayerScreen(
          warmupName: warmup['name'] as String,
          warmupType: warmup['type'] as String,
        ),
      ),
    );
  }
}
