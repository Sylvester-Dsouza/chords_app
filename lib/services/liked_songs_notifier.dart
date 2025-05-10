import 'package:flutter/foundation.dart';
import '../models/song.dart';

// A simple event bus for liked songs events with debouncing
class LikedSongsNotifier extends ChangeNotifier {
  // Singleton instance
  static final LikedSongsNotifier _instance = LikedSongsNotifier._internal();

  // Factory constructor to return the singleton instance
  factory LikedSongsNotifier() {
    return _instance;
  }

  // Private constructor
  LikedSongsNotifier._internal();

  // Track the last notification time for debouncing
  DateTime? _lastNotificationTime;

  // Track the last song ID that was notified to prevent duplicate notifications
  String? _lastSongId;

  // Batch notifications to reduce update frequency
  final List<Song> _pendingNotifications = [];
  bool _notificationScheduled = false;

  // Track notification count to detect potential loops
  int _notificationCount = 0;
  DateTime? _notificationCountResetTime;
  static const int _maxNotificationsPerMinute = 5;

  // Notify listeners when a song is liked or unliked with enhanced debouncing and loop prevention
  void notifySongLikeChanged(Song song) {
    // Increment notification count and check for potential loops
    final now = DateTime.now();

    // Reset counter if it's been more than a minute since we started counting
    if (_notificationCountResetTime == null ||
        now.difference(_notificationCountResetTime!).inSeconds > 60) {
      _notificationCount = 0;
      _notificationCountResetTime = now;
    }

    _notificationCount++;

    // If we've received too many notifications in a short time, it's likely a loop
    if (_notificationCount > _maxNotificationsPerMinute) {
      debugPrint('⚠️ Too many notifications in a short time ($_notificationCount). Potential notification loop detected!');
      debugPrint('Skipping notification to break potential loop');

      // Don't reset the counter yet - let it cool down naturally after a minute
      return;
    }

    // Skip duplicate notifications for the same song in quick succession
    if (_lastSongId == song.id) {
      if (_lastNotificationTime != null) {
        final timeSinceLastNotification = now.difference(_lastNotificationTime!).inMilliseconds;
        if (timeSinceLastNotification < 2000) { // Increased from 500ms to 2000ms
          debugPrint('Skipping duplicate notification for ${song.title} (too soon: $timeSinceLastNotification ms)');
          return;
        }
      }
    }

    // Update tracking variables
    _lastSongId = song.id;
    _lastNotificationTime = now;

    // Add to pending notifications
    if (!_pendingNotifications.any((s) => s.id == song.id)) {
      _pendingNotifications.add(song);
    }

    // Schedule a batch notification if not already scheduled
    if (!_notificationScheduled) {
      _notificationScheduled = true;

      // Wait a longer time to batch notifications (increased from 300ms to 1000ms)
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_pendingNotifications.isNotEmpty) {
          debugPrint('Batch notifying ${_pendingNotifications.length} liked song changes');

          // Store pending notifications in a local variable
          final notifications = List<Song>.from(_pendingNotifications);

          // Clear the pending list before notification to prevent loops
          _pendingNotifications.clear();
          _notificationScheduled = false;

          // Only notify if we have a reasonable number of changes
          if (notifications.length <= 10) {
            // Notify all listeners
            notifyListeners();
          } else {
            debugPrint('⚠️ Too many pending notifications (${notifications.length}). Skipping to prevent potential issues.');
          }
        } else {
          _notificationScheduled = false;
        }
      });
    }
  }
}
