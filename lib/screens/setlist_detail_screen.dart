import 'package:flutter/material.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../widgets/song_placeholder.dart';
import '../widgets/skeleton_loader.dart';
import '../models/setlist.dart';
import '../models/song.dart';
import '../services/setlist_service.dart';
import '../services/liked_songs_service.dart';
import '../services/incremental_sync_service.dart';
import '../config/theme.dart';
import '../utils/ui_helpers.dart';
import '../widgets/enhanced_setlist_share_dialog.dart';
import '../widgets/setlist_settings_dialog.dart';
import 'setlist_collaboration_comments_screen.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class SetlistDetailScreen extends StatefulWidget {
  final String setlistId;
  final String setlistName;

  const SetlistDetailScreen({
    super.key,
    required this.setlistId,
    required this.setlistName,
  });

  @override
  State<SetlistDetailScreen> createState() => _SetlistDetailScreenState();
}

class _SetlistDetailScreenState extends State<SetlistDetailScreen> {
  // Removed _currentIndex as we don't need it anymore

  final SetlistService _setlistService = SetlistService();
  final LikedSongsService _likedSongsService = LikedSongsService();
  final IncrementalSyncService _syncService = IncrementalSyncService();
  List<Song> _likedSongs = [];

  Setlist? _setlist;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isAddingSongs = false;
  bool _hasModifiedSetlist = false; // Track if setlist was modified
  List<dynamic> _songs = [];

  @override
  void initState() {
    super.initState();
    debugPrint('SetlistDetailScreen initState for setlist ID: ${widget.setlistId}');

    // First check login status, then fetch setlist details
    _checkLoginStatus().then((_) {
      if (_isLoggedIn) {
        _fetchSetlistDetails();
      }
    });
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    // Note: Services are stateless and don't need disposal
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Use the UserProvider to check authentication status
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final isAuthenticated = await userProvider.isAuthenticated();

      setState(() {
        _isLoggedIn = isAuthenticated;
      });

      // If not authenticated, clear any stale data
      if (!isAuthenticated) {
        setState(() {
          _setlist = null;
          _songs = [];
          _likedSongs = [];
        });
      } else {
        // If authenticated, fetch liked songs
        await _fetchLikedSongs();
      }

      debugPrint('Login status checked in detail screen: $_isLoggedIn');
    } catch (e) {
      debugPrint('Error checking login status: $e');
      setState(() {
        _isLoggedIn = false;
        _setlist = null;
        _songs = [];
        _likedSongs = [];
      });
    }
  }

  // Fetch liked songs
  Future<void> _fetchLikedSongs() async {
    debugPrint('Fetching liked songs...');
    try {
      final likedSongs = await _likedSongsService.getLikedSongs();
      setState(() {
        _likedSongs = likedSongs;
      });
      debugPrint('Fetched ${_likedSongs.length} liked songs');
    } catch (e) {
      debugPrint('Error fetching liked songs: $e');
    }
  }

  // Simple refresh method for after adding songs (no auth error handling)
  Future<void> _refreshSetlistData() async {
    debugPrint('🔄 Refreshing setlist data for ID: ${widget.setlistId}');

    try {
      if (!_isLoggedIn) {
        debugPrint('❌ User not logged in, skipping setlist refresh');
        return;
      }

      debugPrint('📡 Refreshing setlist details from cache/API');
      final setlist = await _syncService.getSetlistById(widget.setlistId, forceRefresh: true);

      if (setlist == null) {
        debugPrint('❌ Setlist not found during refresh');
        return;
      }

      debugPrint('✅ Setlist details refreshed: ${setlist.name}');
      debugPrint('🎵 Songs count: ${setlist.songs?.length ?? 0}');

      // Log song details for debugging
      if (setlist.songs != null && setlist.songs!.isNotEmpty) {
        debugPrint('📋 Songs in refreshed setlist:');
        for (var i = 0; i < setlist.songs!.length; i++) {
          final song = setlist.songs![i];
          if (song is Map<String, dynamic>) {
            debugPrint('  ${i + 1}. ${song['title'] ?? 'Unknown'} - ${song['artist'] is Map ? song['artist']['name'] : song['artist'] ?? 'Unknown Artist'}');
          }
        }
      }

      if (mounted) {
        setState(() {
          _setlist = setlist;
          _songs = setlist.songs ?? [];
        });
        debugPrint('🔄 State updated with refreshed setlist details - UI should now show ${_songs.length} songs');
      } else {
        debugPrint('⚠️ Widget not mounted, skipping state update');
      }
    } catch (e) {
      debugPrint('❌ Error refreshing setlist details: $e');
      // Don't show error messages or navigate on refresh errors
      // But ensure the user knows something went wrong in development
      if (mounted) {
        debugPrint('⚠️ Refresh failed but widget is still mounted');
      }
    }
  }

  Future<void> _fetchSetlistDetails() async {
    debugPrint('Fetching setlist details for ID: ${widget.setlistId}');
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Check if user is logged in
      if (!_isLoggedIn) {
        debugPrint('User not logged in, skipping setlist fetch');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      debugPrint('Getting setlist details from cache/API');
      final setlist = await _syncService.getSetlistById(widget.setlistId);

      if (setlist == null) {
        throw Exception('Setlist not found');
      }

      debugPrint('Setlist details received: ${setlist.name}');
      debugPrint('Songs count: ${setlist.songs?.length ?? 0}');

      if (setlist.songs != null) {
        for (var i = 0; i < setlist.songs!.length; i++) {
          debugPrint('Song $i: ${setlist.songs![i]['title'] ?? 'Unknown'}');
        }
      }

      if (mounted) {
        setState(() {
          _setlist = setlist;
          _songs = setlist.songs ?? [];
          _isLoading = false;
        });
        debugPrint('State updated with setlist details');
      }
    } catch (e) {
      debugPrint('Error fetching setlist details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // If authentication error, update login status
          if (e.toString().contains('Authentication required')) {
            _isLoggedIn = false;
          }
        });
      }

      // Show error message
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        // Check if it's an authentication error
        if (e.toString().contains('Authentication required') ||
            (e is DioException && e.response?.statusCode == 401)) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Please log in to view setlists'),
              backgroundColor: Colors.red,
            ),
          );

          // Clear auth state in UserProvider
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          await userProvider.logout(silent: true);

          // Navigate to login screen after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to load setlist details: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Start setlist presentation
  void _startSetlistPresentation() {
    if (_songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No songs in setlist to present'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Convert songs to the format expected by the presentation screen
    final List<Map<String, dynamic>> songList = [];

    for (var song in _songs) {
      if (song is Map<String, dynamic>) {
        songList.add({
          'id': song['id'] ?? '',
          'title': song['title'] ?? 'Unknown Song',
          'artist': song['artist'] is Map<String, dynamic>
              ? song['artist']['name'] ?? 'Unknown Artist'
              : song['artist'] ?? 'Unknown Artist',
          'lyrics': song['lyrics'],
          'chords': song['chords'],
          'key': song['key'],
          'capo': song['capo'],
          'tempo': song['tempo'],
          'timeSignature': song['timeSignature'],
        });
      }
    }

    // Navigate to setlist presentation screen
    Navigator.pushNamed(
      context,
      '/setlist_presentation',
      arguments: {
        'setlistName': _setlist?.name ?? widget.setlistName,
        'songs': songList,
      },
    );
  }

  // Build loading skeleton
  Widget _buildLoadingSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header skeleton
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ShimmerEffect(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Row(
              children: [
                // Title skeleton
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Present button skeleton
                Container(
                  width: 80,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 8),
                // Action buttons skeleton
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Description skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ShimmerEffect(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),

        const Divider(
          color: Color(0xFF333333),
          height: 32,
        ),

        // Songs list skeleton
        Expanded(
          child: ListView.builder(
            itemCount: 6, // Show 6 skeleton items
            itemBuilder: (context, index) => const SongListItemSkeleton(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: InnerScreenAppBar(
        title: _setlist?.name ?? 'Edit Setlist',
        centerTitle: true,
        onBackPressed: () {
          // Return modification flag to indicate if the setlist was modified
          // This will trigger a refresh in the setlist screen if needed
          debugPrint('Navigating back from setlist detail screen with result: $_hasModifiedSetlist');
          Navigator.of(context).pop(_hasModifiedSetlist);
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditSetlistDialog,
            tooltip: 'Edit Setlist',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : !_isLoggedIn
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Please log in to view setlists',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text('Log In'),
                      ),
                    ],
                  ),
                )
              : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action Buttons Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: Row(
                    children: [
                      // Present Button
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.present_to_all,
                            size: 18,
                          ),
                          label: const Text(
                            'Present',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _songs.isEmpty
                                ? Colors.grey.withValues(alpha: 0.2)
                                : AppTheme.primary,
                            foregroundColor: _songs.isEmpty
                                ? Colors.grey
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: _songs.isEmpty ? null : () {
                            // Navigate to setlist presentation
                            _startSetlistPresentation();
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Share Button
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.share,
                            size: 18,
                          ),
                          label: const Text(
                            'Share',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            side: const BorderSide(color: Colors.white24, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onPressed: () {
                            // Show share dialog
                            if (_setlist != null) {
                              showDialog(
                                context: context,
                                builder: (context) => EnhancedSetlistShareDialog(
                                  setlist: _setlist!,
                                  onSetlistUpdated: () {
                                    // Refresh setlist data after sharing
                                    _refreshSetlistData();
                                    setState(() {
                                      _hasModifiedSetlist = true;
                                    });
                                  },
                                ),
                              );
                            } else {
                              UIHelpers.showErrorSnackBar(
                                context,
                                'Unable to share setlist. Please try again.',
                              );
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Settings Button
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.settings,
                            size: 18,
                          ),
                          label: const Text(
                            'Settings',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            side: const BorderSide(color: Colors.white24, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onPressed: () {
                            // Show settings dialog
                            if (_setlist != null) {
                              showDialog(
                                context: context,
                                builder: (context) => SetlistSettingsDialog(
                                  setlist: _setlist!,
                                  onSetlistUpdated: () {
                                    // Refresh setlist data after updating settings
                                    _refreshSetlistData();
                                    setState(() {
                                      _hasModifiedSetlist = true;
                                    });
                                  },
                                ),
                              );
                            } else {
                              UIHelpers.showErrorSnackBar(
                                context,
                                'Unable to update settings. Please try again.',
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Description
                if (_setlist?.description != null && _setlist!.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 12.0),
                    child: Text(
                      _setlist!.description!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),

                // Songs List
                Expanded(
                  child: Column(
                    children: [
                      // Collaborative indicator (inside scrollable area)
                      if (_setlist?.shareCode != null || (_setlist?.collaborators?.isNotEmpty == true))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                          child: _buildCollaborativeIndicator(),
                        ),

                      // Songs content
                      Expanded(
                        child: _songs.isEmpty
                            ? const Center(
                                child: Text(
                                  'No songs in this setlist yet',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  // Force refresh setlist details
                                  await _fetchSetlistDetails();
                                },
                          color: AppTheme.primary,
                          child: ListView.builder(
                            itemCount: _songs.length,
                            itemBuilder: (context, index) {
                              final song = _songs[index];
                              debugPrint('Building song item for index $index: ${song.toString()}');

                              // Extract song data safely
                              String title = 'Unknown Song';
                              String artist = 'Unknown Artist';
                              String songId = '';

                              try {
                                if (song is Map<String, dynamic>) {
                                  title = song['title'] ?? 'Unknown Song';

                                  // Handle artist data which could be a string or a map
                                  if (song['artist'] is Map<String, dynamic>) {
                                    artist = song['artist']['name'] ?? 'Unknown Artist';
                                  } else if (song['artist'] is String) {
                                    artist = song['artist'];
                                  } else {
                                    artist = 'Unknown Artist';
                                  }

                                  songId = song['id'] ?? '';
                                  debugPrint('Extracted song data - Title: $title, Artist: $artist, ID: $songId');
                                }
                              } catch (e) {
                                debugPrint('Error extracting song data: $e');
                              }

                              return _buildSongItem(title, artist, songId);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
        onPressed: () {
          // Add new song to setlist
          _showAddSongDialog();
        },
      ),
      // Bottom navigation bar removed from inner screens
    );
  }

  Widget _buildSongItem(String title, String artist, String songId) {
    // Get the song placeholder size
    const double placeholderSize = 48.0;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF333333),
            width: 1.0,
          ),
        ),
      ),
      child: ListTile(
        // Reduce vertical padding to decrease space between items
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: const SongPlaceholder(size: placeholderSize),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          // Ensure text doesn't wrap unnecessarily
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          artist,
          style: const TextStyle(
            color: Colors.grey,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Delete button
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.grey,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                // Delete song from setlist
                _showRemoveSongDialog(songId, title);
              },
            ),
          ],
        ),
        onTap: () {
          // Navigate to song detail or chord sheet
          Navigator.pushNamed(
            context,
            '/song_detail',
            arguments: {
              'songId': songId,
              'songTitle': title,
            },
          );
        },
      ),
    );
  }

  // Build collaborative indicator widget
  Widget _buildCollaborativeIndicator() {
    final collaboratorCount = _setlist?.collaborators?.length ?? 0;
    final isShared = _setlist?.shareCode != null;
    final commentCount = _setlist?.comments?.length ?? 0;
    final allowComments = _setlist?.allowComments ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark solid color
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFFC19FFF).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Main collaborative info row
          Row(
            children: [
              Icon(
                Icons.people,
                color: const Color(0xFFC19FFF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collaborative Setlist',
                      style: const TextStyle(
                        color: Color(0xFFC19FFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isShared
                          ? collaboratorCount > 0
                              ? '$collaboratorCount collaborator${collaboratorCount > 1 ? 's' : ''}'
                              : 'Ready to be shared'
                          : 'Private setlist',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isShared) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC19FFF),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'SHARED',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Comments section (only show if comments are allowed and setlist is shared)
          if (isShared && allowComments) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: const Color(0xFFC19FFF).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  _openCollaborationCommentsScreen();
                },
                borderRadius: BorderRadius.circular(5),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment,
                        color: const Color(0xFFC19FFF),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          commentCount > 0
                              ? '$commentCount comment${commentCount > 1 ? 's' : ''}'
                              : 'Add a comment...',
                          style: TextStyle(
                            color: const Color(0xFFC19FFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: const Color(0xFFC19FFF),
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openCollaborationCommentsScreen() {
    if (_setlist != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SetlistCollaborationCommentsScreen(
            setlist: _setlist!,
            onCommentsUpdated: () {
              // Refresh setlist data when comments are updated
              _refreshSetlistData();
            },
          ),
        ),
      );
    }
  }

  void _showAddSongDialog() {
    // Check if there are liked songs
    if (_likedSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have no liked songs. Like some songs first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create a set of song IDs that are already in the setlist
    final Set<String> existingSongIds = {};

    // Extract song IDs from the setlist songs
    for (var song in _songs) {
      if (song is Map<String, dynamic> && song['id'] != null) {
        existingSongIds.add(song['id']);
      }
    }

    // Set of selected song IDs for multi-select (initially empty)
    final Set<String> selectedSongIds = {};

    // Show bottom sheet instead of dialog for better scrolling with long lists
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Makes the bottom sheet take up the full screen
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        // Calculate available height (80% of screen height)
        final availableHeight = MediaQuery.of(context).size.height * 0.8;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: availableHeight,
              ),
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 16.0 + MediaQuery.of(context).padding.bottom, // Add safe area bottom padding
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button and selection count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Songs to Setlist',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (selectedSongIds.isNotEmpty)
                            Text(
                              '${selectedSongIds.length} selected',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Instructions
                  const Text(
                    'Select songs from your liked songs:',
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 8),

                  // Song list (scrollable) - More compact
                  Expanded(
                    child: ListView.builder(
                      itemCount: _likedSongs.length,
                      itemBuilder: (context, index) {
                        final song = _likedSongs[index];
                        final bool isInSetlist = existingSongIds.contains(song.id);

                        // Initialize selection state - if song is already in setlist, it's pre-selected
                        if (isInSetlist && !selectedSongIds.contains(song.id)) {
                          // Add to selected songs if it's the first time rendering and song is in setlist
                          selectedSongIds.add(song.id);
                        }

                        final bool isSelected = selectedSongIds.contains(song.id);

                        return Container(
                          decoration: BoxDecoration(
                            border: index < _likedSongs.length - 1
                                ? const Border(
                                    bottom: BorderSide(
                                      color: Color(0xFF333333),
                                      width: 0.5,
                                    ),
                                  )
                                : null,
                            color: isInSetlist ? const Color(0xFF252525) : null, // Subtle background for existing songs
                          ),
                          child: ListTile(
                            dense: true, // Makes the list tile more compact
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    song.title,
                                    style: TextStyle(
                                      color: isSelected ? AppTheme.primary : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 15, // Slightly smaller font
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isInSetlist)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Icon(
                                      Icons.playlist_add_check,
                                      color: AppTheme.primary,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              song.artist,
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : Colors.grey,
                                fontSize: 13, // Smaller font for subtitle
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              activeColor: AppTheme.primary,
                              checkColor: Colors.black,
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedSongIds.add(song.id);
                                  } else {
                                    selectedSongIds.remove(song.id);
                                  }
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                if (selectedSongIds.contains(song.id)) {
                                  selectedSongIds.remove(song.id);
                                } else {
                                  selectedSongIds.add(song.id);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Select all button
                      TextButton.icon(
                        icon: const Icon(Icons.select_all, color: Colors.grey),
                        label: Text(
                          selectedSongIds.length == _likedSongs.length ? 'Deselect All' : 'Select All',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        onPressed: () {
                          setState(() {
                            if (selectedSongIds.length == _likedSongs.length) {
                              // If all are selected, deselect all except those already in setlist
                              selectedSongIds.clear();
                              // Re-add songs that are already in the setlist
                              for (var song in _likedSongs) {
                                if (existingSongIds.contains(song.id)) {
                                  selectedSongIds.add(song.id);
                                }
                              }
                            } else {
                              // Otherwise, select all
                              selectedSongIds.clear();
                              for (var song in _likedSongs) {
                                selectedSongIds.add(song.id);
                              }
                            }
                          });
                        },
                      ),

                      Row(
                        children: [
                          // Cancel button
                          TextButton(
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          const SizedBox(width: 8),
                          // Add button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isAddingSongs ? Colors.grey : AppTheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            onPressed: _isAddingSongs ? null : () async {
                              // Add songs to setlist logic
                              if (selectedSongIds.isNotEmpty) {
                                // Filter out songs that are already in the setlist
                                final Set<String> newSongIds = selectedSongIds.difference(existingSongIds);

                                // If no new songs to add, show message and return
                                if (newSongIds.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('All selected songs are already in the setlist'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                Navigator.of(context).pop();

                                // Store context before async operations
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);

                                // Set loading state with mounted check
                                if (mounted) {
                                  setState(() {
                                    _isAddingSongs = true;
                                  });
                                }

                                // Show loading dialog
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: const Color(0xFF1E1E1E),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Adding ${newSongIds.length} song${newSongIds.length > 1 ? "s" : ""} to setlist...',
                                            style: const TextStyle(color: Colors.white),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );

                                try {
                                  // Use bulk add API for much faster performance
                                  await _setlistService.addMultipleSongsToSetlist(widget.setlistId, newSongIds.toList());

                                  // Close loading dialog first
                                  if (mounted) {
                                    navigator.pop();
                                  }

                                  // Reset loading state and mark setlist as modified
                                  if (mounted) {
                                    setState(() {
                                      _isAddingSongs = false;
                                      _hasModifiedSetlist = true; // Mark that setlist was modified
                                    });
                                  }

                                  // Show immediate success message
                                  if (mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Added ${newSongIds.length} song${newSongIds.length > 1 ? "s" : ""} to setlist'),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }

                                  // Refresh setlist details in background to get the complete data from server
                                  if (mounted) {
                                    debugPrint('🔄 Refreshing setlist data after adding songs...');
                                    await _refreshSetlistData();
                                    debugPrint('✅ Setlist data refreshed successfully');
                                  }
                                } catch (e) {
                                  debugPrint('Error adding songs to setlist: $e');

                                  // Close loading dialog
                                  if (mounted) {
                                    navigator.pop();
                                  }

                                  // Reset loading state on error (only if mounted)
                                  if (mounted) {
                                    setState(() {
                                      _isAddingSongs = false;
                                    });
                                  }

                                  // Show error message
                                  if (mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to add songs to setlist: ${e.toString().replaceAll('Exception: ', '')}'),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              } else {
                                // Show error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select at least one song to add'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: _isAddingSongs
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                              : Text(
                                  'Add ${selectedSongIds.isNotEmpty ? "(${selectedSongIds.length})" : ""}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditSetlistDialog() {
    String newName = _setlist?.name ?? widget.setlistName;
    String newDescription = _setlist?.description ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Edit Setlist',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Setlist Name',
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary),
                  ),
                ),
                controller: TextEditingController(text: newName),
                onChanged: (value) {
                  newName = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Description (Optional)',
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary),
                  ),
                ),
                controller: TextEditingController(text: newDescription),
                onChanged: (value) {
                  newDescription = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Save',
                style: TextStyle(color: AppTheme.primary),
              ),
              onPressed: () async {
                if (newName.isNotEmpty) {
                  Navigator.of(context).pop();

                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Updating setlist...'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Color(0xFF1E1E1E),
                    ),
                  );

                  // Store context references
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  try {
                    await _setlistService.updateSetlist(
                      widget.setlistId,
                      newName,
                      description: newDescription.isNotEmpty ? newDescription : null,
                    );

                    // Mark setlist as modified
                    if (mounted) {
                      setState(() {
                        _hasModifiedSetlist = true;
                      });
                    }

                    // Refresh setlist details using simple refresh
                    if (mounted) {
                      await _refreshSetlistData();
                    }

                    // Show success message
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Setlist updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    // Show error message
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to update setlist: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  // Show error for empty name
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Setlist name cannot be empty'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showRemoveSongDialog(String songId, String songTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Remove Song',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to remove "$songTitle" from this setlist?',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();

                // Store context references
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                // Show loading indicator
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Removing song from setlist...'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Color(0xFF1E1E1E),
                  ),
                );

                try {
                  await _setlistService.removeSongFromSetlist(widget.setlistId, songId);

                  // Mark setlist as modified
                  if (mounted) {
                    setState(() {
                      _hasModifiedSetlist = true;
                    });
                  }

                  // Refresh setlist details using simple refresh
                  if (mounted) {
                    await _refreshSetlistData();
                  }

                  // Show success message
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Song "$songTitle" removed from setlist'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Show error message
                  if (mounted) {
                    // Store context in a local variable
                    final currentContext = context;
                    // Use a post-frame callback to avoid BuildContext issues
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                            content: Text('Failed to remove song: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }


}
