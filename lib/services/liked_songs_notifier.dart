import 'package:flutter/foundation.dart';
import '../models/song.dart';

// A simple event bus for liked songs events
class LikedSongsNotifier extends ChangeNotifier {
  // Singleton instance
  static final LikedSongsNotifier _instance = LikedSongsNotifier._internal();
  
  // Factory constructor to return the singleton instance
  factory LikedSongsNotifier() {
    return _instance;
  }
  
  // Private constructor
  LikedSongsNotifier._internal();
  
  // Notify listeners when a song is liked or unliked
  void notifySongLikeChanged(Song song) {
    debugPrint('Notifying song like changed: ${song.title} - isLiked: ${song.isLiked}');
    notifyListeners();
  }
}
