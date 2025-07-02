import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';
import '../services/karaoke_service.dart';
import '../services/karaoke_download_manager.dart';
import '../services/auth_service.dart';
import '../services/song_service.dart';
import '../utils/chord_extractor.dart';

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
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 0.8;
  String? _downloadUrl;
  List<String> _lyricsLines = [];
  int _currentLyricsIndex = 0;

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

    // Remove section headers like {verse}, {chorus}, {bridge}
    lyrics = lyrics.replaceAll(RegExp(r'\{[^}]+\}'), '');

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
      // Check if already downloaded locally first
      final localPath = _downloadManager.getLocalPath(widget.song.id);
      if (localPath != null) {
        _downloadUrl = localPath;
        _isDownloaded = true;
        debugPrint('🎤 Using local karaoke file: $localPath');
      } else if (widget.karaokeUrl == null && widget.song.karaoke != null) {
        // Get download URL from API
        final downloadData = await _karaokeService.getKaraokeDownloadUrl(widget.song.id);
        if (downloadData != null) {
          _downloadUrl = downloadData['downloadUrl'];
          debugPrint('🎤 Using streaming karaoke URL');
        }
      } else {
        _downloadUrl = widget.karaokeUrl;
        debugPrint('🎤 Using provided karaoke URL');
      }

      if (_downloadUrl != null) {
        // Set up listeners
        _audioPlayer.onDurationChanged.listen((duration) {
          setState(() {
            _duration = duration;
          });
        });

        _audioPlayer.onPositionChanged.listen((position) {
          setState(() {
            _position = position;
          });
        });

        _audioPlayer.onPlayerComplete.listen((_) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
          _trackCompleteAnalytics();
        });

        // Load the audio
        await _audioPlayer.setSourceUrl(_downloadUrl!);
        await _audioPlayer.setVolume(_volume);
        
        setState(() {
          _isLoading = false;
        });

        _trackPlayAnalytics();
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError('Karaoke track not available');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error loading karaoke: $e');
    }
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    } catch (e) {
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
    if (_isDownloading || _isDownloaded || _downloadUrl == null) return;

    try {
      final success = await _downloadManager.downloadTrack(
        widget.song.id,
        _downloadUrl!,
        fileSize: widget.song.karaoke?.fileSize ?? 0,
        duration: widget.song.karaoke?.duration ?? 0,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Karaoke track downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Karaoke Player',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading ? _buildLoadingState() : _buildPlayerContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Loading Karaoke...',
            style: TextStyle(color: Colors.white, fontSize: 16),
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
          flex: 7,
          child: _buildLyrics(),
        ),
        // Bottom controls section
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
                Colors.black,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSongInfo(),
              const SizedBox(height: 16),
              _buildProgressBar(),
              const SizedBox(height: 20),
              _buildControls(),
              const SizedBox(height: 16),
              _buildDownloadButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildSongInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            widget.song.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            widget.song.artist,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }



  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blue.shade400,
            inactiveTrackColor: Colors.grey.shade700,
            thumbColor: Colors.blue.shade400,
            overlayColor: Colors.blue.shade400.withValues(alpha: 0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
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
          color: Colors.white.withValues(alpha: 0.8),
          size: 56,
        ),
        const SizedBox(width: 32),
        // Main play/pause button
        _buildControlButton(
          icon: _isPlaying ? Icons.pause : Icons.play_arrow,
          onPressed: _playPause,
          color: Colors.blue.shade400,
          size: 72,
          isPrimary: true,
        ),
        const SizedBox(width: 32),
        // Skip forward 10 seconds
        _buildControlButton(
          icon: Icons.forward_10,
          onPressed: () {
            final newPosition = Duration(
              milliseconds: (_position.inMilliseconds + 10000).clamp(0, _duration.inMilliseconds),
            );
            _seek(newPosition);
          },
          color: Colors.white.withValues(alpha: 0.8),
          size: 56,
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    if (_isDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_done, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Text(
              'Downloaded',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_isDownloading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue,
                value: _downloadProgress,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Downloading... ${(_downloadProgress * 100).toInt()}%',
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _downloadKaraoke,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Text(
              'Download for Offline',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required double size,
    bool isPrimary = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPrimary ? null : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : color,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }



  Widget _buildLyrics() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_lyricsLines.isNotEmpty) ...[
            // Current line highlight
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.1),
                    Colors.purple.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _lyricsLines.isNotEmpty ? _lyricsLines[_currentLyricsIndex] : '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // All lyrics with scroll
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _lyricsLines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final line = entry.value;
                    final isCurrentLine = index == _currentLyricsIndex;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        line,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isCurrentLine
                              ? Colors.blue.shade300
                              : Colors.white.withValues(alpha: 0.6),
                          fontSize: isCurrentLine ? 20 : 18,
                          fontWeight: isCurrentLine ? FontWeight.w600 : FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ] else ...[
            // No lyrics state
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  'No lyrics available',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enjoy the instrumental track',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
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
