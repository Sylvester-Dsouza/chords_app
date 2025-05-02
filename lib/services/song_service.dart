import 'package:flutter/material.dart';
import '../models/song.dart';
import 'api_service.dart';
import 'cache_service.dart';

class SongService {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // Get all songs
  Future<List<Song>> getAllSongs() async {
    try {
      // First check if we have cached songs
      final cachedSongs = await _cacheService.getCachedSongs();
      if (cachedSongs != null) {
        debugPrint('Using cached songs (${cachedSongs.length} songs)');
        return cachedSongs;
      }

      // If no cache, fetch from API
      debugPrint('No cached songs found, fetching from API...');
      final response = await _apiService.get('/songs');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} songs from API');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No songs found in API response');
          return [];
        }

        try {
          final List<Song> songs = [];
          for (var i = 0; i < data.length; i++) {
            try {
              final json = data[i];
              final song = Song.fromJson(json);
              songs.add(song);
            } catch (e) {
              debugPrint('Error parsing individual song: $e');
              // Continue parsing other songs even if one fails
            }
          }

          debugPrint('Successfully parsed ${songs.length} songs');

          // Cache the songs for future use
          await _cacheService.cacheSongs(songs);

          return songs;
        } catch (parseError) {
          debugPrint('Error parsing song data: $parseError');
          throw Exception('Failed to parse song data: $parseError');
        }
      } else {
        debugPrint('Failed to load songs: ${response.statusCode}');
        throw Exception('Failed to load songs: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting songs: $e');
      throw Exception('Failed to load songs: $e');
    }
  }

  // Search songs by query
  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) {
      return getAllSongs();
    }

    try {
      // For search, we'll use the cached songs if available and filter them locally
      // This provides instant search results without API calls
      final cachedSongs = await _cacheService.getCachedSongs();
      if (cachedSongs != null) {
        debugPrint('Searching in cached songs with query: $query');
        final lowercaseQuery = query.toLowerCase();
        final filteredSongs = cachedSongs.where((song) {
          return song.title.toLowerCase().contains(lowercaseQuery) ||
              song.artist.toLowerCase().contains(lowercaseQuery);
        }).toList();
        debugPrint('Found ${filteredSongs.length} songs in cache matching query');
        return filteredSongs;
      }

      // If no cache, fall back to API search
      debugPrint('No cached songs, searching via API with query: $query');
      final response = await _apiService.get('/songs', queryParameters: {'search': query});

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} songs from search');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No songs found in search response');
          return [];
        }

        try {
          final List<Song> songs = [];
          for (var i = 0; i < data.length; i++) {
            try {
              final json = data[i];
              final song = Song.fromJson(json);
              songs.add(song);
            } catch (e) {
              debugPrint('Error parsing individual search result: $e');
              // Continue parsing other songs even if one fails
            }
          }

          debugPrint('Successfully parsed ${songs.length} songs from search');
          return songs;
        } catch (parseError) {
          debugPrint('Error parsing search data: $parseError');
          throw Exception('Failed to parse search data: $parseError');
        }
      } else {
        debugPrint('Failed to search songs: ${response.statusCode}');
        throw Exception('Failed to search songs: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching songs: $e');
      throw Exception('Failed to search songs: $e');
    }
  }

  // Get songs by artist ID
  Future<List<Song>> getSongsByArtist(String artistId) async {
    try {
      debugPrint('Fetching songs for artist ID: $artistId');
      final response = await _apiService.get('/songs', queryParameters: {'artistId': artistId});

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} songs for artist');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No songs found for this artist');
          return [];
        }

        try {
          final List<Song> songs = [];
          for (var i = 0; i < data.length; i++) {
            try {
              final json = data[i];
              debugPrint('Parsing artist song ${i+1}/${data.length}: ${json['title']}');

              final song = Song.fromJson(json);
              songs.add(song);
              debugPrint('Successfully parsed artist song: ${song.title}');
            } catch (e) {
              debugPrint('Error parsing individual artist song: $e');
              // Continue parsing other songs even if one fails
            }
          }

          debugPrint('Successfully parsed ${songs.length} songs for artist');
          return songs;
        } catch (parseError) {
          debugPrint('Error parsing artist songs data: $parseError');
          throw Exception('Failed to parse artist songs data: $parseError');
        }
      } else {
        debugPrint('Failed to load artist songs: ${response.statusCode}');
        throw Exception('Failed to load artist songs: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting artist songs: $e');
      throw Exception('Failed to load artist songs: $e');
    }
  }

  // Get a single song by ID
  Future<Song> getSongById(String id) async {
    try {
      debugPrint('Fetching song with ID: $id');
      final response = await _apiService.get('/songs/$id');

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        debugPrint('Received song data: $data');

        try {
          final song = Song.fromJson(data);
          debugPrint('Successfully parsed song: ${song.title} by ${song.artist}');
          return song;
        } catch (parseError) {
          debugPrint('Error parsing song data: $parseError');
          throw Exception('Failed to parse song data: $parseError');
        }
      } else {
        debugPrint('Failed to load song: ${response.statusCode}');
        throw Exception('Failed to load song: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting song: $e');
      // Return mock data for development
      return _getMockSongById(id);
    }
  }

  // Toggle like status for a song
  Future<bool> toggleLikeSong(String songId, bool isLiked) async {
    try {
      if (isLiked) {
        // Like the song
        final response = await _apiService.post('/liked-songs/$songId', data: {});
        return response.statusCode == 200 || response.statusCode == 201;
      } else {
        // Unlike the song
        final response = await _apiService.delete('/liked-songs/$songId');
        return response.statusCode == 200 || response.statusCode == 204;
      }
    } catch (e) {
      debugPrint('Error toggling song like: $e');
      // For development, just return success
      return true;
    }
  }

  // Mock song for development
  Song _getMockSongById(String id) {
    return Song(
      id: id,
      title: 'At the Cross Love Ran Red',
      artist: 'Worship Paradise',
      key: 'Em',
      chords: '''[Intro]
Em  D|G  |C  |C  |

[Verse 1]
Em           D        G            C
There's a place, where mercy reigns and never dies
Em           D        G            C
There's a place, where streams of grace flows deep and wide

[Pre-Chorus]
D           C
All the love, I've ever found
D                 C
Comes like a flood, comes flowing down

[Chorus]
C
At the cross, at the cross
G
I surrender my life
D                 Am
I'm in awe of you; I'm in awe of you
C                G
Where your love ran red, and my sins washed white
D                 Am
I owe all to you; I owe all to you
C    G
Jesus''',
      isLiked: false,
      commentCount: 0,
    );
  }

  // Get songs by artist name
  Future<List<Song>> getSongsByArtistName(String artistName) async {
    try {
      debugPrint('Fetching songs for artist name: $artistName');
      // First, search for the artist to get their ID
      final response = await _apiService.get('/songs', queryParameters: {'search': artistName});

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} songs from artist name search');

        // Filter songs to only include those by the exact artist name
        final filteredData = data.where((song) {
          final artistData = song['artist'];
          if (artistData == null) return false;

          final name = artistData['name'];
          return name != null && name.toString().toLowerCase() == artistName.toLowerCase();
        }).toList();

        debugPrint('Filtered to ${filteredData.length} songs by exact artist name');

        // Check if data is empty
        if (filteredData.isEmpty) {
          debugPrint('No songs found for this artist name');
          return [];
        }

        try {
          final List<Song> songs = [];
          for (var i = 0; i < filteredData.length; i++) {
            try {
              final json = filteredData[i];
              debugPrint('Parsing artist name song ${i+1}/${filteredData.length}: ${json['title']}');

              final song = Song.fromJson(json);
              songs.add(song);
              debugPrint('Successfully parsed artist name song: ${song.title}');
            } catch (e) {
              debugPrint('Error parsing individual artist name song: $e');
              // Continue parsing other songs even if one fails
            }
          }

          debugPrint('Successfully parsed ${songs.length} songs for artist name');
          return songs;
        } catch (parseError) {
          debugPrint('Error parsing artist name songs data: $parseError');
          throw Exception('Failed to parse artist name songs data: $parseError');
        }
      } else {
        debugPrint('Failed to load artist name songs: ${response.statusCode}');
        throw Exception('Failed to load artist name songs: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting artist name songs: $e');
      throw Exception('Failed to load artist name songs: $e');
    }
  }
}
