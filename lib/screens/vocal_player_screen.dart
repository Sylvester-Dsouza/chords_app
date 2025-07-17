import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';
import '../config/theme.dart';
import '../models/vocal.dart';
import '../utils/performance_utils.dart';

class VocalPlayerScreen extends StatefulWidget {
  final VocalItem vocalItem;
  final List<VocalItem>? categoryItems; // Optional list of items in the same category

  const VocalPlayerScreen({
    super.key,
    required this.vocalItem,
    this.categoryItems,
  });

  @override
  State<VocalPlayerScreen> createState() => _VocalPlayerScreenState();
}

class _VocalPlayerScreenState extends State<VocalPlayerScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isLooping = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _error;

  // Stream subscriptions for proper cleanup
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<void>? _completeSubscription;

  // Navigation between items
  late VocalItem _currentItem;
  List<VocalItem> _categoryItems = [];
  int _currentIndex = 0;

  late AnimationController _waveController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeData();
    _initializeAnimations();
    _setupAudioPlayer();
    _loadAudio();
  }

  void _initializeData() {
    _currentItem = widget.vocalItem;
    _categoryItems = widget.categoryItems ?? [widget.vocalItem];
    _currentIndex = _categoryItems.indexWhere((item) => item.id == widget.vocalItem.id);
    if (_currentIndex == -1) _currentIndex = 0;
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Start slide animation
    _slideController.forward();
  }

  void _setupAudioPlayer() {
    // Setup stream subscriptions with proper cleanup
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position > _duration ? _duration : position;
        });
      }
    });

    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;

      setState(() {
        _isPlaying = state == PlayerState.playing;
        _isLoading = false;
      });

      if (state == PlayerState.playing) {
        _waveController.repeat();
      } else {
        _waveController.stop();
      }
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;

      if (_isLooping) {
        _audioPlayer.seek(Duration.zero).then((_) {
          if (mounted) {
            _audioPlayer.resume();
          }
        });
      } else if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = _duration;
        });
      }
    });
  }

  Future<void> _loadAudio() async {
    if (_isLoading) return; // Prevent multiple loads

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Release any existing source
      try {
        await _audioPlayer.release();
      } catch (e) {
        // Ignore release errors
      }

      if (_currentItem.isDownloaded && _currentItem.localPath != null) {
        // Play from local file
        final file = File(_currentItem.localPath!);
        if (await file.exists()) {
          await _audioPlayer.setSourceDeviceFile(_currentItem.localPath!);
        } else {
          throw Exception('Downloaded file not found');
        }
      } else {
        // Play from URL with timeout
        await _audioPlayer.setSourceUrl(_currentItem.audioFileUrl);
      }

      // Reset position with timeout
      await _audioPlayer.seek(Duration.zero).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          if (mounted) {
            setState(() {
              _position = Duration.zero;
              _isPlaying = false;
            });
          }
          return null;
        },
      );

      // Track performance (non-blocking)
      PerformanceUtils.trackMediaOperation(
        'load',
        'vocal_audio',
        Duration(milliseconds: 100), // Approximate load time
        attributes: {
          'vocal_item_id': _currentItem.id,
          'vocal_item_name': _currentItem.name,
          'source_type': _currentItem.isDownloaded ? 'local' : 'remote',
        },
      ).catchError((e) {
        debugPrint('⚠️ Performance tracking error: $e');
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load audio: ${e.toString()}';
          _isPlaying = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigation methods
  void _playPrevious() {
    if (_categoryItems.length <= 1) return;

    final newIndex = _currentIndex > 0 ? _currentIndex - 1 : _categoryItems.length - 1;
    _switchToItem(newIndex);
  }

  void _playNext() {
    if (_categoryItems.length <= 1) return;

    final newIndex = _currentIndex < _categoryItems.length - 1 ? _currentIndex + 1 : 0;
    _switchToItem(newIndex);
  }

  void _switchToItem(int index) {
    if (index < 0 || index >= _categoryItems.length) return;

    setState(() {
      _currentIndex = index;
      _currentItem = _categoryItems[index];
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = false;
    });

    _loadAudio();
  }

  // Audio control methods
  Future<void> _togglePlayPause() async {
    if (_isLoading) return;
    
    try {
      setState(() => _isLoading = true);
      
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position >= _duration || _position == Duration.zero) {
          await _loadAudio();
        }
        await _audioPlayer.resume();
      }
      
      // State will be updated by the onPlayerStateChanged listener
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Playback error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  


  void _rewind() async {
    final newPosition = _position - const Duration(seconds: 10);
    final targetPosition = newPosition.isNegative ? Duration.zero : newPosition;
    await _audioPlayer.seek(targetPosition);
  }

  void _forward() async {
    final newPosition = _position + const Duration(seconds: 10);
    final targetPosition = newPosition > _duration ? _duration : newPosition;
    await _audioPlayer.seek(targetPosition);
  }



  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() async {
    // Cancel all stream subscriptions first
    await _durationSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _completeSubscription?.cancel();

    // Stop and release audio player resources
    try {
      await _audioPlayer.stop();
      await _audioPlayer.release();
      await _audioPlayer.dispose();
    } catch (e) {
      // Ignore disposal errors
    }

    // Dispose animation controllers
    _waveController.dispose();
    _slideController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.appBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Now Playing',
          style: TextStyle(
            fontFamily: AppTheme.primaryFontFamily,
            fontWeight: FontWeight.w600,
            color: AppTheme.text,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          // Loop Toggle
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isLooping ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _isLooping ? AppTheme.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.repeat_rounded,
                color: _isLooping ? AppTheme.primary : AppTheme.text.withValues(alpha: 0.7),
                size: 16,
              ),
              onPressed: () {
                setState(() {
                  _isLooping = !_isLooping;
                });
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: _slideController,
            child: _buildMainContent(context),
          ),
        ),
      ),
    );
  }



  Widget _buildMainContent(BuildContext context) {
    if (_error != null) {
      return _buildErrorState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Track Info
          _buildTrackInfo(),

          const SizedBox(height: 60),

          // Visual Display
          _buildVisualDisplay(),

          const SizedBox(height: 60),

          // Progress Section
          _buildProgressSection(),

          const SizedBox(height: 40),

          // Controls
          _buildControlsSection(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Playback Error',
              style: TextStyle(
                fontFamily: AppTheme.primaryFontFamily,
                color: AppTheme.text,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontFamily: AppTheme.primaryFontFamily,
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      children: [
        Text(
          _currentItem.name,
          style: TextStyle(
            fontFamily: AppTheme.primaryFontFamily,
            fontWeight: FontWeight.w600,
            color: AppTheme.text,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          _currentItem.formattedDuration,
          style: TextStyle(
            fontFamily: AppTheme.primaryFontFamily,
            color: AppTheme.textMuted,
            fontSize: 16,
          ),
        ),
        if (_categoryItems.length > 1) ...[
          const SizedBox(height: 4),
          Text(
            '${_currentIndex + 1} of ${_categoryItems.length}',
            style: TextStyle(
              fontFamily: AppTheme.primaryFontFamily,
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        // Progress Bar
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: AppTheme.primary,
            overlayColor: AppTheme.primary.withValues(alpha: 0.3),
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          ),
          child: Slider(
            value: _duration.inMilliseconds > 0
                ? _position.inMilliseconds.toDouble()
                : 0.0,
            max: _duration.inMilliseconds.toDouble(),
            onChanged: (value) {
              final position = Duration(milliseconds: value.toInt());
              _audioPlayer.seek(position);
            },
          ),
        ),

        const SizedBox(height: 8),

        // Time Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_position),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: AppTheme.primaryFontFamily,
                color: AppTheme.textMuted,
              ),
            ),
            Text(
              _formatDuration(_duration),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: AppTheme.primaryFontFamily,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlsSection() {
    return Column(
      children: [
        // Main playback controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous Track (if multiple items)
            if (_categoryItems.length > 1)
              _buildControlButton(
                icon: Icons.skip_previous_rounded,
                onPressed: _playPrevious,
                size: 28,
              )
            else
              // Rewind 10s (if single item)
              _buildControlButton(
                icon: Icons.replay_10_rounded,
                onPressed: _rewind,
                size: 28,
              ),

            // Rewind 10s (always show when multiple items)
            if (_categoryItems.length > 1)
              _buildControlButton(
                icon: Icons.replay_10_rounded,
                onPressed: _rewind,
                size: 24,
              ),

            // Play/Pause Button
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  _isLoading ? Icons.hourglass_empty_rounded :
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 32,
                ),
                onPressed: _isLoading ? null : _togglePlayPause,
              ),
            ),

            // Forward 10s (always show when multiple items)
            if (_categoryItems.length > 1)
              _buildControlButton(
                icon: Icons.forward_10_rounded,
                onPressed: _forward,
                size: 24,
              ),

            // Next Track (if multiple items)
            if (_categoryItems.length > 1)
              _buildControlButton(
                icon: Icons.skip_next_rounded,
                onPressed: _playNext,
                size: 28,
              )
            else
              // Forward 10s (if single item)
              _buildControlButton(
                icon: Icons.forward_10_rounded,
                onPressed: _forward,
                size: 28,
              ),
          ],
        ),

        // Track info for multiple items
        if (_categoryItems.length > 1) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              'Track ${_currentIndex + 1} of ${_categoryItems.length}',
              style: TextStyle(
                fontFamily: AppTheme.primaryFontFamily,
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 24,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: AppTheme.text,
          size: size,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildVisualDisplay() {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading indicator when buffering
            if (_isLoading)
              Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.0,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontFamily: AppTheme.primaryFontFamily,
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            // Audio Waveform Visualization
            else if (_isPlaying)
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final delay = index * 0.2;
                          final animValue = (_waveController.value + delay) % 1.0;
                          final height = 30 + (50 * (0.5 + 0.5 * (animValue * 2 - 1).abs()));

                          return Container(
                            width: 8,
                            height: height,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Playing',
                        style: TextStyle(
                          fontFamily: AppTheme.primaryFontFamily,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                },
              )
            // Static music icon when paused
            else
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ready',
                    style: TextStyle(
                      fontFamily: AppTheme.primaryFontFamily,
                      color: AppTheme.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }



}
