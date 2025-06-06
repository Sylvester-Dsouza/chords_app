import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/simple_metronome_service.dart';
import '../../config/theme.dart';

class MetronomeWidget extends StatefulWidget {
  final SimpleMetronomeService metronomeService;
  final bool showBeatIndicator;
  final bool showCountIn;

  const MetronomeWidget({
    super.key,
    required this.metronomeService,
    this.showBeatIndicator = true,
    this.showCountIn = true,
  });

  @override
  State<MetronomeWidget> createState() => _MetronomeWidgetState();
}

class _MetronomeWidgetState extends State<MetronomeWidget>
    with TickerProviderStateMixin {
  late AnimationController _beatController;
  late AnimationController _pendulumController;
  late Animation<double> _beatAnimation;
  late Animation<double> _pendulumAnimation;

  @override
  void initState() {
    super.initState();
    
    // Beat pulse animation
    _beatController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _beatAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _beatController,
      curve: Curves.elasticOut,
    ));

    // Pendulum animation
    _pendulumController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pendulumAnimation = Tween<double>(
      begin: -0.3,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _pendulumController,
      curve: Curves.easeInOut,
    ));

    // Listen to metronome beats
    widget.metronomeService.onBeat = (beat, isAccented) {
      _onBeat(beat, isAccented);
    };

    widget.metronomeService.onCountInTick = (remaining) {
      _onCountInTick(remaining);
    };
  }

  void _onBeat(int beat, bool isAccented) {
    if (mounted) {
      // Trigger beat animation
      _beatController.forward().then((_) {
        _beatController.reverse();
      });

      // Update pendulum direction
      if (beat % 2 == 1) {
        _pendulumController.forward();
      } else {
        _pendulumController.reverse();
      }
    }
  }

  void _onCountInTick(int remaining) {
    if (mounted) {
      // Trigger beat animation for count-in
      _beatController.forward().then((_) {
        _beatController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _beatController.dispose();
    _pendulumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.metronomeService,
      builder: (context, child) {
        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Count-in display
              if (widget.showCountIn && widget.metronomeService.isCountingIn)
                _buildCountInDisplay(),
              
              // Main metronome display
              if (!widget.metronomeService.isCountingIn)
                Expanded(child: _buildMetronomeDisplay()),
              
              const SizedBox(height: 16),
              
              // Beat indicators
              if (widget.showBeatIndicator)
                _buildBeatIndicators(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountInDisplay() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Get Ready...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _beatAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _beatAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${widget.metronomeService.countInRemaining}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetronomeDisplay() {
    return Row(
      children: [
        // Pendulum metronome
        Expanded(
          flex: 2,
          child: _buildPendulum(),
        ),
        
        // Beat circle
        Expanded(
          child: _buildBeatCircle(),
        ),
      ],
    );
  }

  Widget _buildPendulum() {
    return Center(
      child: SizedBox(
        width: 100,
        height: 150,
        child: AnimatedBuilder(
          animation: _pendulumAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: PendulumPainter(
                angle: _pendulumAnimation.value,
                isActive: widget.metronomeService.isRunning,
              ),
              size: const Size(100, 150),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBeatCircle() {
    return Center(
      child: AnimatedBuilder(
        animation: _beatAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _beatAnimation.value,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.metronomeService.isRunning
                    ? AppTheme.primary
                    : Colors.grey[700],
                boxShadow: widget.metronomeService.isRunning
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.music_note,
                color: widget.metronomeService.isRunning ? Colors.black : Colors.white,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBeatIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.metronomeService.beatsPerMeasure,
        (index) => _buildBeatDot(index + 1),
      ),
    );
  }

  Widget _buildBeatDot(int beatNumber) {
    bool isCurrentBeat = widget.metronomeService.currentBeat == beatNumber;
    bool isFirstBeat = beatNumber == 1;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrentBeat
            ? AppTheme.primary
            : isFirstBeat
                ? Colors.white
                : Colors.grey[600],
        border: isFirstBeat && !isCurrentBeat
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
    );
  }
}

class PendulumPainter extends CustomPainter {
  final double angle;
  final bool isActive;

  PendulumPainter({required this.angle, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? Colors.white : Colors.grey[600]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final bobPaint = Paint()
      ..color = isActive ? AppTheme.primary : Colors.grey[700]!
      ..style = PaintingStyle.fill;

    // Pendulum rod
    final center = Offset(size.width / 2, 20);
    final rodLength = size.height - 40;
    final bobCenter = Offset(
      center.dx + math.sin(angle) * rodLength,
      center.dy + math.cos(angle) * rodLength,
    );

    // Draw rod
    canvas.drawLine(center, bobCenter, paint);

    // Draw pivot point
    canvas.drawCircle(center, 4, paint);

    // Draw bob
    canvas.drawCircle(bobCenter, 12, bobPaint);

    // Draw bob highlight
    if (isActive) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(bobCenter.dx - 3, bobCenter.dy - 3),
        4,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(PendulumPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.isActive != isActive;
  }
}
