import 'package:flutter/material.dart';
import '../models/song.dart';
import 'api_service.dart';

class RatingService {
  final ApiService _apiService = ApiService();

  // Rate a song or update existing rating
  Future<bool> rateSong(String songId, int rating, {String? comment}) async {
    try {
      debugPrint('Rating song with ID: $songId, rating: $rating, comment: $comment');
      
      final response = await _apiService.post('/song-ratings', data: {
        'songId': songId,
        'rating': rating,
        'comment': comment,
      });

      debugPrint('Rate song API response: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Successfully rated song');
        return true;
      } else {
        debugPrint('Failed to rate song: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error rating song: $e');
      return false;
    }
  }

  // Get user's rating for a song
  Future<int?> getUserRatingForSong(String songId) async {
    try {
      debugPrint('Getting user rating for song with ID: $songId');
      
      final response = await _apiService.get('/song-ratings/songs/$songId/my-rating');
      
      debugPrint('Get user rating API response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('User rating data: $data');
        
        if (data != null && data['rating'] != null) {
          return data['rating'] as int;
        }
      }
      
      return null; // No rating found
    } catch (e) {
      debugPrint('Error getting user rating: $e');
      // If we get a 404, it means the user hasn't rated this song yet
      if (e.toString().contains('404')) {
        return null;
      }
      // For development, return a mock rating
      return null;
    }
  }

  // Get rating statistics for a song
  Future<Map<String, dynamic>> getSongRatingStats(String songId) async {
    try {
      debugPrint('Getting rating stats for song with ID: $songId');
      
      final response = await _apiService.get('/song-ratings/songs/$songId/stats');
      
      debugPrint('Get song rating stats API response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('Song rating stats data: $data');
        
        return {
          'averageRating': data['averageRating'] ?? 0.0,
          'ratingCount': data['ratingCount'] ?? 0,
          'distribution': data['distribution'] ?? {},
        };
      }
      
      return {
        'averageRating': 0.0,
        'ratingCount': 0,
        'distribution': {},
      };
    } catch (e) {
      debugPrint('Error getting song rating stats: $e');
      // For development, return mock stats
      return {
        'averageRating': 0.0,
        'ratingCount': 0,
        'distribution': {},
      };
    }
  }

  // Update song model with rating information
  Future<Song> updateSongWithRatingInfo(Song song) async {
    try {
      // Get rating stats
      final stats = await getSongRatingStats(song.id);
      
      // Get user's rating
      final userRating = await getUserRatingForSong(song.id);
      
      // Update the song model
      song.averageRating = (stats['averageRating'] as num).toDouble();
      song.ratingCount = stats['ratingCount'] as int;
      song.userRating = userRating;
      
      return song;
    } catch (e) {
      debugPrint('Error updating song with rating info: $e');
      return song;
    }
  }
}
