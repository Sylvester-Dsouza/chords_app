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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: const SongPlaceholder(),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFFC701),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          artist,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.grey,
          ),
          onPressed: () {
            // Delete song from playlist
            _showRemoveSongDialog(songId, title);
          },
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

    // Selected song
    Song? selectedSong;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Add Song to Playlist',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select a song from your liked songs:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _likedSongs.length,
                        itemBuilder: (context, index) {
                          final song = _likedSongs[index];
                          final bool isSelected = selectedSong?.id == song.id;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            title: Text(
                              song.title,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFFFFC701) : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              song.artist,
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : Colors.grey,
                              ),
                            ),
                            leading: Radio<Song>(
                              value: song,
                              groupValue: selectedSong,
                              activeColor: const Color(0xFFFFC701),
                              fillColor: WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return const Color(0xFFFFC701);
                                  }
                                  return Colors.grey;
                                },
                              ),
                              onChanged: (Song? value) {
                                setState(() {
                                  selectedSong = value;
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                selectedSong = song;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
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
                    'Add',
                    style: TextStyle(color: Color(0xFFFFC701)),
                  ),
                  onPressed: () async {
                    // Add song to playlist logic
                    if (selectedSong != null) {
                      Navigator.of(context).pop();

                      // Show loading indicator
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Adding song to playlist...'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Color(0xFF1E1E1E),
                        ),
                      );

                      // Store context and song info before async operations
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final songTitle = selectedSong!.title;

                      try {
                        // Add the song to the playlist
                        await _playlistService.addSongToPlaylist(widget.playlistId, selectedSong!.id);

                        // Refresh playlist details
                        await _fetchPlaylistDetails();

                        // Show success message
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Song "$songTitle" added to playlist'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error adding song to playlist: $e');

                        // Show error message
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to add song: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      // Show error
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a song to add'),
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
