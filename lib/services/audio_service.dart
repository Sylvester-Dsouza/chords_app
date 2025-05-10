import 'dart:async';
import 'dart:math' as math;

/// A simplified audio service that simulates audio capture for the guitar tuner
class AudioService {
  // Stream for detected string and tuning status
  final StreamController<TuningResult> _tuningResultController = StreamController<TuningResult>.broadcast();
  Stream<TuningResult> get tuningResultStream => _tuningResultController.stream;

  Timer? _simulationTimer;

  // Guitar string frequencies
  final Map<String, double> standardTuning = {
    'E': 82.41, // E2 (low E)
    'A': 110.00, // A2
    'D': 146.83, // D3
    'G': 196.00, // G3
    'B': 246.94, // B3
    'e': 329.63, // E4 (high E)
  };

  // Tuning status constants
  static const double tunedThreshold = 0.02; // 2% tolerance for "in tune"

  AudioService() {
    // Start listening automatically when service is created
    _startListening();
  }

  // Track the last detected string and time
  String? _lastDetectedString;
  int _lastDetectionTime = 0;
  int _silenceCounter = 0;
  bool _isStringPlaying = false;

  /// Start listening to audio (simulated)
  void _startListening() {
    // Simulate string detection with a more realistic approach
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final random = math.Random();

      // Simulate periods of silence (no string being played)
      // This makes the tuner only respond when a string is actually being played
      if (!_isStringPlaying) {
        // Randomly decide if a string is being played (10% chance per tick)
        if (random.nextDouble() < 0.1) {
          _isStringPlaying = true;
          _silenceCounter = 0;

          // When a new string is played, select one randomly
          final strings = standardTuning.keys.toList();
          _lastDetectedString = strings[random.nextInt(strings.length)];
          _lastDetectionTime = now;
        } else {
          // No string is being played, don't send any detection
          return;
        }
      } else {
        // If a string is playing, it will continue for a while then stop
        // This simulates the natural decay of a guitar string
        _silenceCounter++;

        // After about 2 seconds (13 ticks at 150ms), stop the string
        if (_silenceCounter > 13) {
          _isStringPlaying = false;
          return;
        }
      }

      // If we get here, we're detecting a string
      final detectedString = _lastDetectedString!;
      final targetFrequency = standardTuning[detectedString]!;

      // Create a more realistic tuning simulation
      // The frequency will gradually move toward being in tune over time
      // This simulates the user adjusting the tuning peg
      final timeSinceDetection = now - _lastDetectionTime;
      final timeNormalized = math.min(timeSinceDetection / 2000, 1.0); // 0.0 to 1.0 over 2 seconds

      // Start with a larger offset that gradually decreases
      final maxOffset = 0.08 * (1.0 - timeNormalized); // Offset decreases over time
      final offset = (random.nextDouble() * maxOffset) - (maxOffset / 2); // Centered around 0

      final detectedFrequency = targetFrequency * (1 + offset);

      // Calculate how far off the tuning is
      final percentageOff = (detectedFrequency - targetFrequency) / targetFrequency;

      // Determine tuning status
      TuningStatus status;
      if (percentageOff.abs() < tunedThreshold) {
        status = TuningStatus.inTune;
      } else if (percentageOff < 0) {
        status = TuningStatus.tooLow;
      } else {
        status = TuningStatus.tooHigh;
      }

      // Send the result
      _tuningResultController.add(
        TuningResult(
          string: detectedString,
          detectedFrequency: detectedFrequency,
          targetFrequency: targetFrequency,
          tuningStatus: status,
          percentageOff: percentageOff,
        )
      );
    });
  }

  /// Dispose resources
  void dispose() {
    _simulationTimer?.cancel();
    _tuningResultController.close();
  }
}

/// Represents the result of a tuning detection
class TuningResult {
  final String string;
  final double detectedFrequency;
  final double targetFrequency;
  final TuningStatus tuningStatus;
  final double percentageOff;

  TuningResult({
    required this.string,
    required this.detectedFrequency,
    required this.targetFrequency,
    required this.tuningStatus,
    required this.percentageOff,
  });
}

/// Enum representing the tuning status
enum TuningStatus {
  tooLow,
  inTune,
  tooHigh,
}
