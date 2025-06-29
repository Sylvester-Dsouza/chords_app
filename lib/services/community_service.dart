import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/community_setlist.dart';
import '../services/auth_service.dart';

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
        return CommunitySetlistsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load community setlists: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading community setlists: $e');
    }
  }

  // Get trending setlists
  Future<CommunitySetlistsResponse> getTrendingSetlists({int limit = 10}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/community/setlists/trending').replace(
        queryParameters: {
          'limit': limit.toString(),
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
        return CommunitySetlistsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load trending setlists: ${response.statusCode}');
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

      final uri = Uri.parse('${ApiConfig.baseUrl}/community/setlists/my-liked').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
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
        return CommunitySetlistsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load liked setlists: ${response.statusCode}');
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
        return json.decode(response.body);
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
        return json.decode(response.body);
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
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/setlists/$setlistId/view'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to increment view count: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error incrementing view count: $e');
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
        return json.decode(response.body);
      } else if (response.statusCode == 409) {
        throw Exception('Setlist is already public');
      } else {
        throw Exception('Failed to make setlist public: ${response.statusCode}');
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
        return json.decode(response.body);
      } else if (response.statusCode == 409) {
        throw Exception('Setlist is already private');
      } else {
        throw Exception('Failed to make setlist private: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error making setlist private: $e');
    }
  }
}
