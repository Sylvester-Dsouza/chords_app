import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';

import 'home_section_service.dart';
import 'persistent_cache_manager.dart';
import 'api_service.dart';

/// Smart data manager that loads data only when needed and uses efficient caching
class SmartDataManager {
  static final SmartDataManager _instance = SmartDataManager._internal();
  factory SmartDataManager() => _instance;
  SmartDataManager._internal();

  final PersistentCacheManager _cache = PersistentCacheManager();
  final ApiService _apiService = ApiService();

  // Cache keys
  static const String _homeSectionsKey = 'home_sections';
  static const String _songsKey = 'songs';
  static const String _artistsKey = 'artists';
  static const String _collectionsKey = 'collections';
  static const String _setlistsKey = 'setlists';
  static const String _likedSongsKey = 'liked_songs';

  /// Initialize the smart data manager
  Future<void> initialize() async {
    await _cache.initialize();
    debugPrint('🧠 Smart data manager initialized');
  }

  /// Get home sections with smart loading
  Future<List<HomeSection>> getHomeSections({bool forceRefresh = false}) async {
    const cacheKey = _homeSectionsKey;
    
    try {
      // Check if we have valid cache and don't need to refresh
      if (!forceRefresh && await _cache.hasValidCache(cacheKey, maxAge: const Duration(hours: 6))) {
        final cached = await _cache.getList<HomeSection>(cacheKey, (json) => HomeSection.fromJson(json));
        if (cached != null && cached.isNotEmpty) {
          debugPrint('📦 Using cached home sections (${cached.length} items)');
          
          // Check for updates in background
          _checkForUpdatesInBackground(cacheKey, () => _fetchHomeSectionsFromAPI());
          
          return cached;
        }
      }

      // Fetch from API
      debugPrint('🌐 Fetching home sections from API...');
      return await _fetchHomeSectionsFromAPI();
    } catch (e) {
      debugPrint('❌ Error getting home sections: $e');
      
      // Fallback to cache even if expired
      final cached = await _cache.getList<HomeSection>(cacheKey, (json) => HomeSection.fromJson(json));
      return cached ?? [];
    }
  }

  /// Get songs with smart loading (only load when needed)
  Future<List<Song>> getSongs({bool forceRefresh = false, int limit = 50}) async {
    const cacheKey = _songsKey;
    
    try {
      // Check if we have valid cache
      if (!forceRefresh && await _cache.hasValidCache(cacheKey, maxAge: const Duration(days: 1))) {
        final cached = await _cache.getList<Song>(cacheKey, (json) => Song.fromJson(json));
        if (cached != null && cached.isNotEmpty) {
          debugPrint('📦 Using cached songs (${cached.length} items, returning first $limit)');
          
          // Check for updates in background
          _checkForUpdatesInBackground(cacheKey, () => _fetchSongsFromAPI(limit: limit));
          
          return cached.take(limit).toList();
        }
      }

      // Fetch from API
      debugPrint('🌐 Fetching songs from API (limit: $limit)...');
      return await _fetchSongsFromAPI(limit: limit);
    } catch (e) {
      debugPrint('❌ Error getting songs: $e');
      
      // Fallback to cache
      final cached = await _cache.getList<Song>(cacheKey, (json) => Song.fromJson(json));
      return cached?.take(limit).toList() ?? [];
    }
  }

  /// Get artists with smart loading
  Future<List<Artist>> getArtists({bool forceRefresh = false, int limit = 30}) async {
    const cacheKey = _artistsKey;
    
    try {
      // Check if we have valid cache
      if (!forceRefresh && await _cache.hasValidCache(cacheKey, maxAge: const Duration(days: 2))) {
        final cached = await _cache.getList<Artist>(cacheKey, (json) => Artist.fromJson(json));
        if (cached != null && cached.isNotEmpty) {
          debugPrint('📦 Using cached artists (${cached.length} items, returning first $limit)');
          
          // Check for updates in background
          _checkForUpdatesInBackground(cacheKey, () => _fetchArtistsFromAPI(limit: limit));
          
          return cached.take(limit).toList();
        }
      }

      // Fetch from API
      debugPrint('🌐 Fetching artists from API (limit: $limit)...');
      return await _fetchArtistsFromAPI(limit: limit);
    } catch (e) {
      debugPrint('❌ Error getting artists: $e');
      
      // Fallback to cache
      final cached = await _cache.getList<Artist>(cacheKey, (json) => Artist.fromJson(json));
      return cached?.take(limit).toList() ?? [];
    }
  }

  /// Get collections with smart loading
  Future<List<Collection>> getCollections({bool forceRefresh = false, int limit = 20}) async {
    const cacheKey = _collectionsKey;
    
    try {
      // Check if we have valid cache
      if (!forceRefresh && await _cache.hasValidCache(cacheKey, maxAge: const Duration(days: 3))) {
        final cached = await _cache.getList<Collection>(cacheKey, (json) => Collection.fromJson(json));
        if (cached != null && cached.isNotEmpty) {
          debugPrint('📦 Using cached collections (${cached.length} items, returning first $limit)');
          
          // Check for updates in background
          _checkForUpdatesInBackground(cacheKey, () => _fetchCollectionsFromAPI(limit: limit));
          
          return cached.take(limit).toList();
        }
      }

      // Fetch from API
      debugPrint('🌐 Fetching collections from API (limit: $limit)...');
      return await _fetchCollectionsFromAPI(limit: limit);
    } catch (e) {
      debugPrint('❌ Error getting collections: $e');
      
      // Fallback to cache
      final cached = await _cache.getList<Collection>(cacheKey, (json) => Collection.fromJson(json));
      return cached?.take(limit).toList() ?? [];
    }
  }

  /// Check for updates in background without blocking UI
  void _checkForUpdatesInBackground(String cacheKey, Future<dynamic> Function() fetchFunction) {
    Timer(const Duration(seconds: 2), () async {
      try {
        debugPrint('🔄 Checking for updates in background for $cacheKey...');
        
        // Get current cache metadata
        final metadata = _cache.getMetadata(cacheKey);
        if (metadata == null) return;
        
        // Make a lightweight API call to check if data has changed
        // This could be a HEAD request or a checksum endpoint
        final hasUpdates = await _checkIfDataHasUpdates(cacheKey, metadata.lastUpdated);
        
        if (hasUpdates) {
          debugPrint('🔄 Updates found for $cacheKey, fetching new data...');
          await fetchFunction();
        } else {
          debugPrint('✅ No updates found for $cacheKey');
        }
      } catch (e) {
        debugPrint('❌ Error checking for background updates: $e');
      }
    });
  }

  /// Check if data has updates (lightweight API call)
  Future<bool> _checkIfDataHasUpdates(String cacheKey, DateTime lastUpdated) async {
    try {
      // This would ideally be a lightweight endpoint that returns last modified time
      // For now, we'll use a simple time-based check
      final response = await _apiService.get('/health');
      
      // In a real implementation, you'd have endpoints like:
      // GET /api/songs/last-modified
      // GET /api/artists/last-modified
      // That return just the timestamp
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return false; // Assume no updates on error
    }
  }

  /// Fetch home sections from API and cache them
  Future<List<HomeSection>> _fetchHomeSectionsFromAPI() async {
    try {
      final response = await _apiService.get('/home-sections/app/content');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final homeSections = data.map((json) => HomeSection.fromJson(json)).toList();
        
        // Cache the data
        await _cache.setList(_homeSectionsKey, homeSections, (section) => section.toJson());
        
        debugPrint('✅ Fetched and cached ${homeSections.length} home sections');
        return homeSections;
      }
      
      throw Exception('Failed to fetch home sections: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching home sections from API: $e');
      rethrow;
    }
  }

  /// Fetch songs from API and cache them
  Future<List<Song>> _fetchSongsFromAPI({int limit = 50}) async {
    try {
      final response = await _apiService.get('/songs?limit=$limit');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final songs = data.map((json) => Song.fromJson(json)).toList();
        
        // Cache the data
        await _cache.setList(_songsKey, songs, (song) => song.toJson());
        
        debugPrint('✅ Fetched and cached ${songs.length} songs');
        return songs;
      }
      
      throw Exception('Failed to fetch songs: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching songs from API: $e');
      rethrow;
    }
  }

  /// Fetch artists from API and cache them
  Future<List<Artist>> _fetchArtistsFromAPI({int limit = 30}) async {
    try {
      final response = await _apiService.get('/artists?limit=$limit');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final artists = data.map((json) => Artist.fromJson(json)).toList();
        
        // Cache the data
        await _cache.setList(_artistsKey, artists, (artist) => artist.toJson());
        
        debugPrint('✅ Fetched and cached ${artists.length} artists');
        return artists;
      }
      
      throw Exception('Failed to fetch artists: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching artists from API: $e');
      rethrow;
    }
  }

  /// Fetch collections from API and cache them
  Future<List<Collection>> _fetchCollectionsFromAPI({int limit = 20}) async {
    try {
      final response = await _apiService.get('/collections?limit=$limit');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final collections = data.map((json) => Collection.fromJson(json)).toList();
        
        // Cache the data
        await _cache.setList(_collectionsKey, collections, (collection) => collection.toJson());
        
        debugPrint('✅ Fetched and cached ${collections.length} collections');
        return collections;
      }
      
      throw Exception('Failed to fetch collections: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching collections from API: $e');
      rethrow;
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _cache.remove(_homeSectionsKey);
    await _cache.remove(_songsKey);
    await _cache.remove(_artistsKey);
    await _cache.remove(_collectionsKey);
    await _cache.remove(_setlistsKey);
    await _cache.remove(_likedSongsKey);
    
    debugPrint('🗑️ All cache cleared');
  }

  /// Get cache statistics
  Future<String> getCacheStats() async {
    final stats = await _cache.getStats();
    return 'Cache: ${stats.totalFiles} files, ${stats.totalSizeMB.toStringAsFixed(1)} MB, ${stats.memoryEntries} in memory';
  }
}
