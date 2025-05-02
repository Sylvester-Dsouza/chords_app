import 'package:flutter/material.dart';
import '../models/artist.dart';
import 'api_service.dart';
import 'cache_service.dart';

class ArtistService {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // Get all artists
  Future<List<Artist>> getAllArtists() async {
    try {
      // First check if we have cached artists
      final cachedArtists = await _cacheService.getCachedArtists();
      if (cachedArtists != null) {
        debugPrint('Using cached artists (${cachedArtists.length} artists)');
        return cachedArtists;
      }

      // If no cache, fetch from API
      debugPrint('No cached artists found, fetching from API...');
      final response = await _apiService.get('/artists');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} artists from API');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No artists found in API response');
          return [];
        }

        try {
          final artists = data.map((json) => Artist.fromJson(json)).toList();
          debugPrint('Successfully parsed ${artists.length} artists');

          // Cache the artists for future use
          await _cacheService.cacheArtists(artists);

          return artists;
        } catch (parseError) {
          debugPrint('Error parsing artist data: $parseError');
          throw Exception('Failed to parse artist data: $parseError');
        }
      } else {
        debugPrint('Failed to load artists: ${response.statusCode}');
        throw Exception('Failed to load artists: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting artists: $e');
      throw Exception('Failed to load artists: $e');
    }
  }

  // Search artists by query
  Future<List<Artist>> searchArtists(String query) async {
    if (query.isEmpty) {
      return getAllArtists();
    }

    try {
      // For search, we'll use the cached artists if available and filter them locally
      // This provides instant search results without API calls
      final cachedArtists = await _cacheService.getCachedArtists();
      if (cachedArtists != null) {
        debugPrint('Searching in cached artists with query: $query');
        final lowercaseQuery = query.toLowerCase();
        final filteredArtists = cachedArtists.where((artist) {
          return artist.name.toLowerCase().contains(lowercaseQuery);
        }).toList();
        debugPrint('Found ${filteredArtists.length} artists in cache matching query');
        return filteredArtists;
      }

      // If no cache, fall back to API search
      debugPrint('No cached artists, searching via API with query: $query');
      final response = await _apiService.get('/artists', queryParameters: {'search': query});

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} artists from search');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No artists found in search response');
          return [];
        }

        try {
          final artists = data.map((json) => Artist.fromJson(json)).toList();
          debugPrint('Successfully parsed ${artists.length} artists from search');
          return artists;
        } catch (parseError) {
          debugPrint('Error parsing search data: $parseError');
          throw Exception('Failed to parse search data: $parseError');
        }
      } else {
        debugPrint('Failed to search artists: ${response.statusCode}');
        throw Exception('Failed to search artists: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching artists: $e');
      throw Exception('Failed to search artists: $e');
    }
  }

  // Get artist by ID
  Future<Artist> getArtistById(String id) async {
    try {
      debugPrint('Fetching artist with ID: $id');
      final response = await _apiService.get('/artists/$id');

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        debugPrint('Received artist data: $data');

        try {
          final artist = Artist.fromJson(data);
          debugPrint('Successfully parsed artist: ${artist.name}');
          return artist;
        } catch (parseError) {
          debugPrint('Error parsing artist data: $parseError');
          throw Exception('Failed to parse artist data: $parseError');
        }
      } else {
        debugPrint('Failed to load artist: ${response.statusCode}');
        throw Exception('Failed to load artist: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting artist: $e');
      throw Exception('Failed to load artist: $e');
    }
  }

  // Get artist by name
  Future<Artist?> getArtistByName(String name) async {
    try {
      debugPrint('Searching for artist with name: $name');
      final response = await _apiService.get('/artists', queryParameters: {'search': name});

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} artists from name search');

        // Find the exact match by name
        final exactMatch = data.firstWhere(
          (artist) => artist['name'].toString().toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );

        if (exactMatch == null) {
          debugPrint('No exact match found for artist name: $name');
          return null;
        }

        try {
          final artist = Artist.fromJson(exactMatch);
          debugPrint('Successfully found artist: ${artist.name}');
          return artist;
        } catch (parseError) {
          debugPrint('Error parsing artist data: $parseError');
          throw Exception('Failed to parse artist data: $parseError');
        }
      } else {
        debugPrint('Failed to search artist by name: ${response.statusCode}');
        throw Exception('Failed to search artist by name: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching artist by name: $e');
      throw Exception('Failed to search artist by name: $e');
    }
  }


}
