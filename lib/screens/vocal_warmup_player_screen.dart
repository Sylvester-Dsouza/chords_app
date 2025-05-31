import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/inner_screen_app_bar.dart';

class WarmupPlayerScreen extends StatefulWidget {
  final String warmupName;
  final String warmupType;

  const WarmupPlayerScreen({
    super.key,
    required this.warmupName,
    required this.warmupType,
  });

  @override
  State<WarmupPlayerScreen> createState() => _WarmupPlayerScreenState();
}

class _WarmupPlayerScreenState extends State<WarmupPlayerScreen>
    with TickerProviderStateMixin {
  bool isPlaying = false;
  int currentStep = 0;
  double progress = 0.0;
  int remainingTime = 0;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _breathingController;

  // Mock warmup steps
  List<Map<String, dynamic>> warmupSteps = [];

  @override
  void initState() {
    super.initState();
    _initializeWarmupSteps();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Initialize remaining time
    if (warmupSteps.isNotEmpty) {
      remainingTime = warmupSteps[currentStep]['duration'] as int;
    }
  }

  void _initializeWarmupSteps() {
    switch (widget.warmupType) {
      case 'quick':
        warmupSteps = [
          {
            'title': 'Breathe & Center',
            'description': 'Take deep breaths to center yourself',
            'instruction': 'Inhale for 4 counts, hold for 4, exhale for 4',
            'duration': 60,
            'color': const Color(0xFF6366F1),
            'emoji': '🧘‍♀️',
            'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          },
          {
            'title': 'Lip Bubbles',
            'description': 'Gentle lip trills to warm up',
            'instruction': 'Make "brrr" sounds like a horse',
            'duration': 90,
            'color': const Color(0xFF00D4AA),
            'emoji': '💨',
            'gradient': [const Color(0xFF00D4AA), const Color(0xFF34D399)],
          },
          {
            'title': 'Vocal Scales',
            'description': 'Easy scales to wake up your voice',
            'instruction': 'Sing "Do-Re-Mi-Fa-Sol-Fa-Mi-Re-Do"',
            'duration': 120,
            'color': const Color(0xFFEC4899),
            'emoji': '🎵',
            'gradient': [const Color(0xFFEC4899), const Color(0xFFF472B6)],
          },
          {
            'title': 'Vocal Glides',
            'description': 'Smooth sirens from low to high',
            'instruction': 'Glide from your lowest to highest note',
            'duration': 90,
            'color': const Color(0xFF8B5CF6),
            'emoji': '🌊',
            'gradient': [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
          },
        ];
        break;
      case 'standard':
        warmupSteps = [
          {
            'title': 'Deep Breathing',
            'description': 'Foundation breathing exercises',
            'instruction': 'Focus on diaphragmatic breathing',
            'duration': 120,
            'color': const Color(0xFF6366F1),
            'emoji': '🫁',
            'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          },
          {
            'title': 'Lip Trills',
            'description': 'Extended lip bubble exercises',
            'instruction': 'Maintain steady airflow through lips',
            'duration': 150,
            'color': const Color(0xFF00D4AA),
            'emoji': '💨',
            'gradient': [const Color(0xFF00D4AA), const Color(0xFF34D399)],
          },
          {
            'title': 'Humming',
            'description': 'Gentle humming to engage resonance',
            'instruction': 'Hum with mouth closed, feel vibrations',
            'duration': 120,
            'color': const Color(0xFFF59E0B),
            'emoji': '🎶',
            'gradient': [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
          },
          {
            'title': 'Scale Practice',
            'description': 'Major scale exercises',
            'instruction': 'Sing scales with "Ah" vowel',
            'duration': 180,
            'color': const Color(0xFFEC4899),
            'emoji': '🎵',
            'gradient': [const Color(0xFFEC4899), const Color(0xFFF472B6)],
          },
          {
            'title': 'Vocal Flexibility',
            'description': 'Agility and range exercises',
            'instruction': 'Practice quick note changes',
            'duration': 150,
            'color': const Color(0xFF8B5CF6),
            'emoji': '🌊',
            'gradient': [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
          },
        ];
        break;
      default:
        warmupSteps = [
          {
            'title': 'Basic Warmup',
            'description': 'Simple vocal preparation',
            'instruction': 'Follow the guided exercises',
            'duration': 120,
            'color': const Color(0xFF6366F1),
            'emoji': '🎤',
            'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          },
        ];
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _breathingController.dispose();
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
            title: widget.warmupName,
          ),

          // Main Content - No Scroll, Fixed Layout
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Compact Progress Section
                  _buildCompactProgress(),

                  // Main Exercise Display (takes most space)
                  Expanded(
                    child: _buildCompactExerciseDisplay(),
                  ),

                  // Compact Controls at Bottom
                  _buildCompactControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Compact Progress Section
  Widget _buildCompactProgress() {
    if (warmupSteps.isEmpty) return const SizedBox();

    final currentExercise = warmupSteps[currentStep];
    final progressPercent = (currentStep + 1) / warmupSteps.length;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (currentExercise['color'] as Color).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Progress Bar and Counter
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: currentExercise['color'] as Color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${currentStep + 1}/${warmupSteps.length}',
                style: TextStyle(
                  color: currentExercise['color'] as Color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Step Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(warmupSteps.length, (index) {
              final isActive = index == currentStep;
              final isCompleted = index < currentStep;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: isActive ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isCompleted || isActive
                      ? currentExercise['color'] as Color
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Compact Exercise Display
  Widget _buildCompactExerciseDisplay() {
    if (warmupSteps.isEmpty) return const SizedBox();

    final currentExercise = warmupSteps[currentStep];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated Exercise Circle - Smaller
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: isPlaying ? 1.0 + (_pulseController.value * 0.06) : 1.0,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: currentExercise['gradient'] as List<Color>,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: isPlaying
                      ? [
                          BoxShadow(
                            color: (currentExercise['color'] as Color).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: (currentExercise['color'] as Color).withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    currentExercise['emoji'] as String,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Exercise Title - Smaller
        Text(
          currentExercise['title'] as String,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.primaryFontFamily,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Exercise Description - Smaller
        Text(
          currentExercise['description'] as String,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
            fontFamily: AppTheme.primaryFontFamily,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Instruction - Inline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Text(
            currentExercise['instruction'] as String,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontFamily: AppTheme.primaryFontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 20),

        // Timer Display - Smaller
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (currentExercise['color'] as Color).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Text(
            _formatDuration(remainingTime > 0 ? remainingTime : currentExercise['duration'] as int),
            style: TextStyle(
              color: currentExercise['color'] as Color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ),
      ],
    );
  }

  // Compact Controls
  Widget _buildCompactControls() {
    return Column(
      children: [
        // Main Play/Pause Button
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _togglePlayPause,
              borderRadius: BorderRadius.circular(35),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Secondary Controls Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous Step
            _buildCompactSecondaryButton(
              icon: Icons.skip_previous_rounded,
              onTap: currentStep > 0 ? _previousStep : null,
            ),

            // Restart Button
            _buildCompactSecondaryButton(
              icon: Icons.replay_rounded,
              onTap: _restartCurrent,
            ),

            // Next Step
            _buildCompactSecondaryButton(
              icon: Icons.skip_next_rounded,
              onTap: currentStep < warmupSteps.length - 1 ? _nextStep : null,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Status Text
        if (warmupSteps.isNotEmpty)
          Text(
            isPlaying ? 'In progress...' : 'Ready to start',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontFamily: AppTheme.primaryFontFamily,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildCompactSecondaryButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isEnabled
            ? const Color(0xFF1A1A1A)
            : const Color(0xFF1A1A1A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEnabled
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
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
            color: isEnabled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            size: 22,
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      _pulseController.repeat();
      _breathingController.repeat();
    } else {
      _pulseController.stop();
      _breathingController.stop();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
        isPlaying = false;
        remainingTime = warmupSteps[currentStep]['duration'] as int;
      });
      _pulseController.stop();
      _breathingController.stop();
    }
  }

  void _nextStep() {
    if (currentStep < warmupSteps.length - 1) {
      setState(() {
        currentStep++;
        isPlaying = false;
        remainingTime = warmupSteps[currentStep]['duration'] as int;
      });
      _pulseController.stop();
      _breathingController.stop();
    }
  }

  void _restartCurrent() {
    setState(() {
      isPlaying = false;
      if (warmupSteps.isNotEmpty) {
        remainingTime = warmupSteps[currentStep]['duration'] as int;
      }
    });
    _pulseController.stop();
    _pulseController.reset();
    _breathingController.stop();
    _breathingController.reset();
  }
}
