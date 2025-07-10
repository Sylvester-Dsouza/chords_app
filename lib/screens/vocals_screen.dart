import 'package:flutter/material.dart';
import '../config/theme.dart';

import '../models/vocal.dart';
import '../services/vocal_service.dart';
import '../utils/page_transitions.dart';
import 'vocal_warmups_screen.dart';
import 'vocal_exercises_screen.dart';

class VocalsScreen extends StatefulWidget {
  const VocalsScreen({super.key});

  @override
  State<VocalsScreen> createState() => _VocalsScreenState();
}

class _VocalsScreenState extends State<VocalsScreen>
    with TickerProviderStateMixin {
  final VocalService _vocalService = VocalService();
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _initializeData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _vocalService.initialize();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.appBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Vocals',
          style: TextStyle(
            fontFamily: AppTheme.primaryFontFamily,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Section Title
              Text(
                'Training Options',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              const SizedBox(height: 16),

              // Main Training Cards
              _buildModernTrainingCards(),
              const SizedBox(height: 24),

              // Quick Stats
              _buildModernStats(),
              const SizedBox(height: 20),

              // Downloaded Content Section
              _buildDownloadedSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildModernTrainingCards() {
    return ListenableBuilder(
      listenable: _vocalService,
      builder: (context, child) {
        // Get categories to ensure the listener is active
        _vocalService.getCategoriesByType(VocalType.warmup);
        _vocalService.getCategoriesByType(VocalType.exercise);

        return Column(
          children: [
            // Vocal Warmups Card
            _buildModernTrainingCard(
              title: 'Vocal Warmups',
              description: 'Prepare your voice with gentle exercises',
              icon: Icons.mic_rounded,
              color: AppTheme.surface,
              onTap: () => _navigateToWarmups(),
            ),

            const SizedBox(height: 12),

            // Vocal Exercises Card
            _buildModernTrainingCard(
              title: 'Vocal Exercises',
              description: 'Build technique and strengthen your voice',
              icon: Icons.fitness_center_rounded,
              color: AppTheme.surface,
              onTap: () => _navigateToExercises(),
            ),

            const SizedBox(height: 12),

            // Coming Soon Card
            _buildComingSoonCard(),
          ],
        );
      },
    );
  }

  Widget _buildModernTrainingCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.border,
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and Arrow Row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Content
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontFamily: AppTheme.primaryFontFamily,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernStats() {
    return ListenableBuilder(
      listenable: _vocalService,
      builder: (context, child) {
        final warmupCategories = _vocalService.getCategoriesByType(
          VocalType.warmup,
        );
        final exerciseCategories = _vocalService.getCategoriesByType(
          VocalType.exercise,
        );
        final totalCategories =
            warmupCategories.length + exerciseCategories.length;
        final downloadedSize = _vocalService.getFormattedDownloadedSize();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.border,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildModernStatItem(
                  '$totalCategories',
                  'Categories',
                  Icons.library_music_rounded,
                  AppTheme.textSecondary,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: AppTheme.border,
              ),
              Expanded(
                child: _buildModernStatItem(
                  '${_vocalService.downloadedItems.length}',
                  'Downloaded',
                  Icons.download_done_rounded,
                  AppTheme.textSecondary,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: AppTheme.border,
              ),
              Expanded(
                child: _buildModernStatItem(
                  downloadedSize.isEmpty ? '0 MB' : downloadedSize,
                  'Storage',
                  Icons.storage_rounded,
                  AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontFamily: AppTheme.primaryFontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Navigation Methods
  void _navigateToWarmups() {
    Navigator.push(
      context,
      FadeSlidePageRoute(page: const VocalWarmupsScreen()),
    );
  }

  void _navigateToExercises() {
    Navigator.push(
      context,
      FadeSlidePageRoute(page: const VocalExercisesScreen()),
    );
  }

  // Coming Soon Card
  Widget _buildComingSoonCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.border,
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('30-Day Vocal Course coming soon! 🚀'),
                backgroundColor: AppTheme.primary,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and Badge Row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Coming Soon',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Content
                Text(
                  '30-Day Vocal Course',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete vocal training program with daily exercises',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontFamily: AppTheme.primaryFontFamily,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Downloaded Content Section
  Widget _buildDownloadedSection() {
    return ListenableBuilder(
      listenable: _vocalService,
      builder: (context, child) {
        final downloadedItems = _vocalService.downloadedItems;

        if (downloadedItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Downloaded Content',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.primaryFontFamily,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.withValues(alpha: 0.2),
                    Colors.green.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(
                      Icons.offline_bolt_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${downloadedItems.length} items ready offline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.primaryFontFamily,
                          ),
                        ),
                        Text(
                          '${_vocalService.getFormattedDownloadedSize()} • No internet needed',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontFamily: AppTheme.primaryFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
