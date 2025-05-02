import 'package:flutter/material.dart';
import 'dart:async';
import '../models/song.dart';
import '../widgets/playlist_bottom_sheet.dart';
import '../widgets/chord_formatter.dart';
import '../services/song_service.dart';
import '../services/liked_songs_service.dart';
import '../services/comment_service.dart';
import '../widgets/chord_diagram_bottom_sheet.dart';
import './comments_screen.dart';
import 'package:google_fonts/google_fonts.dart';


class SongDetailScreen extends StatefulWidget {
  final Song? song;
  final String? songId;

  const SongDetailScreen({super.key, this.song, this.songId});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  // UI state
  bool _isLiked = false;
  bool _showChords = true;
  double _fontSize = 16.0;
  int _transposeValue = 0;
  bool _isAutoScrollEnabled = false;
  double _autoScrollSpeed = 1.0;
  bool _isLoading = true;
  String? _errorMessage;

  // Services
  final SongService _songService = SongService();
  final LikedSongsService _likedSongsService = LikedSongsService();
  final CommentService _commentService = CommentService();

  // Scroll controller for auto-scroll
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;

  // Song data
  late Song _song;

  @override
  void initState() {
    super.initState();

    if (widget.song != null) {
      // Use the song passed from the previous screen
      _song = widget.song!;
      _isLoading = false;
      // Check if the song is liked from the API and fetch comment count
      _checkIfSongIsLiked();
      _fetchCommentCount();
    } else {
      // Fetch song data from the API
      _fetchSongData();
    }
  }

  // Check if the song is liked from the API
  Future<void> _checkIfSongIsLiked() async {
    try {
      final isLiked = await _likedSongsService.isSongLiked(_song.id);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _song.isLiked = isLiked;
        });
      }
    } catch (e) {
      debugPrint('Error checking if song is liked: $e');
      // If there's an error, we'll use the value from the song object
      if (mounted) {
        setState(() {
          _isLiked = _song.isLiked;
        });
      }
    }
  }

  // Fetch comment count for the song
  Future<void> _fetchCommentCount() async {
    try {
      final count = await _commentService.getCommentCount(_song.id);
      if (mounted) {
        setState(() {
          _song.commentCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error fetching comment count: $e');
      // If there's an error, we'll keep the existing count
      // No need to set a default value since it's already initialized to 0 in the constructor
    }
  }

  // Fetch song data from the API
  Future<void> _fetchSongData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the songId from the widget if available, otherwise use a default ID
      final String songId = widget.songId ?? 'song-1';
      final song = await _songService.getSongById(songId);

      // Set the song data
      if (mounted) {
        setState(() {
          _song = song;
          _isLoading = false;
        });
      }

      // Check if the song is liked from the API and fetch comment count
      await _checkIfSongIsLiked();
      await _fetchCommentCount();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load song: $e';
          _isLoading = false;

          // Use a fallback song in case of error
          _song = Song(
            id: widget.songId ?? 'error-song',
            title: 'Song Not Found',
            artist: 'Unknown Artist',
            key: 'C',
            chords: '[No chords available]',
            isLiked: false,
            commentCount: 0,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  // Toggle like status
  Future<void> _toggleLike() async {
    final previousState = _isLiked;

    // Optimistically update UI
    setState(() {
      _isLiked = !_isLiked;
      _song.isLiked = _isLiked;
    });

    try {
      // Update like status in the database using LikedSongsService
      bool success;
      if (_isLiked) {
        success = await _likedSongsService.likeSong(_song);
      } else {
        success = await _likedSongsService.unlikeSong(_song);
      }

      if (!success) {
        // If the API call failed, revert to previous state
        setState(() {
          _isLiked = previousState;
          _song.isLiked = previousState;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update like status')),
          );
        }
      }
    } catch (e) {
      // If there was an error, revert to previous state
      setState(() {
        _isLiked = previousState;
        _song.isLiked = previousState;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Toggle chord visibility
  void _toggleChordsVisibility() {
    setState(() {
      _showChords = !_showChords;
    });
  }

  void _showChordDiagram(String chordName) {
    // Clean up the chord name (remove any brackets)
    final cleanChordName = chordName.replaceAll(RegExp(r'[\[\]]'), '');

    // Show the bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChordDiagramBottomSheet(chordName: cleanChordName),
    );
  }



  // Note: Transposition is handled by the ChordFormatter widget
  // based on the _transposeValue

  // Toggle auto-scroll
  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrollEnabled = !_isAutoScrollEnabled;
    });

    if (_isAutoScrollEnabled) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  // Start auto-scroll
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double currentScroll = _scrollController.offset;
        final double delta = 0.5 * _autoScrollSpeed;

        if (currentScroll < maxScroll) {
          _scrollController.jumpTo(currentScroll + delta);
        } else {
          _stopAutoScroll();
          setState(() {
            _isAutoScrollEnabled = false;
          });
        }
      }
    });
  }

  // Stop auto-scroll
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  // Show add to playlist bottom sheet
  void _showAddToPlaylistSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PlaylistBottomSheet(song: _song),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
        actions: _isLoading
            ? []
            : [
                // Like button
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.white,
                    size: 24,
                  ),
                  onPressed: _toggleLike,
                ),
                // Comment icon with count
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.comment, color: Colors.white, size: 24),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentsScreen(song: _song),
                          ),
                        ).then((_) => _fetchCommentCount()); // Refresh comment count when returning
                      },
                    ),
                    if (_song.commentCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC701),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _song.commentCount > 99 ? '99+' : _song.commentCount.toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                // Add to playlist button
                IconButton(
                  icon: const Icon(Icons.playlist_add, color: Colors.white, size: 24),
                  onPressed: _showAddToPlaylistSheet,
                ),
                // Three-dot menu
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
                  onPressed: () {
                    // TODO: Implement menu functionality
                  },
                ),
              ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading song',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchSongData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC701),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Lyrics and chords content
        Expanded(
          child: _buildLyricsContent(),
        ),

        // Bottom navigation
        _buildBottomNavigation(),
      ],
    );
  }



  Widget _buildLyricsContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Song title and artist
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _song.title,
                  style: GoogleFonts.lexend(
                    color: const Color(0xFFFFC701),
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _song.artist,
                  style: GoogleFonts.lexend(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),


          // Lyrics and chords
          ..._parseLyricsAndChords(),

          // Add some padding at the bottom for better scrolling
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  List<Widget> _parseLyricsAndChords() {
    // If there are no chords, return an empty list
    if (_song.chords == null || _song.chords!.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              'No chord sheet available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        )
      ];
    }

    // Use the ChordFormatter widget to format the chords
    return [
      ChordFormatter(
        chordSheet: _song.chords!,
        fontSize: _fontSize,
        highlightChords: _showChords,
        transposeValue: _transposeValue,
        onChordTap: _showChordDiagram,
      ),
    ];
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: const Border(
          top: BorderSide(
            color: Color(0xFF333333),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Toggle chords button
          _buildBottomNavButton(
            icon: Icons.music_note,
            label: 'Chords',
            isActive: _showChords,
            onPressed: _toggleChordsVisibility,
          ),

          // Font size button
          _buildBottomNavButton(
            icon: Icons.text_fields,
            label: 'Font',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text('Font Size', style: TextStyle(color: Colors.white)),
                  content: Slider(
                    value: _fontSize,
                    min: 12,
                    max: 24,
                    divisions: 6,
                    label: _fontSize.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _fontSize = value;
                      });
                    },
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),

          // Auto-scroll button
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _isAutoScrollEnabled ? Colors.red : const Color(0xFFFFC701),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isAutoScrollEnabled ? Colors.red : const Color(0xFFFFC701)).withAlpha(50),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isAutoScrollEnabled ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
                size: 28,
              ),
              onPressed: _toggleAutoScroll,
              padding: EdgeInsets.zero,
            ),
          ),

          // Speed button
          _buildBottomNavButton(
            icon: Icons.speed,
            label: 'Speed',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text('Scroll Speed', style: TextStyle(color: Colors.white)),
                  content: Slider(
                    value: _autoScrollSpeed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: '${_autoScrollSpeed.toStringAsFixed(1)}x',
                    onChanged: (value) {
                      setState(() {
                        _autoScrollSpeed = value;
                      });
                    },
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),

          // Share button
          _buildBottomNavButton(
            icon: Icons.share,
            label: 'Share',
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFC701).withAlpha(40) : Colors.black.withAlpha(40),
            shape: BoxShape.circle,
            border: isActive ? Border.all(color: const Color(0xFFFFC701), width: 1) : null,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive ? const Color(0xFFFFC701) : Colors.white,
              size: 22
            ),
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFFFFC701) : Colors.white,
            fontSize: 12
          ),
        ),
      ],
    );
  }
}
