import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';

class PlaylistBottomSheet extends StatefulWidget {
  final Song song;

  const PlaylistBottomSheet({super.key, required this.song});

  @override
  State<PlaylistBottomSheet> createState() => _PlaylistBottomSheetState();
}

class _PlaylistBottomSheetState extends State<PlaylistBottomSheet> {
  final TextEditingController _newPlaylistController = TextEditingController();
  bool _isCreatingNewPlaylist = false;
  bool _isLoading = true;
  bool _isCreatingPlaylist = false;
  bool _isSavingSelections = false;
  String? _errorMessage;

  // Playlist service
  final PlaylistService _playlistService = PlaylistService();

  // Playlists data
  List<Playlist> _playlists = [];

  // Map to track which playlists contain the song
  Map<String, bool> _playlistContainsSong = {};

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  // Fetch playlists from the API and check which ones contain the song
  Future<void> _fetchPlaylists() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get all playlists
      final playlists = await _playlistService.getPlaylists();

      // Initialize the map to track which playlists contain the song
      final Map<String, bool> playlistContainsSong = {};

      // Check each playlist to see if it contains the song
      for (final playlist in playlists) {
        try {
          final containsSong = await _playlistService.isSongInPlaylist(playlist.id, widget.song.id);
          playlistContainsSong[playlist.id] = containsSong;
        } catch (e) {
          debugPrint('Error checking if playlist ${playlist.id} contains song: $e');
          playlistContainsSong[playlist.id] = false;
        }
      }

      if (mounted) {
        setState(() {
          _playlists = playlists;
          _playlistContainsSong = playlistContainsSong;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching playlists: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load playlists';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }

  void _toggleCreatePlaylist() {
    setState(() {
      _isCreatingNewPlaylist = !_isCreatingNewPlaylist;
    });
  }

  Future<void> _createNewPlaylist() async {
    if (_newPlaylistController.text.trim().isNotEmpty) {
      try {
        setState(() {
          _isCreatingPlaylist = true;
        });

        // Create the playlist using the service
        final playlist = await _playlistService.createPlaylist(
          _newPlaylistController.text.trim(),
          description: 'Created from song detail screen',
        );

        // Add the song to the playlist
        await _playlistService.addSongToPlaylist(playlist.id, widget.song.id);

        // Update the UI
        setState(() {
          _playlists.add(playlist);
          _playlistContainsSong[playlist.id] = true; // Mark as containing the song
          _isCreatingNewPlaylist = false;
          _isCreatingPlaylist = false;
          _newPlaylistController.clear();
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playlist created and song added!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error creating playlist: $e');

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create playlist: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }

        setState(() {
          _isCreatingPlaylist = false;
        });
      }
    }
  }

  // Toggle song in playlist (add or remove)
  Future<void> _toggleSongInPlaylist(String playlistId) async {
    try {
      setState(() {
        _isSavingSelections = true;
      });

      final bool isCurrentlyInPlaylist = _playlistContainsSong[playlistId] ?? false;

      if (isCurrentlyInPlaylist) {
        // Remove the song from the playlist
        await _playlistService.removeSongFromPlaylist(playlistId, widget.song.id);

        // Update the state
        setState(() {
          _playlistContainsSong[playlistId] = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Song removed from playlist'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Add the song to the playlist
        await _playlistService.addSongToPlaylist(playlistId, widget.song.id);

        // Update the state
        setState(() {
          _playlistContainsSong[playlistId] = true;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Song added to playlist!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling song in playlist: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update playlist: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSelections = false;
        });
      }
    }
  }

  // Save all selections and close the bottom sheet
  void _saveAndClose() {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playlists updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Close the bottom sheet
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add to Playlist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Song info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Song thumbnail placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
                const SizedBox(width: 12),
                // Song details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.song.artist,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Create new playlist button
          if (!_isCreatingNewPlaylist)
            InkWell(
              onTap: _toggleCreatePlaylist,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC701),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.add, color: Colors.black),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Create New Playlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Create new playlist form
          if (_isCreatingNewPlaylist)
            Column(
              children: [
                TextField(
                  controller: _newPlaylistController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Playlist name',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.black.withAlpha(50),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isCreatingPlaylist ? null : _toggleCreatePlaylist,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isCreatingPlaylist ? null : _createNewPlaylist,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC701),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isCreatingPlaylist
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Loading indicator
          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
                ),
              ),
            ),
          ],

          // Error message
          if (_errorMessage != null && !_isCreatingNewPlaylist) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchPlaylists,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC701),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Existing playlists
          if (!_isCreatingNewPlaylist && !_isLoading && _errorMessage == null) ...[
            const Text(
              'Your Playlists',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _playlists.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'No playlists found. Create your first playlist!',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = _playlists[index];
                        final isInPlaylist = _playlistContainsSong[playlist.id] ?? false;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.queue_music, color: Colors.white),
                          ),
                          title: Text(
                            playlist.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${playlist.songs?.length ?? 0} songs',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: _isSavingSelections && _playlistContainsSong[playlist.id] != isInPlaylist
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
                                ),
                              )
                            : Checkbox(
                                value: isInPlaylist,
                                activeColor: const Color(0xFFFFC701),
                                checkColor: Colors.black,
                                onChanged: (_) => _toggleSongInPlaylist(playlist.id),
                              ),
                          onTap: () => _toggleSongInPlaylist(playlist.id),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveAndClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC701),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
          ],

          // Add padding at the bottom for better UX with bottom navigation bar
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
