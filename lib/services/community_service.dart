import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../config/api_config.dart';
import '../models/community_setlist.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class CommunityService {
  final AuthService _authService;

  CommunityService(this._authService);

  // Get community setlists
  Future<CommunitySetlistsResponse> getCommunitySetlists({
    int page = 1,
    int limit = 20,
    String sortBy = 'newest',
    String? search,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/community/setlists').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'sortBy': sortBy,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CommunitySetlistsResponse.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to load community setlists: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading community setlists: $e');
    }
  }

  // Get trending setlists
  Future<CommunitySetlistsResponse> getTrendingSetlists({
    int limit = 10,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/community/setlists/trending',
      ).replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CommunitySetlistsResponse.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to load trending setlists: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading trending setlists: $e');
    }
  }

  // Get my liked setlists
  Future<CommunitySetlistsResponse> getMyLikedSetlists({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/community/setlists/my-liked',
      ).replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CommunitySetlistsResponse.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to load liked setlists: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading liked setlists: $e');
    }
  }

  // Like a setlist
  Future<Map<String, dynamic>> likeSetlist(String setlistId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/setlists/$setlistId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 409) {
        throw Exception('Already liked this setlist');
      } else {
        throw Exception('Failed to like setlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error liking setlist: $e');
    }
  }

  // Unlike a setlist
  Future<Map<String, dynamic>> unlikeSetlist(String setlistId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/setlists/$setlistId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 409) {
        throw Exception('Not liked this setlist');
      } else {
        throw Exception('Failed to unlike setlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error unliking setlist: $e');
    }
  }

  // Increment view count
  Future<Map<String, dynamic>> incrementViewCount(String setlistId) async {
    try {
      // Create an instance of ApiService which handles token management properly
      final apiService = ApiService();
      
      // Log that we're attempting to increment the view count
      debugPrint('🔍 Incrementing view count for setlist: $setlistId');
      
      // Make the API call using ApiService which handles authentication tokens
      final response = await apiService.post(
        '/setlists/$setlistId/view',
        data: {}, // Empty body is fine for this endpoint
      );
      
      debugPrint('✅ View count increment response: ${response.statusCode}');
      
      // Even if we get a 201 status code, consider it successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        // If the response doesn't have the expected format, create a default success response
        if (response.data == null) {
          return {'success': true, 'viewCount': 1};
        }
        final setlistJson = Map<String, dynamic>.from(response.data as Map<dynamic, dynamic>);
        return setlistJson;
      } else {
        debugPrint('❌ Failed to increment view count: ${response.statusCode}');
        // Return a default success response even on error to prevent UI disruption
        return {'success': true, 'viewCount': 0};
      }
    } catch (e) {
      debugPrint('❌ Error incrementing view count: $e');
      // Return a default success response even on error to prevent UI disruption
      return {'success': true, 'viewCount': 0};
    }
  }

  // Make setlist public
  Future<Map<String, dynamic>> makeSetlistPublic(String setlistId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/setlists/$setlistId/make-public'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 409) {
        throw Exception('Setlist is already public');
      } else {
        throw Exception(
          'Failed to make setlist public: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error making setlist public: $e');
    }
  }

  // Make setlist private
  Future<Map<String, dynamic>> makeSetlistPrivate(String setlistId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/setlists/$setlistId/make-private'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 409) {
        throw Exception('Setlist is already private');
      } else {
        throw Exception(
          'Failed to make setlist private: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error making setlist private: $e');
    }
  }
}
