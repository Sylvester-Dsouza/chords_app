import 'package:flutter/material.dart';
import '../widgets/animated_bottom_nav_bar.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../widgets/song_placeholder.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import '../services/liked_songs_service.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/navigation_provider.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  int _currentIndex = 1; // Set to 1 for My Playlist tab

  final PlaylistService _playlistService = PlaylistService();
  final LikedSongsService _likedSongsService = LikedSongsService();
  List<Song> _likedSongs = [];

  Playlist? _playlist;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  List<dynamic> _songs = [];

  @override
  void initState() {
    super.initState();
    debugPrint('PlaylistDetailScreen initState for playlist ID: ${widget.playlistId}');

    // First check login status, then fetch playlist details
    _checkLoginStatus().then((_) {
      if (_isLoggedIn) {
        _fetchPlaylistDetails();
      }
    });
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
          _playlist = null;
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
        _playlist = null;
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

  Future<void> _fetchPlaylistDetails() async {
    debugPrint('Fetching playlist details for ID: ${widget.playlistId}');
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user is logged in
      if (!_isLoggedIn) {
        debugPrint('User not logged in, skipping playlist fetch');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      debugPrint('Calling playlist service to get playlist details');
      final playlist = await _playlistService.getPlaylist(widget.playlistId);
      debugPrint('Playlist details received: ${playlist.name}');
      debugPrint('Songs count: ${playlist.songs?.length ?? 0}');

      if (playlist.songs != null) {
        for (var i = 0; i < playlist.songs!.length; i++) {
          debugPrint('Song $i: ${playlist.songs![i]['title'] ?? 'Unknown'}');
        }
      }

      setState(() {
        _playlist = playlist;
        _songs = playlist.songs ?? [];
        _isLoading = false;
      });
      debugPrint('State updated with playlist details');
    } catch (e) {
      debugPrint('Error fetching playlist details: $e');
      setState(() {
        _isLoading = false;
        // If authentication error, update login status
        if (e.toString().contains('Authentication required')) {
          _isLoggedIn = false;
        }
      });

      // Show error message
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        // Check if it's an authentication error
        if (e.toString().contains('Authentication required') ||
            (e is DioException && e.response?.statusCode == 401)) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Please log in to view playlists'),
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
              content: Text('Failed to load playlist details: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      // Update the navigation provider
      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
      navigationProvider.updateIndex(index);

      // Pop back to the main navigation screen with the updated index
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: InnerScreenAppBar(
        title: 'Edit Playlist',
        centerTitle: true,
        onBackPressed: () {
          // Return true to indicate that the playlist was modified
          // This will trigger a refresh in the playlist screen
          debugPrint('Navigating back from playlist detail screen with result: true');
          Navigator.of(context).pop(true);
        },
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
              ),
            )
          : !_isLoggedIn
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Please log in to view playlists',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 20),
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
                )
              : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Playlist Title and Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Playlist Title
                      Expanded(
                        child: Text(
                          _playlist?.name ?? widget.playlistName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Share Button
                      IconButton(
                        icon: const Icon(
                          Icons.share,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // Share functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share functionality coming soon!'),
                              backgroundColor: Color(0xFF1E1E1E),
                            ),
                          );
                        },
                      ),

                      // Edit Button
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // Edit functionality
                          _showEditPlaylistDialog();
                        },
                      ),
                    ],
                  ),
                ),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _playlist?.description ?? 'No description',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),

                const Divider(
                  color: Color(0xFF333333),
                  height: 32,
                ),

                // Songs List
                Expanded(
                  child: _songs.isEmpty
                      ? const Center(
                          child: Text(
                            'No songs in this playlist yet',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            // Force refresh playlist details
                            await _fetchPlaylistDetails();
                          },
                          color: const Color(0xFFFFC701),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
        onPressed: () {
          // Add new song to playlist
          _showAddSongDialog();
        },
      ),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
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
                // Delete song from playlist
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

    // Create a set of song IDs that are already in the playlist
    final Set<String> existingSongIds = {};

    // Extract song IDs from the playlist songs
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
              padding: const EdgeInsets.all(16.0),
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
                            'Add Songs to Playlist',
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
                                color: Color(0xFFFFC701),
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
                        final bool isInPlaylist = existingSongIds.contains(song.id);

                        // Initialize selection state - if song is already in playlist, it's pre-selected
                        if (isInPlaylist && !selectedSongIds.contains(song.id)) {
                          // Add to selected songs if it's the first time rendering and song is in playlist
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
                            color: isInPlaylist ? const Color(0xFF252525) : null, // Subtle background for existing songs
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
                                      color: isSelected ? const Color(0xFFFFC701) : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 15, // Slightly smaller font
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isInPlaylist)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Icon(
                                      Icons.playlist_add_check,
                                      color: Color(0xFFFFC701),
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
                              activeColor: const Color(0xFFFFC701),
                              checkColor: Colors.black,
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
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
                              // If all are selected, deselect all except those already in playlist
                              selectedSongIds.clear();
                              // Re-add songs that are already in the playlist
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
                              backgroundColor: const Color(0xFFFFC701),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Add ${selectedSongIds.isNotEmpty ? "(${selectedSongIds.length})" : ""}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              // Add songs to playlist logic
                              if (selectedSongIds.isNotEmpty) {
                                // Filter out songs that are already in the playlist
                                final Set<String> newSongIds = selectedSongIds.difference(existingSongIds);

                                // If no new songs to add, show message and return
                                if (newSongIds.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('All selected songs are already in the playlist'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                Navigator.of(context).pop();

                                // Show loading indicator
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Adding ${newSongIds.length} song${newSongIds.length > 1 ? "s" : ""} to playlist...'),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: const Color(0xFF1E1E1E),
                                  ),
                                );

                                // Store context before async operations
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                int successCount = 0;
                                int failCount = 0;

                                // Add each selected song to the playlist (only new ones)
                                for (String songId in newSongIds) {
                                  try {
                                    await _playlistService.addSongToPlaylist(widget.playlistId, songId);
                                    successCount++;
                                  } catch (e) {
                                    debugPrint('Error adding song $songId to playlist: $e');
                                    failCount++;
                                  }
                                }

                                // Refresh playlist details
                                await _fetchPlaylistDetails();

                                // Show success/failure message
                                if (mounted) {
                                  if (successCount > 0) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Added $successCount song${successCount > 1 ? "s" : ""} to playlist${failCount > 0 ? " ($failCount failed)" : ""}'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else if (failCount > 0) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to add songs to playlist'),
                                        backgroundColor: Colors.red,
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

  void _showEditPlaylistDialog() {
    String newName = _playlist?.name ?? widget.playlistName;
    String newDescription = _playlist?.description ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Edit Playlist',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Playlist Name',
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFC701)),
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
                    borderSide: BorderSide(color: Color(0xFFFFC701)),
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
                style: TextStyle(color: Color(0xFFFFC701)),
              ),
              onPressed: () async {
                if (newName.isNotEmpty) {
                  Navigator.of(context).pop();

                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Updating playlist...'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Color(0xFF1E1E1E),
                    ),
                  );

                  try {
                    await _playlistService.updatePlaylist(
                      widget.playlistId,
                      newName,
                      description: newDescription.isNotEmpty ? newDescription : null,
                    );

                    // Refresh playlist details
                    await _fetchPlaylistDetails();

                    // Show success message
                    if (mounted) {
                      // Store context in a local variable
                      final currentContext = context;
                      // Use a post-frame callback to avoid BuildContext issues
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Playlist updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      });
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
                              content: Text('Failed to update playlist: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      });
                    }
                  }
                } else {
                  // Show error for empty name
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Playlist name cannot be empty'),
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
            'Are you sure you want to remove "$songTitle" from this playlist?',
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

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Removing song from playlist...'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Color(0xFF1E1E1E),
                  ),
                );

                try {
                  await _playlistService.removeSongFromPlaylist(widget.playlistId, songId);

                  // Refresh playlist details
                  await _fetchPlaylistDetails();

                  // Show success message
                  if (mounted) {
                    // Store context in a local variable
                    final currentContext = context;
                    // Use a post-frame callback to avoid BuildContext issues
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                            content: Text('Song "$songTitle" removed from playlist'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    });
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
