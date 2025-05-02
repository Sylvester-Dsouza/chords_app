import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';

/// An optimized cache service that efficiently manages memory usage
/// and prevents memory leaks.
class OptimizedCacheService {
  // Singleton instance
  static final OptimizedCacheService _instance = OptimizedCacheService._internal();
  factory OptimizedCacheService() => _instance;
  OptimizedCacheService._internal();

  // Cache keys
  static const String _keySongs = 'cached_songs';
  static const String _keyArtists = 'cached_artists';
  static const String _keyCollections = 'cached_collections';
  static const String _keySeasonalCollections = 'cached_seasonal_collections';
  static const String _keyBeginnerCollections = 'cached_beginner_collections';
  static const String _keyTrendingSongs = 'cached_trending_songs';
  static const String _keyTopArtists = 'cached_top_artists';
  static const String _keyNewSongs = 'cached_new_songs';

  // Cache expiration times (in minutes)
  static const int _songExpirationMinutes = 60; // 1 hour
  static const int _artistExpirationMinutes = 120; // 2 hours
  static const int _collectionExpirationMinutes = 120; // 2 hours
  static const int _trendingExpirationMinutes = 30; // 30 minutes

  // Memory cache with weak references to prevent memory leaks
  final Map<String, dynamic> _memoryCache = {};

  // Maximum memory cache size (number of items)
  static const int _maxMemoryCacheSize = 100;

  // Initialize the cache service
  Future<void> initialize() async {
    debugPrint('Initializing OptimizedCacheService');
    // No initialization needed for now
  }

  // Clear all caches
  Future<void> clearAllCaches() async {
    debugPrint('Clearing all caches');
    _memoryCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySongs);
    await prefs.remove(_keyArtists);
    await prefs.remove(_keyCollections);
    await prefs.remove(_keySeasonalCollections);
    await prefs.remove(_keyBeginnerCollections);
    await prefs.remove(_keyTrendingSongs);
    await prefs.remove(_keyTopArtists);
    await prefs.remove(_keyNewSongs);
  }

  // Generic method to cache data
  Future<void> cacheData<T>(String key, List<T> items, Function(T) toJsonConverter, {int? expirationMinutes}) async {
    try {
      final itemsJson = items.map((item) => toJsonConverter(item)).toList();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': itemsJson,
      };
      
      // Manage memory cache size
      _manageMemoryCacheSize();
      
      // Save to memory cache
      _memoryCache[key] = cacheData;
      
      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(cacheData));
      
      debugPrint('Cached ${items.length} items for key: $key');
    } catch (e) {
      debugPrint('Error caching data for key $key: $e');
    }
  }

  // Generic method to get cached data
  Future<List<T>?> getCachedData<T>(
    String key, 
    Function(Map<String, dynamic>) fromJsonConverter, 
    {int? expirationMinutes}
  ) async {
    try {
      final expiration = expirationMinutes ?? _songExpirationMinutes;
      
      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        final cacheMap = _memoryCache[key] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (expiration * 60 * 1000);
        
        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final itemsJson = cacheMap['data'] as List;
          final items = itemsJson.map((json) => fromJsonConverter(json)).toList();
          
          debugPrint('Retrieved ${items.length} items from memory cache for key: $key');
          return items as List<T>;
        }
      }
      
      // If not in memory or expired, check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(key);
      
      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (expiration * 60 * 1000);
        
        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final itemsJson = cacheMap['data'] as List;
          final items = itemsJson.map((json) => fromJsonConverter(json)).toList();
          
          // Update memory cache
          _memoryCache[key] = cacheMap;
          
          debugPrint('Retrieved ${items.length} items from persistent cache for key: $key');
          return items as List<T>;
        }
      }
      
      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('Error getting cached data for key $key: $e');
      return null;
    }
  }

  // Manage memory cache size to prevent memory leaks
  void _manageMemoryCacheSize() {
    if (_memoryCache.length > _maxMemoryCacheSize) {
      debugPrint('Memory cache size exceeded, removing oldest entries');
      
      // Get all entries sorted by timestamp (oldest first)
      final entries = _memoryCache.entries.toList()
        ..sort((a, b) {
          final aTimestamp = (a.value as Map<String, dynamic>)['timestamp'] as int;
          final bTimestamp = (b.value as Map<String, dynamic>)['timestamp'] as int;
          return aTimestamp.compareTo(bTimestamp);
        });
      
      // Remove oldest entries until we're under the limit
      final entriesToRemove = entries.length - _maxMemoryCacheSize;
      for (var i = 0; i < entriesToRemove; i++) {
        _memoryCache.remove(entries[i].key);
      }
    }
  }

  // Cache songs
  Future<void> cacheSongs(List<Song> songs) async {
    await cacheData<Song>(
      _keySongs, 
      songs, 
      (song) => song.toJson(),
      expirationMinutes: _songExpirationMinutes
    );
  }

  // Get cached songs
  Future<List<Song>?> getCachedSongs() async {
    return await getCachedData<Song>(
      _keySongs,
      (json) => Song.fromJson(json),
      expirationMinutes: _songExpirationMinutes
    );
  }

  // Cache artists
  Future<void> cacheArtists(List<Artist> artists) async {
    await cacheData<Artist>(
      _keyArtists, 
      artists, 
      (artist) => artist.toJson(),
      expirationMinutes: _artistExpirationMinutes
    );
  }

  // Get cached artists
  Future<List<Artist>?> getCachedArtists() async {
    return await getCachedData<Artist>(
      _keyArtists,
      (json) => Artist.fromJson(json),
      expirationMinutes: _artistExpirationMinutes
    );
  }

  // Cache collections
  Future<void> cacheCollections(List<Collection> collections) async {
    await cacheData<Collection>(
      _keyCollections, 
      collections, 
      (collection) => collection.toJson(),
      expirationMinutes: _collectionExpirationMinutes
    );
  }

  // Get cached collections
  Future<List<Collection>?> getCachedCollections() async {
    return await getCachedData<Collection>(
      _keyCollections,
      (json) => Collection.fromJson(json),
      expirationMinutes: _collectionExpirationMinutes
    );
  }

  // Cache seasonal collections
  Future<void> cacheSeasonalCollections(List<Collection> collections) async {
    await cacheData<Collection>(
      _keySeasonalCollections, 
      collections, 
      (collection) => collection.toJson(),
      expirationMinutes: _collectionExpirationMinutes
    );
  }

  // Get cached seasonal collections
  Future<List<Collection>?> getCachedSeasonalCollections() async {
    return await getCachedData<Collection>(
      _keySeasonalCollections,
      (json) => Collection.fromJson(json),
      expirationMinutes: _collectionExpirationMinutes
    );
  }

  // Cache beginner collections
  Future<void> cacheBeginnerCollections(List<Collection> collections) async {
    await cacheData<Collection>(
      _keyBeginnerCollections, 
      collections, 
      (collection) => collection.toJson(),
      expirationMinutes: _collectionExpirationMinutes
    );
  }

  // Get cached beginner collections
  Future<List<Collection>?> getCachedBeginnerCollections() async {
    return await getCachedData<Collection>(
      _keyBeginnerCollections,
      (json) => Collection.fromJson(json),
      expirationMinutes: _collectionExpirationMinutes
    );
  }

  // Cache trending songs
  Future<void> cacheTrendingSongs(List<Song> songs) async {
    await cacheData<Song>(
      _keyTrendingSongs, 
      songs, 
      (song) => song.toJson(),
      expirationMinutes: _trendingExpirationMinutes
    );
  }

  // Get cached trending songs
  Future<List<Song>?> getCachedTrendingSongs() async {
    return await getCachedData<Song>(
      _keyTrendingSongs,
      (json) => Song.fromJson(json),
      expirationMinutes: _trendingExpirationMinutes
    );
  }

  // Cache top artists
  Future<void> cacheTopArtists(List<Artist> artists) async {
    await cacheData<Artist>(
      _keyTopArtists, 
      artists, 
      (artist) => artist.toJson(),
      expirationMinutes: _trendingExpirationMinutes
    );
  }

  // Get cached top artists
  Future<List<Artist>?> getCachedTopArtists() async {
    return await getCachedData<Artist>(
      _keyTopArtists,
      (json) => Artist.fromJson(json),
      expirationMinutes: _trendingExpirationMinutes
    );
  }

  // Cache new songs
  Future<void> cacheNewSongs(List<Song> songs) async {
    await cacheData<Song>(
      _keyNewSongs, 
      songs, 
      (song) => song.toJson(),
      expirationMinutes: _trendingExpirationMinutes
    );
  }

  // Get cached new songs
  Future<List<Song>?> getCachedNewSongs() async {
    return await getCachedData<Song>(
      _keyNewSongs,
      (json) => Song.fromJson(json),
      expirationMinutes: _trendingExpirationMinutes
    );
  }
}
