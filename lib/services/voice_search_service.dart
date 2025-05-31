import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling voice search functionality
class VoiceSearchService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();

  bool _isAvailable = false;
  bool _isListening = false;
  String _lastWords = '';
  String _lastError = '';
  double _confidence = 0.0;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String get lastError => _lastError;
  double get confidence => _confidence;

  /// Initialize the voice search service
  Future<bool> initialize() async {
    try {
      // Check microphone permission
      final permissionStatus = await Permission.microphone.status;
      if (permissionStatus.isDenied) {
        final result = await Permission.microphone.request();
        if (result.isDenied) {
          _lastError = 'Microphone permission denied';
          return false;
        }
      }

      // Initialize speech to text
      _isAvailable = await _speechToText.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: kDebugMode,
      );

      if (!_isAvailable) {
        _lastError = 'Speech recognition not available';
      }

      notifyListeners();
      return _isAvailable;
    } catch (e) {
      debugPrint('Error initializing voice search: $e');
      _lastError = 'Failed to initialize voice search: $e';
      _isAvailable = false;
      notifyListeners();
      return false;
    }
  }

  /// Start listening for voice input
  Future<void> startListening({
    Function(String)? onResult,
    Duration? timeout,
  }) async {
    if (!_isAvailable) {
      await initialize();
      if (!_isAvailable) return;
    }

    try {
      _lastError = '';
      _lastWords = '';
      _confidence = 0.0;

      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _confidence = result.confidence;

          if (result.finalResult) {
            onResult?.call(_lastWords);
            stopListening();
          }

          notifyListeners();
        },
        listenFor: timeout ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        onSoundLevelChange: (level) {
          // Handle sound level changes if needed
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );

      _isListening = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting voice search: $e');
      _lastError = 'Failed to start voice search: $e';
      _isListening = false;
      notifyListeners();
    }
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping voice search: $e');
      _lastError = 'Failed to stop voice search: $e';
      notifyListeners();
    }
  }

  /// Cancel voice input
  Future<void> cancel() async {
    try {
      await _speechToText.cancel();
      _isListening = false;
      _lastWords = '';
      _confidence = 0.0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error canceling voice search: $e');
      _lastError = 'Failed to cancel voice search: $e';
      notifyListeners();
    }
  }

  /// Get available locales for speech recognition
  Future<List<LocaleName>> getLocales() async {
    try {
      return await _speechToText.locales();
    } catch (e) {
      debugPrint('Error getting locales: $e');
      return [];
    }
  }

  /// Check if speech recognition is supported on this device
  static Future<bool> isSupported() async {
    try {
      final speechToText = SpeechToText();
      return await speechToText.initialize();
    } catch (e) {
      debugPrint('Speech recognition not supported: $e');
      return false;
    }
  }

  void _onError(dynamic error) {
    debugPrint('Voice search error: $error');
    _lastError = error.toString();
    _isListening = false;
    notifyListeners();
  }

  void _onStatus(String status) {
    debugPrint('Voice search status: $status');

    switch (status) {
      case 'listening':
        _isListening = true;
        break;
      case 'notListening':
      case 'done':
        _isListening = false;
        break;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _speechToText.cancel();
    super.dispose();
  }
}

/// Voice search result
class VoiceSearchResult {
  final String text;
  final double confidence;
  final bool isFinal;

  VoiceSearchResult({
    required this.text,
    required this.confidence,
    required this.isFinal,
  });

  @override
  String toString() {
    return 'VoiceSearchResult(text: $text, confidence: $confidence, isFinal: $isFinal)';
  }
}

/// Voice search status
enum VoiceSearchStatus {
  idle,
  listening,
  processing,
  error,
}

/// Voice search error types
enum VoiceSearchError {
  permissionDenied,
  notAvailable,
  networkError,
  timeout,
  unknown,
}

/// Extension to convert error strings to enum
extension VoiceSearchErrorExtension on String {
  VoiceSearchError get toVoiceSearchError {
    switch (toLowerCase()) {
      case 'permission denied':
      case 'microphone permission denied':
        return VoiceSearchError.permissionDenied;
      case 'not available':
      case 'speech recognition not available':
        return VoiceSearchError.notAvailable;
      case 'network error':
        return VoiceSearchError.networkError;
      case 'timeout':
        return VoiceSearchError.timeout;
      default:
        return VoiceSearchError.unknown;
    }
  }
}

/// Voice search configuration
class VoiceSearchConfig {
  final Duration listenTimeout;
  final Duration pauseTimeout;
  final String localeId;
  final bool partialResults;
  final bool cancelOnError;

  const VoiceSearchConfig({
    this.listenTimeout = const Duration(seconds: 30),
    this.pauseTimeout = const Duration(seconds: 3),
    this.localeId = 'en_US',
    this.partialResults = true,
    this.cancelOnError = true,
  });
}
