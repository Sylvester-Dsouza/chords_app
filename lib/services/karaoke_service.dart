import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/karaoke.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class KaraokeService {
  final AuthService _authService;

  KaraokeService(this._authService);

  /// Get all karaoke songs with filters
  Future<List<KaraokeSong>> getKaraokeSongs({
    String? search,
    String? key,
    String? difficulty,
    String? artistId,
    KaraokeSortOption sort = KaraokeSortOption.popular,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort.apiValue,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (key != null && key.isNotEmpty) {
        queryParams['key'] = key;
      }
      if (difficulty != null && difficulty.isNotEmpty) {
        queryParams['difficulty'] = difficulty;
      }
      if (artistId != null && artistId.isNotEmpty) {
        queryParams['artistId'] = artistId;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/karaoke/songs')
          .replace(queryParameters: queryParams);

      final headers = {
        'Content-Type': 'application/json',
      };

      // Add auth token if available
      final token = await _authService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      debugPrint('🎤 Karaoke songs API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('🎤 Response data keys: ${data.keys}');

        if (data['songs'] != null) {
          final songs = (data['songs'] as List)
              .map((json) => KaraokeSong.fromJson(json))
              .toList();
          debugPrint('🎤 Parsed ${songs.length} karaoke songs');
          return songs;
        } else {
          debugPrint('🎤 No songs key in response');
        }
      } else {
        debugPrint('🎤 API error: ${response.statusCode} - ${response.body}');
      }

      return [];
    } catch (e) {
      debugPrint('🎤 Error fetching karaoke songs: $e');
      return [];
    }
  }

  /// Get popular karaoke songs
  Future<List<KaraokeSong>> getPopularKaraokeSongs({int limit = 10}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/karaoke/songs/popular')
          .replace(queryParameters: {'limit': limit.toString()});

      final headers = {
        'Content-Type': 'application/json',
      };

      // Add auth token if available
      final token = await _authService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      debugPrint('🎤 Popular karaoke songs API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('🎤 Popular response data keys: ${data.keys}');

        if (data['songs'] != null) {
          final songs = (data['songs'] as List)
              .map((json) => KaraokeSong.fromJson(json))
              .toList();
          debugPrint('🎤 Parsed ${songs.length} popular karaoke songs');
          return songs;
        } else {
          debugPrint('🎤 No songs key in popular response');
        }
      } else {
        debugPrint('🎤 Popular API error: ${response.statusCode} - ${response.body}');
      }

      return [];
    } catch (e) {
      debugPrint('🎤 Error fetching popular karaoke songs: $e');
      return [];
    }
  }

  /// Get recent karaoke songs
  Future<List<KaraokeSong>> getRecentKaraokeSongs({int limit = 10}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/karaoke/songs/recent')
          .replace(queryParameters: {'limit': limit.toString()});

      final headers = {
        'Content-Type': 'application/json',
      };

      // Add auth token if available
      final token = await _authService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      debugPrint('🎤 Recent karaoke songs API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('🎤 Recent response data keys: ${data.keys}');

        if (data['songs'] != null) {
          final songs = (data['songs'] as List)
              .map((json) => KaraokeSong.fromJson(json))
              .toList();
          debugPrint('🎤 Parsed ${songs.length} recent karaoke songs');
          return songs;
        } else {
          debugPrint('🎤 No songs key in recent response');
        }
      } else {
        debugPrint('🎤 Recent API error: ${response.statusCode} - ${response.body}');
      }

      return [];
    } catch (e) {
      debugPrint('🎤 Error fetching recent karaoke songs: $e');
      return [];
    }
  }

  /// Get karaoke download URL
  Future<Map<String, dynamic>?> getKaraokeDownloadUrl(String songId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/karaoke/songs/$songId/download'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get download URL: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting karaoke download URL: $e');
      return null;
    }
  }

  /// Track karaoke analytics
  Future<void> trackAnalytics(String songId, String action, {int? duration}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return; // Skip analytics if not authenticated
      }

      final data = {
        'songId': songId,
        'action': action,
        if (duration != null) 'duration': duration,
      };

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/karaoke/analytics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
    } catch (e) {
      debugPrint('Error tracking karaoke analytics: $e');
      // Don't throw error for analytics failures
    }
  }

  /// Get karaoke stats (for admin)
  Future<Map<String, dynamic>?> getKaraokeStats() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/karaoke/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching karaoke stats: $e');
      return null;
    }
  }
}
