import 'package:flutter/material.dart';
import 'dart:async';
import '../models/song.dart';
import '../widgets/playlist_bottom_sheet.dart';
import '../widgets/chord_formatter.dart';
import '../services/song_service.dart';
import '../services/liked_songs_service.dart';
import '../services/comment_service.dart';
import '../services/rating_service.dart';
import '../widgets/chord_diagram_bottom_sheet.dart';
// Import the new YouTube iFrame players
import '../widgets/youtube_iframe_bottom_sheet.dart';
import '../widgets/floating_youtube_iframe_player.dart';
import '../widgets/star_rating.dart';
import '../config/theme.dart';
import './comments_screen.dart';


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
  double _fontSize = 14.0; // Reduced default font size from 16.0 to 14.0
  int _transposeValue = 0;
  bool _isAutoScrollEnabled = false;
  double _autoScrollSpeed = 1.0;
  bool _isLoading = true;
  bool _isRatingLoading = false;
  String? _errorMessage;

  // Floating video player state
  bool _isVideoPlaying = false;
  String? _currentVideoUrl;
  String? _currentVideoTitle;

  // Services
  final SongService _songService = SongService();
  final LikedSongsService _likedSongsService = LikedSongsService();
  final CommentService _commentService = CommentService();
  final RatingService _ratingService = RatingService();

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
      // Check if the song is liked from the API, fetch comment count, and rating info
      _checkIfSongIsLiked();
      _fetchCommentCount();
      _fetchRatingInfo(); // Add this to fetch rating info even when song is passed
    } else {
      // Fetch song data from the API
      _fetchSongData();
    }
  }

  // Check if the song is liked from the API
  Future<void> _checkIfSongIsLiked() async {
    try {
      // Use the updated LikedSongsService which checks both local storage and server
      final isLiked = await _likedSongsService.isSongLiked(_song.id);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _song.isLiked = isLiked;
        });
        debugPrint('Song ${_song.title} is liked: $isLiked');
      }
    } catch (e) {
      debugPrint('Error checking if song is liked: $e');
      // If there's an error, we'll use the value from the song object
      if (mounted) {
        setState(() {
          _isLiked = _song.isLiked;
        });
        debugPrint('Using fallback liked status for ${_song.title}: ${_song.isLiked}');
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

  // Fetch rating information for the song
  Future<void> _fetchRatingInfo() async {
    try {
      setState(() {
        _isRatingLoading = true;
      });

      // Get song rating stats and user's rating
      final updatedSong = await _ratingService.updateSongWithRatingInfo(_song);

      if (mounted) {
        setState(() {
          _song = updatedSong;
          _isRatingLoading = false;
        });
      }

      debugPrint('Song rating info: Average: ${_song.averageRating}, Count: ${_song.ratingCount}, User Rating: ${_song.userRating}');
    } catch (e) {
      debugPrint('Error fetching rating info: $e');
      if (mounted) {
        setState(() {
          _isRatingLoading = false;
        });
      }
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

      // Check if the song is liked from the API, fetch comment count, and rating info
      await _checkIfSongIsLiked();
      await _fetchCommentCount();
      await _fetchRatingInfo();
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
      } else {
        // Show feedback with correct message based on the new state
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isLiked
                  ? 'Added "${_song.title}" to liked songs'
                  : 'Removed "${_song.title}" from liked songs'
              ),
              backgroundColor: _isLiked ? Colors.green : Colors.grey,
              duration: const Duration(seconds: 1),
            ),
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
    // Update the state
    setState(() {
      _isAutoScrollEnabled = !_isAutoScrollEnabled;
    });

    if (_isAutoScrollEnabled) {
      // Start the auto-scroll
      _startAutoScroll();
    } else {
      // Stop the auto-scroll
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

  // Rate a song
  Future<void> _rateSong(int rating) async {
    try {
      setState(() {
        _isRatingLoading = true;
        // Immediately update the UI with the new rating
        _song.userRating = rating;
      });

      // Call the API to rate the song
      final success = await _ratingService.rateSong(_song.id, rating);

      if (success) {
        // Update the song's rating info
        await _fetchRatingInfo();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You rated "${_song.title}" $rating stars'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          // Reset the user rating if the API call failed
          setState(() {
            _song.userRating = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to rate song. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error rating song: $e');
      if (mounted) {
        // Reset the user rating if there was an error
        setState(() {
          _song.userRating = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRatingLoading = false;
        });
      }
    }
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
                            color: Theme.of(context).colorScheme.primary,
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
      body: Stack(
        children: [
          _buildBody(),

          // Floating video player (only show when video is playing)
          if (_isVideoPlaying && _currentVideoUrl != null)
            FloatingYoutubeIframePlayer(
              videoUrl: _currentVideoUrl!,
              title: _currentVideoTitle ?? 'Now Playing',
              onClose: () {
                setState(() {
                  _isVideoPlaying = false;
                  _currentVideoUrl = null;
                  _currentVideoTitle = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Song details section (Ultimate Guitar style)
          _buildSongDetailsSection(),

          // Divider between details and content
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 3.0),
            child: Divider(
              color: Color(0xFF333333),
              thickness: 1,
            ),
          ),

          // Lyrics and chords
          ..._parseLyricsAndChords(),

          // Divider before rating section
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(
              color: Color(0xFF333333),
              thickness: 1,
            ),
          ),

          // Rating section
          _buildRatingSection(),

          // Add some padding at the bottom for better scrolling
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSongDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Song title
        Text(
          _song.title,
          style: AppTheme.songTitleStyle,
        ),
        const SizedBox(height: 4),

        // Artist name
        Text(
          _song.artist,
          style: AppTheme.artistNameStyle,
        ),
        const SizedBox(height: 8),

        // Rating information
        if (_song.ratingCount > 0) ...[
          Row(
            children: [
              StarRating(
                rating: _song.averageRating,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
                showRating: true,
              ),
              const SizedBox(width: 4),
              Text(
                '(${_song.ratingCount} ${_song.ratingCount == 1 ? 'rating' : 'ratings'})',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Song details in a grid layout
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              // Key pill
              _buildDetailPill(
                icon: Icons.music_note,
                label: 'Key',
                value: _song.key,
              ),

              // Capo pill (if available)
              if (_song.capo != null && _song.capo! > 0)
                _buildDetailPill(
                  icon: Icons.tune,
                  label: 'Capo',
                  value: _song.capo.toString(),
                ),

              // Time signature pill (if available)
              if (_song.timeSignature != null && _song.timeSignature!.isNotEmpty)
                _buildDetailPill(
                  icon: Icons.timer,
                  label: 'Time',
                  value: _song.timeSignature!,
                ),

              // Tempo pill (if available)
              if (_song.tempo != null && _song.tempo! > 0)
                _buildDetailPill(
                  icon: Icons.speed,
                  label: 'Tempo',
                  value: '${_song.tempo} BPM',
                ),

              // Difficulty pill (if available)
              if (_song.difficulty != null && _song.difficulty!.isNotEmpty)
                _buildDetailPill(
                  icon: Icons.bar_chart,
                  label: 'Difficulty',
                  value: _song.difficulty!,
                ),

              // Language pill (if available)
              if (_song.language != null)
                _buildDetailPill(
                  icon: Icons.language,
                  label: 'Language',
                  value: _song.language!['name'] ?? 'Unknown',
                ),

              // Video links (if available)
              if (_song.officialVideoUrl != null && _song.officialVideoUrl!.isNotEmpty)
                _buildDetailPill(
                  icon: Icons.music_video,
                  label: 'Video',
                  value: 'Available',
                  onTap: () => _showVideoOptions(),
                ),

              // Tutorial video (if available)
              if (_song.tutorialVideoUrl != null && _song.tutorialVideoUrl!.isNotEmpty)
                _buildDetailPill(
                  icon: Icons.school,
                  label: 'Tutorial',
                  value: 'Available',
                  onTap: () => _showVideoOptions(),
                ),
            ],
          ),
        ),

        // Tags (if available)
        if (_song.tags != null && _song.tags!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.tag,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _song.tags!.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ],
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
              style: TextStyle(
                color: Colors.grey,
                fontFamily: AppTheme.primaryFontFamily,
              ),
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
        // Use the primary color from the theme for chords
        chordColor: Theme.of(context).colorScheme.primary,
      ),
    ];
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000), // Black with 20% opacity
            blurRadius: 8,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: _isAutoScrollEnabled
          // When auto-scroll is enabled, show minimal controls
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Exit auto-scroll mode button
                _buildBottomNavButton(
                  icon: Icons.close,
                  label: 'Exit',
                  onPressed: () {
                    _toggleAutoScroll(); // This will stop auto-scroll
                  },
                ),

                // Auto-scroll button (center, prominent)
                _buildScrollButton(),

                // Speed button
                _buildBottomNavButton(
                  icon: Icons.speed_outlined,
                  label: 'Speed',
                  onPressed: _showSpeedBottomSheet,
                ),
              ],
            )
          // When auto-scroll is disabled, show all controls
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Toggle chords button
                _buildBottomNavButton(
                  icon: _showChords ? Icons.music_note : Icons.music_note_outlined,
                  label: 'Chords',
                  isActive: _showChords,
                  onPressed: _toggleChordsVisibility,
                ),

                // Font size button
                _buildBottomNavButton(
                  icon: Icons.format_size,
                  label: 'Font',
                  onPressed: _showFontSizeBottomSheet,
                ),

                // Auto-scroll button (center, prominent)
                _buildScrollButton(),

                // Video button
                _buildBottomNavButton(
                  icon: Icons.video_library_outlined,
                  label: 'Video',
                  onPressed: _showVideoOptions,
                ),

                // Print button
                _buildBottomNavButton(
                  icon: Icons.print_outlined,
                  label: 'Print',
                  onPressed: _printChordSheet,
                ),
              ],
            ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            'Rate This Song',
            style: AppTheme.sectionTitleStyle,
          ),
        ),

        // Rating UI
        Center(
          child: Column(
            children: [
              // Current average rating display
              if (_song.ratingCount > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StarRating(
                      rating: _song.averageRating,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                      showRating: true,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_song.ratingCount} ${_song.ratingCount == 1 ? 'rating' : 'ratings'})',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // User's rating
              const Text(
                'Your Rating:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              InteractiveStarRating(
                initialRating: _song.userRating ?? 0,
                onRatingChanged: _rateSong,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
                showLabel: true,
              ),

              // Thank you message if user has rated
              if (_song.userRating != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Thanks for rating!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Build a detail pill for song information
  Widget _buildDetailPill({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '$label: $value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollButton() {
    // Light purple color
    const Color lightPurple = Color(0xFFC19FFF);

    return InkWell(
      onTap: _toggleAutoScroll,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isAutoScrollEnabled ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: _isAutoScrollEnabled ? Colors.redAccent : lightPurple,
              size: 24,
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 14,
              child: Text(
                _isAutoScrollEnabled ? 'Pause' : 'Play',
                style: TextStyle(
                  color: _isAutoScrollEnabled ? Colors.redAccent : lightPurple,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Font Size',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.text_fields, color: Colors.white, size: 16),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 10, // Reduced minimum font size for more flexibility
                      max: 28, // Increased maximum font size for better readability
                      divisions: 9, // More divisions for finer control
                      label: _fontSize.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          this.setState(() {
                            _fontSize = value;
                          });
                        });
                      },
                    ),
                  ),
                  const Icon(Icons.text_fields, color: Colors.white, size: 24),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      this.setState(() {
                        _fontSize = 14.0; // Reset to new default
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpeedBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scroll Speed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.speed, color: Colors.white, size: 16),
                  Expanded(
                    child: Slider(
                      value: _autoScrollSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,
                      label: '${_autoScrollSpeed.toStringAsFixed(1)}x',
                      onChanged: (value) {
                        setState(() {
                          this.setState(() {
                            _autoScrollSpeed = value;
                          });
                        });
                      },
                    ),
                  ),
                  const Icon(Icons.speed, color: Colors.white, size: 24),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      this.setState(() {
                        _autoScrollSpeed = 1.0; // Reset to default
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _printChordSheet() {
    // Show a bottom sheet with print options
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Print Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.white),
              title: const Text('Save as PDF', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _saveToPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.white),
              title: const Text('Print', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _sendToPrinter();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _shareChordSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveToPdf() {
    // Show a success message for now
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chord sheet saved as PDF'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sendToPrinter() {
    // Show a success message for now
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sent to printer'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareChordSheet() {
    // Show a success message for now
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chord sheet shared'),
        backgroundColor: Colors.green,
      ),
    );
  }



  void _showVideoOptions() {
    // Check if any video URLs are available
    final bool hasTutorialVideo = _song.tutorialVideoUrl != null && _song.tutorialVideoUrl!.isNotEmpty;
    final bool hasOfficialVideo = _song.officialVideoUrl != null && _song.officialVideoUrl!.isNotEmpty;

    // Show a bottom sheet with video options
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Video Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Tutorial video option (only show if available)
            if (hasTutorialVideo)
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.white),
                title: const Text('Watch Tutorial', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showYouTubeVideo(_song.tutorialVideoUrl!, 'Tutorial: ${_song.title}');
                },
              ),

            // Official music video option (only show if available)
            if (hasOfficialVideo)
              ListTile(
                leading: const Icon(Icons.music_video, color: Colors.white),
                title: const Text('Watch Music Video', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showYouTubeVideo(_song.officialVideoUrl!, 'Music Video: ${_song.title}');
                },
              ),

            // No videos available message
            if (!hasTutorialVideo && !hasOfficialVideo)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No videos are currently available for this song.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showYouTubeVideo(String videoUrl, String title) {
    // Check if the URL is empty or invalid
    if (videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video URL available for this song.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Log the video URL for debugging
    debugPrint('Opening YouTube video: $videoUrl');

    // Show dialog to choose between floating player and bottom sheet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Choose Video Mode',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Would you like to watch the video in a floating window (so you can still see the chord sheet) or in full view?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Start floating player
              setState(() {
                _isVideoPlaying = true;
                _currentVideoUrl = videoUrl;
                _currentVideoTitle = title;
              });
            },
            child: const Text('Floating'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Show in bottom sheet (original behavior)
              _showVideoBottomSheet(videoUrl, title);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC19FFF), // Light purple
            ),
            child: const Text('Full View'),
          ),
        ],
      ),
    );
  }

  // Show video in bottom sheet (using the new iFrame player)
  void _showVideoBottomSheet(String videoUrl, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7, // Increased to 70% of screen height
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: YouTubeIframeBottomSheet(
          videoUrl: videoUrl,
          title: title,
        ),
      ),
    );
  }



  Widget _buildBottomNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFFFC701) : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 14,
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFFFFC701) : Colors.white70,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
