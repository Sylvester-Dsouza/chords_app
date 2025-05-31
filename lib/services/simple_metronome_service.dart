import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'metronome_audio_service.dart';

class SimpleMetronomeService extends ChangeNotifier {
  Timer? _timer;

  // Single audio player for better timing
  late AudioPlayer _audioPlayer;

  // Enhanced audio service for kick/hihat sounds
  final MetronomeAudioService _audioService = MetronomeAudioService();

  // Core properties
  int _bpm = 120;
  int _currentBeat = 1;
  int _beatsPerMeasure = 4;
  bool _isRunning = false;
  bool _isMuted = false;

  // Timing precision
  DateTime? _startTime;
  int _totalBeats = 0;

  // Count-in feature
  bool _useCountIn = true;
  final int _countInBeats = 4;
  bool _isCountingIn = false;
  int _countInRemaining = 0;

  // Visual feedback
  bool _showVisualBeat = true;

  // Audio type selection
  MetronomeAudioType _audioType = MetronomeAudioType.traditional;

  // Callbacks for UI updates
  Function(int beat, bool isAccented)? onBeat;
  Function()? onCountInComplete;
  Function(int remaining)? onCountInTick;

  SimpleMetronomeService() {
    // Initialize single audio player for better timing
    _audioPlayer = AudioPlayer();

    // Configure for low latency and immediate playback
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setPlayerMode(PlayerMode.lowLatency);

    debugPrint('🎵 Metronome service initialized with single audio player');
    debugPrint('   Will play: accent.wav (beat 1) and click.wav (beats 2,3,4)');
  }

  // Getters
  int get bpm => _bpm;
  int get currentBeat => _currentBeat;
  int get beatsPerMeasure => _beatsPerMeasure;
  bool get isRunning => _isRunning;
  bool get isMuted => _isMuted;
  bool get isCountingIn => _isCountingIn;
  int get countInRemaining => _countInRemaining;
  bool get useCountIn => _useCountIn;
  bool get showVisualBeat => _showVisualBeat;
  MetronomeAudioType get audioType => _audioType;

  // Setters
  set bpm(int value) {
    if (value >= 40 && value <= 300) {
      _bpm = value;
      if (_isRunning) {
        _restart();
      }
      notifyListeners();
    }
  }

  set beatsPerMeasure(int value) {
    if (value >= 2 && value <= 12) {
      _beatsPerMeasure = value;
      _currentBeat = 1;
      notifyListeners();
    }
  }

  set useCountIn(bool value) {
    _useCountIn = value;
    notifyListeners();
  }

  set showVisualBeat(bool value) {
    _showVisualBeat = value;
    notifyListeners();
  }

  set audioType(MetronomeAudioType value) {
    _audioType = value;
    _audioService.setAudioType(value);
    notifyListeners();
  }

  // Initialize audio service
  Future<void> initialize() async {
    await _audioService.initialize();
    _audioService.setAudioType(_audioType);
  }

  // Test your custom audio files
  Future<void> testAudio() async {
    debugPrint('🔊 Testing your custom audio files...');

    try {
      // Test click.wav (regular beat)
      debugPrint('   Testing click.wav...');
      await _audioPlayer.play(AssetSource('audio/click.wav'));
      await Future.delayed(const Duration(milliseconds: 800));

      // Test accent.wav (accent beat)
      debugPrint('   Testing accent.wav...');
      await _audioPlayer.play(AssetSource('audio/accent.wav'));
      await Future.delayed(const Duration(milliseconds: 800));

      debugPrint('✅ Custom audio test completed');
    } catch (e) {
      debugPrint('⚠️ Audio test failed: $e');
      debugPrint('   Make sure accent.wav and click.wav are in assets/audio/');
    }
  }

  // Core metronome functions
  Future<void> start() async {
    if (_isRunning) return;

    if (_useCountIn && _countInBeats > 0) {
      await _startCountIn();
    } else {
      await _startMetronome();
    }
  }

  void stop() {
    debugPrint('🛑 Stopping metronome...');
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isCountingIn = false;
    _currentBeat = 1;
    _countInRemaining = 0;
    _startTime = null;
    _totalBeats = 0;
    notifyListeners();
    debugPrint('✅ Metronome stopped successfully');
  }

  void pause() {
    debugPrint('⏸️ Pausing metronome...');
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isCountingIn = false;
    notifyListeners();
    debugPrint('✅ Metronome paused successfully');
  }

  Future<void> resume() async {
    if (!_isRunning) {
      await _startMetronome();
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isRunning || _isCountingIn) {
      stop();
    } else {
      start();
    }
  }

  // Tempo adjustment functions
  void increaseTempo({int amount = 5}) {
    bpm = (_bpm + amount).clamp(40, 300);
  }

  void decreaseTempo({int amount = 5}) {
    bpm = (_bpm - amount).clamp(40, 300);
  }

  void setTempoPercentage(double percentage) {
    // For practice mode - set tempo as percentage of original
    int baseTempo = 120; // Default base tempo
    bpm = (baseTempo * percentage).round().clamp(40, 300);
  }

  // Private methods
  Future<void> _startCountIn() async {
    _isCountingIn = true;
    _countInRemaining = _countInBeats;
    _currentBeat = 1;

    _timer = Timer.periodic(_getBeatDuration(), (timer) {
      if (_countInRemaining > 0) {
        _playCountInSound();
        onCountInTick?.call(_countInRemaining);
        _countInRemaining--;
        notifyListeners();
      } else {
        _isCountingIn = false;
        onCountInComplete?.call();
        _startMetronome();
      }
    });
  }

  Future<void> _startMetronome() async {
    _isRunning = true;
    _currentBeat = 1;
    _totalBeats = 0;
    _startTime = DateTime.now();

    // Cancel any existing timer first
    _timer?.cancel();

    // Use a more frequent timer for better precision
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _checkAndTick();
    });

    notifyListeners();
    debugPrint('🎼 Metronome started at $_bpm BPM with precise timing');
  }

  void _checkAndTick() {
    if (_startTime == null) return;

    // Calculate how many beats should have played by now
    final elapsed = DateTime.now().difference(_startTime!);
    final expectedBeats = (elapsed.inMilliseconds * _bpm / 60000).floor();

    // If we're behind, play the next beat
    if (expectedBeats > _totalBeats) {
      _totalBeats = expectedBeats;
      _tick();
    }
  }

  void _restart() {
    if (_isRunning) {
      _timer?.cancel();
      _startMetronome();
    }
  }

  void _tick() {
    bool isAccented = _currentBeat == 1; // Accent first beat

    // Play sound (fire and forget for precise timing)
    if (!_isMuted) {
      _playBeatSound(isAccented);
    } else {
      // If muted, still provide haptic feedback
      if (isAccented) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }

    // Notify listeners about the beat
    onBeat?.call(_currentBeat, isAccented);

    // Move to next beat
    _currentBeat++;
    if (_currentBeat > _beatsPerMeasure) {
      _currentBeat = 1;
    }

    notifyListeners();
  }

  Duration _getBeatDuration() {
    return Duration(milliseconds: (60000 / _bpm).round());
  }

  void _playBeatSound(bool isAccented) {
    if (_isMuted) return;

    // Use enhanced audio service for better sound options
    _audioService.playBeat(isAccented);

    // Keep haptic feedback for better user experience
    if (isAccented) {
      HapticFeedback.heavyImpact();
      debugPrint('🥁 Beat $_currentBeat - ACCENT (${_audioType.displayName} + heavy haptic)');
    } else {
      HapticFeedback.lightImpact();
      debugPrint('🥁 Beat $_currentBeat - regular (${_audioType.displayName} + light haptic)');
    }
  }

  void _playCountInSound() {
    if (_isMuted) return;

    // Use enhanced audio service for count-in
    _audioService.playCountIn();
    HapticFeedback.selectionClick();
    debugPrint('🎵 Count-in $_countInRemaining (${_audioType.displayName} + selection haptic)');
  }

  // Get tempo as percentage (useful for practice mode)
  double getTempoPercentage(int originalTempo) {
    return _bpm / originalTempo;
  }

  // Get beat progress (0.0 to 1.0 within current beat)
  double getBeatProgress() {
    // This would require more precise timing, simplified for now
    return 0.0;
  }

  @override
  void dispose() {
    _timer?.cancel();

    // Dispose audio player and enhanced audio service
    _audioPlayer.dispose();
    _audioService.dispose();

    super.dispose();
  }
}

// Simple data classes for practice mode
class PracticeSettings {
  final int originalTempo;
  final double tempoPercentage;
  final bool useCountIn;
  final int beatsPerMeasure;
  final bool visualBeatEnabled;

  PracticeSettings({
    required this.originalTempo,
    this.tempoPercentage = 1.0,
    this.useCountIn = true,
    this.beatsPerMeasure = 4,
    this.visualBeatEnabled = true,
  });
}
