import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/karaoke.dart';
import '../config/theme.dart';

class MultiTrackControls extends StatefulWidget {
  final Map<TrackType, AudioPlayer> trackPlayers;
  final Map<TrackType, bool> trackMuted;
  final Map<TrackType, double> trackVolumes;
  final Map<TrackType, IconData> trackIcons;
  final Map<TrackType, Color> trackColors;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final Function(Duration) onSeek;
  final Function(TrackType) onToggleTrackMute;
  final Function(TrackType, double) onSetTrackVolume;

  const MultiTrackControls({
    super.key,
    required this.trackPlayers,
    required this.trackMuted,
    required this.trackVolumes,
    required this.trackIcons,
    required this.trackColors,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onSeek,
    required this.onToggleTrackMute,
    required this.onSetTrackVolume,
  });

  @override
  State<MultiTrackControls> createState() => _MultiTrackControlsState();
}

class _MultiTrackControlsState extends State<MultiTrackControls> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 24),
                
                // Track Controls
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: TrackType.values.map((trackType) {
                      return _buildTrackControl(trackType);
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Export Button (like Moises)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.download,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Export',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTheme.primaryFontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // Bottom Player Controls
          _buildBottomPlayerControls(),
        ],
      ),
    );
  }

  Widget _buildTrackControl(TrackType trackType) {
    final isMuted = widget.trackMuted[trackType] ?? false;
    final volume = widget.trackVolumes[trackType] ?? 1.0;
    final icon = widget.trackIcons[trackType] ?? Icons.music_note;
    final color = widget.trackColors[trackType] ?? AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          // Track Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Volume Slider
          Expanded(
            child: Column(
              children: [
                // Custom Slider that looks like Moises
                SizedBox(
                  height: 40,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                        pressedElevation: 8,
                      ),
                      thumbColor: color,
                      activeTrackColor: color,
                      inactiveTrackColor: color.withValues(alpha: 0.2),
                      overlayColor: color.withValues(alpha: 0.1),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                    ),
                    child: Slider(
                      value: isMuted ? 0.0 : volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        if (value == 0.0 && !isMuted) {
                          widget.onToggleTrackMute(trackType);
                        } else if (value > 0.0 && isMuted) {
                          widget.onToggleTrackMute(trackType);
                          widget.onSetTrackVolume(trackType, value);
                        } else if (!isMuted) {
                          widget.onSetTrackVolume(trackType, value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // More Options Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
              border: Border.all(
                color: AppTheme.border,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                },
                borderRadius: BorderRadius.circular(20),
                child: Icon(
                  Icons.more_vert,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPlayerControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(
            color: AppTheme.border,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Progress Bar
          Row(
            children: [
              Text(
                _formatDuration(widget.position),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      thumbColor: AppTheme.primary,
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.border,
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: widget.duration.inMilliseconds > 0
                          ? widget.position.inMilliseconds / widget.duration.inMilliseconds
                          : 0.0,
                      onChanged: (value) {
                        final newPosition = Duration(
                          milliseconds: (value * widget.duration.inMilliseconds).round(),
                        );
                        widget.onSeek(newPosition);
                      },
                    ),
                  ),
                ),
              ),
              Text(
                _formatDuration(widget.duration),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Player Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Metronome Button
              _buildControlButton(
                icon: Icons.av_timer,
                onTap: () {
                },
              ),
              
              // Previous Button
              _buildControlButton(
                icon: Icons.skip_previous,
                onTap: () {
                  widget.onSeek(Duration.zero);
                },
              ),

              // Play/Pause Button
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPlayPause,
                    borderRadius: BorderRadius.circular(32),
                    child: Icon(
                      widget.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ),
              ),

              // Next Button
              _buildControlButton(
                icon: Icons.skip_next,
                onTap: () {
                  widget.onSeek(widget.duration);
                },
              ),
              
              // Playlist Button
              _buildControlButton(
                icon: Icons.playlist_play,
                onTap: () {
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.background,
        border: Border.all(
          color: AppTheme.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Icon(
            icon,
            color: AppTheme.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
