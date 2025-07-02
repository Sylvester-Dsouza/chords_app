import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/karaoke.dart';
import '../services/karaoke_service.dart';
import '../services/karaoke_download_manager.dart';
import '../services/auth_service.dart';
import '../screens/karaoke_player_screen.dart';
import '../models/song.dart';
import '../config/theme.dart';

class KaraokeScreen extends StatefulWidget {
  const KaraokeScreen({super.key});

  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late KaraokeDownloadManager _downloadManager;
  late KaraokeService _karaokeService;
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<KaraokeSong> _allSongs = [];
  List<KaraokeSong> _popularSongs = [];
  List<KaraokeSong> _recentSongs = [];

  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedKey;
  String? _selectedDifficulty;
  KaraokeSortOption _sortOption = KaraokeSortOption.popular;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _downloadManager = KaraokeDownloadManager();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Initialize AuthService first
    await _authService.initializeFirebase();
    _karaokeService = KaraokeService(_authService);
    await _downloadManager.initialize();
    await _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🎤 Loading karaoke data...');

      final results = await Future.wait([
        _karaokeService.getKaraokeSongs(
          search: _searchQuery.isEmpty ? null : _searchQuery,
          key: _selectedKey,
          difficulty: _selectedDifficulty,
          sort: _sortOption,
          page: 1,
          limit: 20,
        ),
        _karaokeService.getPopularKaraokeSongs(limit: 10),
        _karaokeService.getRecentKaraokeSongs(limit: 10),
      ]);

      debugPrint('🎤 Karaoke data loaded:');
      debugPrint('  - All songs: ${results[0].length}');
      debugPrint('  - Popular songs: ${results[1].length}');
      debugPrint('  - Recent songs: ${results[2].length}');

      if (mounted) {
        setState(() {
          _allSongs = results[0];
          _popularSongs = results[1];
          _recentSongs = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading karaoke data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadInitialData();
  }

  void _onFiltersChanged({
    String? key,
    String? difficulty,
    KaraokeSortOption? sort,
  }) {
    setState(() {
      if (key != null) _selectedKey = key.isEmpty ? null : key;
      if (difficulty != null) _selectedDifficulty = difficulty.isEmpty ? null : difficulty;
      if (sort != null) _sortOption = sort;
    });
    _loadInitialData();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedKey = null;
      _selectedDifficulty = null;
      _sortOption = KaraokeSortOption.popular;
    });
    _searchController.clear();
    _loadInitialData();
  }

  void _openKaraokePlayer(KaraokeSong karaokeSong) {
    // Convert KaraokeSong to Song for the player
    final song = Song(
      id: karaokeSong.id,
      title: karaokeSong.title,
      artist: karaokeSong.artistName,
      key: karaokeSong.songKey ?? 'C', // Provide default key
      imageUrl: karaokeSong.imageUrl,
      tempo: karaokeSong.tempo,
      difficulty: karaokeSong.difficulty,
      averageRating: karaokeSong.averageRating,
      ratingCount: karaokeSong.ratingCount,
      karaoke: karaokeSong.karaoke,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => KaraokePlayerScreen(
          song: song,
          karaokeUrl: karaokeSong.karaoke.fileUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildModernAppBar(),
            _buildSearchAndFilters(),
            _buildTabBar(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllSongsTab(),
            _buildPopularTab(),
            _buildRecentTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Karaoke',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: AppTheme.displayFontFamily,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withOpacity(0.1),
                AppTheme.background,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.mic_rounded,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: AppTheme.background,
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
                decoration: InputDecoration(
                  hintText: 'Search karaoke songs...',
                  hintStyle: TextStyle(
                    color: AppTheme.textPlaceholder,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Filter Chips
            _buildFilterChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Sort Options
          _buildFilterChip(
            'Popular',
            _sortOption == KaraokeSortOption.popular,
            () => _onFiltersChanged(sort: KaraokeSortOption.popular),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Recent',
            _sortOption == KaraokeSortOption.recent,
            () => _onFiltersChanged(sort: KaraokeSortOption.recent),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'A-Z',
            _sortOption == KaraokeSortOption.title,
            () => _onFiltersChanged(sort: KaraokeSortOption.title),
          ),
          const SizedBox(width: 8),
          // Downloaded Filter
          _buildFilterChip(
            'Downloaded',
            false, // We'll implement this later
            () {
              // Show downloaded songs
            },
            icon: Icons.download_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppTheme.background : AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.background : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.background,
        child: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: AppTheme.primaryFontFamily,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            fontFamily: AppTheme.primaryFontFamily,
          ),
          tabs: const [
            Tab(text: 'All Songs'),
            Tab(text: 'Popular'),
            Tab(text: 'Recent'),
          ],
        ),
      ),
    );
  }

  Widget _buildAllSongsTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_allSongs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: Colors.blue,
      backgroundColor: Colors.grey.shade800,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allSongs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildKaraokeSongCard(_allSongs[index]),
          );
        },
      ),
    );
  }

  Widget _buildPopularTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_popularSongs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: Colors.blue,
      backgroundColor: Colors.grey.shade800,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _popularSongs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildKaraokeSongCard(
              _popularSongs[index],
              showRank: true,
              rank: index + 1,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_recentSongs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: Colors.blue,
      backgroundColor: Colors.grey.shade800,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recentSongs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildKaraokeSongCard(_recentSongs[index]),
          );
        },
      ),
    );
  }

  Widget _buildKaraokeSongCard(KaraokeSong song, {bool showRank = false, int? rank}) {
    final isDownloaded = _downloadManager.isDownloaded(song.id);
    final isDownloading = _downloadManager.isDownloading(song.id);
    final downloadProgress = _downloadManager.getDownloadProgress(song.id);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openKaraokePlayer(song),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildModernLeadingWidget(song, showRank, rank),
                const SizedBox(width: 16),
                Expanded(child: _buildModernSongInfo(song)),
                const SizedBox(width: 12),
                _buildModernTrailingWidget(song, isDownloaded, isDownloading, downloadProgress),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernLeadingWidget(KaraokeSong song, bool showRank, int? rank) {
    if (showRank && rank != null) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '#$rank',
            style: TextStyle(
              color: AppTheme.background,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.displayFontFamily,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        color: AppTheme.surfaceSecondary,
        child: song.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: song.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.surfaceSecondary,
                  child: Icon(
                    Icons.music_note_rounded,
                    color: AppTheme.textSecondary,
                    size: 24,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceSecondary,
                  child: Icon(
                    Icons.music_note_rounded,
                    color: AppTheme.textSecondary,
                    size: 24,
                  ),
                ),
              )
            : Icon(
                Icons.music_note_rounded,
                color: AppTheme.textSecondary,
                size: 24,
              ),
      ),
    );
  }

  Widget _buildModernSongInfo(KaraokeSong song) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.primaryFontFamily,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          song.artistName,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontFamily: AppTheme.primaryFontFamily,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _buildModernSongDetails(song),
      ],
    );
  }

  Widget _buildModernSongDetails(KaraokeSong song) {
    final details = <Widget>[];

    if (song.songKey != null) {
      details.add(_buildModernDetailChip('Key: ${song.songKey}', AppTheme.primary));
    }

    if (song.karaoke.duration != null) {
      details.add(_buildModernDetailChip(song.karaoke.formattedDuration, AppTheme.textSecondary));
    }

    if (song.karaoke.quality != null) {
      details.add(_buildModernDetailChip(
        '${song.karaoke.quality} Quality',
        _getModernQualityColor(song.karaoke.quality!),
      ));
    }

    if (song.difficulty != null) {
      details.add(_buildModernDetailChip(song.difficulty!, AppTheme.textSecondary));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: details,
    );
  }

  Widget _buildModernDetailChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: AppTheme.primaryFontFamily,
        ),
      ),
    );
  }

  Color _getModernQualityColor(String quality) {
    switch (quality.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFF4CAF50); // Green
      case 'MEDIUM':
        return AppTheme.primary; // Orange
      case 'LOW':
        return const Color(0xFFF44336); // Red
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildModernTrailingWidget(KaraokeSong song, bool isDownloaded, bool isDownloading, double downloadProgress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Download Button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: isDownloading
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    value: downloadProgress,
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
                  ),
                )
              : Icon(
                  isDownloaded ? Icons.play_arrow_rounded : Icons.mic_rounded,
                  color: AppTheme.background,
                  size: 20,
                ),
        ),
        const SizedBox(height: 4),
        // Download Status
        if (isDownloaded)
          Icon(
            Icons.download_done_rounded,
            color: AppTheme.primary,
            size: 16,
          )
        else if (!isDownloading)
          GestureDetector(
            onTap: () => _downloadKaraokeTrack(song),
            child: Icon(
              Icons.download_rounded,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ),
      ],
    );
  }

  Future<void> _downloadKaraokeTrack(KaraokeSong song) async {
    try {
      final downloadData = await _karaokeService.getKaraokeDownloadUrl(song.id);
      if (downloadData != null) {
        final success = await _downloadManager.downloadTrack(
          song.id,
          downloadData['downloadUrl'],
          fileSize: downloadData['fileSize'] ?? 0,
          duration: downloadData['duration'] ?? 0,
          fileName: '${song.title}_${song.artistName}.mp3',
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${song.title} downloaded successfully'),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${song.title}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Shimmer placeholder for image
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Shimmer placeholder for text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Shimmer placeholder for button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.mic_off_rounded,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Karaoke Songs',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.displayFontFamily,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty || _selectedKey != null || _selectedDifficulty != null
                  ? 'Try adjusting your search or filters'
                  : 'No karaoke songs are available yet',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontFamily: AppTheme.primaryFontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedKey != null || _selectedDifficulty != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _clearFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Clear Filters',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildFiltersBottomSheet(),
    );
  }

  Widget _buildFiltersBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Filter Karaoke Songs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort By',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: KaraokeSortOption.values.map((option) {
                    final isSelected = _sortOption == option;
                    return FilterChip(
                      label: Text(option.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        _onFiltersChanged(sort: option);
                        Navigator.of(context).pop();
                      },
                      backgroundColor: Colors.grey.shade800,
                      selectedColor: Colors.blue.withValues(alpha: 0.2),
                      checkmarkColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue : Colors.white70,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? Colors.blue : Colors.grey.shade600,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _clearFilters();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.grey.shade600),
                        ),
                        child: const Text('Clear All'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
