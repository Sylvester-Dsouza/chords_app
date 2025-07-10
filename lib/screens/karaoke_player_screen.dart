import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';
import '../services/karaoke_service.dart';
import '../services/karaoke_download_manager.dart';
import '../services/auth_service.dart';
import '../services/song_service.dart';
import '../utils/chord_extractor.dart';
import '../config/theme.dart';

class KaraokePlayerScreen extends StatefulWidget {
  final Song song;
  final String? karaokeUrl;

  const KaraokePlayerScreen({
    super.key,
    required this.song,
    this.karaokeUrl,
  });

  @override
  State<KaraokePlayerScreen> createState() => _KaraokePlayerScreenState();
}

class _KaraokePlayerScreenState extends State<KaraokePlayerScreen> {
  late AudioPlayer _audioPlayer;
  late KaraokeDownloadManager _downloadManager;
  late KaraokeService _karaokeService;
  final AuthService _authService = AuthService();
  final SongService _songService = SongService();
  Song? _completeSong; // Store the complete song data with chord sheet
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double _downloadProgress = 0.0;
  String _loadingMessage = 'Initializing...';
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  final double _volume = 0.8;
  String? _downloadUrl;
  List<String> _lyricsLines = [];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _downloadManager = KaraokeDownloadManager();
    _initializeServices();
  }



  Future<void> _initializeServices() async {
    // Initialize AuthService first
    await _authService.initializeFirebase();
    _karaokeService = KaraokeService(_authService);
    await _downloadManager.initialize();

    // Listen to download progress updates
    _downloadManager.addListener(_onDownloadProgressUpdate);

    // Fetch complete song data if chord sheet is missing
    await _ensureCompleteSongData();

    _extractLyrics();
    await _initializePlayer();
  }

  /// Fetch complete song data if the current song is missing chord sheet
  Future<void> _ensureCompleteSongData() async {
    // Check if we already have chord data
    if (widget.song.chords != null && widget.song.chords!.isNotEmpty) {
      _completeSong = widget.song;
      return;
    }

    // Check if we have lyrics data as fallback
    if (widget.song.lyrics != null && widget.song.lyrics!.isNotEmpty) {
      _completeSong = widget.song;
      return;
    }

    // Fetch complete song data from API
    try {
      debugPrint('🎤 Fetching complete song data for: ${widget.song.title}');
      _completeSong = await _songService.getSongById(widget.song.id);
      debugPrint('🎤 Complete song data loaded successfully');
    } catch (e) {
      debugPrint('🎤 Error fetching song data: $e');
      _completeSong = widget.song; // Fallback to original song
    }
  }

  void _onDownloadProgressUpdate() {
    if (mounted) {
      final progress = _downloadManager.getDownloadProgress(widget.song.id);
      final isDownloading = _downloadManager.isDownloading(widget.song.id);
      final isDownloaded = _downloadManager.isDownloaded(widget.song.id);

      setState(() {
        _downloadProgress = progress;
        _isDownloading = isDownloading;
        _isDownloaded = isDownloaded;
      });
    }
  }

  /// Extract lyrics from chord sheet
  void _extractLyrics() {
    final songToUse = _completeSong ?? widget.song;

    debugPrint('🎤 Extracting lyrics for: ${songToUse.title}');

    String? chordSheetData = songToUse.chords;

    // If chords field is empty, try lyrics field as fallback
    if (chordSheetData == null || chordSheetData.trim().isEmpty) {
      chordSheetData = songToUse.lyrics;
    }

    if (chordSheetData != null && chordSheetData.trim().isNotEmpty) {
      // Try ChordExtractor first
      String lyrics = ChordExtractor.extractLyrics(chordSheetData);

      // If ChordExtractor returns empty or very short result, try manual extraction
      if (lyrics.trim().isEmpty || lyrics.length < 20) {
        lyrics = _manualLyricsExtraction(chordSheetData);
      }

      _lyricsLines = lyrics.split('\n').where((line) => line.trim().isNotEmpty).toList();
      debugPrint('🎤 Extracted ${_lyricsLines.length} lyrics lines');
    } else {
      debugPrint('🎤 No chord sheet data available');
      _lyricsLines = [];
    }
  }

  /// Manual lyrics extraction as fallback
  String _manualLyricsExtraction(String chordSheet) {
    String lyrics = chordSheet;

    // Keep section headers but format them nicely
    lyrics = lyrics.replaceAllMapped(RegExp(r'\{([^}]+)\}'), (match) {
      final sectionName = match.group(1)?.toUpperCase() ?? '';
      return '\n--- $sectionName ---\n';
    });

    // Remove bracketed chords [C] [Am] [G/B] etc.
    lyrics = lyrics.replaceAll(RegExp(r'\[[^\]]+\]'), '');

    // Remove lines that are mostly chords (lines with multiple chord patterns)
    final lines = lyrics.split('\n');
    final lyricsLines = <String>[];

    for (String line in lines) {
      final trimmedLine = line.trim();

      // Skip empty lines
      if (trimmedLine.isEmpty) continue;

      // Skip lines that are mostly chord patterns
      // Check if line has more than 3 chord-like patterns
      final chordMatches = RegExp(r'\b[A-G][#b]?(?:maj|min|m|sus|aug|dim|add|maj7|m7|7|6|9|11|13|sus2|sus4)?(?:\d)?(?:/[A-G][#b]?)?\b').allMatches(trimmedLine);

      if (chordMatches.length > 3 && trimmedLine.length < 50) {
        // Likely a chord line, skip it
        continue;
      }

      // Keep lines that look like lyrics
      lyricsLines.add(trimmedLine);
    }

    return lyricsLines.join('\n');
  }



  @override
  void dispose() {
    _downloadManager.removeListener(_onDownloadProgressUpdate);
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _loadingMessage = 'Checking local storage...';
      });

      // Check if already downloaded locally first
      final localPath = _downloadManager.getLocalPath(widget.song.id);
      if (localPath != null && await File(localPath).exists()) {
        debugPrint('🎤 Found local karaoke file: $localPath');
        await _setupAudioPlayer(localPath, isLocal: true);
        return;
      }

      // Not available locally, need to download
      setState(() {
        _loadingMessage = 'Getting download URL...';
      });

      String? downloadUrl;
      if (widget.karaokeUrl != null) {
        downloadUrl = widget.karaokeUrl;
        debugPrint('🎤 Using provided karaoke URL');
      } else if (widget.song.karaoke != null) {
        // Get download URL from API
        final downloadData = await _karaokeService.getKaraokeDownloadUrl(widget.song.id);
        if (downloadData != null) {
          downloadUrl = downloadData['downloadUrl'];
          debugPrint('🎤 Got download URL from API');
        }
      }

      if (downloadUrl == null) {
        throw Exception('No karaoke track available for this song');
      }

      // Start automatic download
      setState(() {
        _isDownloading = true;
        _loadingMessage = 'Downloading karaoke track...';
      });

      final success = await _downloadManager.downloadTrack(
        widget.song.id,
        downloadUrl,
        fileSize: widget.song.karaoke?.fileSize ?? 0,
        duration: widget.song.karaoke?.duration ?? 0,
      );

      if (!success) {
        throw Exception('Failed to download karaoke track');
      }

      // Get the downloaded file path and play
      final downloadedPath = _downloadManager.getLocalPath(widget.song.id);
      if (downloadedPath != null) {
        debugPrint('🎤 Download complete, playing from: $downloadedPath');
        await _setupAudioPlayer(downloadedPath, isLocal: true);
      } else {
        throw Exception('Downloaded file not found');
      }

    } catch (e) {
      debugPrint('🎤 Error in _initializePlayer: $e');
      setState(() {
        _isLoading = false;
        _isDownloading = false;
      });
      _showError('Error loading karaoke: $e');
    }
  }

  Future<void> _setupAudioPlayer(String audioSource, {bool isLocal = false}) async {
    try {
      setState(() {
        _loadingMessage = 'Setting up audio player...';
      });

      // Set up audio player listeners
      _audioPlayer.onDurationChanged.listen((duration) {
        debugPrint('🎤 Duration changed: ${duration.inSeconds}s');
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        debugPrint('🎤 Audio playback completed');
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
          _trackCompleteAnalytics();
        }
      });

      // Add player state listener for debugging and state sync
      _audioPlayer.onPlayerStateChanged.listen((state) {
        debugPrint('🎤 Player state changed: $state');
        if (mounted) {
          setState(() {
            _isPlaying = (state == PlayerState.playing);
          });
        }
      });

      // Load the audio source
      debugPrint('🎤 Setting audio source: $audioSource (isLocal: $isLocal)');

      if (isLocal) {
        // Verify file exists before setting source
        final file = File(audioSource);
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint('🎤 Local file exists, size: $fileSize bytes');
          await _audioPlayer.setSourceDeviceFile(audioSource);
        } else {
          throw Exception('Local audio file not found: $audioSource');
        }
      } else {
        debugPrint('🎤 Setting remote URL source');
        await _audioPlayer.setSourceUrl(audioSource);
      }

      debugPrint('🎤 Setting volume to $_volume');
      await _audioPlayer.setVolume(_volume);

      setState(() {
        _isLoading = false;
        _isDownloading = false;
        _isDownloaded = isLocal;
        _downloadUrl = audioSource;
        _loadingMessage = 'Ready to play!';
      });

      _trackPlayAnalytics();
      debugPrint('🎤 Audio player setup complete');
      debugPrint('🎤 Player state after setup: ${_audioPlayer.state}');
      debugPrint('🎤 Duration: ${_duration.inSeconds}s, Volume: $_volume');

    } catch (e) {
      debugPrint('🎤 Error setting up audio player: $e');
      setState(() {
        _isLoading = false;
        _isDownloading = false;
      });
      _showError('Error setting up audio player: $e');
    }
  }

  Future<void> _playPause() async {
    try {
      debugPrint('🎤 Play/Pause clicked. Current state: _isPlaying = $_isPlaying');

      if (_isPlaying) {
        debugPrint('🎤 Pausing audio...');
        await _audioPlayer.pause();
      } else {
        debugPrint('🎤 Starting/Resuming audio...');
        final playerState = _audioPlayer.state;
        debugPrint('🎤 Player state: $playerState');

        await _audioPlayer.resume();
      }

      // Don't manually set _isPlaying here - let the state listener handle it
      debugPrint('🎤 Play/Pause action completed');
    } catch (e) {
      debugPrint('🎤 Error in _playPause: $e');
      _showError('Error playing audio: $e');
    }
  }



  Future<void> _seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _showError('Error seeking: $e');
    }
  }



  void _trackPlayAnalytics() {
    _karaokeService.trackAnalytics(widget.song.id, 'play');
  }

  void _trackCompleteAnalytics() {
    _karaokeService.trackAnalytics(
      widget.song.id,
      'complete',
      duration: _duration.inSeconds,
    );
  }

  Future<void> _downloadKaraoke() async {
    // This method is now only used for manual re-download if needed
    if (_isDownloading || _isDownloaded) return;

    try {
      setState(() {
        _isDownloading = true;
        _loadingMessage = 'Re-downloading karaoke track...';
      });

      String? downloadUrl;
      if (widget.karaokeUrl != null) {
        downloadUrl = widget.karaokeUrl;
      } else if (widget.song.karaoke != null) {
        final downloadData = await _karaokeService.getKaraokeDownloadUrl(widget.song.id);
        if (downloadData != null) {
          downloadUrl = downloadData['downloadUrl'];
        }
      }

      if (downloadUrl == null) {
        throw Exception('No download URL available');
      }

      final success = await _downloadManager.downloadTrack(
        widget.song.id,
        downloadUrl,
        fileSize: widget.song.karaoke?.fileSize ?? 0,
        duration: widget.song.karaoke?.duration ?? 0,
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = success;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Karaoke track downloaded successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.song.title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.displayFontFamily,
            letterSpacing: -0.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.background,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
        actions: [
          // Download button in app bar
          _buildAppBarDownloadButton(),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildPlayerContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading indicator
          if (_isDownloading) ...[
            // Download progress indicator
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _downloadProgress,
                    color: AppTheme.textPrimary,
                    backgroundColor: AppTheme.textTertiary.withValues(alpha: 0.3),
                    strokeWidth: 3,
                  ),
                  Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Regular loading indicator
            CircularProgressIndicator(
              color: AppTheme.textSecondary,
              strokeWidth: 2,
            ),
          ],

          const SizedBox(height: 32),

          // Loading message
          Text(
            _loadingMessage,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: AppTheme.displayFontFamily,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Sub message based on state
          Text(
            _isDownloading
                ? 'Downloading for offline playback...'
                : 'Preparing your karaoke experience...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontFamily: AppTheme.primaryFontFamily,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Song info during loading
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.textTertiary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.song.title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.displayFontFamily,
                    letterSpacing: -0.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.song.artist,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerContent() {
    return Column(
      children: [
        // Lyrics section - takes most of the screen
        Expanded(
          child: _buildLyrics(),
        ),
        // Bottom controls section - minimal and clean
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              top: BorderSide(
                color: AppTheme.textTertiary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProgressBar(),
              const SizedBox(height: 16),
              _buildControls(),
            ],
          ),
        ),
      ],
    );
  }







  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.textPrimary,
            inactiveTrackColor: AppTheme.textTertiary,
            thumbColor: AppTheme.textPrimary,
            overlayColor: AppTheme.textPrimary.withValues(alpha: 0.1),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: _duration.inMilliseconds > 0
                ? _position.inMilliseconds / _duration.inMilliseconds
                : 0.0,
            onChanged: (value) {
              final position = Duration(
                milliseconds: (value * _duration.inMilliseconds).round(),
              );
              _seek(position);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_position),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
            Text(
              _formatDuration(_duration),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Skip backward 10 seconds
        _buildControlButton(
          icon: Icons.replay_10,
          onPressed: () {
            final newPosition = Duration(
              milliseconds: (_position.inMilliseconds - 10000).clamp(0, _duration.inMilliseconds),
            );
            _seek(newPosition);
          },
        ),
        const SizedBox(width: 24),
        // Main play/pause button
        _buildPlayButton(),
        const SizedBox(width: 24),
        // Skip forward 10 seconds
        _buildControlButton(
          icon: Icons.forward_10,
          onPressed: () {
            final newPosition = Duration(
              milliseconds: (_position.inMilliseconds + 10000).clamp(0, _duration.inMilliseconds),
            );
            _seek(newPosition);
          },
        ),
      ],
    );
  }



  // Simple control button for skip forward/backward
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            icon,
            color: AppTheme.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }

  // Main play/pause button
  Widget _buildPlayButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _playPause,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.textPrimary,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: AppTheme.background,
            size: 32,
          ),
        ),
      ),
    );
  }

  // App bar download button
  Widget _buildAppBarDownloadButton() {
    if (_isDownloaded) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(
          Icons.download_done,
          color: AppTheme.success,
          size: 20,
        ),
      );
    }

    if (_isDownloading) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.textSecondary,
            value: _downloadProgress,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: _downloadKaraoke,
      icon: Icon(
        Icons.download_outlined,
        color: AppTheme.textSecondary,
        size: 20,
      ),
      tooltip: 'Download for offline',
    );
  }



  Widget _buildLyrics() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: _lyricsLines.isNotEmpty ? _buildLyricsContent() : _buildNoLyricsState(),
    );
  }

  Widget _buildLyricsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: _lyricsLines.map((line) {
          // Check if this line is a section header
          final isSectionHeader = line.startsWith('---') && line.endsWith('---');

          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: isSectionHeader ? 16 : 8,
            ),
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSectionHeader ? AppTheme.textSecondary : AppTheme.textPrimary,
                fontSize: isSectionHeader ? 16 : 20,
                fontWeight: isSectionHeader ? FontWeight.w600 : FontWeight.w500,
                fontFamily: isSectionHeader ? AppTheme.primaryFontFamily : AppTheme.displayFontFamily,
                height: 1.6,
                letterSpacing: isSectionHeader ? 0.5 : -0.2,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoLyricsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 24),
          Text(
            'No lyrics available',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: AppTheme.displayFontFamily,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy the instrumental track',
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 14,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
