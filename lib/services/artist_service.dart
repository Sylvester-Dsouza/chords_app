import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/artist.dart';
import 'api_service.dart';
import 'cache_service.dart';
import 'song_service.dart';

class ArtistService {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();
  final SongService _songService = SongService();

  // Cache for artist song counts
  Map<String, int> _artistSongCounts = {};

  // Get all artists
  Future<List<Artist>> getAllArtists({bool forceRefresh = false}) async {
    try {
      // First, get song counts for all artists
      if (_artistSongCounts.isEmpty || forceRefresh) {
        _artistSongCounts = await _songService.countSongsByArtist();
        debugPrint('Loaded song counts for ${_artistSongCounts.length} artists');
      }

      // Check if we have cached artists and we're not forcing a refresh
      if (!forceRefresh) {
        final cachedArtists = await _cacheService.getCachedArtists();
        if (cachedArtists != null) {
          debugPrint('Using cached artists (${cachedArtists.length} artists)');

          // Update song counts for cached artists
          final updatedArtists = _updateArtistSongCounts(cachedArtists);

          // Start a background refresh if the cache is older than 30 minutes
          _refreshArtistsIfNeeded();

          return updatedArtists;
        }
      }

      // If no cache or forcing refresh, fetch from API
      debugPrint(forceRefresh
          ? 'Forcing refresh of artists from API...'
          : 'No cached artists found, fetching from API...');

      final response = await _apiService.get('/api/artists');

      debugPrint('Artist API response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        List<dynamic> data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] as List<dynamic>;
          debugPrint('Received ${data.length} artists from API (nested data field)');
        } else if (response.data is List) {
          data = response.data as List<dynamic>;
          debugPrint('Received ${data.length} artists from API (direct list)');
        } else {
          debugPrint('Unexpected response format: ${response.data.runtimeType}');
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No artists found in API response');
          return [];
        }

        try {
          // Log the raw data for the first few artists to debug
          for (var artistJson in data.take(3)) {
            debugPrint('Raw artist data: $artistJson');
          }

          // Process artists with accurate song counts
          final List<Artist> artists = [];
          for (var artistJson in data) {
            // Create the artist object
            final artist = Artist.fromJson(artistJson);

            // Update song count from our accurate count if available
            final String artistNameLower = artist.name.toLowerCase();
            if (_artistSongCounts.containsKey(artistNameLower)) {
              // Create a new artist with the updated song count
              final updatedArtist = Artist(
                id: artist.id,
                name: artist.name,
                bio: artist.bio,
                imageUrl: artist.imageUrl,
                songCount: _artistSongCounts[artistNameLower]!,
              );
              artists.add(updatedArtist);
              debugPrint('Updated song count for ${artist.name}: ${_artistSongCounts[artistNameLower]} songs');
            } else {
              // If we don't have a count, keep it as 0 to accurately show artists with no songs
              final updatedArtist = Artist(
                id: artist.id,
                name: artist.name,
                bio: artist.bio,
                imageUrl: artist.imageUrl,
                songCount: 0,
              );
              artists.add(updatedArtist);
              debugPrint('No songs found for artist ${artist.name}, keeping count as 0');
            }
          }

          debugPrint('Successfully processed ${artists.length} artists with accurate song counts');

          // Log song counts for debugging
          for (var artist in artists.take(10)) {
            debugPrint('Artist from API: ${artist.name}, Song Count: ${artist.songCount}, Image URL: ${artist.imageUrl}');
          }

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

      // If we have cached data and encounter an error, return the cached data as fallback
      if (!forceRefresh) {
        final cachedArtists = await _cacheService.getCachedArtists();
        if (cachedArtists != null) {
          debugPrint('Returning cached artists as fallback after API error');

          // Update song counts for cached artists
          final updatedArtists = _updateArtistSongCounts(cachedArtists);

          return updatedArtists;
        }
      }

      throw Exception('Failed to load artists: $e');
    }
  }

  // Helper method to update artist song counts
  List<Artist> _updateArtistSongCounts(List<Artist> artists) {
    return artists.map((artist) {
      final String artistNameLower = artist.name.toLowerCase();
      if (_artistSongCounts.containsKey(artistNameLower)) {
        // Create a new artist with the updated song count
        return Artist(
          id: artist.id,
          name: artist.name,
          bio: artist.bio,
          imageUrl: artist.imageUrl,
          songCount: _artistSongCounts[artistNameLower]!,
        );
      }
      return artist;
    }).toList();
  }

  // Refresh artists in the background if the cache is older than 30 minutes
  Future<void> _refreshArtistsIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRefreshStr = prefs.getString('last_artists_refresh');

      if (lastRefreshStr != null) {
        final lastRefresh = int.parse(lastRefreshStr);
        final now = DateTime.now().millisecondsSinceEpoch;
        final thirtyMinutesInMillis = 30 * 60 * 1000;

        if (now - lastRefresh > thirtyMinutesInMillis) {
          debugPrint('Artist cache is older than 30 minutes, refreshing in background...');
          // Don't await this call to avoid blocking the UI
          getAllArtists(forceRefresh: true).then((_) {
            prefs.setString('last_artists_refresh', now.toString());
            debugPrint('Background refresh of artists completed');
          }).catchError((e) {
            debugPrint('Background refresh of artists failed: $e');
          });
        }
      } else {
        // No last refresh time, set it now
        prefs.setString('last_artists_refresh', DateTime.now().millisecondsSinceEpoch.toString());
      }
    } catch (e) {
      debugPrint('Error checking if artists need refresh: $e');
    }
  }

  // Search artists by query
  Future<List<Artist>> searchArtists(String query) async {
    if (query.isEmpty) {
      return getAllArtists();
    }

    try {
      // First, get song counts for all artists if not already loaded
      if (_artistSongCounts.isEmpty) {
        _artistSongCounts = await _songService.countSongsByArtist();
        debugPrint('Loaded song counts for ${_artistSongCounts.length} artists');
      }

      // For search, we'll use the cached artists if available and filter them locally
      // This provides instant search results without API calls
      final cachedArtists = await _cacheService.getCachedArtists();
      if (cachedArtists != null) {
        debugPrint('Searching in cached artists with query: $query');
        final lowercaseQuery = query.toLowerCase();
        final filteredArtists = cachedArtists.where((artist) {
          return artist.name.toLowerCase().contains(lowercaseQuery);
        }).toList();

        // Update song counts for filtered artists
        final updatedArtists = _updateArtistSongCounts(filteredArtists);

        debugPrint('Found ${updatedArtists.length} artists in cache matching query');
        return updatedArtists;
      }

      // If no cache, fall back to API search
      debugPrint('No cached artists, searching via API with query: $query');
      final response = await _apiService.get('/api/artists', queryParameters: {'search': query});

      debugPrint('Artist search API response: ${response.toString()}');
      debugPrint('Artist search API response data type: ${response.data.runtimeType}');
      debugPrint('Artist search API response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] as List<dynamic>;
          debugPrint('Received ${data.length} artists from search (nested data field)');
        } else if (response.data is List) {
          data = response.data as List<dynamic>;
          debugPrint('Received ${data.length} artists from search (direct list)');
        } else {
          debugPrint('Unexpected response format: ${response.data.runtimeType}');
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No artists found in search response');
          return [];
        }

        try {
          // Process artists with accurate song counts
          final List<Artist> artists = [];
          for (var artistJson in data) {
            // Create the artist object
            final artist = Artist.fromJson(artistJson);

            // Update song count from our accurate count if available
            final String artistNameLower = artist.name.toLowerCase();
            if (_artistSongCounts.containsKey(artistNameLower)) {
              // Create a new artist with the updated song count
              final updatedArtist = Artist(
                id: artist.id,
                name: artist.name,
                bio: artist.bio,
                imageUrl: artist.imageUrl,
                songCount: _artistSongCounts[artistNameLower]!,
              );
              artists.add(updatedArtist);
              debugPrint('Updated song count for ${artist.name}: ${_artistSongCounts[artistNameLower]} songs');
            } else {
              // If we don't have a count, keep it as 0 to accurately show artists with no songs
              final updatedArtist = Artist(
                id: artist.id,
                name: artist.name,
                bio: artist.bio,
                imageUrl: artist.imageUrl,
                songCount: 0,
              );
              artists.add(updatedArtist);
              debugPrint('No songs found for artist ${artist.name}, keeping count as 0');
            }
          }

          debugPrint('Successfully processed ${artists.length} artists from search with accurate song counts');

          // Log song counts for debugging
          for (var artist in artists.take(5)) {
            debugPrint('Artist from search: ${artist.name}, Song Count: ${artist.songCount}');
          }

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
      // First, get song counts for all artists if not already loaded
      if (_artistSongCounts.isEmpty) {
        _artistSongCounts = await _songService.countSongsByArtist();
        debugPrint('Loaded song counts for ${_artistSongCounts.length} artists');
      }

      debugPrint('Fetching artist with ID: $id');
      final response = await _apiService.get('/api/artists/$id');

      debugPrint('Artist by ID API response: ${response.toString()}');
      debugPrint('Artist by ID API response data type: ${response.data.runtimeType}');
      debugPrint('Artist by ID API response data: ${response.data}');

      if (response.statusCode == 200) {
        dynamic data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'];
          debugPrint('Received artist data (nested data field)');
        } else {
          data = response.data;
          debugPrint('Received artist data (direct object)');
        }

        try {
          // Create the artist object
          final artist = Artist.fromJson(data);

          // Update song count from our accurate count if available
          final String artistNameLower = artist.name.toLowerCase();
          if (_artistSongCounts.containsKey(artistNameLower)) {
            // Create a new artist with the updated song count
            final updatedArtist = Artist(
              id: artist.id,
              name: artist.name,
              bio: artist.bio,
              imageUrl: artist.imageUrl,
              songCount: _artistSongCounts[artistNameLower]!,
            );
            debugPrint('Successfully parsed artist: ${updatedArtist.name}, Song Count: ${updatedArtist.songCount}');
            return updatedArtist;
          } else {
            // If we don't have a count, keep it as 0 to accurately show artists with no songs
            final updatedArtist = Artist(
              id: artist.id,
              name: artist.name,
              bio: artist.bio,
              imageUrl: artist.imageUrl,
              songCount: 0,
            );
            debugPrint('Successfully parsed artist: ${updatedArtist.name}, No songs found, keeping count as 0');
            return updatedArtist;
          }
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
      // First, get song counts for all artists if not already loaded
      if (_artistSongCounts.isEmpty) {
        _artistSongCounts = await _songService.countSongsByArtist();
        debugPrint('Loaded song counts for ${_artistSongCounts.length} artists');
      }

      debugPrint('Searching for artist with name: $name');
      final response = await _apiService.get('/api/artists', queryParameters: {'search': name});

      debugPrint('Artist by name API response: ${response.toString()}');
      debugPrint('Artist by name API response data type: ${response.data.runtimeType}');
      debugPrint('Artist by name API response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] as List<dynamic>;
          debugPrint('Received ${data.length} artists from name search (nested data field)');
        } else if (response.data is List) {
          data = response.data as List<dynamic>;
          debugPrint('Received ${data.length} artists from name search (direct list)');
        } else {
          debugPrint('Unexpected response format: ${response.data.runtimeType}');
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }

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
          // Create the artist object
          final artist = Artist.fromJson(exactMatch);

          // Update song count from our accurate count if available
          final String artistNameLower = artist.name.toLowerCase();
          if (_artistSongCounts.containsKey(artistNameLower)) {
            // Create a new artist with the updated song count
            final updatedArtist = Artist(
              id: artist.id,
              name: artist.name,
              bio: artist.bio,
              imageUrl: artist.imageUrl,
              songCount: _artistSongCounts[artistNameLower]!,
            );
            debugPrint('Successfully found artist: ${updatedArtist.name}, Song Count: ${updatedArtist.songCount}');
            return updatedArtist;
          } else {
            // If we don't have a count, keep it as 0 to accurately show artists with no songs
            final updatedArtist = Artist(
              id: artist.id,
              name: artist.name,
              bio: artist.bio,
              imageUrl: artist.imageUrl,
              songCount: 0,
            );
            debugPrint('Successfully found artist: ${updatedArtist.name}, No songs found, keeping count as 0');
            return updatedArtist;
          }
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
