import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/inner_screen_app_bar.dart';

class ExercisePlayerScreen extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const ExercisePlayerScreen({
    super.key,
    required this.exercise,
  });

  @override
  State<ExercisePlayerScreen> createState() => _ExercisePlayerScreenState();
}

class _ExercisePlayerScreenState extends State<ExercisePlayerScreen>
    with TickerProviderStateMixin {
  bool isPlaying = false;
  bool isLooping = false;
  double currentPosition = 0.0;
  double totalDuration = 100.0; // Mock duration
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Custom App Bar
          InnerScreenAppBar(
            title: widget.exercise['title'] as String,
          ),

          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Exercise Info Header
                  _buildExerciseHeader(),

                  const SizedBox(height: 32),

                  // Visual Display
                  Expanded(
                    child: _buildVisualDisplay(),
                  ),

                  const SizedBox(height: 32),

                  // Audio Controls
                  _buildAudioControls(),

                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (widget.exercise['color'] as Color).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Exercise Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (widget.exercise['color'] as Color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                widget.exercise['emoji'] as String,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Exercise Title
          Text(
            widget.exercise['title'] as String,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: AppTheme.primaryFontFamily,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Exercise Description
          Text(
            widget.exercise['description'] as String,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 15,
              fontFamily: AppTheme.primaryFontFamily,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Exercise Meta
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Duration
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (widget.exercise['color'] as Color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.exercise['duration']}m',
                  style: TextStyle(
                    color: widget.exercise['color'] as Color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Difficulty
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(widget.exercise['difficulty'] as String).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.exercise['difficulty'] as String,
                  style: TextStyle(
                    color: _getDifficultyColor(widget.exercise['difficulty'] as String),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.exercise['category'] as String,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Exercise Visual
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: isPlaying ? 1.0 + (_pulseController.value * 0.1) : 1.0,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: (widget.exercise['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (widget.exercise['color'] as Color).withValues(alpha: 0.3),
                      width: 3,
                    ),
                    boxShadow: isPlaying
                        ? [
                            BoxShadow(
                              color: (widget.exercise['color'] as Color).withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      widget.exercise['emoji'] as String,
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Instructions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Instructions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getExerciseInstructions(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Progress Bar
          Row(
            children: [
              Text(
                _formatDuration(currentPosition),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              Expanded(
                child: Slider(
                  value: currentPosition,
                  max: totalDuration,
                  onChanged: (value) {
                    setState(() {
                      currentPosition = value;
                    });
                  },
                  activeColor: widget.exercise['color'] as Color,
                  inactiveColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              Text(
                _formatDuration(totalDuration),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rewind
              _buildControlButton(
                icon: Icons.replay_10_rounded,
                onTap: _rewind,
              ),

              const SizedBox(width: 24),

              // Play/Pause
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: widget.exercise['color'] as Color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.exercise['color'] as Color).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _togglePlayPause,
                    borderRadius: BorderRadius.circular(36),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Forward
              _buildControlButton(
                icon: Icons.forward_10_rounded,
                onTap: _forward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Loop Button
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isLooping
                  ? (widget.exercise['color'] as Color).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLooping
                    ? (widget.exercise['color'] as Color).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleLoop,
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      color: isLooping
                          ? widget.exercise['color'] as Color
                          : Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loop',
                      style: TextStyle(
                        color: isLooping
                            ? widget.exercise['color'] as Color
                            : Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Restart Button
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _restart,
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.replay_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Restart',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
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
            color: Colors.white.withValues(alpha: 0.8),
            size: 20,
          ),
        ),
      ),
    );
  }

  String _getExerciseInstructions() {
    final type = widget.exercise['type'] as String;
    final title = widget.exercise['title'] as String;

    switch (type) {
      case 'breathing':
        return 'Focus on deep, controlled breathing. Keep your shoulders relaxed and breathe from your diaphragm.';
      case 'scales':
        if (title.contains('Do-Re-Mi')) {
          return 'Sing along with the piano: Do-Re-Mi-Fa-Sol-Fa-Mi-Re-Do. Focus on pitch accuracy and smooth transitions.';
        } else if (title.contains('Chromatic')) {
          return 'Sing each half-step clearly. Use "La" or "Ah" vowel sounds for smooth transitions.';
        } else if (title.contains('Arpeggio')) {
          return 'Sing the broken chord pattern smoothly. Focus on clean intervals and  agility.';
        }
        return 'Follow the scale pattern with clear pitch accuracy. Use consistent vowel sounds.';
      case 'range':
        return 'Start gently and gradually expand your range. Don\'t strain - let your voice flow naturally.';
      case 'agility':
        return 'Start slowly and build up speed. Focus on clarity and precision in each note.';
      case 'contemporary':
        return 'Practice modern  techniques. Focus on power and control while maintaining healthy technique.';
      case 'worship':
        return 'Practice with worship in mind. Focus on expression, sustain, and blending techniques.';
      default:
        return 'Follow along with the audio guide. Focus on proper technique and breath support.';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF00D4AA);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'pro':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      _pulseController.repeat();
      _waveController.repeat();
    } else {
      _pulseController.stop();
      _waveController.stop();
    }
  }

  void _toggleLoop() {
    setState(() {
      isLooping = !isLooping;
    });
  }

  void _restart() {
    setState(() {
      currentPosition = 0.0;
      isPlaying = false;
    });
    _pulseController.stop();
    _waveController.stop();
    _pulseController.reset();
    _waveController.reset();
  }

  void _rewind() {
    setState(() {
      currentPosition = (currentPosition - 10).clamp(0.0, totalDuration);
    });
  }

  void _forward() {
    setState(() {
      currentPosition = (currentPosition + 10).clamp(0.0, totalDuration);
    });
  }
}