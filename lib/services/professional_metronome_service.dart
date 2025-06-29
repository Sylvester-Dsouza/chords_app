import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:metronome/metronome.dart';

/// Professional metronome service using the metronome package
/// This provides accurate, efficient, and cross-platform metronome functionality
class ProfessionalMetronomeService {
  // Remove singleton pattern to ensure proper disposal
  ProfessionalMetronomeService();

  // Keep track of active instances for emergency cleanup
  static final List<ProfessionalMetronomeService> _activeInstances = [];

  /// Emergency stop all active metronome instances
  static void stopAllInstances() {
    debugPrint('🚨 Emergency stop all metronome instances');
    for (final instance in _activeInstances) {
      try {
        instance.stop();
      } catch (e) {
        debugPrint('❌ Error stopping instance: $e');
      }
    }
  }

  // Metronome instance
  final Metronome _metronome = Metronome();
  
  // Metronome state
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isEnabled = true;
  
  // Metronome settings
  int _bpm = 120;
  int _beatsPerMeasure = 4;
  int _volume = 50; // 0-100
  int _currentBeat = 0;
  String _soundType = 'hihat'; // 'click', 'wood', 'beep', 'hihat' - default to hihat (known working)
  
  // Callback for beat events
  Function(int beat, bool isAccented)? onBeat;
  
  // Stream subscription for tick events
  StreamSubscription<int>? _tickSubscription;

  /// Initialize the professional metronome service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🎵 Initializing Professional Metronome...');

      // Add to active instances for tracking
      if (!_activeInstances.contains(this)) {
        _activeInstances.add(this);
      }

      // Try to initialize with the selected sound, with fallback to hihat
      await _initializeWithFallback();

      // Listen to tick events
      _tickSubscription = _metronome.tickStream.listen((int tick) {
        _onTick(tick);
      });

      _isInitialized = true;
      debugPrint('✅ Professional Metronome initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Professional Metronome: $e');
      _isInitialized = false;
    }
  }

  /// Initialize metronome with fallback mechanism
  Future<void> _initializeWithFallback() async {
    final soundPath = _getSoundPath(_soundType);
    debugPrint('🎵 Attempting to load sound: $soundPath for type: $_soundType');

    // List of sounds to try in order of preference (hihat first as it's known to work)
    final soundsToTry = [
      {'type': 'hihat', 'path': 'assets/audio/hihat.wav'}, // Known working file first
      {'type': _soundType, 'path': soundPath}, // User's selected sound
      {'type': 'click', 'path': 'assets/audio/click.wav'},
      {'type': 'wood', 'path': 'assets/audio/wood.wav'},
      {'type': 'beep', 'path': 'assets/audio/beep.wav'},
    ];

    // Remove duplicates while preserving order
    final uniqueSounds = <String, Map<String, String>>{};
    for (final sound in soundsToTry) {
      uniqueSounds[sound['path']!] = sound;
    }

    Exception? lastError;

    for (final sound in uniqueSounds.values) {
      try {
        debugPrint('🔄 Trying to load: ${sound['path']} (${sound['type']})');

        await _metronome.init(
          sound['path']!,
          accentedPath: sound['path']!,
          bpm: _bpm,
          volume: _volume,
          enableTickCallback: true,
          timeSignature: _beatsPerMeasure,
          sampleRate: 44100,
        );

        debugPrint('✅ Successfully loaded: ${sound['path']} (${sound['type']})');
        _soundType = sound['type']!; // Update to reflect what actually loaded
        return; // Success! Exit the method

      } catch (e) {
        debugPrint('❌ Failed to load ${sound['path']}: $e');
        lastError = e as Exception;

        // Try to destroy the failed metronome instance before trying the next one
        try {
          await _metronome.destroy();
        } catch (destroyError) {
          debugPrint('⚠️ Error destroying failed metronome: $destroyError');
        }
      }
    }

    // If we get here, all sounds failed
    debugPrint('💥 All audio files failed to load!');
    if (lastError != null) {
      throw lastError;
    } else {
      throw Exception('No audio files could be loaded');
    }
  }

  /// Handle metronome tick events
  void _onTick(int tick) {
    debugPrint('🔍 Raw tick from metronome package: $tick, beatsPerMeasure: $_beatsPerMeasure');

    // The metronome package is giving us 0-based ticks: 0, 1, 2, 3 for 4/4 time
    // We need to convert this to 1-based: 1, 2, 3, 4
    if (tick == 0) {
      _currentBeat = _beatsPerMeasure; // 0 becomes the last beat (4 in 4/4 time)
    } else {
      _currentBeat = tick; // 1, 2, 3 stay as they are
    }

    final isAccented = _currentBeat == 1;

    debugPrint('🥁 Beat: $_currentBeat ${isAccented ? "(ACCENT)" : "(regular)"} ${_isEnabled ? "♪" : "🔇"}');

    // Trigger haptic feedback
    if (isAccented) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    // Call beat callback
    onBeat?.call(_currentBeat, isAccented);
  }

  /// Start the metronome
  void start() {
    if (!_isInitialized || _isPlaying) return;

    try {
      _metronome.play();
      _isPlaying = true;
      debugPrint('🎼 Professional metronome started at $_bpm BPM');
    } catch (e) {
      debugPrint('❌ Error starting metronome: $e');
    }
  }

  /// Stop the metronome
  void stop() {
    try {
      if (_isInitialized) {
        _metronome.stop();
      }
      _isPlaying = false;
      _currentBeat = 0;
      debugPrint('🛑 Professional metronome stopped');
    } catch (e) {
      debugPrint('❌ Error stopping metronome: $e');
      // Force stop even if there's an error
      _isPlaying = false;
      _currentBeat = 0;
    }
  }

  /// Set BPM (beats per minute)
  set bpm(int newBpm) {
    _bpm = newBpm.clamp(60, 300);
    
    if (_isInitialized) {
      try {
        _metronome.setBPM(_bpm);
        debugPrint('🎵 BPM changed to $_bpm');
      } catch (e) {
        debugPrint('❌ Error setting BPM: $e');
      }
    }
  }

  /// Get current BPM
  int get bpm => _bpm;

  /// Set beats per measure (time signature)
  set beatsPerMeasure(int beats) {
    _beatsPerMeasure = beats.clamp(2, 8);
    
    if (_isInitialized) {
      try {
        _metronome.setTimeSignature(_beatsPerMeasure);
        debugPrint('🎵 Time signature changed to $_beatsPerMeasure/4');
      } catch (e) {
        debugPrint('❌ Error setting time signature: $e');
      }
    }
  }

  /// Get beats per measure
  int get beatsPerMeasure => _beatsPerMeasure;

  /// Set volume (0-100)
  set volume(int newVolume) {
    _volume = newVolume.clamp(0, 100);
    
    if (_isInitialized) {
      try {
        _metronome.setVolume(_volume);
        debugPrint('🎵 Volume changed to $_volume');
      } catch (e) {
        debugPrint('❌ Error setting volume: $e');
      }
    }
  }

  /// Get current volume
  int get volume => _volume;

  /// Set metronome enabled/disabled state
  set enabled(bool isEnabled) {
    _isEnabled = isEnabled;
    
    if (_isInitialized) {
      // The metronome package doesn't have a direct enable/disable
      // So we control volume instead
      try {
        _metronome.setVolume(_isEnabled ? _volume : 0);
        debugPrint('🎵 Metronome ${_isEnabled ? "enabled" : "disabled"}');
      } catch (e) {
        debugPrint('❌ Error toggling metronome: $e');
      }
    }
  }

  /// Check if metronome is enabled
  bool get enabled => _isEnabled;

  /// Check if metronome is playing
  bool get isPlaying => _isPlaying;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get current beat number
  int get currentBeat => _currentBeat;

  /// Set metronome sound type
  set soundType(String type) {
    final validTypes = ['click', 'wood', 'beep', 'hihat'];
    if (validTypes.contains(type)) {
      _soundType = type;
      debugPrint('🎵 Metronome sound changed to $_soundType');

      // Reinitialize with new sound if already initialized
      if (_isInitialized) {
        _reinitializeWithNewSound();
      }
    }
  }

  /// Get current sound type
  String get soundType => _soundType;

  /// Get the file path for a sound type
  String _getSoundPath(String type) {
    switch (type) {
      case 'click':
        return 'assets/audio/click.wav';
      case 'wood':
        return 'assets/audio/wood.wav';
      case 'beep':
        return 'assets/audio/beep.wav';
      case 'hihat':
        return 'assets/audio/hihat.wav';
      default:
        return 'assets/audio/hihat.wav'; // Default fallback
    }
  }

  /// Reinitialize metronome with new sound
  Future<void> _reinitializeWithNewSound() async {
    final wasPlaying = _isPlaying;

    if (wasPlaying) {
      stop();
    }

    try {
      await _metronome.destroy();
      _isInitialized = false;

      // Reinitialize with fallback mechanism
      await _initializeWithFallback();

      // Restart tick subscription
      _tickSubscription = _metronome.tickStream.listen((int tick) {
        _onTick(tick);
      });

      _isInitialized = true;

      if (wasPlaying) {
        start();
      }

      debugPrint('✅ Successfully reinitialized with new sound');
    } catch (e) {
      debugPrint('❌ Error reinitializing metronome with new sound: $e');
    }
  }

  /// Test audio playback
  void testAudio() {
    if (!_isInitialized) {
      debugPrint('❌ Cannot test audio - service not initialized');
      return;
    }

    debugPrint('🧪 Testing Professional Metronome audio...');

    try {
      // Play a few test beats
      start();
      Future.delayed(const Duration(seconds: 2), () {
        stop();
        debugPrint('✅ Professional Metronome audio test completed');
      });
    } catch (e) {
      debugPrint('❌ Audio test failed: $e');
    }
  }

  /// Test all available sound files
  Future<void> testAllSounds() async {
    final soundTypes = ['hihat', 'click', 'wood', 'beep']; // Test hihat first
    final workingSounds = <String>[];
    final failingSounds = <String>[];

    debugPrint('🧪 Testing all metronome sounds...');
    debugPrint('📋 Audio file requirements:');
    debugPrint('   - Format: WAV (uncompressed)');
    debugPrint('   - Sample Rate: 44.1 kHz');
    debugPrint('   - Bit Depth: 16-bit');
    debugPrint('   - Duration: 0.1-0.3 seconds');
    debugPrint('   - Size: Under 50KB');

    for (final soundType in soundTypes) {
      try {
        final testMetronome = Metronome();
        final soundPath = _getSoundPath(soundType);
        debugPrint('🔍 Testing $soundType at path: $soundPath');

        await testMetronome.init(
          soundPath,
          accentedPath: soundPath,
          bpm: 120,
          volume: 50,
          enableTickCallback: false,
          timeSignature: 4,
          sampleRate: 44100,
        );

        // Test playing the sound briefly
        testMetronome.play();
        await Future.delayed(const Duration(milliseconds: 300));
        testMetronome.stop();

        await testMetronome.destroy();
        workingSounds.add(soundType);
        debugPrint('✅ $soundType sound: WORKING');
      } catch (e) {
        failingSounds.add(soundType);
        debugPrint('❌ $soundType sound: FAILED - $e');
        debugPrint('   Possible issues: corrupted file, wrong format, too large, or encoding problems');
      }
    }

    debugPrint('🎵 Working sounds: $workingSounds');
    debugPrint('💥 Failing sounds: $failingSounds');

    if (workingSounds.isNotEmpty && workingSounds.first != _soundType) {
      debugPrint('🔄 Switching to first working sound: ${workingSounds.first}');
      soundType = workingSounds.first;
    }
  }

  /// Force reload the current sound
  Future<void> forceReloadSound() async {
    debugPrint('🔄 Force reloading sound: $_soundType');

    final wasPlaying = _isPlaying;
    if (wasPlaying) {
      stop();
    }

    try {
      await _metronome.destroy();
      _isInitialized = false;

      await initialize();

      if (wasPlaying) {
        start();
      }

      debugPrint('✅ Successfully reloaded sound');
    } catch (e) {
      debugPrint('❌ Error reloading sound: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('🗑️ Starting Professional Metronome disposal...');

    // Force stop first
    stop();

    try {
      // Remove from active instances
      _activeInstances.remove(this);

      // Cancel tick subscription
      _tickSubscription?.cancel();
      _tickSubscription = null;

      // Destroy metronome instance
      if (_isInitialized) {
        await _metronome.destroy();
      }

      // Reset all state
      _isInitialized = false;
      _isPlaying = false;
      _currentBeat = 0;
      onBeat = null;

      debugPrint('✅ Professional Metronome disposed successfully');
    } catch (e) {
      debugPrint('❌ Error disposing metronome: $e');
      // Force reset state even if disposal fails
      _activeInstances.remove(this);
      _isInitialized = false;
      _isPlaying = false;
      _currentBeat = 0;
      onBeat = null;
    }
  }
}
