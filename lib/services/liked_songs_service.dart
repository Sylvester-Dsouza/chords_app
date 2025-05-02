import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/song.dart';
import 'api_service.dart';
import 'liked_songs_notifier.dart';

class LikedSongsService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LikedSongsNotifier _notifier = LikedSongsNotifier();

  // Key for storing liked songs in secure storage
  static const String _likedSongsKey = 'liked_songs';

  // Get all liked songs
  Future<List<Song>> getLikedSongs() async {
    try {
      // First try to get from local storage
      final likedSongsJson = await _secureStorage.read(key: _likedSongsKey);

      if (likedSongsJson != null) {
        final List<dynamic> likedSongsData = jsonDecode(likedSongsJson);
        debugPrint('Found ${likedSongsData.length} liked songs in local storage');

        final likedSongs = likedSongsData.map((json) => Song.fromJson(json)).toList();
        return likedSongs;
      }

      // If no liked songs in local storage, return empty list
      debugPrint('No liked songs found in local storage');
      return [];
    } catch (e) {
      debugPrint('Error getting liked songs: $e');
      return [];
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

      // Try to save to API if available
      try {
        await _apiService.post('/liked-songs/${song.id}', data: {});
        debugPrint('Liked song ${song.title} on API');
      } catch (apiError) {
        debugPrint('Error liking song on API: $apiError');
        // Continue even if API call fails, as we've saved locally
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

      // Try to save to API if available
      try {
        await _apiService.delete('/liked-songs/${song.id}');
        debugPrint('Unliked song ${song.title} on API');
      } catch (apiError) {
        debugPrint('Error unliking song on API: $apiError');
        // Continue even if API call fails, as we've saved locally
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
      // First try to check with the API
      try {
        final response = await _apiService.get('/liked-songs/$songId');
        debugPrint('API response for isLiked: ${response.data}');
        return response.data['isLiked'] ?? false;
      } catch (apiError) {
        debugPrint('Error checking if song is liked from API: $apiError');
        // Fall back to local storage if API fails
        final likedSongs = await getLikedSongs();
        return likedSongs.any((song) => song.id == songId);
      }
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
}
