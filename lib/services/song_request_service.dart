import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_request.dart';
import 'api_service.dart';

class SongRequestService {
  final ApiService _apiService = ApiService();

  // Key for storing upvoted song requests in SharedPreferences
  static const String _upvotedSongRequestsKey = 'upvoted_song_requests';

  // Save upvoted song request ID to local storage
  Future<void> _saveUpvotedSongRequest(String songRequestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final upvotedRequests = prefs.getStringList(_upvotedSongRequestsKey) ?? [];

      if (!upvotedRequests.contains(songRequestId)) {
        upvotedRequests.add(songRequestId);
        await prefs.setStringList(_upvotedSongRequestsKey, upvotedRequests);
        debugPrint('Saved upvoted song request to local storage: $songRequestId');
      }
    } catch (e) {
      debugPrint('Error saving upvoted song request: $e');
    }
  }

  // Remove upvoted song request ID from local storage
  Future<void> _removeUpvotedSongRequest(String songRequestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final upvotedRequests = prefs.getStringList(_upvotedSongRequestsKey) ?? [];

      if (upvotedRequests.contains(songRequestId)) {
        upvotedRequests.remove(songRequestId);
        await prefs.setStringList(_upvotedSongRequestsKey, upvotedRequests);
        debugPrint('Removed upvoted song request from local storage: $songRequestId');
      }
    } catch (e) {
      debugPrint('Error removing upvoted song request: $e');
    }
  }

  // Get all upvoted song request IDs from local storage
  Future<List<String>> getUpvotedSongRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final upvotedRequests = prefs.getStringList(_upvotedSongRequestsKey) ?? [];
      debugPrint('Retrieved ${upvotedRequests.length} upvoted song requests from local storage');
      return upvotedRequests;
    } catch (e) {
      debugPrint('Error getting upvoted song requests: $e');
      return [];
    }
  }

  // Clear all upvoted song requests from local storage (used when logging out)
  Future<void> clearUpvotedSongRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_upvotedSongRequestsKey);
      debugPrint('Cleared all upvoted song requests from local storage');
    } catch (e) {
      debugPrint('Error clearing upvoted song requests: $e');
    }
  }

  // Get all song requests
  Future<List<SongRequest>> getAllSongRequests() async {
    try {
      debugPrint('Fetching all song requests from API...');

      // Get locally stored upvoted song request IDs
      final upvotedRequestIds = await getUpvotedSongRequests();
      debugPrint('Found ${upvotedRequestIds.length} locally stored upvoted song requests');

      final response = await _apiService.get('/song-requests');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} song requests from API');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No song requests found in API response');
          return [];
        }

        try {
          // Parse song requests from API
          final List<SongRequest> songRequests = data.map((item) {
            // Create the song request from JSON
            final songRequest = SongRequest.fromJson(item);

            // Check if this song request is in our local upvoted list
            // If it is, override the hasUpvoted flag from the server
            if (upvotedRequestIds.contains(songRequest.id)) {
              debugPrint('Song request ${songRequest.id} found in local upvoted list');

              // Create a new song request with hasUpvoted set to true
              return SongRequest(
                id: songRequest.id,
                songName: songRequest.songName,
                artistName: songRequest.artistName,
                youtubeLink: songRequest.youtubeLink,
                spotifyLink: songRequest.spotifyLink,
                notes: songRequest.notes,
                status: songRequest.status,
                upvotes: songRequest.upvotes,
                customerId: songRequest.customerId,
                createdAt: songRequest.createdAt,
                updatedAt: songRequest.updatedAt,
                hasUpvoted: true, // Override with local state
              );
            }

            return songRequest; // Use server state for non-upvoted requests
          }).toList();

          debugPrint('Successfully parsed ${songRequests.length} song requests');
          return songRequests;
        } catch (parseError) {
          debugPrint('Error parsing song request data: $parseError');
          throw Exception('Failed to parse song request data: $parseError');
        }
      } else {
        debugPrint('Failed to load song requests: ${response.statusCode}');
        throw Exception('Failed to load song requests: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting song requests: $e');
      return [];
    }
  }

  // Get song requests for the current user
  Future<List<SongRequest>> getMyRequests() async {
    try {
      debugPrint('Fetching my song requests from API...');
      final response = await _apiService.get('/song-requests/my-requests');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} of my song requests from API');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No song requests found in API response');
          return [];
        }

        try {
          final List<SongRequest> songRequests = data
              .map((item) => SongRequest.fromJson(item))
              .toList();
          debugPrint('Successfully parsed ${songRequests.length} song requests');
          return songRequests;
        } catch (parseError) {
          debugPrint('Error parsing song request data: $parseError');
          throw Exception('Failed to parse song request data: $parseError');
        }
      } else {
        debugPrint('Failed to load song requests: ${response.statusCode}');
        throw Exception('Failed to load song requests: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting song requests: $e');
      return [];
    }
  }

  // Create a new song request
  Future<SongRequest?> createSongRequest({
    required String songName,
    String? artistName,
    String? youtubeLink,
    String? spotifyLink,
    String? notes,
  }) async {
    try {
      debugPrint('Creating new song request: $songName by $artistName');

      final Map<String, dynamic> requestData = {
        'songName': songName,
      };

      if (artistName != null && artistName.isNotEmpty) {
        requestData['artistName'] = artistName;
      }

      if (youtubeLink != null && youtubeLink.isNotEmpty) {
        requestData['youtubeLink'] = youtubeLink;
      }

      if (spotifyLink != null && spotifyLink.isNotEmpty) {
        requestData['spotifyLink'] = spotifyLink;
      }

      if (notes != null && notes.isNotEmpty) {
        requestData['notes'] = notes;
      }

      final response = await _apiService.post('/song-requests', data: requestData);

      if (response.statusCode == 201) {
        debugPrint('Song request created successfully');
        return SongRequest.fromJson(response.data);
      } else {
        debugPrint('Failed to create song request: ${response.statusCode}');
        throw Exception('Failed to create song request: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating song request: $e');
      return null;
    }
  }

  // Upvote a song request
  Future<bool> upvoteSongRequest(String songRequestId) async {
    try {
      debugPrint('Upvoting song request: $songRequestId');

      // Send an empty body with the POST request
      final response = await _apiService.post(
        '/song-requests/$songRequestId/upvote',
        data: {}, // Add empty JSON body
        options: Options(
          validateStatus: (status) => status != null && (status == 200 || status == 201),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Song request upvoted successfully');

        // Save upvoted song request to local storage
        final prefs = await SharedPreferences.getInstance();
        final upvotedRequests = prefs.getStringList(_upvotedSongRequestsKey) ?? [];

        if (!upvotedRequests.contains(songRequestId)) {
          upvotedRequests.add(songRequestId);
          await prefs.setStringList(_upvotedSongRequestsKey, upvotedRequests);
          debugPrint('Saved upvoted song request to local storage: $songRequestId');
        }

        return true;
      } else {
        debugPrint('Failed to upvote song request: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error upvoting song request: $e');
      // Check if it's already upvoted
      if (e.toString().contains('400') || e.toString().contains('already upvoted')) {
        debugPrint('Request may have already been upvoted');

        // Save upvoted song request to local storage even if it's already upvoted on the server
        final prefs = await SharedPreferences.getInstance();
        final upvotedRequests = prefs.getStringList(_upvotedSongRequestsKey) ?? [];

        if (!upvotedRequests.contains(songRequestId)) {
          upvotedRequests.add(songRequestId);
          await prefs.setStringList(_upvotedSongRequestsKey, upvotedRequests);
          debugPrint('Saved already upvoted song request to local storage: $songRequestId');
        }

        return true; // Return true to update UI
      }
      // Rethrow the error so we can handle it in the UI
      rethrow;
    }
  }

  // Remove upvote from a song request
  Future<bool> removeUpvote(String songRequestId) async {
    try {
      debugPrint('Removing upvote from song request: $songRequestId');
      final response = await _apiService.delete(
        '/song-requests/$songRequestId/upvote',
        options: Options(
          validateStatus: (status) => status != null && (status == 200 || status == 204),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Upvote removed successfully');

        // Remove upvoted song request from local storage
        final prefs = await SharedPreferences.getInstance();
        final upvotedRequests = prefs.getStringList(_upvotedSongRequestsKey) ?? [];

        if (upvotedRequests.contains(songRequestId)) {
          upvotedRequests.remove(songRequestId);
          await prefs.setStringList(_upvotedSongRequestsKey, upvotedRequests);
          debugPrint('Removed upvoted song request from local storage: $songRequestId');
        }

        return true;
      } else {
        debugPrint('Failed to remove upvote: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error removing upvote: $e');
      // Check if it's a 400 error (not upvoted)
      if (e.toString().contains('400') || e.toString().contains('not upvoted')) {
        debugPrint('Request may not have been upvoted');

        // Remove upvoted song request from local storage even if it's not upvoted on the server
        final prefs = await SharedPreferences.getInstance();
        final upvotedRequests = prefs.getStringList(_upvotedSongRequestsKey) ?? [];

        if (upvotedRequests.contains(songRequestId)) {
          upvotedRequests.remove(songRequestId);
          await prefs.setStringList(_upvotedSongRequestsKey, upvotedRequests);
          debugPrint('Removed not upvoted song request from local storage: $songRequestId');
        }

        return true; // Return true to update UI
      }
      // Rethrow the error so we can handle it in the UI
      rethrow;
    }
  }
}
