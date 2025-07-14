import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/karaoke.dart';
import '../services/karaoke_service.dart';
import '../services/karaoke_download_manager.dart';
import '../services/auth_service.dart';
import '../services/song_service.dart';
import '../screens/multi_track_karaoke_player_screen.dart';
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
  final SongService _songService = SongService();
  final TextEditingController _searchController = TextEditingController();

  List<KaraokeSong> _allSongs = [];
  List<KaraokeSong> _popularSongs = [];
  List<KaraokeSong> _recentSongs = [];

  bool _isLoading = true;
  String _searchQuery = '';

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
          sort: KaraokeSortOption.popular,
          page: 1,
          limit: 50,
        ),
        _karaokeService.getPopularKaraokeSongs(limit: 20),
        _karaokeService.getRecentKaraokeSongs(limit: 20),
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

          // Fallback: if All Songs is empty but we have popular/recent, combine them
          if (_allSongs.isEmpty &&
              (_popularSongs.isNotEmpty || _recentSongs.isNotEmpty)) {
            debugPrint(
              '🎤 All songs empty, using fallback with popular + recent',
            );
            final Set<String> seenIds = <String>{};
            _allSongs = [
              ..._popularSongs.where((song) => seenIds.add(song.id)),
              ..._recentSongs.where((song) => seenIds.add(song.id)),
            ];
          }

          _isLoading = false;
        });

        // Additional debug info
        debugPrint('🎤 State updated - All songs count: ${_allSongs.length}');
        if (_allSongs.isNotEmpty) {
          debugPrint(
            '🎤 First song: ${_allSongs.first.title} by ${_allSongs.first.artistName}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading karaoke data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadInitialData();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
    });
    _searchController.clear();
    _loadInitialData();
  }

  Future<void> _openKaraokePlayer(KaraokeSong karaokeSong) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Fetch complete song data with chord sheet from backend
      debugPrint('🎤 Fetching complete song data for karaoke: ${karaokeSong.id}');
      final completeSong = await _songService.getSongById(karaokeSong.id);

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Debug complete song data
      debugPrint('🎤 Complete song data loaded: ${completeSong.title}');
      debugPrint('🎤 Has chord sheet: ${completeSong.chords != null && completeSong.chords!.isNotEmpty}');
      if (completeSong.karaoke != null) {
        debugPrint('🎤 Karaoke tracks in complete song: ${completeSong.karaoke!.tracks.length}');
      }

      // Navigate to multi-track karaoke player with complete data
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MultiTrackKaraokePlayerScreen(song: completeSong),
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      debugPrint('🎤 Error fetching complete song data: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load complete song data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Fallback: create Song from KaraokeSong data
      if (mounted) {
        final fallbackSong = Song(
          id: karaokeSong.id,
          title: karaokeSong.title,
          artist: karaokeSong.artistName,
          key: karaokeSong.songKey ?? 'C',
          imageUrl: karaokeSong.imageUrl,
          tempo: karaokeSong.tempo,
          difficulty: karaokeSong.difficulty,
          averageRating: karaokeSong.averageRating,
          ratingCount: karaokeSong.ratingCount,
          karaoke: karaokeSong.karaoke,
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MultiTrackKaraokePlayerScreen(song: fallbackSong),
          ),
        );
      }
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
        title: Text(
          'Karaoke',
          style: TextStyle(
            fontFamily: AppTheme.primaryFontFamily,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllSongsTab(),
                _buildPopularTab(),
                _buildRecentTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.background,
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontFamily: AppTheme.primaryFontFamily,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search karaoke songs...',
                hintStyle: TextStyle(
                  color: AppTheme.textPlaceholder,
                  fontFamily: AppTheme.primaryFontFamily,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.background,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 2,
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

  Widget _buildKaraokeSongCard(
    KaraokeSong song, {
    bool showRank = false,
    int? rank,
  }) {
    final isDownloaded = _downloadManager.isDownloaded(song.id);
    final isDownloading = _downloadManager.isDownloading(song.id);
    final downloadProgress = _downloadManager.getDownloadProgress(song.id);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async => await _openKaraokePlayer(song),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildModernLeadingWidget(song, showRank, rank),
                const SizedBox(width: 12),
                Expanded(child: _buildModernSongInfo(song)),
                const SizedBox(width: 8),
                _buildModernTrailingWidget(
                  song,
                  isDownloaded,
                  isDownloading,
                  downloadProgress,
                ),
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '#$rank',
            style: TextStyle(
              color: AppTheme.background,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.displayFontFamily,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        color: AppTheme.surfaceSecondary,
        child:
            song.imageUrl != null
                ? CachedNetworkImage(
                  imageUrl: song.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: AppTheme.surfaceSecondary,
                        child: Icon(
                          Icons.music_note_rounded,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: AppTheme.surfaceSecondary,
                        child: Icon(
                          Icons.music_note_rounded,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                      ),
                )
                : Icon(
                  Icons.music_note_rounded,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
      ),
    );
  }

  Widget _buildModernSongInfo(KaraokeSong song) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          song.title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.primaryFontFamily,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                song.artistName,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (song.karaoke.tracks.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.multitrack_audio,
                      size: 10,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'AI',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildModernTrailingWidget(
    KaraokeSong song,
    bool isDownloaded,
    bool isDownloading,
    double downloadProgress,
  ) {
    if (isDownloading) {
      return Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(6),
        child: CircularProgressIndicator(
          value: downloadProgress,
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isDownloaded)
          GestureDetector(
            onTap: () => _downloadKaraokeTrack(song),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.download_rounded,
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppTheme.textSecondary,
          size: 14,
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
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search'
                  : 'No karaoke songs are available yet',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontFamily: AppTheme.primaryFontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _clearFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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
}
