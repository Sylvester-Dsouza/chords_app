import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/vocal.dart';
import '../services/vocal_service.dart';
import '../core/service_locator.dart';
import '../core/constants.dart';
import 'vocal_warmup_category_detail_screen.dart';

class VocalWarmupsScreen extends StatefulWidget {
  const VocalWarmupsScreen({super.key});

  @override
  State<VocalWarmupsScreen> createState() => _VocalWarmupsScreenState();
}

class _VocalWarmupsScreenState extends State<VocalWarmupsScreen>
    with TickerProviderStateMixin {
  // Use service locator instead of creating new instance
  VocalService get _vocalService => serviceLocator.vocalService;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.fadeAnimationDuration,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: AppConstants.slideAnimationDuration,
      vsync: this,
    );
    _initializeData();
  }

  @override
  void dispose() {
    // Dispose animation controllers with error handling
    try {
      if (_fadeController.isAnimating) {
        _fadeController.stop();
      }
      _fadeController.dispose();
    } catch (e) {
      debugPrint('Error disposing fade controller: $e');
    }

    try {
      if (_slideController.isAnimating) {
        _slideController.stop();
      }
      _slideController.dispose();
    } catch (e) {
      debugPrint('Error disposing slide controller: $e');
    }

    super.dispose();
  }

  Future<void> _initializeData() async {
    await _vocalService.fetchCategories();
    _fadeController.forward();
    _slideController.forward();
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
          'Vocal Warmups',
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
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: _VocalWarmupsContent(vocalService: _vocalService),
        ),
      ),
    );
  }
}

/// Optimized content widget that reduces unnecessary rebuilds
class _VocalWarmupsContent extends StatefulWidget {
  final VocalService vocalService;

  const _VocalWarmupsContent({required this.vocalService});

  @override
  State<_VocalWarmupsContent> createState() => _VocalWarmupsContentState();
}

class _VocalWarmupsContentState extends State<_VocalWarmupsContent> {
  List<VocalCategory>? _cachedCategories;
  bool? _cachedIsLoading;
  String? _cachedError;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vocalService,
      builder: (context, child) {
        final warmupCategories = widget.vocalService.getCategoriesByType(
          VocalType.warmup,
        );
        final isLoading = widget.vocalService.isLoading;
        final error = widget.vocalService.error;

        // Only rebuild if data actually changed
        if (_cachedCategories != warmupCategories ||
            _cachedIsLoading != isLoading ||
            _cachedError != error) {
          _cachedCategories = warmupCategories;
          _cachedIsLoading = isLoading;
          _cachedError = error;
        }

        if (isLoading) {
          return _buildLoadingState();
        }

        if (error != null) {
          return _buildErrorState(error);
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categories
                if (warmupCategories.isNotEmpty) ...[
                  _buildCategoriesSection(warmupCategories),
                ] else ...[
                  _buildEmptyState(),
                ],

                // Bottom padding
                SizedBox(height: AppConstants.extraLargePadding),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
              'Failed to Load Warmups',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: AppTheme.primaryFontFamily,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: AppTheme.primaryFontFamily,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(List<VocalCategory> categories) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _VocalCategoryCard(
          category: categories[index],
          vocalService: widget.vocalService,
        );
      },
    );
  }

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
            'No Warmups Available',
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
              'New vocal warmup exercises will be added soon. Check back later!',
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
}

/// Optimized category card widget
class _VocalCategoryCard extends StatelessWidget {
  final VocalCategory category;
  final VocalService vocalService;

  const _VocalCategoryCard({
    required this.category,
    required this.vocalService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1), width: 1),
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
          onTap: () => _openCategory(context),
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
                        '${category.itemCount ?? 0} warmups',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
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

  void _openCategory(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VocalWarmupCategoryDetailScreen(category: category),
      ),
    );
  }
}
