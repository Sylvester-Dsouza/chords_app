import 'package:flutter/material.dart';
import 'dart:async';
import '../models/song.dart';
import '../models/karaoke.dart';
import '../widgets/setlist_bottom_sheet.dart';
import '../widgets/chord_formatter.dart';
import '../services/song_service.dart';
import '../services/liked_songs_service.dart';
import '../services/comment_service.dart';
import '../services/rating_service.dart';
import '../services/pdf_service.dart';
import '../services/analytics_service.dart';
import '../widgets/chord_diagram_bottom_sheet.dart';
// Import the new YouTube iFrame players
import '../widgets/youtube_iframe_bottom_sheet.dart';
import '../widgets/floating_youtube_iframe_player.dart';
import '../widgets/star_rating.dart';
import '../config/theme.dart';
import './comments_screen.dart';
import '../utils/chord_extractor.dart';
import './song_presentation_screen.dart';
import './practice_mode_screen.dart';
import '../widgets/enhanced_song_share_dialog.dart';
import './multi_track_karaoke_player_screen.dart';

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
  int _transposeValue = 0; // Made mutable for transpose functionality
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
  final PdfService _pdfService = PdfService();
  final AnalyticsService _analyticsService = AnalyticsService();

  // Scroll controller for auto-scroll
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _userIsScrolling = false;
  double _lastAutoScrollPosition = 0.0;
  Timer? _userScrollTimer;
  bool _autoScrollPaused = false;

  // Song data
  late Song _song;

  @override
  void initState() {
    super.initState();

    // Add scroll listener to detect manual scrolling
    _scrollController.addListener(_onScrollChanged);

    if (widget.song != null) {
      // Use the song passed from the previous screen
      _song = widget.song!;
      _isLoading = false;
      
      // Debug the initial song data
      debugPrint('🎵 === INITIAL SONG DATA DEBUG ===');
      debugPrint('🎵 Song: ${_song.title}');
      debugPrint('🎵 Has karaoke: ${_song.karaoke != null}');
      if (_song.karaoke != null) {
        debugPrint('🎵 Karaoke tracks: ${_song.karaoke!.tracks.length}');
        debugPrint('🎵 Karaoke status: ${_song.karaoke!.status}');
        for (int i = 0; i < _song.karaoke!.tracks.length; i++) {
          final track = _song.karaoke!.tracks[i];
          debugPrint('🎵   Track $i: ${track.trackType.displayName} - Status: ${track.status}');
        }
      }
      debugPrint('🎵 _hasKaraokeAvailable: $_hasKaraokeAvailable');
      debugPrint('🎵 ================================');
      
      // Check if the song is liked from the API, fetch comment count, and rating info
      _checkIfSongIsLiked();
      _fetchCommentCount();
      _fetchRatingInfo(); // Add this to fetch rating info even when song is passed

      // Track song view
      _trackSongView();
    } else {
      // Fetch song data from the API
      _fetchSongData();
    }
  }

  // Check if the song is liked from the API
  Future<void> _checkIfSongIsLiked() async {
    try {
      // Add null safety checks
      if (_song.id.isEmpty) {
        debugPrint('Cannot check liked status: song ID is empty');
        if (mounted) {
          setState(() {
            _isLiked = false;
            _song.isLiked = false;
          });
        }
        return;
      }

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
      // If there's an error, we'll use the value from the song object or set a safe default
      if (mounted) {
        setState(() {
          _isLiked = _song.isLiked;
        });
        debugPrint(
          'Using fallback liked status for ${_song.title}: ${_song.isLiked}',
        );
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

      debugPrint(
        'Song rating info: Average: ${_song.averageRating}, Count: ${_song.ratingCount}, User Rating: ${_song.userRating}',
      );
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
        
        // Debug the fetched song data
        debugPrint('🎵 === FETCHED SONG DATA DEBUG ===');
        debugPrint('🎵 Song: ${_song.title}');
        debugPrint('🎵 Has karaoke: ${_song.karaoke != null}');
        if (_song.karaoke != null) {
          debugPrint('🎵 Karaoke tracks: ${_song.karaoke!.tracks.length}');
          debugPrint('🎵 Karaoke status: ${_song.karaoke!.status}');
          for (int i = 0; i < _song.karaoke!.tracks.length; i++) {
            final track = _song.karaoke!.tracks[i];
            debugPrint('🎵   Track $i: ${track.trackType.displayName} - Status: ${track.status}');
          }
        }
        debugPrint('🎵 _hasKaraokeAvailable: $_hasKaraokeAvailable');
        debugPrint('🎵 =================================');
      }

      // Check if the song is liked from the API, fetch comment count, and rating info
      await _checkIfSongIsLiked();
      await _fetchCommentCount();
      await _fetchRatingInfo();

      // Track song view
      _trackSongView();
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

  // Track song view for analytics
  void _trackSongView() {
    if (_song.id.isNotEmpty) {
      _analyticsService.trackSongView(_song.id, source: 'song_detail_screen');
    }
  }

  // Handle scroll changes to detect manual scrolling
  void _onScrollChanged() {
    if (_isAutoScrollEnabled && _scrollController.hasClients) {
      final currentPosition = _scrollController.offset;

      // Check if the user manually scrolled (position changed significantly from auto-scroll)
      if ((currentPosition - _lastAutoScrollPosition).abs() > 2.0) {
        if (!_userIsScrolling) {
          _userIsScrolling = true;
          _autoScrollPaused = true;
          setState(() {}); // Update UI to show paused state

          // Show a brief notification that auto-scroll is paused
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Auto-scroll paused - will resume in 2 seconds',
              ),
              duration: const Duration(milliseconds: 1500),
              backgroundColor: AppTheme.warning.withValues(alpha: 0.8),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );

          // Pause auto-scroll temporarily when user scrolls manually
          _pauseAutoScrollTemporarily();
        }

        // Reset the timer each time user scrolls
        _resetUserScrollTimer();
      }
    }
  }

  // Reset the user scroll timer
  void _resetUserScrollTimer() {
    _userScrollTimer?.cancel();
    _userScrollTimer = Timer(const Duration(seconds: 2), () {
      // User stopped scrolling, resume auto-scroll
      _userIsScrolling = false;
      _autoScrollPaused = false;
      setState(() {}); // Update UI

      if (_isAutoScrollEnabled) {
        _startAutoScroll();
      }
    });
  }

  // Temporarily pause auto-scroll when user scrolls manually
  void _pauseAutoScrollTemporarily() {
    _stopAutoScroll();
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _userScrollTimer?.cancel();
    _scrollController.removeListener(_onScrollChanged);
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
                    : 'Removed "${_song.title}" from liked songs',
              ),
              backgroundColor:
                  _isLiked ? AppTheme.success : AppTheme.textSecondary,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Toggle chord visibility
  void _toggleChordsVisibility() {
    setState(() {
      _showChords = !_showChords;
    });
  }

  // Transpose up by one semitone
  void _transposeUp() {
    setState(() {
      _transposeValue = (_transposeValue + 1).clamp(-11, 11);
    });
  }

  // Transpose down by one semitone
  void _transposeDown() {
    setState(() {
      _transposeValue = (_transposeValue - 1).clamp(-11, 11);
    });
  }

  // Reset transpose to original key
  void _resetTranspose() {
    setState(() {
      _transposeValue = 0;
    });
  }

  // Check if karaoke mode is available for this song
  bool get _hasKaraokeAvailable {
    final hasKaraoke = _song.karaoke != null && 
                      _song.karaoke!.tracks.isNotEmpty;
    
    debugPrint('🎤 Karaoke availability check for ${_song.title}:');
    debugPrint('  - Has karaoke object: ${_song.karaoke != null}');
    if (_song.karaoke != null) {
      debugPrint('  - Karaoke is active: ${_song.karaoke!.isActive}');
      debugPrint('  - Tracks count: ${_song.karaoke!.tracks.length}');
      debugPrint('  - Active tracks: ${_song.karaoke!.tracks.where((track) => track.isActive).length}');
    }
    debugPrint('  - Final result: $hasKaraoke');
    
    return hasKaraoke;
  }

  // Get the current key after transposition
  String _getCurrentKey() {
    if (_transposeValue == 0) return _song.key;

    const List<String> notes = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];

    // Map flat notes to their sharp equivalents
    const Map<String, String> flatToSharp = {
      'Db': 'C#',
      'Eb': 'D#',
      'Gb': 'F#',
      'Ab': 'G#',
      'Bb': 'A#',
    };

    // Find the original key index
    int keyIndex = notes.indexOf(_song.key);

    // If not found, try to convert flat to sharp
    if (keyIndex == -1 && _song.key.endsWith('b')) {
      final sharpEquivalent = flatToSharp[_song.key];
      if (sharpEquivalent != null) {
        keyIndex = notes.indexOf(sharpEquivalent);
      }
    }

    if (keyIndex == -1) return _song.key; // Return original if not found

    // Calculate new key
    final newIndex = (keyIndex + _transposeValue + 12) % 12;
    return notes[newIndex];
  }

  void _showChordDiagram(String chordName) {
    // Clean up the chord name (remove any brackets)
    final cleanChordName = chordName.replaceAll(RegExp(r'[\[\]]'), '');

    // Show the bottom sheet with proper responsive handling
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true, // Ensures safe area handling
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(
                    context,
                  ).viewInsets.bottom, // Handle keyboard if needed
            ),
            child: ChordDiagramBottomSheet(chordName: cleanChordName),
          ),
    );
  }

  // Open presentation mode
  void _openPresentationMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongPresentationScreen(song: _song),
      ),
    );
  }

  // Open practice mode
  void _openPracticeMode() {
    // Convert Song object to Map for practice mode
    Map<String, dynamic> songData = {
      'id': _song.id,
      'title': _song.title,
      'artist': _song.artist,
      'key': _song.key,
      'content': _song.chords ?? '', // Use 'content' instead of 'chordSheet'
      'tempo': _song.tempo ?? 120,
      'timeSignature': _song.timeSignature ?? '4/4',
      'capo': _song.capo,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeModeScreen(songData: songData),
      ),
    );
  }

  // Open karaoke mode
  Future<void> _openKaraokeMode() async {
    // Debug karaoke data
    debugPrint('Opening karaoke mode for song: ${_song.title}');
    if (_song.karaoke != null) {
      debugPrint('Karaoke tracks available: ${_song.karaoke!.tracks.length}');
    } else {
      debugPrint('No karaoke data available for this song');
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Fetch fresh song data with complete karaoke information
      debugPrint('Fetching fresh song data with karaoke information for: ${_song.id}');
      final freshSong = await _songService.getSongById(_song.id);

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Debug fresh karaoke data
      debugPrint('Fresh song data loaded for: ${freshSong.title}');
      if (freshSong.karaoke != null) {
        debugPrint('Fresh karaoke tracks available: ${freshSong.karaoke!.tracks.length}');
        for (final track in freshSong.karaoke!.tracks) {
          debugPrint('Track: ${track.trackType.displayName}, URL: ${track.fileUrl}');
        }
      } else {
        debugPrint('No karaoke data in fresh song data');
      }

      // Navigate to multi-track karaoke player with fresh data
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MultiTrackKaraokePlayerScreen(song: freshSong),
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      debugPrint('Error fetching fresh song data for karaoke: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load karaoke data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Fallback: try to navigate with existing song data
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MultiTrackKaraokePlayerScreen(song: _song),
          ),
        );
      }
    }
  }

  // Build floating action button
  Widget _buildFloatingActionButton() {
    debugPrint('🎵 Building floating action button - karaoke available: $_hasKaraokeAvailable');
    return FloatingActionButton(
      onPressed: _showPracticeAndPresentOptions,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      child: const Icon(Icons.play_arrow),
    );
  }

  // Show practice and present options
  void _showPracticeAndPresentOptions() {
    // Debug print to check karaoke data
    debugPrint('🎵 === PRACTICE & PRESENT OPTIONS DEBUG ===');
    debugPrint('🎵 Song: ${_song.title}');
    debugPrint('🎵 Song karaoke data: ${_song.karaoke != null ? 'Available' : 'Not available'}');
    
    if (_song.karaoke != null) {
      debugPrint('🎵 Karaoke tracks: ${_song.karaoke!.tracks.length}');
      debugPrint('🎵 Karaoke status: ${_song.karaoke!.status}');
      debugPrint('🎵 Karaoke is active: ${_song.karaoke!.isActive}');
      final activeTracks = _song.karaoke!.tracks.where((track) => track.isActive).length;
      debugPrint('🎵 Active tracks: $activeTracks');
      
      // List all tracks
      for (int i = 0; i < _song.karaoke!.tracks.length; i++) {
        final track = _song.karaoke!.tracks[i];
        debugPrint('🎵   Track $i: ${track.trackType.displayName} - Status: ${track.status} - Active: ${track.isActive}');
      }
    }
    
    debugPrint('🎵 _hasKaraokeAvailable result: $_hasKaraokeAvailable');
    debugPrint('🎵 Will show karaoke option: ${_hasKaraokeAvailable ? 'YES' : 'NO'}');
    debugPrint('🎵 ==========================================');

    // Additional debug right before showing modal
    debugPrint('🎵 FINAL CHECK - _hasKaraokeAvailable: $_hasKaraokeAvailable');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 0.0,
            right: 0.0,
            top: 20.0,
            bottom:
                20.0 +
                MediaQuery.of(
                  context,
                ).padding.bottom, // Add safe area bottom padding
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Practice option
              ListTile(
                leading: const Icon(Icons.piano, color: AppTheme.textPrimary),
                title: const Text(
                  'Practice Mode',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                subtitle: const Text(
                  'Practice with metronome and auto-scroll',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openPracticeMode();
                },
              ),
              // Present option
              ListTile(
                leading: const Icon(Icons.present_to_all, color: Colors.white),
                title: const Text(
                  'Present Mode',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Display for congregation or audience',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openPresentationMode();
                },
              ),
              // AI Karaoke Mode option (only show if song has active karaoke tracks)
              // Temporarily always show for debugging
              if (_hasKaraokeAvailable || true)
                ListTile(
                  leading: Icon(
                    Icons.multitrack_audio,
                    color: const Color(0xFF9BB5FF),
                  ),
                  title: Row(
                    children: [
                      const Text(
                        'AI Karaoke Mode',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9BB5FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Multi-Track',
                          style: TextStyle(
                            color: Color(0xFF9BB5FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'AI-separated tracks with individual controls',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openKaraokeMode();
                  },
                ),
            ],
          ),
        );
      },
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
    _userIsScrolling = false; // Reset user scrolling flag

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      if (_scrollController.hasClients && !_userIsScrolling) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double currentScroll = _scrollController.offset;
        final double delta = 0.5 * _autoScrollSpeed;

        if (currentScroll < maxScroll) {
          // Use animateTo for smoother scrolling that can be interrupted
          _scrollController.animateTo(
            currentScroll + delta,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
          _lastAutoScrollPosition = currentScroll + delta;
        } else {
          // Reached the end, stop auto-scroll
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

  // Show add to setlist bottom sheet
  void _showAddToSetlistSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SetlistBottomSheet(song: _song),
    );
  }

  // Show more options menu
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 0.0,
            right: 0.0,
            top: 20.0,
            bottom:
                20.0 +
                MediaQuery.of(
                  context,
                ).padding.bottom, // Add safe area bottom padding
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: const Text(
                  'Share Song',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Show enhanced song share dialog
                  showDialog(
                    context: context,
                    builder: (context) => EnhancedSongShareDialog(song: _song),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem, color: Colors.white),
                title: const Text(
                  'Report Issue',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Show report issue dialog
                  _showReportIssueDialog();
                },
              ),
              if (_song.officialVideoUrl != null ||
                  _song.tutorialVideoUrl != null)
                ListTile(
                  leading: const Icon(Icons.video_library, color: Colors.white),
                  title: const Text(
                    'Watch Videos',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showVideoOptions();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Show report issue dialog
  void _showReportIssueDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Report an Issue',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'What issue would you like to report with this song?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Thank you for your report. We will review it shortly.',
                    ),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
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
              backgroundColor: AppTheme.success,
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
              backgroundColor: AppTheme.error,
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
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: AppTheme.appBar,
        elevation: 2,
        scrolledUnderElevation: 0, // Prevents elevation change when scrolling
        surfaceTintColor:
            Colors.transparent, // Prevents blue tinting from primary color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
        actions:
            _isLoading
                ? []
                : [
                  // Like button
                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? AppTheme.error : AppTheme.textPrimary,
                      size: 24,
                    ),
                    onPressed: _toggleLike,
                  ),
                  // Comment icon with count
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.comment,
                          color: AppTheme.textPrimary,
                          size: 24,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommentsScreen(song: _song),
                            ),
                          ).then(
                            (_) => _fetchCommentCount(),
                          ); // Refresh comment count when returning
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
                              borderRadius: BorderRadius.circular(5),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _song.commentCount > 99
                                  ? '99+'
                                  : _song.commentCount.toString(),
                              style: const TextStyle(
                                color: AppTheme.background,
                                fontSize: 10,
                                fontWeight: FontWeight.w600, // Standardized to w600 for headings
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Add to setlist button
                  IconButton(
                    icon: const Icon(
                      Icons.playlist_add,
                      color: AppTheme.textPrimary,
                      size: 24,
                    ),
                    onPressed: _showAddToSetlistSheet,
                  ),
                  // Print button
                  IconButton(
                    icon: const Icon(
                      Icons.print,
                      color: AppTheme.textPrimary,
                      size: 24,
                    ),
                    onPressed: _printChordSheet,
                  ),
                  // Three-dot menu
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppTheme.textPrimary,
                      size: 24,
                    ),
                    onPressed: _showMoreOptions,
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
      floatingActionButton:
          _isLoading
              ? null
              : Container(
                margin: const EdgeInsets.only(
                  bottom: 80,
                ), // Move FAB up by 80 pixels
                child: _buildFloatingActionButton(),
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
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
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading song',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.textSecondary),
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
        Expanded(child: _buildLyricsContent()),

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
            child: Divider(color: AppTheme.separator, thickness: 1),
          ),

          // Lyrics and chords
          ..._parseLyricsAndChords(),

          // Divider before rating section
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: AppTheme.separator, thickness: 1),
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
        Text(_song.title, style: AppTheme.songTitleStyle),
        const SizedBox(height: 2),

        // Artist name
        Text(_song.artist, style: AppTheme.artistNameStyle),
        const SizedBox(height: 6),

        // Rating information (more compact)
        if (_song.ratingCount > 0) ...[
          Row(
            children: [
              StarRating(
                rating: _song.averageRating,
                size: 14,
                color: const Color(0xFFFFD700),
                showRating: true,
              ),
              const SizedBox(width: 6),
              Text(
                '(${_song.ratingCount})',
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],

        // Compact song details in a minimal layout
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _buildCompactSongDetails(),
        ),
      ],
    );
  }

  // Extract unique chords from the chord sheet
  List<String> _extractUniqueChords() {
    if (_song.chords == null || _song.chords!.isEmpty) {
      return [];
    }

    // Use the ChordExtractor utility to extract and sort chords
    final extractedChords = ChordExtractor.extractChords(_song.chords!);
    
    // Ensure the main chord (song key) appears first
    final mainChord = _song.key;
    final List<String> orderedChords = [];
    
    // Add the main chord first if it exists in the extracted chords
    if (extractedChords.contains(mainChord)) {
      orderedChords.add(mainChord);
    }
    
    // Add all other chords (excluding the main chord to avoid duplicates)
    for (final chord in extractedChords) {
      if (chord != mainChord) {
        orderedChords.add(chord);
      }
    }
    
    return orderedChords;
  }

  // Build chord summary section
  Widget _buildChordSummary() {
    final uniqueChords = _extractUniqueChords();

    if (uniqueChords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Chords Used (${uniqueChords.length})',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),
        ),

        // Horizontal scrollable chord list
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: uniqueChords.length,
            physics:
                const BouncingScrollPhysics(), // Add smooth scrolling physics
            itemBuilder: (context, index) {
              final chord = uniqueChords[index];
              return Padding(
                padding: EdgeInsets.only(
                  right:
                      index == uniqueChords.length - 1
                          ? 4.0
                          : 12.0, // Less padding for last item
                ),
                child: _buildChordSummaryItem(chord),
              );
            },
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // Build individual chord summary item
  Widget _buildChordSummaryItem(String chord) {
    return GestureDetector(
      onTap: () => _showChordDiagram(chord),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            chord,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.primaryFontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ),
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
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ),
        ),
      ];
    }

    // Return chord summary followed by the chord sheet
    return [
      // Chord summary section
      _buildChordSummary(),

      // Chord sheet
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom, // Add safe area padding
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface, // Use theme surface color
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000), // Black with 20% opacity
            blurRadius: 8,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SizedBox(
        height: 64,
        child:
            _isAutoScrollEnabled
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
                  children: [
                    // Left side buttons (2 buttons)
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Toggle chords button
                          _buildBottomNavButton(
                            icon:
                                _showChords
                                    ? Icons.music_note
                                    : Icons.music_note_outlined,
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
                        ],
                      ),
                    ),

                    // Center play button (1 button, prominent)
                    Expanded(
                      flex: 1,
                      child: Center(child: _buildScrollButton()),
                    ),

                    // Right side buttons (2 buttons)
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Transpose button
                          _buildBottomNavButton(
                            icon:
                                _transposeValue != 0
                                    ? Icons.music_note
                                    : Icons.music_note_outlined,
                            label: 'Transpose',
                            isActive: _transposeValue != 0,
                            onPressed: _showTransposeBottomSheet,
                          ),

                          // Video button
                          _buildBottomNavButton(
                            icon: Icons.video_library_outlined,
                            label: 'Video',
                            onPressed: _showVideoOptions,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Rating UI - Full Width
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
            ),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: const Color(0xFF0F3460).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE94560).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFE94560),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rate this song',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Help others discover great music',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Current average rating display (if exists)
                if (_song.ratingCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3460).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StarRating(
                          rating: _song.averageRating,
                          size: 18,
                          color: const Color(0xFFFFD700),
                          showRating: true,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_song.ratingCount} ${_song.ratingCount == 1 ? 'rating' : 'ratings'}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // User's rating section
                _isRatingLoading
                    ? Container(
                      padding: const EdgeInsets.all(20),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFE94560),
                        ),
                        strokeWidth: 3,
                      ),
                    )
                    : Column(
                      children: [
                        // Your rating label
                        Text(
                          _song.userRating != null
                              ? 'Your rating:'
                              : 'Tap to rate:',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Interactive star rating
                        InteractiveStarRating(
                          initialRating: _song.userRating ?? 0,
                          onRatingChanged: _rateSong,
                          size: 32,
                          color: const Color(0xFFE94560),
                          unratedColor: const Color(0xFF0F3460),
                          showLabel: true,
                        ),

                        // Thank you message or encouragement
                        const SizedBox(height: 12),
                        if (_song.userRating != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE94560,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFFE94560),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Thanks for rating!',
                                  style: TextStyle(
                                    color: Color(0xFFE94560),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Your feedback helps improve recommendations',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build compact song details with better styling and labels
  Widget _buildCompactSongDetails() {
    List<Widget> details = [];

    // Helper function to add a detail item with label (no icons)
    void addDetail(String label, String value, {VoidCallback? onTap}) {
      details.add(
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF404040), width: 0.5),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Add details with proper spacing
    // Show current key (transposed if applicable)
    final currentKey = _getCurrentKey();
    final keyDisplay =
        _transposeValue == 0
            ? currentKey
            : '$currentKey (${_transposeValue > 0 ? '+' : ''}$_transposeValue)';
    addDetail('Key', keyDisplay);

    if (_song.capo != null && _song.capo! > 0) {
      details.add(const SizedBox(width: 8));
      addDetail('Capo', _song.capo.toString());
    }

    if (_song.timeSignature != null && _song.timeSignature!.isNotEmpty) {
      details.add(const SizedBox(width: 8));
      addDetail('Time', _song.timeSignature!);
    }

    if (_song.tempo != null && _song.tempo! > 0) {
      details.add(const SizedBox(width: 8));
      addDetail('Tempo', '${_song.tempo} BPM');
    }

    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 6,
      children: details,
    );
  }

  Widget _buildScrollButton() {
    // Get primary color from theme
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Determine the current state
    final bool isPlaying = _isAutoScrollEnabled && !_autoScrollPaused;
    final bool isPaused = _isAutoScrollEnabled && _autoScrollPaused;

    // Choose icon and color based on state
    IconData icon;
    Color color;
    String label;

    if (isPaused) {
      icon = Icons.pause_circle_outline;
      color = Colors.orange;
      label = 'Paused';
    } else if (isPlaying) {
      icon = Icons.pause_rounded;
      color = Colors.redAccent;
      label = 'Pause';
    } else {
      icon = Icons.play_arrow_rounded;
      color = primaryColor;
      label = 'Scroll';
    }

    return InkWell(
      onTap: _toggleAutoScroll,
      borderRadius: BorderRadius.circular(5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                // Add a small indicator when paused by user
                if (isPaused)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 14,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
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
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Padding(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom:
                        16.0 +
                        MediaQuery.of(
                          context,
                        ).padding.bottom, // Add safe area bottom padding
                  ),
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
                          const Icon(
                            Icons.text_fields,
                            color: Colors.white,
                            size: 16,
                          ),
                          Expanded(
                            child: Slider(
                              value: _fontSize,
                              min:
                                  10, // Reduced minimum font size for more flexibility
                              max:
                                  28, // Increased maximum font size for better readability
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
                          const Icon(
                            Icons.text_fields,
                            color: Colors.white,
                            size: 24,
                          ),
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
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
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
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Padding(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom:
                        16.0 +
                        MediaQuery.of(
                          context,
                        ).padding.bottom, // Add safe area bottom padding
                  ),
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
                          const Icon(
                            Icons.speed,
                            color: Colors.white,
                            size: 16,
                          ),
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
                          const Icon(
                            Icons.speed,
                            color: Colors.white,
                            size: 24,
                          ),
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
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
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

  void _showTransposeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 24.0,
                    bottom: 24.0 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Header with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Icon(
                              Icons.music_note,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Transpose Chords',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Change the key of all chords',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Key transformation display
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Original key
                            Column(
                              children: [
                                Text(
                                  'Original',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _song.key,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 24),

                            // Arrow
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),

                            const SizedBox(width: 24),

                            // Current key
                            Column(
                              children: [
                                Text(
                                  'Current',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getCurrentKey(),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Transpose controls
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          children: [
                            // Semitone display
                            Text(
                              _transposeValue == 0
                                  ? 'Original Key'
                                  : '${_transposeValue > 0 ? '+' : ''}$_transposeValue semitone${_transposeValue.abs() == 1 ? '' : 's'}',
                              style: TextStyle(
                                color:
                                    _transposeValue == 0
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : Theme.of(context).colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Control buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Transpose down
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        _transposeValue > -11
                                            ? const Color(0xFF3A3A3A)
                                            : const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color:
                                          _transposeValue > -11
                                              ? Colors.white.withValues(
                                                alpha: 0.1,
                                              )
                                              : Colors.transparent,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed:
                                        _transposeValue > -11
                                            ? () {
                                              // Update the main widget state
                                              setState(() {
                                                _transposeDown();
                                              });
                                              // Update the modal state to refresh the UI
                                              setModalState(() {});
                                            }
                                            : null,
                                    icon: const Icon(Icons.remove_rounded),
                                    color:
                                        _transposeValue > -11
                                            ? Colors.white
                                            : Colors.grey,
                                    iconSize: 24,
                                  ),
                                ),

                                const SizedBox(width: 32),

                                // Reset button
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        _transposeValue != 0
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.15)
                                            : const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color:
                                          _transposeValue != 0
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.3)
                                              : Colors.transparent,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed:
                                        _transposeValue != 0
                                            ? () {
                                              setState(() {
                                                this.setState(() {
                                                  _resetTranspose();
                                                });
                                              });
                                            }
                                            : null,
                                    icon: const Icon(Icons.refresh_rounded),
                                    color:
                                        _transposeValue != 0
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Colors.grey,
                                    iconSize: 24,
                                  ),
                                ),

                                const SizedBox(width: 32),

                                // Transpose up
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        _transposeValue < 11
                                            ? const Color(0xFF3A3A3A)
                                            : const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color:
                                          _transposeValue < 11
                                              ? Colors.white.withValues(
                                                alpha: 0.1,
                                              )
                                              : Colors.transparent,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed:
                                        _transposeValue < 11
                                            ? () {
                                              setState(() {
                                                this.setState(() {
                                                  _transposeUp();
                                                });
                                              });
                                            }
                                            : null,
                                    icon: const Icon(Icons.add_rounded),
                                    color:
                                        _transposeValue < 11
                                            ? Colors.white
                                            : Colors.grey,
                                    iconSize: 24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Done button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        // Local state for chord visibility in PDF - default to true
        bool showChordsInPdf = true;

        // Use a StatefulBuilder to manage the toggle state
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Get screen dimensions and safe area
            final screenHeight = MediaQuery.of(context).size.height;
            final safeAreaBottom = MediaQuery.of(context).padding.bottom;
            final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

            // Calculate available height
            final availableHeight =
                screenHeight - safeAreaBottom - viewInsetsBottom;
            final maxHeight =
                availableHeight * 0.8; // Use max 80% of available height

            return Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom:
                        16.0 + safeAreaBottom, // Add safe area bottom padding
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      const Text(
                        'Chord Sheet Options',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      const Text(
                        'Create a printable version of this chord sheet',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Chord visibility toggle
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0x33000000),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: SwitchListTile(
                          title: const Text(
                            'Include Chords',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            showChordsInPdf
                                ? 'PDF will include both chords and lyrics'
                                : 'PDF will only include lyrics (no chords)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          value: showChordsInPdf,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (bool value) {
                            setModalState(() {
                              showChordsInPdf = value;
                              debugPrint('Chord visibility changed to: $value');
                            });
                          },
                          secondary: Icon(
                            showChordsInPdf
                                ? Icons.music_note
                                : Icons.text_format,
                            color:
                                showChordsInPdf
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                          ),
                        ),
                      ),

                      const Divider(color: Colors.white24),

                      // Action buttons
                      ListTile(
                        leading: const Icon(Icons.print, color: Colors.white),
                        title: const Text(
                          'Print',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Send to a printer',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _sendToPrinter(showChords: showChordsInPdf);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.share, color: Colors.white),
                        title: const Text(
                          'Share',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Share via other apps',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _shareChordSheet(showChords: showChordsInPdf);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendToPrinter({bool? showChords}) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing to print...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Print the PDF
      await _pdfService.printSongPdf(
        _song,
        showChords: showChords ?? _showChords,
      );

      // No need for a success message as the printing dialog will be shown
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _shareChordSheet({bool? showChords}) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing to share...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Share the PDF
      await _pdfService.shareSongPdf(
        _song,
        showChords: showChords ?? _showChords,
      );

      // No need for a success message as the share dialog will be shown
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showVideoOptions() {
    // Check if any video URLs are available
    final bool hasTutorialVideo =
        _song.tutorialVideoUrl != null && _song.tutorialVideoUrl!.isNotEmpty;
    final bool hasOfficialVideo =
        _song.officialVideoUrl != null && _song.officialVideoUrl!.isNotEmpty;

    // Show a bottom sheet with video options
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom:
                  16.0 +
                  MediaQuery.of(
                    context,
                  ).padding.bottom, // Add safe area bottom padding
            ),
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
                    leading: const Icon(
                      Icons.video_library,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Watch Tutorial',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showYouTubeVideo(
                        _song.tutorialVideoUrl!,
                        'Tutorial: ${_song.title}',
                      );
                    },
                  ),

                // Official music video option (only show if available)
                if (hasOfficialVideo)
                  ListTile(
                    leading: const Icon(Icons.music_video, color: Colors.white),
                    title: const Text(
                      'Watch Music Video',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showYouTubeVideo(
                        _song.officialVideoUrl!,
                        'Music Video: ${_song.title}',
                      );
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
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // Log the video URL for debugging
    debugPrint('Opening YouTube video: $videoUrl');

    // Show dialog to choose between floating player and bottom sheet
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
      builder:
          (context) => Container(
            height:
                MediaQuery.of(context).size.height *
                0.7, // Increased to 70% of screen height
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: YouTubeIframeBottomSheet(videoUrl: videoUrl, title: title),
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
      borderRadius: BorderRadius.circular(5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 14,
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white70,
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
