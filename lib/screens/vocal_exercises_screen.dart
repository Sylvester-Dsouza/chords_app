import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/vocal.dart';
import '../services/vocal_service.dart';
import '../core/service_locator.dart';
import '../core/constants.dart';
import 'vocal_exercise_category_detail_screen.dart';

class VocalExercisesScreen extends StatefulWidget {
  const VocalExercisesScreen({super.key});

  @override
  State<VocalExercisesScreen> createState() => _VocalExercisesScreenState();
}

class _VocalExercisesScreenState extends State<VocalExercisesScreen>
    with TickerProviderStateMixin {
  // Use service locator instead of creating new instance
  VocalService get _vocalService => serviceLocator.vocalService;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.fadeAnimationDuration,
      vsync: this,
    );
    _initializeData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _vocalService.fetchCategories();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Vocal Exercises',
          style: TextStyle(
            fontFamily: AppTheme.primaryFontFamily,
            fontWeight: FontWeight.w600,
            color: AppTheme.text,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: ListenableBuilder(
          listenable: _vocalService,
          builder: (context, child) {
            final exerciseCategories = _vocalService.getCategoriesByType(
              VocalType.exercise,
            );

            if (_vocalService.isLoading) {
              return _buildLoadingState();
            }

            if (_vocalService.error != null) {
              return _buildErrorState();
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Categories
                    if (exerciseCategories.isNotEmpty) ...[
                      _buildCategoriesGrid(exerciseCategories),
                    ] else ...[
                      _buildEmptyState(),
                    ],

                    // Bottom padding
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Exercises',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: AppTheme.primaryFontFamily,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _vocalService.error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: AppTheme.primaryFontFamily,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    () => _vocalService.fetchCategories(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Categories List Section
  Widget _buildCategoriesGrid(List<VocalCategory> categories) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildCategoryCard(categories[index]);
      },
    );
  }

  // Category Card for List
  Widget _buildCategoryCard(VocalCategory category) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openCategory(category),
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withValues(alpha: 0.8),
                        primaryColor.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    Icons.music_note_outlined,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.primaryFontFamily,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${category.itemCount ?? 0} exercises',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.8,
                          ),
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTheme.primaryFontFamily,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              Icons.music_note_outlined,
              size: 48,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Exercises Available',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: AppTheme.primaryFontFamily,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'New vocal exercises will be added soon. Check back later!',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: AppTheme.primaryFontFamily,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation
  void _openCategory(VocalCategory category) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VocalExerciseCategoryDetailScreen(category: category),
      ),
    );
  }
}
