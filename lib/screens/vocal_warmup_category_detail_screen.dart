import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../models/vocal.dart';
import '../services/vocal_service.dart';
import '../core/service_locator.dart';
import 'vocal_player_screen.dart';

class VocalWarmupCategoryDetailScreen extends StatefulWidget {
  final VocalCategory category;

  const VocalWarmupCategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  State<VocalWarmupCategoryDetailScreen> createState() => _VocalWarmupCategoryDetailScreenState();
}

class _VocalWarmupCategoryDetailScreenState extends State<VocalWarmupCategoryDetailScreen> {
  VocalService get _vocalService => serviceLocator.vocalService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryItems();
  }

  Future<void> _loadCategoryItems() async {
    setState(() => _isLoading = true);
    await _vocalService.fetchCategoryItems(widget.category.id);
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
          widget.category.name,
          style: TextStyle(
            fontFamily: AppTheme.primaryFontFamily,
            fontWeight: FontWeight.w600,
            color: AppTheme.text,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
      ),
    );
  }

  Widget _buildContent() {
    return ListenableBuilder(
      listenable: _vocalService,
      builder: (context, child) {
        final items = _vocalService.getItemsForCategory(widget.category.id);

        if (items.isEmpty) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Category Header
              _buildCategoryHeader(items.length),

              // Items List
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildVocalItemCard(items[index]);
                  },
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryHeader(int itemCount) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.8),
            const Color(0xFF8B5CF6).withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemCount vocal warmups',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.category.description != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.category.description!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontFamily: AppTheme.primaryFontFamily,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVocalItemCard(VocalItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleItemTap(item),
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Action Button
                _buildActionButton(item),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: AppTheme.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            item.formattedDuration,
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              fontFamily: AppTheme.primaryFontFamily,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.formattedFileSize,
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              fontFamily: AppTheme.primaryFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Indicator
                _buildStatusIndicator(item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(VocalItem item) {
    IconData icon;
    Color backgroundColor;
    
    if (item.isDownloading) {
      icon = Icons.downloading_rounded;
      backgroundColor = AppTheme.primary.withValues(alpha: 0.2);
    } else if (item.isDownloaded) {
      icon = Icons.play_arrow_rounded;
      backgroundColor = AppTheme.primary.withValues(alpha: 0.2);
    } else {
      icon = Icons.download_rounded;
      backgroundColor = AppTheme.surface;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: item.isDownloaded ? AppTheme.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: item.isDownloaded ? AppTheme.primary : AppTheme.textMuted,
        size: 24,
      ),
    );
  }

  Widget _buildStatusIndicator(VocalItem item) {
    if (item.isDownloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          value: item.downloadProgress,
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      );
    } else if (item.isDownloaded) {
      return Icon(
        Icons.offline_bolt_rounded,
        color: AppTheme.primary,
        size: 20,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                Icons.mic_rounded,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Warmups Available',
              style: TextStyle(
                color: AppTheme.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This category doesn\'t have any vocal warmups yet.',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
                fontFamily: AppTheme.primaryFontFamily,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleItemTap(VocalItem item) async {
    if (item.isDownloading) {
      // Show downloading message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} is currently downloading...'),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!item.isDownloaded) {
      // Start download
      final success = await _vocalService.downloadItem(item);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} downloaded successfully'),
            backgroundColor: AppTheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${item.name}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Play the item with category items for navigation
      final categoryItems = _vocalService.getItemsForCategory(widget.category.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VocalPlayerScreen(
            vocalItem: item,
            categoryItems: categoryItems,
          ),
        ),
      );
    }
  }
}
