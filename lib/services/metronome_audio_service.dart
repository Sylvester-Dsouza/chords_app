import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Enhanced audio service for metronome with kick/hihat sounds
class MetronomeAudioService {
  static final MetronomeAudioService _instance = MetronomeAudioService._internal();
  factory MetronomeAudioService() => _instance;
  MetronomeAudioService._internal();

  // Audio players for different sounds
  final AudioPlayer _kickPlayer = AudioPlayer();
  final AudioPlayer _hihatPlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _accentPlayer = AudioPlayer();

  bool _isInitialized = false;
  double _volume = 0.8;
  MetronomeAudioType _audioType = MetronomeAudioType.kickHihat;

  // Getters
  bool get isInitialized => _isInitialized;
  double get volume => _volume;
  MetronomeAudioType get audioType => _audioType;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set audio mode for low latency
      await _kickPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _hihatPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _clickPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _accentPlayer.setPlayerMode(PlayerMode.lowLatency);

      // Set initial volume
      await _kickPlayer.setVolume(_volume);
      await _hihatPlayer.setVolume(_volume);
      await _clickPlayer.setVolume(_volume);
      await _accentPlayer.setVolume(_volume);

      // Preload audio files for better performance
      await _preloadAudioFiles();

      _isInitialized = true;
      debugPrint('🎵 MetronomeAudioService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing MetronomeAudioService: $e');
      _isInitialized = false;
    }
  }

  /// Preload audio files for better performance
  Future<void> _preloadAudioFiles() async {
    try {
      // Preload kick and hihat sounds
      await _kickPlayer.setSource(AssetSource('audio/kick.wav'));
      await _hihatPlayer.setSource(AssetSource('audio/hihat.wav'));
      
      // Preload traditional metronome sounds
      await _clickPlayer.setSource(AssetSource('audio/click.wav'));
      await _accentPlayer.setSource(AssetSource('audio/accent.wav'));
      
      debugPrint('🎵 Audio files preloaded successfully');
    } catch (e) {
      debugPrint('⚠️ Some audio files could not be preloaded: $e');
      // Continue without preloading - files will load on demand
    }
  }

  /// Play beat sound based on accent and audio type
  Future<void> playBeat(bool isAccented) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      switch (_audioType) {
        case MetronomeAudioType.kickHihat:
          await _playKickHihat(isAccented);
          break;
        case MetronomeAudioType.traditional:
          await _playTraditional(isAccented);
          break;
        case MetronomeAudioType.hapticOnly:
          _playHaptic(isAccented);
          break;
      }
    } catch (e) {
      debugPrint('❌ Error playing beat sound: $e');
      // Fallback to haptic feedback
      _playHaptic(isAccented);
    }
  }

  /// Play kick/hihat pattern
  Future<void> _playKickHihat(bool isAccented) async {
    try {
      if (isAccented) {
        // Play kick drum for accented beats
        await _kickPlayer.stop();
        await _kickPlayer.resume();
      } else {
        // Play hihat for regular beats
        await _hihatPlayer.stop();
        await _hihatPlayer.resume();
      }
    } catch (e) {
      debugPrint('❌ Error playing kick/hihat: $e');
      _playHaptic(isAccented);
    }
  }

  /// Play traditional metronome sounds
  Future<void> _playTraditional(bool isAccented) async {
    try {
      if (isAccented) {
        await _accentPlayer.stop();
        await _accentPlayer.resume();
      } else {
        await _clickPlayer.stop();
        await _clickPlayer.resume();
      }
    } catch (e) {
      debugPrint('❌ Error playing traditional sounds: $e');
      _playHaptic(isAccented);
    }
  }

  /// Fallback to haptic feedback
  void _playHaptic(bool isAccented) {
    if (isAccented) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Play count-in sound
  Future<void> playCountIn() async {
    try {
      // Use a distinct sound for count-in
      await _clickPlayer.stop();
      await _clickPlayer.resume();
    } catch (e) {
      debugPrint('❌ Error playing count-in: $e');
      HapticFeedback.lightImpact();
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    
    if (_isInitialized) {
      await _kickPlayer.setVolume(_volume);
      await _hihatPlayer.setVolume(_volume);
      await _clickPlayer.setVolume(_volume);
      await _accentPlayer.setVolume(_volume);
    }
  }

  /// Set audio type
  void setAudioType(MetronomeAudioType type) {
    _audioType = type;
    debugPrint('🎵 Audio type changed to: ${type.name}');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _kickPlayer.dispose();
    await _hihatPlayer.dispose();
    await _clickPlayer.dispose();
    await _accentPlayer.dispose();
    _isInitialized = false;
  }
}

/// Audio types for metronome
enum MetronomeAudioType {
  kickHihat('Kick & Hihat'),
  traditional('Traditional'),
  hapticOnly('Haptic Only');

  const MetronomeAudioType(this.displayName);
  final String displayName;
}
