import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/playlist.dart';
import 'api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PlaylistService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      // First check for access token
      final token = await _secureStorage.read(key: 'access_token');
      if (token != null) {
        debugPrint('Access token found, user is authenticated');
        return true;
      }

      // If no access token, check Firebase auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          // Get a fresh token
          final idToken = await firebaseUser.getIdToken(true);
          debugPrint('Firebase user is authenticated, got fresh token');

          // Store the token for future use
          await _secureStorage.write(key: 'firebase_token', value: idToken);

          return true;
        } catch (e) {
          debugPrint('Error getting Firebase token: $e');
          return false;
        }
      }

      debugPrint('No authentication found (no token, no Firebase user)');
      return false;
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  // Get all playlists for the current user
  Future<List<Playlist>> getPlaylists() async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        debugPrint('User is not authenticated when fetching playlists');
        throw Exception('Authentication required. Please log in.');
      }

      // The API service will automatically use the token from secure storage
      // or get a fresh Firebase token if needed
      debugPrint('Fetching playlists from API');

      // Make the API request
      final response = await _apiService.get('/playlists');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} playlists from API');

        // Log the raw data for debugging
        debugPrint('Raw playlist data: $data');

        if (data.isEmpty) {
          debugPrint('No playlists found for the current customer');
          return [];
        }

        try {
          final playlists = data.map((json) => Playlist.fromJson(json)).toList();
          debugPrint('Parsed ${playlists.length} playlists');

          // Log each playlist for debugging
          for (var playlist in playlists) {
            debugPrint('Playlist: ${playlist.id} - ${playlist.name}');
          }

          return playlists;
        } catch (parseError) {
          debugPrint('Error parsing playlist data: $parseError');
          throw Exception('Failed to parse playlists: $parseError');
        }
      } else {
        debugPrint('Failed to load playlists: ${response.statusCode}');
        throw Exception('Failed to load playlists: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting playlists: $e');
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');

        if (e.response?.statusCode == 401) {
          // Clear tokens on authentication error
          await _secureStorage.delete(key: 'access_token');
          await _secureStorage.delete(key: 'refresh_token');
          throw Exception('Authentication required. Please log in.');
        }
      }
      throw Exception('Failed to load playlists: $e');
    }
  }

  // Create a new playlist
  Future<Playlist> createPlaylist(String name, {String? description}) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      // The API service will automatically use the token from secure storage
      // or get a fresh Firebase token if needed
      debugPrint('Creating playlist: $name');

      // Make the API request
      final response = await _apiService.post('/playlists', data: {
        'name': name,
        'description': description,
      });

      if (response.statusCode == 201) {
        debugPrint('Playlist created successfully: ${response.data}');
        try {
          final playlist = Playlist.fromJson(response.data);
          debugPrint('Parsed playlist: ${playlist.id} - ${playlist.name}');
          return playlist;
        } catch (parseError) {
          debugPrint('Error parsing created playlist: $parseError');
          throw Exception('Failed to parse created playlist: $parseError');
        }
      } else {
        debugPrint('Failed to create playlist: ${response.statusCode}');
        throw Exception('Failed to create playlist: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating playlist: $e');
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');

        if (e.response?.statusCode == 401) {
          // Clear tokens on authentication error
          await _secureStorage.delete(key: 'access_token');
          await _secureStorage.delete(key: 'refresh_token');
          throw Exception('Authentication required. Please log in.');
        }
      }
      throw Exception('Failed to create playlist: $e');
    }
  }

  // Get a specific playlist by ID
  Future<Playlist> getPlaylist(String id) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        debugPrint('User not authenticated when fetching playlist $id');
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Sending API request to get playlist $id');
      final response = await _apiService.get('/playlists/$id');

      if (response.statusCode == 200) {
        debugPrint('Playlist $id fetched successfully');
        debugPrint('Response data: ${response.data}');

        // Check if response data is valid
        if (response.data == null) {
          debugPrint('Response data is null');
          throw Exception('Invalid playlist data received');
        }

        // Log songs data if available
        if (response.data['songs'] != null) {
          debugPrint('Songs in response: ${response.data['songs'].length}');
          for (var song in response.data['songs']) {
            debugPrint('Song: ${song['title'] ?? 'Unknown'} by ${song['artist']?['name'] ?? 'Unknown Artist'}');
          }
        } else {
          debugPrint('No songs in response');
        }

        return Playlist.fromJson(response.data);
      } else {
        debugPrint('Failed to load playlist: ${response.statusCode}');
        throw Exception('Failed to load playlist: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting playlist: $e');
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');

        if (e.response?.statusCode == 401) {
          // Clear tokens on authentication error
          await _secureStorage.delete(key: 'access_token');
          await _secureStorage.delete(key: 'refresh_token');
          throw Exception('Authentication required. Please log in.');
        }
      }
      throw Exception('Failed to load playlist: $e');
    }
  }

  // Update a playlist
  Future<Playlist> updatePlaylist(String id, String name, {String? description}) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Updating playlist with ID: $id, name: $name, description: $description');
      final response = await _apiService.patch('/playlists/$id', data: {
        'name': name,
        'description': description,
      });

      if (response.statusCode == 200) {
        return Playlist.fromJson(response.data);
      } else {
        throw Exception('Failed to update playlist');
      }
    } catch (e) {
      debugPrint('Error updating playlist: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to update playlist: $e');
    }
  }

  // Delete a playlist
  Future<void> deletePlaylist(String id) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      final response = await _apiService.delete('/playlists/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete playlist');
      }
    } catch (e) {
      debugPrint('Error deleting playlist: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to delete playlist: $e');
    }
  }

  // Add a song to a playlist
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      final response = await _apiService.post('/playlists/$playlistId/songs', data: {
        'songId': songId,
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add song to playlist');
      }
    } catch (e) {
      debugPrint('Error adding song to playlist: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to add song to playlist: $e');
    }
  }

  // Remove a song from a playlist
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      final response = await _apiService.delete('/playlists/$playlistId/songs/$songId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove song from playlist');
      }
    } catch (e) {
      debugPrint('Error removing song from playlist: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to remove song from playlist: $e');
    }
  }

  // Check if a song is in a playlist
  Future<bool> isSongInPlaylist(String playlistId, String songId) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      // Get the playlist with songs
      final playlist = await getPlaylist(playlistId);

      // Check if the song is in the playlist
      if (playlist.songs == null || playlist.songs!.isEmpty) {
        return false;
      }

      // Check each song in the playlist
      for (final song in playlist.songs!) {
        if (song is Map<String, dynamic> && song['id'] == songId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking if song is in playlist: $e');
      return false;
    }
  }
}
