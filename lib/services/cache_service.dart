import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';
import '../models/setlist.dart';


/// A service for caching data to reduce API calls and improve app performance
class CacheService {
  static final CacheService _instance = CacheService._internal();

  // Secure storage for sensitive cache data
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // In-memory cache for faster access during app session
  final Map<String, dynamic> _memoryCache = {};

  // Cache expiration times (in minutes) - Standardized for consistency
  static const int _defaultExpirationMinutes = 60; // Standardized to 1 hour
  static const int _songExpirationMinutes = 60; // Standardized to 1 hour
  static const int _artistExpirationMinutes = 60; // Standardized to 1 hour

  // Cache keys
  static const String _keySongs = 'cache_songs';
  static const String _keyArtists = 'cache_artists';
  static const String _keySeasonalCollections = 'cache_seasonal_collections';
  static const String _keyBeginnerCollections = 'cache_beginner_collections';
  static const String _keyTrendingSongs = 'cache_trending_songs';
  static const String _keyTopArtists = 'cache_top_artists';
  static const String _keyNewSongs = 'cache_new_songs';
  static const String _keyHomeSections = 'cache_home_sections';
  static const String _keyBannerImages = 'cache_banner_images';
  static const String _keySetlists = 'cache_setlists';
  static const String _keyLikedSongs = 'cache_liked_songs';

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

  /// Check if cache should be used based on session state
  bool shouldUseCacheForSession() {
    try {
      // Always use cache for better performance, only refresh on new sessions
      // Session-based refresh is handled by SessionManager in other services
      return true;
    } catch (e) {
      debugPrint('Error checking session state: $e');
      return true; // Default to using cache
    }
  }

  /// Clear all cached data - ONLY for logout or critical situations
  Future<void> clearAllCache() async {
    debugPrint('⚠️ CRITICAL: Clearing all cached data - this should be rare...');
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
    await prefs.remove(_keyHomeSections);
    await prefs.remove(_keyBannerImages);
    await prefs.remove(_keySetlists);
    await prefs.remove(_keyLikedSongs);

    // Clear secure storage cache
    await _secureStorage.delete(key: 'setlists_cache');
    await _secureStorage.delete(key: 'shared_setlists_cache');

    // Clear individual setlist caches
    final keys = await _secureStorage.readAll();
    for (final key in keys.keys) {
      if (key.startsWith('setlist_') || key.contains('cache')) {
        await _secureStorage.delete(key: key);
      }
    }

    debugPrint('⚠️ All cached data cleared - user may experience slower performance');
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
          final songs = songsJson.map((json) => Song.fromJson(json as Map<String, dynamic>)).toList();
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
          final songs = songsJson.map((json) => Song.fromJson(json as Map<String, dynamic>)).toList();

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
          final artists = artistsJson.map((json) => Artist.fromJson(json as Map<String, dynamic>)).toList();
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
          final artists = artistsJson.map((json) => Artist.fromJson(json as Map<String, dynamic>)).toList();

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
          final collections = collectionsJson.map((json) => Collection.fromJson(json as Map<String, dynamic>)).toList();
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
          final collections = collectionsJson.map((json) => Collection.fromJson(json as Map<String, dynamic>)).toList();

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
          final collections = collectionsJson.map((json) => Collection.fromJson(json as Map<String, dynamic>)).toList();
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
          final collections = collectionsJson.map((json) => Collection.fromJson(json as Map<String, dynamic>)).toList();

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
          final songs = songsJson.map((json) => Song.fromJson(json as Map<String, dynamic>)).toList();
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
          final songs = songsJson.map((json) => Song.fromJson(json as Map<String, dynamic>)).toList();

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
          final artists = artistsJson.map((json) => Artist.fromJson(json as Map<String, dynamic>)).toList();
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
          final artists = artistsJson.map((json) => Artist.fromJson(json as Map<String, dynamic>)).toList();

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
          final songs = songsJson.map((json) => Song.fromJson(json as Map<String, dynamic>)).toList();
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
          final songs = songsJson.map((json) => Song.fromJson(json as Map<String, dynamic>)).toList();

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

  /// Cache home sections
  Future<void> cacheHomeSections(List<dynamic> sections) async {
    try {
      // Convert sections to JSON
      final sectionsJson = sections.map((section) => {
        'id': section.id,
        'title': section.title,
        'type': section.type.toString().split('.').last,
        'items': _serializeItems(section.type, section.items as List<dynamic>),
      }).toList();

      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': sectionsJson,
      };

      // Save to memory cache
      _memoryCache[_keyHomeSections] = cacheData;

      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyHomeSections, json.encode(cacheData));

      debugPrint('Cached ${sections.length} home sections');
    } catch (e) {
      debugPrint('Error caching home sections: $e');
    }
  }

  // Helper method to serialize different types of items
  List<Map<String, dynamic>> _serializeItems(dynamic sectionType, List<dynamic> items) {
    if (items.isEmpty) return [];

    if (sectionType.toString().contains('COLLECTIONS')) {
      return items.map((item) => (item as Collection).toJson()).toList();
    } else if (sectionType.toString().contains('SONGS')) {
      return items.map((item) => (item as Song).toJson()).toList();
    } else if (sectionType.toString().contains('ARTISTS')) {
      return items.map((item) => (item as Artist).toJson()).toList();
    } else {
      // For banner items or other types, just return the raw items
      return items.map((item) => item as Map<String, dynamic>).toList();
    }
  }

  /// Get cached home sections
  Future<List<dynamic>?> getCachedHomeSections() async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(_keyHomeSections)) {
        final cacheMap = _memoryCache[_keyHomeSections] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);

        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final sectionsJson = cacheMap['data'] as List;
          // We'll parse the sections in the HomeSectionService
          debugPrint('Retrieved ${sectionsJson.length} home sections from memory cache');
          return sectionsJson.cast<Map<String, dynamic>>();
        }
      }

      // If not in memory or expired, check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyHomeSections);

      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);

        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final sectionsJson = cacheMap['data'] as List;
          // We'll parse the sections in the HomeSectionService

          // Update memory cache
          _memoryCache[_keyHomeSections] = cacheMap;

          debugPrint('Retrieved ${sectionsJson.length} home sections from persistent cache');
          return sectionsJson.cast<Map<String, dynamic>>();
        }
      }

      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('Error getting cached home sections: $e');
      return null;
    }
  }

  /// Check if a cache is stale based on its key and a maximum age in minutes
  /// Returns true if the cache is stale or doesn't exist, false if it's still fresh
  Future<bool> isCacheStale(String cacheKey, int maxAgeMinutes) async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(cacheKey)) {
        final cacheMap = _memoryCache[cacheKey] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final maxAge = maxAgeMinutes * 60 * 1000; // Convert to milliseconds
        final now = DateTime.now().millisecondsSinceEpoch;

        // Check if memory cache is still fresh
        if (now - timestamp < maxAge) {
          debugPrint('Cache for $cacheKey is still fresh (in memory)');
          return false;
        }
      }

      // If not in memory or stale, check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final maxAge = maxAgeMinutes * 60 * 1000; // Convert to milliseconds
        final now = DateTime.now().millisecondsSinceEpoch;

        // Check if persistent cache is still fresh
        if (now - timestamp < maxAge) {
          debugPrint('Cache for $cacheKey is still fresh (in persistent storage)');
          return false;
        }
      }

      // Cache is stale or doesn't exist
      debugPrint('Cache for $cacheKey is stale or doesn\'t exist');
      return true;
    } catch (e) {
      debugPrint('Error checking if cache is stale: $e');
      // If there's an error, assume cache is stale to force a refresh
      return true;
    }
  }

  /// Cache banner image metadata (URLs and timestamps)
  Future<void> cacheBannerImages(List<String> imageUrls) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': imageUrls,
      };

      // Save to memory cache
      _memoryCache[_keyBannerImages] = cacheData;

      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBannerImages, json.encode(cacheData));

      debugPrint('Cached ${imageUrls.length} banner image URLs');
    } catch (e) {
      debugPrint('Error caching banner images: $e');
    }
  }

  /// Get cached banner image URLs
  Future<List<String>?> getCachedBannerImages() async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(_keyBannerImages)) {
        final cacheMap = _memoryCache[_keyBannerImages] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);

        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final imageUrls = (cacheMap['data'] as List).cast<String>();
          debugPrint('Retrieved ${imageUrls.length} banner image URLs from memory cache');
          return imageUrls;
        }
      }

      // If not in memory or expired, check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyBannerImages);

      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);

        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final imageUrls = (cacheMap['data'] as List).cast<String>();

          // Update memory cache
          _memoryCache[_keyBannerImages] = cacheMap;

          debugPrint('Retrieved ${imageUrls.length} banner image URLs from persistent cache');
          return imageUrls;
        }
      }

      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('Error getting cached banner images: $e');
      return null;
    }
  }

  /// Check if banner images have changed by comparing URLs
  Future<bool> haveBannerImagesChanged(List<String> newImageUrls) async {
    try {
      final cachedUrls = await getCachedBannerImages();

      if (cachedUrls == null) {
        // No cache exists, so images have "changed"
        return true;
      }

      // Compare the lists
      if (cachedUrls.length != newImageUrls.length) {
        return true;
      }

      // Check if all URLs match
      for (int i = 0; i < cachedUrls.length; i++) {
        if (cachedUrls[i] != newImageUrls[i]) {
          return true;
        }
      }

      // All URLs match
      return false;
    } catch (e) {
      debugPrint('Error checking if banner images changed: $e');
      // If there's an error, assume they've changed to force a refresh
      return true;
    }
  }

  /// Generic method to cache any string data with a key
  Future<void> set(String key, String data) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };

      // Save to memory cache
      _memoryCache[key] = cacheData;

      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(cacheData));

      debugPrint('Cached data for key: $key');
    } catch (e) {
      debugPrint('Error caching data for key $key: $e');
    }
  }

  /// Generic method to get cached string data by key
  Future<String?> get(String key, {int expirationMinutes = 30}) async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(key)) {
        final cacheMap = _memoryCache[key] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (expirationMinutes * 60 * 1000);

        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final data = cacheMap['data'] as String;
          debugPrint('Retrieved data for key $key from memory cache');
          return data;
        }
      }

      // If not in memory or expired, check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(key);

      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (expirationMinutes * 60 * 1000);

        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final data = cacheMap['data'] as String;

          // Update memory cache
          _memoryCache[key] = cacheMap;

          debugPrint('Retrieved data for key $key from persistent cache');
          return data;
        }
      }

      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('Error getting cached data for key $key: $e');
      return null;
    }
  }

  /// Remove cached data by key
  Future<void> remove(String key) async {
    try {
      // Remove from memory cache
      _memoryCache.remove(key);

      // Remove from persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);

      debugPrint('Removed cached data for key: $key');
    } catch (e) {
      debugPrint('Error removing cached data for key $key: $e');
    }
  }

  // ==================== SETLIST CACHING METHODS ====================

  /// Cache setlists
  Future<void> cacheSetlists(List<Setlist> setlists) async {
    try {
      final setlistsJson = setlists.map((setlist) => setlist.toJson()).toList();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': setlistsJson,
      };

      // Save to memory cache
      _memoryCache[_keySetlists] = cacheData;

      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySetlists, json.encode(cacheData));

      debugPrint('💾 Cached ${setlists.length} setlists');
    } catch (e) {
      debugPrint('❌ Error caching setlists: $e');
    }
  }

  /// Get cached setlists
  Future<List<Setlist>?> getCachedSetlists() async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(_keySetlists)) {
        final cacheMap = _memoryCache[_keySetlists] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);

        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final setlistsJson = cacheMap['data'] as List;
          final setlists = setlistsJson.map((json) => Setlist.fromJson(json as Map<String, dynamic>)).toList();
          debugPrint('📦 Retrieved ${setlists.length} setlists from memory cache');
          return setlists;
        }
      }

      // Check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keySetlists);

      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);

        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final setlistsJson = cacheMap['data'] as List;
          final setlists = setlistsJson.map((json) => Setlist.fromJson(json as Map<String, dynamic>)).toList();

          // Update memory cache
          _memoryCache[_keySetlists] = cacheMap;

          debugPrint('📦 Retrieved ${setlists.length} setlists from persistent cache');
          return setlists;
        }
      }

      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('❌ Error getting cached setlists: $e');
      return null;
    }
  }

  /// Cache liked songs
  Future<void> cacheLikedSongs(List<Song> likedSongs) async {
    try {
      final likedSongsJson = likedSongs.map((song) => song.toJson()).toList();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': likedSongsJson,
      };

      // Save to memory cache
      _memoryCache[_keyLikedSongs] = cacheData;

      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLikedSongs, json.encode(cacheData));

      debugPrint('💾 Cached ${likedSongs.length} liked songs');
    } catch (e) {
      debugPrint('❌ Error caching liked songs: $e');
    }
  }

  /// Get cached liked songs
  Future<List<Song>?> getCachedLikedSongs() async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(_keyLikedSongs)) {
        final cacheMap = _memoryCache[_keyLikedSongs] as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);

        // Check if memory cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final likedSongsJson = cacheMap['data'] as List;
          final likedSongs = likedSongsJson.map((json) => Song.fromJson(json as Map<String, dynamic>)).toList();
          debugPrint('📦 Retrieved ${likedSongs.length} liked songs from memory cache');
          return likedSongs;
        }
      }

      // Check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyLikedSongs);

      if (cachedData != null) {
        final cacheMap = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final expirationTime = timestamp + (_defaultExpirationMinutes * 60 * 1000);

        // Check if persistent cache is still valid
        if (DateTime.now().millisecondsSinceEpoch < expirationTime) {
          final likedSongsJson = cacheMap['data'] as List;
          final likedSongs = likedSongsJson.map((json) => Song.fromJson(json as Map<String, dynamic>)).toList();

          // Update memory cache
          _memoryCache[_keyLikedSongs] = cacheMap;

          debugPrint('📦 Retrieved ${likedSongs.length} liked songs from persistent cache');
          return likedSongs;
        }
      }

      // No valid cache found
      return null;
    } catch (e) {
      debugPrint('❌ Error getting cached liked songs: $e');
      return null;
    }
  }

  /// Clear all setlist-related cache (for CRUD operations)
  Future<void> clearSetlistCache() async {
    try {
      debugPrint('🗑️ Clearing all setlist cache...');

      // Remove from memory cache
      _memoryCache.remove(_keySetlists);

      // Remove from persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySetlists);

      // Clear any secure storage setlist caches
      await _secureStorage.delete(key: 'setlists_cache');
      await _secureStorage.delete(key: 'shared_setlists_cache');

      // Clear individual setlist caches
      final keys = await _secureStorage.readAll();
      for (final key in keys.keys) {
        if (key.startsWith('setlist_')) {
          await _secureStorage.delete(key: key);
        }
      }

      debugPrint('✅ All setlist cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing setlist cache: $e');
    }
  }
}
