import 'package:flutter/material.dart';
import '../models/song_request.dart';
import 'api_service.dart';

class SongRequestService {
  final ApiService _apiService = ApiService();

  // Get all song requests
  Future<List<SongRequest>> getAllSongRequests() async {
    try {
      debugPrint('Fetching all song requests from API...');
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
      final response = await _apiService.post('/song-requests/$songRequestId/upvote');

      if (response.statusCode == 201) {
        debugPrint('Song request upvoted successfully');
        return true;
      } else {
        debugPrint('Failed to upvote song request: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error upvoting song request: $e');
      // Rethrow the error so we can handle it in the UI
      rethrow;
    }
  }

  // Remove upvote from a song request
  Future<bool> removeUpvote(String songRequestId) async {
    try {
      debugPrint('Removing upvote from song request: $songRequestId');
      final response = await _apiService.delete('/song-requests/$songRequestId/upvote');

      if (response.statusCode == 200) {
        debugPrint('Upvote removed successfully');
        return true;
      } else {
        debugPrint('Failed to remove upvote: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error removing upvote: $e');
      // Rethrow the error so we can handle it in the UI
      rethrow;
    }
  }
}
