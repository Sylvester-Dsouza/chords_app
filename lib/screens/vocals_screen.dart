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
            fontWeight: FontWeight.bold,
            color: AppTheme.text,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Hero Section
              _buildHeroSection(),

              const SizedBox(height: 24),

              // Main Training Cards
              _buildModernTrainingCards(),
              const SizedBox(height: 24),

              // Quick Stats
              _buildModernStats(),
              const SizedBox(height: 24),

              // Downloaded Content Section
              _buildDownloadedSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withValues(alpha: 0.15),
              AppTheme.primary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Modern Icon Container
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.record_voice_over_rounded,
                color: Colors.black,
                size: 36,
              ),
            ),

            const SizedBox(width: 24),

            // Enhanced Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vocal Training',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTheme.primaryFontFamily,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Master your voice with professional exercises and warmups',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      fontFamily: AppTheme.primaryFontFamily,
                      height: 1.4,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress indicator
                  Container(
                    height: 4,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            // Main Training Cards
            Row(
              children: [
                // Vocal Warmups Card
                Expanded(
                  child: _buildModernTrainingCard(
                    title: 'Vocal Warmups',
                    description: 'Prepare your voice',
                    icon: Icons.mic_rounded,
                    color: AppTheme.primary.withValues(alpha: 0.9),
                    onTap: () => _navigateToWarmups(),
                  ),
                ),

                const SizedBox(width: 16),

                // Vocal Exercises Card
                Expanded(
                  child: _buildModernTrainingCard(
                    title: 'Vocal Exercises',
                    description: 'Build technique',
                    icon: Icons.fitness_center_rounded,
                    color: AppTheme.primary.withValues(alpha: 0.8),
                    onTap: () => _navigateToExercises(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

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
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),

                const SizedBox(height: 12),

                // Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.primaryFontFamily,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontFamily: AppTheme.primaryFontFamily,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildModernStatItem(
                  '$totalCategories',
                  'Categories',
                  Icons.library_music_rounded,
                  AppTheme.primary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildModernStatItem(
                  '${_vocalService.downloadedItems.length}',
                  'Downloaded',
                  Icons.download_done_rounded,
                  AppTheme.primary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildModernStatItem(
                  downloadedSize.isEmpty ? '0 MB' : downloadedSize,
                  'Storage',
                  Icons.storage_rounded,
                  AppTheme.primary,
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 300;
        final iconSize = isSmallScreen ? 32.0 : 36.0;
        final titleFontSize = isSmallScreen ? 14.0 : 16.0;
        final descriptionFontSize = isSmallScreen ? 12.0 : 13.0;
        final padding = isSmallScreen ? 16.0 : 20.0;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(5),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        color: AppTheme.primary,
                        size: iconSize * 0.5,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title and Badge Row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Text(
                                      '30-Day Vocal Course',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: AppTheme.primaryFontFamily,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Coming Soon',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          fontFamily:
                                              AppTheme.primaryFontFamily,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.clip,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Description
                          const SizedBox(height: 4),
                          Text(
                            'Complete vocal training program with daily exercises and lessons',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: descriptionFontSize,
                              fontFamily: AppTheme.primaryFontFamily,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.textMuted,
                      size: isSmallScreen ? 10 : 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
