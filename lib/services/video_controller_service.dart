import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:developer' as developer;

/// A service to manage YouTube video players and ensure only one plays at a time
class VideoControllerService {
  // Singleton pattern
  static final VideoControllerService _instance = VideoControllerService._internal();
  factory VideoControllerService() => _instance;
  VideoControllerService._internal();

  // Currently active controller
  YoutubePlayerController? _activeController;
  
  // ID of the currently playing video
  String? _activeVideoId;

  /// Register a controller as active and pause any existing active controller
  void registerActiveController(YoutubePlayerController controller, String videoId) {
    // If there's already an active controller playing the same video, do nothing
    if (_activeController != null && _activeVideoId == videoId) {
      developer.log('Same video is already playing: $videoId');
      return;
    }
    
    // Pause any existing active controller
    if (_activeController != null) {
      try {
        developer.log('Pausing previous video: $_activeVideoId');
        _activeController!.pauseVideo();
      } catch (e) {
        developer.log('Error pausing previous video: $e');
      }
    }
    
    // Set the new controller as active
    _activeController = controller;
    _activeVideoId = videoId;
    developer.log('New active video: $videoId');
  }

  /// Unregister a controller if it's the active one
  void unregisterController(YoutubePlayerController controller) {
    if (_activeController == controller) {
      developer.log('Unregistering active controller for video: $_activeVideoId');
      _activeController = null;
      _activeVideoId = null;
    }
  }

  /// Get the currently active video ID
  String? get activeVideoId => _activeVideoId;
}
