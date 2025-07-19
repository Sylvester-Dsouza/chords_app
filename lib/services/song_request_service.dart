import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_request.dart';
import 'api_service.dart';

class SongRequestService {
  final ApiService _apiService = ApiService();



  // Get current user ID from UserProvider
  Future<String?> _getCurrentUserId() async {
    try {
      // Get user data from shared preferences (stored by UserProvider)
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      if (userData != null) {
        final userJson = json.decode(userData);
        return userJson['id'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }

  // Get all song requests
  Future<List<SongRequest>> getAllSongRequests() async {
    try {
      debugPrint('Fetching all song requests from API...');

      final response = await _apiService.get('/song-requests');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        debugPrint('Received ${data.length} song requests from API');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No song requests found in API response');
          return [];
        }

        try {
          // Parse song requests from API - use the hasUpvoted status directly from the backend
          final List<SongRequest> songRequests = data.map((item) {
            final songRequest = SongRequest.fromJson(item as Map<String, dynamic>);
            debugPrint('Song request ${songRequest.id} - ${songRequest.songName} - hasUpvoted: ${songRequest.hasUpvoted}');
            return songRequest;
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
        final List<dynamic> data = response.data as List<dynamic>;
        debugPrint('Received ${data.length} of my song requests from API');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No song requests found in API response');
          return [];
        }

        try {
          final List<SongRequest> songRequests = data
              .map((item) => SongRequest.fromJson(item as Map<String, dynamic>))
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
        final songRequest = SongRequest.fromJson(response.data as Map<String, dynamic>);

        // Since the user created this request, they should have it "upvoted" by default
        // Return a modified version with hasUpvoted set to true
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
          hasUpvoted: true, // Creator should have this as upvoted
        );
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

      // Get current user ID to prevent self-upvoting
      final currentUserId = await _getCurrentUserId();

      // Check if this is the user's own request (additional safety check)
      if (currentUserId != null) {
        try {
          final allRequests = await getAllSongRequests();
          final targetRequest = allRequests.firstWhere(
            (request) => request.id == songRequestId,
            orElse: () => throw Exception('Request not found'),
          );

          if (targetRequest.customerId == currentUserId) {
            debugPrint('User attempted to upvote their own request - preventing action');
            return false; // Don't allow users to upvote their own requests
          }
        } catch (e) {
          debugPrint('Could not verify request ownership, proceeding with upvote: $e');
        }
      }

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
        return true; // Return true to update UI
      }
      // Rethrow the error so we can handle it in the UI
      rethrow;
    }
  }
}
