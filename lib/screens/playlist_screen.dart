import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import '../services/liked_songs_service.dart';
import '../services/liked_songs_notifier.dart';

import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/navigation_provider.dart';

// Import our new widgets
import '../widgets/playlist_card.dart';
import '../widgets/empty_playlist_state.dart';
import '../widgets/create_playlist_dialog.dart';
import '../widgets/song_placeholder.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _currentIndex = 1; // Set to 1 for My Playlist tab

  final PlaylistService _playlistService = PlaylistService();
  final LikedSongsService _likedSongsService = LikedSongsService();
  final LikedSongsNotifier _likedSongsNotifier = LikedSongsNotifier();

  List<Playlist> _playlists = [];
  List<Song> _likedSongs = [];
  bool _isLoading = true;
  bool _isLoadingLikedSongs = false;
  bool _isLoggedIn = false;

  // Last time playlists were fetched
  DateTime? _lastFetchTime;

  // Define the fetchPlaylists method with caching
  Future<void> _fetchPlaylists({bool forceRefresh = false}) async {
    // If we already have playlists and it's not a forced refresh, don't show loading
    bool shouldShowLoading = _playlists.isEmpty || forceRefresh;

    // Check if we need to fetch (if forced or if cache is older than 5 minutes)
    bool shouldFetch = forceRefresh ||
                      _lastFetchTime == null ||
                      DateTime.now().difference(_lastFetchTime!).inMinutes > 5;

    // If we don't need to fetch and have data, return immediately
    if (!shouldFetch && _playlists.isNotEmpty) {
      debugPrint('Using cached playlists, skipping fetch');
      return;
    }

    debugPrint('Fetching playlists... (force: $forceRefresh)');
    if (mounted && shouldShowLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Only fetch playlists if user is logged in
      if (_isLoggedIn) {
        debugPrint('User is logged in, fetching playlists from service');
        final playlists = await _playlistService.getPlaylists();
        debugPrint('Received ${playlists.length} playlists from service');

        if (mounted) {
          setState(() {
            _playlists = playlists;
            _isLoading = false;
            _lastFetchTime = DateTime.now(); // Update last fetch time
          });
          debugPrint('Updated state with ${_playlists.length} playlists');
        }
      } else {
        debugPrint('User is not logged in, clearing playlists');
        if (mounted) {
          setState(() {
            _playlists = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching playlists: $e');
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          // If authentication error, clear playlists
          if (e.toString().contains('Authentication required')) {
            _playlists = [];
            _isLoggedIn = false;
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Only call _checkLoginStatus() which will call _fetchPlaylists() if authenticated
    _checkLoginStatus();

    // Register as an observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Listen for liked songs changes
    _likedSongsNotifier.addListener(_handleLikedSongsChanged);

    // Add listener for tab changes
    _tabController.addListener(_handleTabSelection);

    // Sync with navigation provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
      navigationProvider.updateIndex(1); // Playlist screen is index 1
      setState(() {
        _currentIndex = 1;
      });
    });
  }

  // Handle liked songs changes
  void _handleLikedSongsChanged() {
    debugPrint('Liked songs changed, updating liked songs tab');
    if (_tabController.index == 1) {
      // Only refresh if we're on the liked songs tab, and force refresh
      _fetchLikedSongs(forceRefresh: true);
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      // If switching to liked songs tab
      if (_tabController.index == 1) {
        // Don't force refresh when just switching tabs
        _fetchLikedSongs(forceRefresh: false);
      }

      // Update UI for tab selection
      setState(() {});
    }
  }

  // Last time liked songs were fetched
  DateTime? _lastLikedSongsFetchTime;

  // Fetch liked songs with caching
  Future<void> _fetchLikedSongs({bool forceRefresh = false}) async {
    // If we already have liked songs and it's not a forced refresh, don't show loading
    bool shouldShowLoading = _likedSongs.isEmpty || forceRefresh;

    // Check if we need to fetch (if forced or if cache is older than 5 minutes)
    bool shouldFetch = forceRefresh ||
                      _lastLikedSongsFetchTime == null ||
                      DateTime.now().difference(_lastLikedSongsFetchTime!).inMinutes > 5;

    // If we don't need to fetch and have data, return immediately
    if (!shouldFetch && _likedSongs.isNotEmpty) {
      debugPrint('Using cached liked songs, skipping fetch');
      return;
    }

    debugPrint('Fetching liked songs... (force: $forceRefresh)');
    if (mounted && shouldShowLoading) {
      setState(() {
        _isLoadingLikedSongs = true;
      });
    }

    try {
      // Only fetch liked songs if user is logged in
      if (_isLoggedIn) {
        debugPrint('User is logged in, fetching liked songs from service');
        final likedSongs = await _likedSongsService.getLikedSongs();
        debugPrint('Received ${likedSongs.length} liked songs from service');

        if (mounted) {
          setState(() {
            _likedSongs = likedSongs;
            _isLoadingLikedSongs = false;
            _lastLikedSongsFetchTime = DateTime.now(); // Update last fetch time
          });
          debugPrint('Updated state with ${_likedSongs.length} liked songs');
        }
      } else {
        debugPrint('User is not logged in, clearing liked songs');
        if (mounted) {
          setState(() {
            _likedSongs = [];
            _isLoadingLikedSongs = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching liked songs: $e');
      if (mounted) {
        setState(() {
          _isLoadingLikedSongs = false;
        });
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Use the UserProvider to check authentication status
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final isAuthenticated = await userProvider.isAuthenticated();

      // Only update state if login status changed
      bool loginStatusChanged = _isLoggedIn != isAuthenticated;

      if (loginStatusChanged) {
        setState(() {
          _isLoggedIn = isAuthenticated;
        });
      }

      // If not authenticated, clear any stale data
      if (!isAuthenticated) {
        setState(() {
          _playlists = [];
          _likedSongs = [];
          _lastFetchTime = null; // Reset cache timestamp
        });
      } else {
        // If authenticated, fetch playlists and liked songs
        // Only force refresh if login status changed
        await _fetchPlaylists(forceRefresh: loginStatusChanged);
        await _fetchLikedSongs();
      }

      debugPrint('Login status checked: $_isLoggedIn');
    } catch (e) {
      debugPrint('Error checking login status: $e');
      setState(() {
        _isLoggedIn = false;
        _playlists = [];
        _lastFetchTime = null; // Reset cache timestamp
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _likedSongsNotifier.removeListener(_handleLikedSongsChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, refresh liked songs if on that tab
    if (state == AppLifecycleState.resumed) {
      // Check which tab is active
      if (_tabController.index == 0) {
        // Playlist tab - don't force refresh
        _fetchPlaylists(forceRefresh: false);
      } else if (_tabController.index == 1) {
        // Liked songs tab - don't force refresh
        _fetchLikedSongs(forceRefresh: false);
      }
    }
  }

  Widget _buildLikedSongsTab() {
    if (_isLoadingLikedSongs) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
        ),
      );
    }

    if (!_isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please log in to view your liked songs',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC701),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Log In'),
            ),
          ],
        ),
      );
    }

    if (_likedSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No liked songs yet',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Like songs to add them to this list',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC701),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/search');
              },
              child: const Text('Find Songs'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchLikedSongs(forceRefresh: true),
      color: const Color(0xFFFFC701),
      child: ListView.builder(
        itemCount: _likedSongs.length + 1, // +1 for the extra space at the bottom
        itemBuilder: (context, index) {
          if (index == _likedSongs.length) {
            // Add extra space at the bottom for better UX
            return const SizedBox(height: 80);
          }

          final song = _likedSongs[index];
          return _buildLikedSongItem(song);
        },
      ),
    );
  }

  Widget _buildLikedSongItem(Song song) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () {
          // Navigate to song detail
          Navigator.pushNamed(
            context,
            '/song_detail',
            arguments: song,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Song image or placeholder
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC701).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  image: song.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(song.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: song.imageUrl == null
                  ? const Icon(
                      Icons.music_note,
                      color: Color(0xFFFFC701),
                      size: 24,
                    )
                  : null,
              ),
              const SizedBox(width: 12),
              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                  ],
                ),
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Key badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      song.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Unlike button
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 22,
                    ),
                    onPressed: () async {
                      // Set isLiked to false before calling the service
                      song.isLiked = false;

                      // Unlike the song
                      final success = await _likedSongsService.unlikeSong(song);
                      if (success && mounted) {
                        setState(() {
                          // Remove from liked songs
                          _likedSongs.removeWhere((s) => s.id == song.id);
                        });

                        // Notify other screens about the change
                        _likedSongsNotifier.notifySongLikeChanged(song);

                        // Show feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Removed "${song.title}" from liked songs'),
                            backgroundColor: Colors.grey,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      } else if (mounted) {
                        // If the operation failed, revert the isLiked state
                        song.isLiked = true;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'My Music',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAnimatedTabItem('My Playlists', 0),
                  ),
                  Expanded(
                    child: _buildAnimatedTabItem('Liked Songs', 1),
                  ),
                ],
              ),
            ),
          ),

          // Add some spacing
          const SizedBox(height: 16),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // My Playlists Tab
                _buildPlaylistsTab(),

                // All Liked Songs Tab
                _buildLikedSongsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFC701),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'New Playlist',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          // Show dialog to create a new playlist
          _showCreatePlaylistDialog();
        },
      ),

      );
  }

  Widget _buildPlaylistsTab() {
    // If not logged in, show login prompt
    if (!_isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please log in to view your playlists',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create and manage your playlists after logging in',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC701),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // If loading, show loading indicator
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
        ),
      );
    }

    // If no playlists, show empty state
    if (_playlists.isEmpty) {
      return EmptyPlaylistState(
        onCreatePlaylist: _showCreatePlaylistDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchPlaylists(forceRefresh: true),
      color: const Color(0xFFFFC701),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: _playlists.length + 1, // +1 for the extra space at the bottom
          itemBuilder: (context, index) {
            if (index == _playlists.length) {
              // Extra space at the bottom for FAB
              return const SizedBox(height: 100);
            }

            final playlist = _playlists[index];
            return PlaylistCard(
              playlist: playlist,
              onTap: () {
                // Navigate to playlist details
                Navigator.pushNamed(
                  context,
                  '/playlist_detail',
                  arguments: {
                    'playlistId': playlist.id,
                    'playlistName': playlist.name,
                  },
                ).then((result) {
                  // Only refresh if something changed (like songs added/removed)
                  if (result == true) {
                    // Force refresh only if explicitly told to
                    _fetchPlaylists(forceRefresh: true);
                  }
                });
              },
              onDelete: () => _showDeletePlaylistDialog(playlist.id, playlist.name),
              onEdit: () => _showEditPlaylistDialog(playlist),
              onShare: () => _sharePlaylist(playlist),
            );
          },
        ),
      ),
    );
  }



  // New animated tab item
  Widget _buildAnimatedTabItem(String title, int index) {
    bool isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFC701) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }



  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CreatePlaylistDialog(
          onCreatePlaylist: (name, description) async {
            Navigator.of(dialogContext).pop();

            // Show loading indicator
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Creating playlist...'),
                duration: Duration(seconds: 1),
                backgroundColor: Color(0xFF1E1E1E),
              ),
            );

            try {
              // Check if user is logged in first
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              if (!userProvider.isLoggedIn) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Please log in to create playlists'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Proceed with creation
              final createdPlaylist = await _playlistService.createPlaylist(
                name,
                description: description,
              );

              debugPrint('Created playlist: ${createdPlaylist.id} - ${createdPlaylist.name}');

              // Refresh playlists with force refresh
              await _fetchPlaylists(forceRefresh: true);

              // Show success message
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Playlist "$name" created successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              // Show error message
              if (mounted) {
                // Check if it's an authentication error
                if (e.toString().contains('Authentication required') ||
                    (e is DioException && e.response?.statusCode == 401)) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to create playlists'),
                      backgroundColor: Colors.red,
                    ),
                  );

                  // Don't automatically log out or redirect
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to create playlist: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
        );
      },
    );
  }

  void _showDeletePlaylistDialog(String playlistId, String playlistName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with warning icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Delete Playlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Warning message
                Text(
                  'Are you sure you want to delete "$playlistName"?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone and all songs in this playlist will be removed.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel button
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[400],
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),

                    // Delete button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();

                        // Show loading indicator
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Deleting playlist...'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Color(0xFF1E1E1E),
                          ),
                        );

                        try {
                          // Check if user is logged in first
                          final userProvider = Provider.of<UserProvider>(context, listen: false);
                          if (!userProvider.isLoggedIn) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please log in to delete playlists'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Proceed with deletion
                          await _playlistService.deletePlaylist(playlistId);

                          // Refresh playlists with force refresh
                          await _fetchPlaylists(forceRefresh: true);

                          // Show success message
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Playlist "$playlistName" deleted successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          // Show error message
                          if (mounted) {
                            // Check if it's an authentication error
                            if (e.toString().contains('Authentication required') ||
                                (e is DioException && e.response?.statusCode == 401)) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Please log in to delete playlists'),
                                  backgroundColor: Colors.red,
                                ),
                              );

                              // Don't automatically log out or redirect
                            } else {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete playlist: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to show edit playlist dialog
  void _showEditPlaylistDialog(Playlist playlist) {
    // Create text editing controllers with initial values
    final nameController = TextEditingController(text: playlist.name);
    final descriptionController = TextEditingController(text: playlist.description ?? '');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with edit icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Edit Playlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name field
                const Text(
                  'Name',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter playlist name',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Description field
                const Text(
                  'Description (Optional)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter playlist description',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel button
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[400],
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),

                    // Save button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        // Validate input
                        final name = nameController.text.trim();
                        final description = descriptionController.text.trim();

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a playlist name'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.of(dialogContext).pop();

                        // Show loading indicator
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Updating playlist...'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Color(0xFF1E1E1E),
                          ),
                        );

                        try {
                          // Check if user is logged in first
                          final userProvider = Provider.of<UserProvider>(context, listen: false);
                          if (!userProvider.isLoggedIn) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please log in to edit playlists'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Proceed with update
                          await _playlistService.updatePlaylist(
                            playlist.id,
                            name,
                            description: description.isNotEmpty ? description : null,
                          );

                          // Refresh playlists with force refresh
                          await _fetchPlaylists(forceRefresh: true);

                          // Show success message
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Playlist "$name" updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          // Show error message
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to update playlist: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to share playlist
  void _sharePlaylist(Playlist playlist) {
    // For now, just show a snackbar since we don't have actual sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${playlist.name}" playlist (Coming soon)'),
        backgroundColor: const Color(0xFF1E1E1E),
        action: SnackBarAction(
          label: 'OK',
          textColor: const Color(0xFF4FC3F7),
          onPressed: () {},
        ),
      ),
    );
  }
}