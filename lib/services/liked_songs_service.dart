import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song.dart';
import 'api_service.dart';
import 'liked_songs_notifier.dart';

class LikedSongsService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LikedSongsNotifier _notifier = LikedSongsNotifier();

  // Key for storing liked songs in secure storage
  static const String _likedSongsKey = 'liked_songs';
  static const String _lastSyncTimeKey = 'liked_songs_last_sync';

  // Flag to track if we're currently syncing
  bool _isSyncing = false;

  // Track the last time we returned liked songs to prevent rapid successive calls
  DateTime? _lastGetLikedSongsTime;

  // Get all liked songs with improved caching and syncing
  Future<List<Song>> getLikedSongs({bool forceSync = false}) async {
    try {
      // Implement debouncing - don't process calls less than 300ms apart unless forced
      final now = DateTime.now();
      if (!forceSync && _lastGetLikedSongsTime != null) {
        final timeSinceLastGet = now.difference(_lastGetLikedSongsTime!).inMilliseconds;
        if (timeSinceLastGet < 300) {
          debugPrint('Debouncing getLikedSongs - too soon since last call ($timeSinceLastGet ms)');
          // Return an empty list if we're debouncing and don't have cached data yet
          final likedSongsJson = await _secureStorage.read(key: _likedSongsKey);
          if (likedSongsJson == null) {
            return [];
          }

          // Otherwise return the cached data
          final List<dynamic> likedSongsData = jsonDecode(likedSongsJson);
          return likedSongsData.map((json) => Song.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      _lastGetLikedSongsTime = now;

      // First try to get from local storage for immediate display
      final likedSongsJson = await _secureStorage.read(key: _likedSongsKey);
      List<Song> localLikedSongs = [];

      if (likedSongsJson != null) {
        final List<dynamic> likedSongsData = jsonDecode(likedSongsJson);
        debugPrint('Found ${likedSongsData.length} liked songs in local storage');
        final likedSongs = likedSongsData.map((json) => Song.fromJson(json as Map<String, dynamic>)).toList();
        localLikedSongs = likedSongs;
      } else {
        debugPrint('No liked songs found in local storage');
      }

      // Check if we should sync with the server
      final shouldSync = forceSync || await _shouldSyncWithServer();

      if (shouldSync) {
        // If we're forcing a sync, wait for it to complete
        if (forceSync) {
          debugPrint('Force sync requested, waiting for sync to complete');
          await _syncWithServer(localLikedSongs);

          // After sync, get the updated local data
          final updatedJson = await _secureStorage.read(key: _likedSongsKey);
          if (updatedJson != null) {
            final List<dynamic> updatedData = jsonDecode(updatedJson);
            localLikedSongs = updatedData.map((json) => Song.fromJson(json as Map<String, dynamic>)).toList();
            debugPrint('Returning ${localLikedSongs.length} liked songs after forced sync');
          }
        } else {
          // Otherwise start syncing in the background
          debugPrint('Starting background sync');
          _syncWithServer(localLikedSongs);
        }
      }

      // Make sure all songs have isLiked set to true
      for (var song in localLikedSongs) {
        song.isLiked = true;
      }

      return localLikedSongs;
    } catch (e) {
      debugPrint('Error getting liked songs: $e');
      return [];
    }
  }

  // Check if we should sync with the server
  Future<bool> _shouldSyncWithServer() async {
    try {
      // Check if user is authenticated
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        debugPrint('User not authenticated, skipping sync');
        return false;
      }

      // Check when we last synced
      final lastSyncTimeStr = await _secureStorage.read(key: _lastSyncTimeKey);
      if (lastSyncTimeStr == null) {
        debugPrint('No previous sync found, should sync');
        return true;
      }

      // Check if it's been more than 1 hour since last sync
      final lastSyncTime = DateTime.parse(lastSyncTimeStr);
      final now = DateTime.now();
      final difference = now.difference(lastSyncTime);

      if (difference.inHours >= 1) {
        debugPrint('Last sync was ${difference.inHours} hours ago, should sync');
        return true;
      }

      debugPrint('Last sync was ${difference.inMinutes} minutes ago, no need to sync yet');
      return false;
    } catch (e) {
      debugPrint('Error checking if should sync: $e');
      return false;
    }
  }

  // Sync local liked songs with the server
  Future<void> _syncWithServer(List<Song> localLikedSongs) async {
    // Prevent multiple syncs at the same time
    if (_isSyncing) {
      debugPrint('Already syncing, skipping');
      return;
    }

    _isSyncing = true;

    try {
      debugPrint('Starting sync with server...');

      // Check if user is authenticated
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        debugPrint('User not authenticated, skipping sync');
        _isSyncing = false;
        return;
      }

      // Get a fresh Firebase token
      final idToken = await firebaseUser.getIdToken(true);
      await _secureStorage.write(key: 'firebase_token', value: idToken);

      // Fetch liked songs from the server
      final response = await _apiService.get('/liked-songs');

      // Check response format
      List<dynamic> serverData;
      if (response.data is List) {
        serverData = response.data as List<dynamic>;
      } else if (response.data is Map && response.data['data'] is List) {
        serverData = response.data['data'] as List<dynamic>;
      } else {
        debugPrint('Unexpected response format: ${response.data.runtimeType}');
        _isSyncing = false;
        return;
      }
      debugPrint('Fetched ${serverData.length} liked songs from server');

      // Convert server data to Song objects
      final List<Song> serverLikedSongs = serverData.map((json) {
        final song = Song.fromJson(json as Map<String, dynamic>);
        song.isLiked = true; // Mark as liked
        return song;
      }).toList();

      // Merge local and server liked songs
      final Map<String, Song> mergedSongs = {};

      // Add all server songs
      for (final song in serverLikedSongs) {
        mergedSongs[song.id] = song;
      }

      // Add local songs that aren't on the server
      for (final song in localLikedSongs) {
        if (!mergedSongs.containsKey(song.id)) {
          // This song is liked locally but not on the server
          // Like it on the server
          try {
            await _apiService.post('/liked-songs/${song.id}', data: {});
            debugPrint('Synced local liked song to server: ${song.title}');
            mergedSongs[song.id] = song;
          } catch (e) {
            debugPrint('Error syncing local liked song to server: $e');
            // Keep it in the merged list anyway
            mergedSongs[song.id] = song;
          }
        }
      }

      // Save the merged list to local storage
      final List<Song> finalLikedSongs = mergedSongs.values.toList();
      await _saveLikedSongs(finalLikedSongs);

      // Update last sync time
      await _secureStorage.write(key: _lastSyncTimeKey, value: DateTime.now().toIso8601String());

      debugPrint('Sync completed. Final liked songs count: ${finalLikedSongs.length}');

      // Notify listeners that liked songs have been updated
      for (final song in finalLikedSongs) {
        _notifier.notifySongLikeChanged(song);
      }
    } catch (e) {
      debugPrint('Error syncing with server: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Like a song
  Future<bool> likeSong(Song song) async {
    try {
      // We'll set the isLiked property in the UI layer
      // to avoid race conditions

      // Get current liked songs
      final likedSongs = await getLikedSongs();

      // Check if song is already liked
      final existingIndex = likedSongs.indexWhere((s) => s.id == song.id);
      if (existingIndex >= 0) {
        debugPrint('Song ${song.title} is already liked');
        return true;
      }

      // Add the song to liked songs
      likedSongs.add(song);

      // Save to local storage
      await _saveLikedSongs(likedSongs);

      // Try to save to API if user is authenticated
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          // Get a fresh Firebase token
          final idToken = await firebaseUser.getIdToken(true);
          await _secureStorage.write(key: 'firebase_token', value: idToken);

          // Like the song on the server
          await _apiService.post('/liked-songs/${song.id}', data: {});
          debugPrint('Liked song ${song.title} on API');

          // Update last sync time
          await _secureStorage.write(key: _lastSyncTimeKey, value: DateTime.now().toIso8601String());
        } catch (apiError) {
          debugPrint('Error liking song on API: $apiError');
          // Continue even if API call fails, as we've saved locally
        }
      } else {
        debugPrint('User not authenticated, song liked only locally');
      }

      // Notify listeners that a song was liked
      _notifier.notifySongLikeChanged(song);

      debugPrint('Successfully liked song: ${song.title}');
      return true;
    } catch (e) {
      debugPrint('Error liking song: $e');
      return false;
    }
  }

  // Unlike a song
  Future<bool> unlikeSong(Song song) async {
    try {
      // We'll set the isLiked property in the UI layer
      // to avoid race conditions

      // Get current liked songs
      final likedSongs = await getLikedSongs();

      // Remove the song from liked songs
      likedSongs.removeWhere((s) => s.id == song.id);

      // Save to local storage
      await _saveLikedSongs(likedSongs);

      // Try to save to API if user is authenticated
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          // Get a fresh Firebase token
          final idToken = await firebaseUser.getIdToken(true);
          await _secureStorage.write(key: 'firebase_token', value: idToken);

          // Unlike the song on the server
          await _apiService.delete('/liked-songs/${song.id}');
          debugPrint('Unliked song ${song.title} on API');

          // Update last sync time
          await _secureStorage.write(key: _lastSyncTimeKey, value: DateTime.now().toIso8601String());
        } catch (apiError) {
          debugPrint('Error unliking song on API: $apiError');
          // Continue even if API call fails, as we've saved locally
        }
      } else {
        debugPrint('User not authenticated, song unliked only locally');
      }

      // Notify listeners that a song was unliked
      _notifier.notifySongLikeChanged(song);

      debugPrint('Successfully unliked song: ${song.title}');
      return true;
    } catch (e) {
      debugPrint('Error unliking song: $e');
      return false;
    }
  }

  // Toggle like status of a song
  Future<bool> toggleLike(Song song) async {
    // We don't modify the song.isLiked property here
    // because the UI will handle that after the operation completes
    final currentlyLiked = song.isLiked;

    if (currentlyLiked) {
      return await unlikeSong(song);
    } else {
      return await likeSong(song);
    }
  }

  // Check if a song is liked
  Future<bool> isSongLiked(String songId) async {
    try {
      // First check local storage for immediate response
      final likedSongs = await getLikedSongs();
      final isLikedLocally = likedSongs.any((song) => song.id == songId);

      // If user is authenticated, also check with the API
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          // Get a fresh Firebase token
          final idToken = await firebaseUser.getIdToken(true);
          await _secureStorage.write(key: 'firebase_token', value: idToken);

          // Check with the API
          final response = await _apiService.get('/liked-songs/$songId');

          // Parse the response
          bool isLikedOnServer = false;
          if (response.data is Map && (response.data as Map).containsKey('isLiked')) {
            isLikedOnServer = response.data['isLiked'] as bool? ?? false;
          }

          debugPrint('Song $songId liked status - Local: $isLikedLocally, Server: $isLikedOnServer');

          // If there's a discrepancy, sync with the server
          if (isLikedLocally != isLikedOnServer) {
            debugPrint('Discrepancy detected between local and server liked status, syncing...');
            // Force a sync to resolve the discrepancy
            await getLikedSongs(forceSync: true);

            // Return the server's value as it's more authoritative
            return isLikedOnServer;
          }

          return isLikedOnServer;
        } catch (apiError) {
          debugPrint('Error checking if song is liked from API: $apiError');
          // Fall back to local storage if API fails
          return isLikedLocally;
        }
      }

      // If not authenticated, just use local storage
      return isLikedLocally;
    } catch (e) {
      debugPrint('Error checking if song is liked: $e');
      return false;
    }
  }

  // Save liked songs to local storage
  Future<void> _saveLikedSongs(List<Song> likedSongs) async {
    try {
      final likedSongsJson = jsonEncode(likedSongs.map((song) => song.toJson()).toList());
      await _secureStorage.write(key: _likedSongsKey, value: likedSongsJson);
      debugPrint('Saved ${likedSongs.length} liked songs to local storage');
    } catch (e) {
      debugPrint('Error saving liked songs: $e');
      throw Exception('Failed to save liked songs: $e');
    }
  }

  // Sync liked songs when user logs in
  Future<void> syncAfterLogin() async {
    debugPrint('Syncing liked songs after login...');

    // Force a sync with the server
    await getLikedSongs(forceSync: true);

    // Clear the last sync time to ensure we sync again next time
    await _secureStorage.write(key: _lastSyncTimeKey, value: DateTime.now().toIso8601String());

    debugPrint('Liked songs sync after login completed');
  }

  // Clear local liked songs when user logs out
  Future<void> clearLocalDataOnLogout({bool forceFullClear = false}) async {
    debugPrint('Clearing local liked songs data on logout (forceFullClear: $forceFullClear)');

    try {
      // Always delete the sync timestamp
      await _secureStorage.delete(key: _lastSyncTimeKey);

      // If forceFullClear is true, delete all liked songs data
      if (forceFullClear) {
        await _secureStorage.delete(key: _likedSongsKey);
        debugPrint('Force cleared all liked songs data');

        // Reset the in-memory state
        _isSyncing = false;
      } else {
        // We don't delete the data, just mark it for sync
        // This way, if the user logs in again, we can sync with the server
        // and recover their liked songs
        debugPrint('Cleared liked songs sync timestamp (data preserved for future sync)');
      }
    } catch (e) {
      debugPrint('Error clearing liked songs data: $e');
    }
  }
}
