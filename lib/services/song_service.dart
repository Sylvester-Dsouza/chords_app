import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/search_filters.dart';
import 'api_service.dart';
import 'cache_service.dart';

class SongService {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // Get paginated songs for better performance
  Future<Map<String, dynamic>> getPaginatedSongs({
    int page = 1,
    int limit = 20,
    String? search,
    String? artistId,
    String? tags,
    String? sortBy,
    String? sortOrder,
    bool forceRefresh = false,
  }) async {
    try {
      final Map<String, String> queryParameters = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (artistId != null && artistId.isNotEmpty) {
        queryParameters['artistId'] = artistId;
      }
      if (tags != null && tags.isNotEmpty) {
        queryParameters['tags'] = tags;
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParameters['sortBy'] = sortBy;
      }
      if (sortOrder != null && sortOrder.isNotEmpty) {
        queryParameters['sortOrder'] = sortOrder;
      }

      debugPrint('Fetching paginated songs with parameters: $queryParameters');
      final response = await _apiService.get('/songs/paginated', queryParameters: queryParameters);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final List<dynamic> songsData = responseData['data'] as List<dynamic>;
        final Map<String, dynamic> pagination = responseData['pagination'] as Map<String, dynamic>;

        final List<Song> songs = [];
        for (var songJson in songsData) {
          try {
            final song = Song.fromJson(songJson);
            songs.add(song);
          } catch (e) {
            debugPrint('Error parsing individual song: $e');
          }
        }

        debugPrint('Successfully fetched ${songs.length} songs (page $page of ${pagination['totalPages']})');

        return {
          'songs': songs,
          'pagination': pagination,
        };
      } else {
        throw Exception('Failed to load paginated songs: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting paginated songs: $e');
      throw Exception('Failed to load paginated songs: $e');
    }
  }

  // Get all songs
  Future<List<Song>> getAllSongs({bool forceRefresh = false}) async {
    try {
      // Check if we should force refresh or if we have valid cached songs
      if (!forceRefresh) {
        // Check if cache is stale (older than 5 minutes)
        final isCacheStale = await _cacheService.isCacheStale('cache_songs', 5);

        if (isCacheStale) {
          debugPrint('Song cache is stale, forcing refresh from API');
          forceRefresh = true;
        } else {
          // Try to use cached songs if not stale
          final cachedSongs = await _cacheService.getCachedSongs();
          if (cachedSongs != null) {
            debugPrint('Using cached songs (${cachedSongs.length} songs)');
            return cachedSongs;
          }
        }
      } else {
        debugPrint('Force refreshing songs from API');
      }

      // If no valid cache or force refresh, fetch from API
      debugPrint('Fetching songs from API...');
      final response = await _apiService.get('/songs');

      debugPrint('Song API response: ${response.toString()}');
      debugPrint('Song API response data type: ${response.data.runtimeType}');
      debugPrint('Song API response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] as List<dynamic>;
          debugPrint('Received ${data.length} songs from API (nested data field)');
        } else if (response.data is List) {
          data = response.data as List<dynamic>;
          debugPrint('Received ${data.length} songs from API (direct list)');
        } else {
          debugPrint('Unexpected response format: ${response.data.runtimeType}');
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }

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
  Future<List<Song>> searchSongs(String query, {SongSearchFilters? filters}) async {
    if (query.isEmpty && (filters == null || !filters.isActive)) {
      return getAllSongs();
    }

    try {
      // Try to use cached songs for local filtering when possible
      final cachedSongs = await _cacheService.getCachedSongs();
      if (cachedSongs != null && cachedSongs.isNotEmpty) {
        debugPrint('Filtering cached songs locally with query: "$query" and filters: ${filters?.isActive == true ? "active" : "none"}');

        List<Song> filteredSongs = List.from(cachedSongs);

        // Apply search query filter
        if (query.isNotEmpty) {
          final lowercaseQuery = query.toLowerCase();
          filteredSongs = filteredSongs.where((song) {
            return song.title.toLowerCase().contains(lowercaseQuery) ||
                song.artist.toLowerCase().contains(lowercaseQuery);
          }).toList();
        }

        // Apply additional filters if provided
        if (filters != null && filters.isActive) {
          filteredSongs = _applyFiltersLocally(filteredSongs, filters);
        }

        debugPrint('Found ${filteredSongs.length} songs after local filtering');
        return filteredSongs;
      }

      // If no cache available, fall back to API filtering
      debugPrint('No cached songs available, using API for filtering');
      final Map<String, String> queryParameters = {};

      // Add search query if provided
      if (query.isNotEmpty) {
        queryParameters['search'] = query;
      }

      // Add filters if provided
      if (filters != null && filters.isActive) {
        queryParameters.addAll(filters.toQueryParameters());
      }

      debugPrint('Searching songs via API with parameters: $queryParameters');
      final response = await _apiService.get('/songs', queryParameters: queryParameters);

      debugPrint('Song search API response: ${response.toString()}');
      debugPrint('Song search API response data type: ${response.data.runtimeType}');
      debugPrint('Song search API response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] as List<dynamic>;
          debugPrint('Received ${data.length} songs from search (nested data field)');
        } else if (response.data is List) {
          data = response.data as List<dynamic>;
          debugPrint('Received ${data.length} songs from search (direct list)');
        } else {
          debugPrint('Unexpected response format: ${response.data.runtimeType}');
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }

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

      debugPrint('Songs by artist API response: ${response.toString()}');
      debugPrint('Songs by artist API response data type: ${response.data.runtimeType}');
      debugPrint('Songs by artist API response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] as List<dynamic>;
          debugPrint('Received ${data.length} songs for artist (nested data field)');
        } else if (response.data is List) {
          data = response.data as List<dynamic>;
          debugPrint('Received ${data.length} songs for artist (direct list)');
        } else {
          debugPrint('Unexpected response format: ${response.data.runtimeType}');
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }

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

      // Always fetch fresh data from the API for individual songs
      // This ensures we always have the latest data when viewing song details
      debugPrint('Always fetching fresh song data from API to ensure latest content');
      final response = await _apiService.get('/songs/$id');

      debugPrint('Song by ID API response: ${response.toString()}');
      debugPrint('Song by ID API response data type: ${response.data.runtimeType}');
      debugPrint('Song by ID API response data: ${response.data}');

      if (response.statusCode == 200) {
        dynamic data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'];
          debugPrint('Received song data (nested data field)');
        } else {
          data = response.data;
          debugPrint('Received song data (direct object)');
        }

        try {
          final song = Song.fromJson(data);
          debugPrint('Successfully parsed song: ${song.title} by ${song.artist}');

          // Update the song in the cache with the fresh data
          // This ensures other parts of the app using cached data will have the latest version
          _updateSongInCache(song);

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

  // Apply filters locally to a list of songs
  List<Song> _applyFiltersLocally(List<Song> songs, SongSearchFilters filters) {
    List<Song> filteredSongs = List.from(songs);

    // Apply key filter
    if (filters.key != null && filters.key!.isNotEmpty) {
      debugPrint('Applying key filter: ${filters.key}');
      filteredSongs = filteredSongs.where((song) {
        final songKey = song.key.trim();
        final filterKey = filters.key!.trim();
        final matches = songKey.toLowerCase() == filterKey.toLowerCase();
        if (!matches) {
          debugPrint('Song "${song.title}" key "$songKey" does not match filter "$filterKey"');
        }
        return matches;
      }).toList();
      debugPrint('After key filter: ${filteredSongs.length} songs remain');
    }

    // Apply difficulty filter
    if (filters.difficulty != null && filters.difficulty!.isNotEmpty) {
      debugPrint('Applying difficulty filter: ${filters.difficulty}');
      filteredSongs = filteredSongs.where((song) {
        if (song.difficulty == null) return false;
        final matches = song.difficulty!.toLowerCase() == filters.difficulty!.toLowerCase();
        if (!matches) {
          debugPrint('Song "${song.title}" difficulty "${song.difficulty}" does not match filter "${filters.difficulty}"');
        }
        return matches;
      }).toList();
      debugPrint('After difficulty filter: ${filteredSongs.length} songs remain');
    }

    // Apply capo filter
    if (filters.capo != null) {
      debugPrint('Applying capo filter: ${filters.capo}');
      filteredSongs = filteredSongs.where((song) {
        final matches = song.capo == filters.capo;
        if (!matches) {
          debugPrint('Song "${song.title}" capo "${song.capo}" does not match filter "${filters.capo}"');
        }
        return matches;
      }).toList();
      debugPrint('After capo filter: ${filteredSongs.length} songs remain');
    }

    // Apply time signature filter
    if (filters.timeSignature != null && filters.timeSignature!.isNotEmpty) {
      debugPrint('Applying time signature filter: ${filters.timeSignature}');
      filteredSongs = filteredSongs.where((song) {
        if (song.timeSignature == null) return false;
        final matches = song.timeSignature!.toLowerCase() == filters.timeSignature!.toLowerCase();
        if (!matches) {
          debugPrint('Song "${song.title}" time signature "${song.timeSignature}" does not match filter "${filters.timeSignature}"');
        }
        return matches;
      }).toList();
      debugPrint('After time signature filter: ${filteredSongs.length} songs remain');
    }

    // Apply artist filter
    if (filters.artistId != null && filters.artistId!.isNotEmpty) {
      debugPrint('Applying artist ID filter: ${filters.artistId}');
      filteredSongs = filteredSongs.where((song) {
        final matches = song.artistId == filters.artistId;
        if (!matches) {
          debugPrint('Song "${song.title}" artist ID "${song.artistId}" does not match filter "${filters.artistId}"');
        }
        return matches;
      }).toList();
      debugPrint('After artist ID filter: ${filteredSongs.length} songs remain');
    }

    // Apply language filter
    if (filters.languageId != null && filters.languageId!.isNotEmpty) {
      debugPrint('Applying language ID filter: ${filters.languageId}');
      filteredSongs = filteredSongs.where((song) {
        final matches = song.languageId == filters.languageId;
        if (!matches) {
          debugPrint('Song "${song.title}" language ID "${song.languageId}" does not match filter "${filters.languageId}"');
        }
        return matches;
      }).toList();
      debugPrint('After language ID filter: ${filteredSongs.length} songs remain');
    }

    // Apply sorting
    if (filters.sortBy != null && filters.sortBy!.isNotEmpty) {
      debugPrint('Applying sort: ${filters.sortBy}');
      switch (filters.sortBy) {
        case 'alphabetical':
          filteredSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          break;
        case 'newest':
          // Sort by rating count as a proxy for newest (higher rating count = more recent activity)
          filteredSongs.sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
          break;
        case 'mostViewed':
          // Sort by average rating as a proxy for most viewed (higher rated songs are likely more viewed)
          filteredSongs.sort((a, b) => b.averageRating.compareTo(a.averageRating));
          break;
        default:
          debugPrint('Unknown sort option: ${filters.sortBy}');
      }
    }

    return filteredSongs;
  }

  // Update a single song in the cache
  Future<void> _updateSongInCache(Song updatedSong) async {
    try {
      // Get the current cached songs
      final cachedSongs = await _cacheService.getCachedSongs();
      if (cachedSongs == null || cachedSongs.isEmpty) {
        debugPrint('No cached songs to update');
        return;
      }

      // Find and update the song in the cache
      final updatedSongs = cachedSongs.map((song) {
        if (song.id == updatedSong.id) {
          debugPrint('Updating song ${updatedSong.id} in cache with fresh data');
          return updatedSong;
        }
        return song;
      }).toList();

      // Save the updated cache
      await _cacheService.cacheSongs(updatedSongs);
      debugPrint('Successfully updated song in cache');
    } catch (e) {
      debugPrint('Error updating song in cache: $e');
      // Continue anyway, this is just a cache update
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
      artist: 'Stuthi',
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

      debugPrint('Songs by artist name API response: ${response.toString()}');
      debugPrint('Songs by artist name API response data type: ${response.data.runtimeType}');
      debugPrint('Songs by artist name API response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] as List<dynamic>;
          debugPrint('Received ${data.length} songs from artist name search (nested data field)');
        } else if (response.data is List) {
          data = response.data as List<dynamic>;
          debugPrint('Received ${data.length} songs from artist name search (direct list)');
        } else {
          debugPrint('Unexpected response format: ${response.data.runtimeType}');
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }

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

  // Count songs by artist
  Future<Map<String, int>> countSongsByArtist() async {
    try {
      debugPrint('Counting songs by artist...');
      // Get all songs
      final songs = await getAllSongs();

      // Create a map to count songs by artist
      final Map<String, int> artistSongCounts = {};

      // Count songs for each artist
      for (var song in songs) {
        final artistName = song.artist.toLowerCase();
        if (artistSongCounts.containsKey(artistName)) {
          artistSongCounts[artistName] = artistSongCounts[artistName]! + 1;
        } else {
          artistSongCounts[artistName] = 1;
        }
      }

      debugPrint('Counted songs for ${artistSongCounts.length} artists');
      // Log a few examples
      artistSongCounts.entries.take(5).forEach((entry) {
        debugPrint('Artist: ${entry.key}, Song Count: ${entry.value}');
      });

      return artistSongCounts;
    } catch (e) {
      debugPrint('Error counting songs by artist: $e');
      return {};
    }
  }
}
