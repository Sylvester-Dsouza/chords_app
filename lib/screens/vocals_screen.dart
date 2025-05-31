import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/inner_screen_app_bar.dart';
import 'vocal_warmups_screen.dart';
import 'vocal_exercises_screen.dart';

class VocalsScreen extends StatefulWidget {
  const VocalsScreen({super.key});

  @override
  State<VocalsScreen> createState() => _VocalsScreenState();
}

class _VocalsScreenState extends State<VocalsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Custom App Bar
          InnerScreenAppBar(
            title: 'Vocals',
            showBackButton: false,
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section
                    _buildHeroSection(),

                    const SizedBox(height: 32),

                    // Quick Stats
                    _buildQuickStats(),

                    const SizedBox(height: 20),

                    // Features Section
                    _buildFeaturesSection(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Compact Header Section
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Compact Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: Colors.black,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vocal Training Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Improve your voice with guided exercises and warmups',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Stats Section
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('12+', 'Exercises', Icons.fitness_center_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('5-15', 'Minutes', Icons.timer_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('All', 'Levels', Icons.trending_up_rounded),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  // Features Section
  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Training Options',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),

        const SizedBox(height: 16),

        // Vocal Warmups Card
        _buildFeatureCard(
          title: 'Vocal Warmups',
          description: 'Quick voice preparation',
          details: '5-15 min sessions • 4 exercises',
          emoji: '🎵',
          gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          onTap: () => _navigateToWarmups(),
          isAvailable: true,
        ),

        const SizedBox(height: 12),

        // Vocal Exercises Card
        _buildFeatureCard(
          title: 'Vocal Exercises',
          description: 'Technique & skill building',
          details: 'Scales • Breathing • Range training',
          emoji: '🎶',
          gradient: [const Color(0xFF00D4AA), const Color(0xFF34D399)],
          onTap: () => _navigateToExercises(),
          isAvailable: true,
        ),

        const SizedBox(height: 12),

        // Vocal Course Card
        _buildFeatureCard(
          title: '30-Day Course',
          description: 'Complete vocal program',
          details: 'Daily lessons • Professional guidance',
          emoji: '🚀',
          gradient: [const Color(0xFFEC4899), const Color(0xFFF472B6)],
          onTap: () => _showComingSoon(),
          isAvailable: false,
          comingSoon: true,
        ),
      ],
    );
  }

  // Feature Card Widget
  Widget _buildFeatureCard({
    required String title,
    required String description,
    required String details,
    required String emoji,
    required List<Color> gradient,
    required VoidCallback onTap,
    required bool isAvailable,
    bool comingSoon = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isAvailable
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.withValues(alpha: 0.3),
                  Colors.grey.withValues(alpha: 0.2),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isAvailable
            ? [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Emoji Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppTheme.primaryFontFamily,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (comingSoon) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Soon',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTheme.primaryFontFamily,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation Methods
  void _navigateToWarmups() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VocalWarmupsScreen(),
      ),
    );
  }

  void _navigateToExercises() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VocalExercisesScreen(),
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('30-Day Vocal Course coming soon! 🚀'),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
