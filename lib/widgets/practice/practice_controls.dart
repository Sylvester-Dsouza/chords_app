import 'package:flutter/material.dart';
import '../../services/simple_metronome_service.dart';
import '../../services/chord_timing_service.dart';
import '../../config/theme.dart';

class PracticeControls extends StatefulWidget {
  final SimpleMetronomeService metronomeService;
  final ChordTimingService chordTimingService;
  final int originalTempo;
  final Function(double)? onTempoChanged;

  const PracticeControls({
    super.key,
    required this.metronomeService,
    required this.chordTimingService,
    required this.originalTempo,
    this.onTempoChanged,
  });

  @override
  State<PracticeControls> createState() => _PracticeControlsState();
}

class _PracticeControlsState extends State<PracticeControls> {
  double _tempoPercentage = 1.0;

  @override
  void initState() {
    super.initState();
    _tempoPercentage = widget.metronomeService.bpm / widget.originalTempo;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous section
              _buildControlButton(
                icon: Icons.skip_previous,
                onPressed: () => widget.chordTimingService.previousSection(),
                tooltip: 'Previous Section',
              ),
              
              // Play/Pause
              ListenableBuilder(
                listenable: widget.metronomeService,
                builder: (context, child) {
                  return _buildControlButton(
                    icon: widget.metronomeService.isRunning || widget.metronomeService.isCountingIn
                        ? Icons.pause
                        : Icons.play_arrow,
                    onPressed: () => widget.metronomeService.togglePlayPause(),
                    tooltip: widget.metronomeService.isRunning ? 'Pause' : 'Play',
                    isPrimary: true,
                  );
                },
              ),
              
              // Next section
              _buildControlButton(
                icon: Icons.skip_next,
                onPressed: () => widget.chordTimingService.nextSection(),
                tooltip: 'Next Section',
              ),
              
              // Loop toggle
              ListenableBuilder(
                listenable: widget.chordTimingService,
                builder: (context, child) {
                  return _buildControlButton(
                    icon: Icons.repeat,
                    onPressed: () => widget.chordTimingService.toggleLoop(null),
                    tooltip: 'Loop Section',
                    isActive: widget.chordTimingService.isLooping,
                  );
                },
              ),
              
              // Mute toggle
              ListenableBuilder(
                listenable: widget.metronomeService,
                builder: (context, child) {
                  return _buildControlButton(
                    icon: widget.metronomeService.isMuted 
                        ? Icons.volume_off 
                        : Icons.volume_up,
                    onPressed: () => widget.metronomeService.toggleMute(),
                    tooltip: widget.metronomeService.isMuted ? 'Unmute' : 'Mute',
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tempo control
          _buildTempoControl(),
          
          const SizedBox(height: 12),
          
          // BPM display and count-in toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // BPM display
              ListenableBuilder(
                listenable: widget.metronomeService,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '♩ = ${widget.metronomeService.bpm}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  );
                },
              ),
              
              // Count-in toggle
              ListenableBuilder(
                listenable: widget.metronomeService,
                builder: (context, child) {
                  return Row(
                    children: [
                      const Text(
                        'Count-in',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: widget.metronomeService.useCountIn,
                        onChanged: (value) {
                          widget.metronomeService.useCountIn = value;
                        },
                        activeColor: AppTheme.primaryColor,
                        inactiveThumbColor: Colors.grey[600],
                        inactiveTrackColor: Colors.grey[800],
                      ),
                    ],
                  );
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
    required VoidCallback onPressed,
    required String tooltip,
    bool isPrimary = false,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPrimary 
              ? AppTheme.primaryColor
              : isActive 
                  ? AppTheme.primaryColor.withValues(alpha: 0.3)
                  : Colors.grey[800],
          border: isActive && !isPrimary
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : null,
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: isPrimary ? Colors.black : Colors.white,
            size: isPrimary ? 32 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTempoControl() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Tempo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
            const Spacer(),
            Text(
              '${(_tempoPercentage * 100).round()}%',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Row(
          children: [
            // Tempo decrease button
            IconButton(
              onPressed: () => _adjustTempo(-0.05),
              icon: const Icon(Icons.remove, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[800],
                shape: const CircleBorder(),
              ),
            ),
            
            // Tempo slider
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: Colors.grey[700],
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: _tempoPercentage,
                  min: 0.5,
                  max: 1.5,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      _tempoPercentage = value;
                    });
                    _updateTempo(value);
                  },
                ),
              ),
            ),
            
            // Tempo increase button
            IconButton(
              onPressed: () => _adjustTempo(0.05),
              icon: const Icon(Icons.add, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[800],
                shape: const CircleBorder(),
              ),
            ),
          ],
        ),
        
        // Tempo presets
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTempoPreset('50%', 0.5),
            _buildTempoPreset('75%', 0.75),
            _buildTempoPreset('100%', 1.0),
            _buildTempoPreset('125%', 1.25),
          ],
        ),
      ],
    );
  }

  Widget _buildTempoPreset(String label, double percentage) {
    bool isSelected = (_tempoPercentage - percentage).abs() < 0.01;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _tempoPercentage = percentage;
        });
        _updateTempo(percentage);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: Colors.grey[600]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
      ),
    );
  }

  void _adjustTempo(double delta) {
    double newPercentage = (_tempoPercentage + delta).clamp(0.5, 1.5);
    setState(() {
      _tempoPercentage = newPercentage;
    });
    _updateTempo(newPercentage);
  }

  void _updateTempo(double percentage) {
    int newBpm = (widget.originalTempo * percentage).round().clamp(40, 300);
    widget.metronomeService.bpm = newBpm;
    widget.onTempoChanged?.call(percentage);
  }
}
