import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';

/// A service for caching data to reduce API calls and improve app performance
class CacheService {
  static final CacheService _instance = CacheService._internal();
  // Removed unused _secureStorage field
  
  // In-memory cache for faster access during app session
  final Map<String, dynamic> _memoryCache = {};
  
  // Cache expiration times (in minutes)
  static const int _defaultExpirationMinutes = 30;
  static const int _songExpirationMinutes = 60; // Songs change less frequently
  static const int _artistExpirationMinutes = 120; // Artists change even less frequently
  
  // Cache keys
  static const String _keySongs = 'cache_songs';
  static const String _keyArtists = 'cache_artists';
  static const String _keySeasonalCollections = 'cache_seasonal_collections';
  static const String _keyBeginnerCollections = 'cache_beginner_collections';
  static const String _keyTrendingSongs = 'cache_trending_songs';
  static const String _keyTopArtists = 'cache_top_artists';
  static const String _keyNewSongs = 'cache_new_songs';
  
  // Factory constructor
  factory CacheService() {
    return _instance;
  }
  
  // Private constructor
  CacheService._internal();
  
  /// Initialize the cache service
  Future<void> initialize() async {
    debugPrint('Initializing cache service...');
    // Load cached data into memory for faster access
    await _loadCachedSongs();
    await _loadCachedArtists();
    await _loadCachedCollections();
    debugPrint('Cache service initialized');
  }
  
  /// Clear all cached data
  Future<void> clearAllCache() async {
    debugPrint('Clearing all cached data...');
    // Clear memory cache
    _memoryCache.clear();
    
    // Clear persistent cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySongs);
    await prefs.remove(_keyArtists);
    await prefs.remove(_keySeasonalCollections);
    await prefs.remove(_keyBeginnerCollections);
    await prefs.remove(_keyTrendingSongs);
    await prefs.remove(_keyTopArtists);
    await prefs.remove(_keyNewSongs);
    
    debugPrint('All cached data cleared');
  }
  
  /// Load cached songs into memory
  Future<void> _loadCachedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keySongs);
      
      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_songExpirationMinutes * 60 * 1000);
        
        // Check if cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          _memoryCache[_keySongs] = cacheMap;
          debugPrint('Loaded ${(cacheMap['data'] as List).length} songs from cache');
        } else {
          debugPrint('Song cache expired, will fetch fresh data');
        }
      }
    } catch (e) {
      debugPrint('Error loading cached songs: $e');
    }
  }
  
  /// Load cached artists into memory
  Future<void> _loadCachedArtists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyArtists);
      
      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_artistExpirationMinutes * 60 * 1000);
        
        // Check if cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          _memoryCache[_keyArtists] = cacheMap;
          debugPrint('Loaded ${(cacheMap['data'] as List).length} artists from cache');
        } else {
          debugPrint('Artist cache expired, will fetch fresh data');
        }
      }
    } catch (e) {
      debugPrint('Error loading cached artists: $e');
    }
  }
  
  /// Load cached collections into memory
  Future<void> _loadCachedCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load seasonal collections
      final cachedSeasonalData = prefs.getString(_keySeasonalCollections);
      if (cachedSeasonalData != null) {
        final cacheMap = json.decode(cachedSeasonalData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);
        
        // Check if cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          _memoryCache[_keySeasonalCollections] = cacheMap;
          debugPrint('Loaded ${(cacheMap['data'] as List).length} seasonal collections from cache');
        }
      }
      
      // Load beginner collections
      final cachedBeginnerData = prefs.getString(_keyBeginnerCollections);
      if (cachedBeginnerData != null) {
        final cacheMap = json.decode(cachedBeginnerData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);
        
        // Check if cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          _memoryCache[_keyBeginnerCollections] = cacheMap;
          debugPrint('Loaded ${(cacheMap['data'] as List).length} beginner collections from cache');
        }
      }
    } catch (e) {
      debugPrint('Error loading cached collections: $e');
    }
  }
  
  /// Cache songs data
  Future<void> cacheSongs(List<Song> songs) async {
    try {
      final songsJson = songs.map((song) => song.toJson()).toList();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': songsJson,
      };
      
      // Save to memory cache
      _memoryCache[_keySongs] = cacheData;
      
      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySongs, json.encode(cacheData));
      
      debugPrint('Cached ${songs.length} songs');
    } catch (e) {
      debugPrint('Error caching songs: $e');
    }
  }
  
  /// Get cached songs
  Future<List<Song>?> getCachedSongs() async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(_keySongs)) {
        final cacheMap = _memoryCache[_keySongs] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_songExpirationMinutes * 60 * 1000);
        
        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final songsJson = cacheMap['data'] as List;
          final songs = songsJson.map((json) => Song.fromJson(json)).toList();
          debugPrint('Retrieved ${songs.length} songs from memory cache');
          return songs;
        }
      }
      
      // If not in memory or expired, check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keySongs);
      
      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_songExpirationMinutes * 60 * 1000);
        
        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final songsJson = cacheMap['data'] as List;
          final songs = songsJson.map((json) => Song.fromJson(json)).toList();
          
          // Update memory cache
          _memoryCache[_keySongs] = cacheMap;
          
          debugPrint('Retrieved ${songs.length} songs from persistent cache');
          return songs;
        }
      }
      
      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('Error getting cached songs: $e');
      return null;
    }
  }
  
  /// Cache artists data
  Future<void> cacheArtists(List<Artist> artists) async {
    try {
      final artistsJson = artists.map((artist) => artist.toJson()).toList();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': artistsJson,
      };
      
      // Save to memory cache
      _memoryCache[_keyArtists] = cacheData;
      
      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyArtists, json.encode(cacheData));
      
      debugPrint('Cached ${artists.length} artists');
    } catch (e) {
      debugPrint('Error caching artists: $e');
    }
  }
  
  /// Get cached artists
  Future<List<Artist>?> getCachedArtists() async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(_keyArtists)) {
        final cacheMap = _memoryCache[_keyArtists] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_artistExpirationMinutes * 60 * 1000);
        
        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final artistsJson = cacheMap['data'] as List;
          final artists = artistsJson.map((json) => Artist.fromJson(json)).toList();
          debugPrint('Retrieved ${artists.length} artists from memory cache');
          return artists;
        }
      }
      
      // If not in memory or expired, check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyArtists);
      
      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_artistExpirationMinutes * 60 * 1000);
        
        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final artistsJson = cacheMap['data'] as List;
          final artists = artistsJson.map((json) => Artist.fromJson(json)).toList();
          
          // Update memory cache
          _memoryCache[_keyArtists] = cacheMap;
          
          debugPrint('Retrieved ${artists.length} artists from persistent cache');
          return artists;
        }
      }
      
      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('Error getting cached artists: $e');
      return null;
    }
  }
  
  /// Cache seasonal collections
  Future<void> cacheSeasonalCollections(List<Collection> collections) async {
    try {
      final collectionsJson = collections.map((collection) => collection.toJson()).toList();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': collectionsJson,
      };
      
      // Save to memory cache
      _memoryCache[_keySeasonalCollections] = cacheData;
      
      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySeasonalCollections, json.encode(cacheData));
      
      debugPrint('Cached ${collections.length} seasonal collections');
    } catch (e) {
      debugPrint('Error caching seasonal collections: $e');
    }
  }
  
  /// Get cached seasonal collections
  Future<List<Collection>?> getCachedSeasonalCollections() async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(_keySeasonalCollections)) {
        final cacheMap = _memoryCache[_keySeasonalCollections] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);
        
        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final collectionsJson = cacheMap['data'] as List;
          final collections = collectionsJson.map((json) => Collection.fromJson(json)).toList();
          debugPrint('Retrieved ${collections.length} seasonal collections from memory cache');
          return collections;
        }
      }
      
      // If not in memory or expired, check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keySeasonalCollections);
      
      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);
        
        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final collectionsJson = cacheMap['data'] as List;
          final collections = collectionsJson.map((json) => Collection.fromJson(json)).toList();
          
          // Update memory cache
          _memoryCache[_keySeasonalCollections] = cacheMap;
          
          debugPrint('Retrieved ${collections.length} seasonal collections from persistent cache');
          return collections;
        }
      }
      
      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('Error getting cached seasonal collections: $e');
      return null;
    }
  }
  
  /// Cache beginner friendly collections
  Future<void> cacheBeginnerCollections(List<Collection> collections) async {
    try {
      final collectionsJson = collections.map((collection) => collection.toJson()).toList();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': collectionsJson,
      };
      
      // Save to memory cache
      _memoryCache[_keyBeginnerCollections] = cacheData;
      
      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBeginnerCollections, json.encode(cacheData));
      
      debugPrint('Cached ${collections.length} beginner collections');
    } catch (e) {
      debugPrint('Error caching beginner collections: $e');
    }
  }
  
  /// Get cached beginner friendly collections
  Future<List<Collection>?> getCachedBeginnerCollections() async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(_keyBeginnerCollections)) {
        final cacheMap = _memoryCache[_keyBeginnerCollections] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);
        
        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final collectionsJson = cacheMap['data'] as List;
          final collections = collectionsJson.map((json) => Collection.fromJson(json)).toList();
          debugPrint('Retrieved ${collections.length} beginner collections from memory cache');
          return collections;
        }
      }
      
      // If not in memory or expired, check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyBeginnerCollections);
      
      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);
        
        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final collectionsJson = cacheMap['data'] as List;
          final collections = collectionsJson.map((json) => Collection.fromJson(json)).toList();
          
          // Update memory cache
          _memoryCache[_keyBeginnerCollections] = cacheMap;
          
          debugPrint('Retrieved ${collections.length} beginner collections from persistent cache');
          return collections;
        }
      }
      
      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('Error getting cached beginner collections: $e');
      return null;
    }
  }
  
  /// Cache trending songs
  Future<void> cacheTrendingSongs(List<Song> songs) async {
    try {
      final songsJson = songs.map((song) => song.toJson()).toList();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': songsJson,
      };
      
      // Save to memory cache
      _memoryCache[_keyTrendingSongs] = cacheData;
      
      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTrendingSongs, json.encode(cacheData));
      
      debugPrint('Cached ${songs.length} trending songs');
    } catch (e) {
      debugPrint('Error caching trending songs: $e');
    }
  }
  
  /// Get cached trending songs
  Future<List<Song>?> getCachedTrendingSongs() async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(_keyTrendingSongs)) {
        final cacheMap = _memoryCache[_keyTrendingSongs] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);
        
        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final songsJson = cacheMap['data'] as List;
          final songs = songsJson.map((json) => Song.fromJson(json)).toList();
          debugPrint('Retrieved ${songs.length} trending songs from memory cache');
          return songs;
        }
      }
      
      // If not in memory or expired, check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyTrendingSongs);
      
      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);
        
        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final songsJson = cacheMap['data'] as List;
          final songs = songsJson.map((json) => Song.fromJson(json)).toList();
          
          // Update memory cache
          _memoryCache[_keyTrendingSongs] = cacheMap;
          
          debugPrint('Retrieved ${songs.length} trending songs from persistent cache');
          return songs;
        }
      }
      
      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('Error getting cached trending songs: $e');
      return null;
    }
  }
  
  /// Cache top artists
  Future<void> cacheTopArtists(List<Artist> artists) async {
    try {
      final artistsJson = artists.map((artist) => artist.toJson()).toList();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': artistsJson,
      };
      
      // Save to memory cache
      _memoryCache[_keyTopArtists] = cacheData;
      
      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTopArtists, json.encode(cacheData));
      
      debugPrint('Cached ${artists.length} top artists');
    } catch (e) {
      debugPrint('Error caching top artists: $e');
    }
  }
  
  /// Get cached top artists
  Future<List<Artist>?> getCachedTopArtists() async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(_keyTopArtists)) {
        final cacheMap = _memoryCache[_keyTopArtists] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);
        
        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final artistsJson = cacheMap['data'] as List;
          final artists = artistsJson.map((json) => Artist.fromJson(json)).toList();
          debugPrint('Retrieved ${artists.length} top artists from memory cache');
          return artists;
        }
      }
      
      // If not in memory or expired, check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyTopArtists);
      
      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);
        
        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final artistsJson = cacheMap['data'] as List;
          final artists = artistsJson.map((json) => Artist.fromJson(json)).toList();
          
          // Update memory cache
          _memoryCache[_keyTopArtists] = cacheMap;
          
          debugPrint('Retrieved ${artists.length} top artists from persistent cache');
          return artists;
        }
      }
      
      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('Error getting cached top artists: $e');
      return null;
    }
  }
  
  /// Cache new songs
  Future<void> cacheNewSongs(List<Song> songs) async {
    try {
      final songsJson = songs.map((song) => song.toJson()).toList();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': songsJson,
      };
      
      // Save to memory cache
      _memoryCache[_keyNewSongs] = cacheData;
      
      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNewSongs, json.encode(cacheData));
      
      debugPrint('Cached ${songs.length} new songs');
    } catch (e) {
      debugPrint('Error caching new songs: $e');
    }
  }
  
  /// Get cached new songs
  Future<List<Song>?> getCachedNewSongs() async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(_keyNewSongs)) {
        final cacheMap = _memoryCache[_keyNewSongs] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);
        
        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final songsJson = cacheMap['data'] as List;
          final songs = songsJson.map((json) => Song.fromJson(json)).toList();
          debugPrint('Retrieved ${songs.length} new songs from memory cache');
          return songs;
        }
      }
      
      // If not in memory or expired, check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyNewSongs);
      
      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);
        
        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final songsJson = cacheMap['data'] as List;
          final songs = songsJson.map((json) => Song.fromJson(json)).toList();
          
          // Update memory cache
          _memoryCache[_keyNewSongs] = cacheMap;
          
          debugPrint('Retrieved ${songs.length} new songs from persistent cache');
          return songs;
        }
      }
      
      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('Error getting cached new songs: $e');
      return null;
    }
  }
}
