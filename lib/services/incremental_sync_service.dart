import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';
import '../models/setlist.dart';
import '../services/home_section_service.dart';
import 'api_service.dart';

/// Comprehensive offline-first incremental sync service
/// Stores all data permanently and only syncs changes
class IncrementalSyncService {
  static final IncrementalSyncService _instance = IncrementalSyncService._internal();
  factory IncrementalSyncService() => _instance;
  IncrementalSyncService._internal();

  final ApiService _apiService = ApiService();
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Cache keys for different data types
  static const String _homeSectionsKey = 'cached_home_sections_v2';
  static const String _songsKey = 'cached_songs_v2';
  static const String _artistsKey = 'cached_artists_v2';
  static const String _collectionsKey = 'cached_collections_v2';
  static const String _setlistsKey = 'cached_setlists_v2';
  
  // Last sync timestamp keys
  static const String _lastSyncHomeSections = 'last_sync_home_sections';
  static const String _lastSyncSongs = 'last_sync_songs';
  static const String _lastSyncArtists = 'last_sync_artists';
  static const String _lastSyncCollections = 'last_sync_collections';
  static const String _lastSyncSetlists = 'last_sync_setlists';

  // App version for cache invalidation
  static const String _cacheVersionKey = 'cache_version';
  static const String _currentCacheVersion = '2.0.0';

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _checkCacheVersion();
    _isInitialized = true;

    debugPrint('🔄 Incremental sync service initialized');
  }

  /// Check if cache version is current, clear if outdated
  Future<void> _checkCacheVersion() async {
    final cachedVersion = _prefs?.getString(_cacheVersionKey);
    if (cachedVersion != _currentCacheVersion) {
      debugPrint('🗑️ Cache version outdated, clearing all cache');
      await clearAllCache();
      await _prefs?.setString(_cacheVersionKey, _currentCacheVersion);
    }
  }

  /// Check if device is online
  Future<bool> get isOnline async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  /// Get home sections with incremental sync
  Future<List<HomeSection>> getHomeSections({bool forceRefresh = false}) async {
    await _ensureInitialized();

    // Always try to return cached data first
    final cachedSections = await _getCachedHomeSections();
    
    if (!forceRefresh && cachedSections.isNotEmpty) {
      debugPrint('📱 Returning ${cachedSections.length} cached home sections');
      
      // Check for updates in background if online
      if (await isOnline) {
        _syncHomeSectionsInBackground();
      }
      
      return cachedSections;
    }

    // If no cache or force refresh, sync from API
    return await _syncHomeSections();
  }

  /// Sync home sections from API
  Future<List<HomeSection>> _syncHomeSections() async {
    try {
      if (!await isOnline) {
        final cached = await _getCachedHomeSections();
        debugPrint('📱 Offline: returning ${cached.length} cached home sections');
        return cached;
      }

      final lastSync = _prefs?.getString(_lastSyncHomeSections);
      final endpoint = lastSync != null 
          ? '/home-sections/app/content?since=$lastSync'
          : '/home-sections/app/content';

      debugPrint('🔄 Syncing home sections from: $endpoint');
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> sectionsJson = response.data;
        final sections = sectionsJson.map((json) => HomeSection.fromJson(json)).toList();

        // Cache the sections
        await _cacheHomeSections(sections);
        await _prefs?.setString(_lastSyncHomeSections, DateTime.now().toIso8601String());

        debugPrint('✅ Synced ${sections.length} home sections');
        return sections;
      } else {
        throw Exception('Failed to sync home sections: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error syncing home sections: $e');
      // Return cached data as fallback
      return await _getCachedHomeSections();
    }
  }

  /// Background sync for home sections
  void _syncHomeSectionsInBackground() {
    Timer(const Duration(seconds: 2), () async {
      try {
        await _syncHomeSections();
        debugPrint('🔄 Background sync completed for home sections');
      } catch (e) {
        debugPrint('❌ Background sync failed for home sections: $e');
      }
    });
  }

  /// Cache home sections
  Future<void> _cacheHomeSections(List<HomeSection> sections) async {
    try {
      final sectionsJson = sections.map((section) => section.toJson()).toList();
      await _prefs?.setString(_homeSectionsKey, json.encode(sectionsJson));
      debugPrint('💾 Cached ${sections.length} home sections');
    } catch (e) {
      debugPrint('❌ Error caching home sections: $e');
    }
  }

  /// Get cached home sections
  Future<List<HomeSection>> _getCachedHomeSections() async {
    try {
      final cachedData = _prefs?.getString(_homeSectionsKey);
      if (cachedData == null) return [];

      final List<dynamic> sectionsJson = json.decode(cachedData);
      return sectionsJson.map((json) => HomeSection.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error reading cached home sections: $e');
      return [];
    }
  }

  /// Get songs with incremental sync
  Future<List<Song>> getSongs({bool forceRefresh = false, int limit = 100}) async {
    await _ensureInitialized();

    final cachedSongs = await _getCachedSongs();
    
    if (!forceRefresh && cachedSongs.isNotEmpty) {
      debugPrint('📱 Returning ${cachedSongs.length} cached songs');
      
      if (await isOnline) {
        _syncSongsInBackground();
      }
      
      return cachedSongs.take(limit).toList();
    }

    return await _syncSongs(limit: limit);
  }

  /// Sync songs from API
  Future<List<Song>> _syncSongs({int limit = 100}) async {
    try {
      if (!await isOnline) {
        final cached = await _getCachedSongs();
        debugPrint('📱 Offline: returning ${cached.length} cached songs');
        return cached.take(limit).toList();
      }

      final lastSync = _prefs?.getString(_lastSyncSongs);
      final endpoint = lastSync != null 
          ? '/songs?since=$lastSync&limit=$limit'
          : '/songs?limit=$limit';

      debugPrint('🔄 Syncing songs from: $endpoint');
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> songsJson = response.data;
        final songs = songsJson.map((json) => Song.fromJson(json)).toList();

        // Merge with existing cache for incremental updates
        await _mergeCachedSongs(songs);
        await _prefs?.setString(_lastSyncSongs, DateTime.now().toIso8601String());

        final allCached = await _getCachedSongs();
        debugPrint('✅ Synced ${songs.length} songs, total cached: ${allCached.length}');
        return allCached.take(limit).toList();
      } else {
        throw Exception('Failed to sync songs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error syncing songs: $e');
      final cached = await _getCachedSongs();
      return cached.take(limit).toList();
    }
  }

  /// Background sync for songs
  void _syncSongsInBackground() {
    Timer(const Duration(seconds: 3), () async {
      try {
        await _syncSongs();
        debugPrint('🔄 Background sync completed for songs');
      } catch (e) {
        debugPrint('❌ Background sync failed for songs: $e');
      }
    });
  }

  /// Merge songs with existing cache (for incremental updates)
  Future<void> _mergeCachedSongs(List<Song> newSongs) async {
    try {
      final existingSongs = await _getCachedSongs();
      final Map<String, Song> songMap = {for (var song in existingSongs) song.id: song};

      // Update existing songs or add new ones
      for (var newSong in newSongs) {
        songMap[newSong.id] = newSong;
      }

      final mergedSongs = songMap.values.toList();
      await _cacheSongs(mergedSongs);
      debugPrint('🔄 Merged ${newSongs.length} songs with ${existingSongs.length} existing');
    } catch (e) {
      debugPrint('❌ Error merging songs: $e');
      // Fallback to replacing cache
      await _cacheSongs(newSongs);
    }
  }

  /// Cache songs
  Future<void> _cacheSongs(List<Song> songs) async {
    try {
      final songsJson = songs.map((song) => song.toJson()).toList();
      await _prefs?.setString(_songsKey, json.encode(songsJson));
      debugPrint('💾 Cached ${songs.length} songs');
    } catch (e) {
      debugPrint('❌ Error caching songs: $e');
    }
  }

  /// Get cached songs
  Future<List<Song>> _getCachedSongs() async {
    try {
      final cachedData = _prefs?.getString(_songsKey);
      if (cachedData == null) return [];

      final List<dynamic> songsJson = json.decode(cachedData);
      return songsJson.map((json) => Song.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error reading cached songs: $e');
      return [];
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await _prefs?.remove(_homeSectionsKey);
    await _prefs?.remove(_songsKey);
    await _prefs?.remove(_artistsKey);
    await _prefs?.remove(_collectionsKey);
    await _prefs?.remove(_setlistsKey);
    
    await _prefs?.remove(_lastSyncHomeSections);
    await _prefs?.remove(_lastSyncSongs);
    await _prefs?.remove(_lastSyncArtists);
    await _prefs?.remove(_lastSyncCollections);
    await _prefs?.remove(_lastSyncSetlists);
    
    debugPrint('🗑️ All cache cleared');
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get artists with incremental sync
  Future<List<Artist>> getArtists({bool forceRefresh = false, int limit = 50}) async {
    await _ensureInitialized();

    final cachedArtists = await _getCachedArtists();

    if (!forceRefresh && cachedArtists.isNotEmpty) {
      debugPrint('📱 Returning ${cachedArtists.length} cached artists');

      if (await isOnline) {
        _syncArtistsInBackground();
      }

      return cachedArtists.take(limit).toList();
    }

    return await _syncArtists(limit: limit);
  }

  /// Sync artists from API
  Future<List<Artist>> _syncArtists({int limit = 50}) async {
    try {
      if (!await isOnline) {
        final cached = await _getCachedArtists();
        debugPrint('📱 Offline: returning ${cached.length} cached artists');
        return cached.take(limit).toList();
      }

      final lastSync = _prefs?.getString(_lastSyncArtists);
      final endpoint = lastSync != null
          ? '/artists?since=$lastSync&limit=$limit'
          : '/artists?limit=$limit';

      debugPrint('🔄 Syncing artists from: $endpoint');
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> artistsJson = response.data;
        final artists = artistsJson.map((json) => Artist.fromJson(json)).toList();

        await _mergeCachedArtists(artists);
        await _prefs?.setString(_lastSyncArtists, DateTime.now().toIso8601String());

        final allCached = await _getCachedArtists();
        debugPrint('✅ Synced ${artists.length} artists, total cached: ${allCached.length}');
        return allCached.take(limit).toList();
      } else {
        throw Exception('Failed to sync artists: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error syncing artists: $e');
      final cached = await _getCachedArtists();
      return cached.take(limit).toList();
    }
  }

  /// Background sync for artists
  void _syncArtistsInBackground() {
    Timer(const Duration(seconds: 4), () async {
      try {
        await _syncArtists();
        debugPrint('🔄 Background sync completed for artists');
      } catch (e) {
        debugPrint('❌ Background sync failed for artists: $e');
      }
    });
  }

  /// Merge artists with existing cache
  Future<void> _mergeCachedArtists(List<Artist> newArtists) async {
    try {
      final existingArtists = await _getCachedArtists();
      final Map<String, Artist> artistMap = {for (var artist in existingArtists) artist.id: artist};

      for (var newArtist in newArtists) {
        artistMap[newArtist.id] = newArtist;
      }

      final mergedArtists = artistMap.values.toList();
      await _cacheArtists(mergedArtists);
      debugPrint('🔄 Merged ${newArtists.length} artists with ${existingArtists.length} existing');
    } catch (e) {
      debugPrint('❌ Error merging artists: $e');
      await _cacheArtists(newArtists);
    }
  }

  /// Cache artists
  Future<void> _cacheArtists(List<Artist> artists) async {
    try {
      final artistsJson = artists.map((artist) => artist.toJson()).toList();
      await _prefs?.setString(_artistsKey, json.encode(artistsJson));
      debugPrint('💾 Cached ${artists.length} artists');
    } catch (e) {
      debugPrint('❌ Error caching artists: $e');
    }
  }

  /// Get cached artists
  Future<List<Artist>> _getCachedArtists() async {
    try {
      final cachedData = _prefs?.getString(_artistsKey);
      if (cachedData == null) return [];

      final List<dynamic> artistsJson = json.decode(cachedData);
      return artistsJson.map((json) => Artist.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error reading cached artists: $e');
      return [];
    }
  }

  /// Get collections with incremental sync
  Future<List<Collection>> getCollections({bool forceRefresh = false, int limit = 30}) async {
    await _ensureInitialized();

    final cachedCollections = await _getCachedCollections();

    if (!forceRefresh && cachedCollections.isNotEmpty) {
      debugPrint('📱 Returning ${cachedCollections.length} cached collections');

      if (await isOnline) {
        _syncCollectionsInBackground();
      }

      return cachedCollections.take(limit).toList();
    }

    return await _syncCollections(limit: limit);
  }

  /// Sync collections from API
  Future<List<Collection>> _syncCollections({int limit = 30}) async {
    try {
      if (!await isOnline) {
        final cached = await _getCachedCollections();
        debugPrint('📱 Offline: returning ${cached.length} cached collections');
        return cached.take(limit).toList();
      }

      final lastSync = _prefs?.getString(_lastSyncCollections);
      final endpoint = lastSync != null
          ? '/collections?since=$lastSync&limit=$limit'
          : '/collections?limit=$limit';

      debugPrint('🔄 Syncing collections from: $endpoint');
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> collectionsJson = response.data;
        final collections = collectionsJson.map((json) => Collection.fromJson(json)).toList();

        await _mergeCachedCollections(collections);
        await _prefs?.setString(_lastSyncCollections, DateTime.now().toIso8601String());

        final allCached = await _getCachedCollections();
        debugPrint('✅ Synced ${collections.length} collections, total cached: ${allCached.length}');
        return allCached.take(limit).toList();
      } else {
        throw Exception('Failed to sync collections: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error syncing collections: $e');
      final cached = await _getCachedCollections();
      return cached.take(limit).toList();
    }
  }

  /// Background sync for collections
  void _syncCollectionsInBackground() {
    Timer(const Duration(seconds: 5), () async {
      try {
        await _syncCollections();
        debugPrint('🔄 Background sync completed for collections');
      } catch (e) {
        debugPrint('❌ Background sync failed for collections: $e');
      }
    });
  }

  /// Merge collections with existing cache
  Future<void> _mergeCachedCollections(List<Collection> newCollections) async {
    try {
      final existingCollections = await _getCachedCollections();
      final Map<String, Collection> collectionMap = {for (var collection in existingCollections) collection.id: collection};

      for (var newCollection in newCollections) {
        collectionMap[newCollection.id] = newCollection;
      }

      final mergedCollections = collectionMap.values.toList();
      await _cacheCollections(mergedCollections);
      debugPrint('🔄 Merged ${newCollections.length} collections with ${existingCollections.length} existing');
    } catch (e) {
      debugPrint('❌ Error merging collections: $e');
      await _cacheCollections(newCollections);
    }
  }

  /// Cache collections
  Future<void> _cacheCollections(List<Collection> collections) async {
    try {
      final collectionsJson = collections.map((collection) => collection.toJson()).toList();
      await _prefs?.setString(_collectionsKey, json.encode(collectionsJson));
      debugPrint('💾 Cached ${collections.length} collections');
    } catch (e) {
      debugPrint('❌ Error caching collections: $e');
    }
  }

  /// Get cached collections
  Future<List<Collection>> _getCachedCollections() async {
    try {
      final cachedData = _prefs?.getString(_collectionsKey);
      if (cachedData == null) return [];

      final List<dynamic> collectionsJson = json.decode(cachedData);
      return collectionsJson.map((json) => Collection.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error reading cached collections: $e');
      return [];
    }
  }

  /// Get setlists with incremental sync
  Future<List<Setlist>> getSetlists({bool forceRefresh = false, int limit = 50}) async {
    await _ensureInitialized();

    final cachedSetlists = await _getCachedSetlists();

    if (!forceRefresh && cachedSetlists.isNotEmpty) {
      debugPrint('📱 Returning ${cachedSetlists.length} cached setlists');

      if (await isOnline) {
        _syncSetlistsInBackground();
      }

      return cachedSetlists.take(limit).toList();
    }

    return await _syncSetlists(limit: limit);
  }

  /// Sync setlists from API
  Future<List<Setlist>> _syncSetlists({int limit = 50}) async {
    try {
      if (!await isOnline) {
        final cached = await _getCachedSetlists();
        debugPrint('📱 Offline: returning ${cached.length} cached setlists');
        return cached.take(limit).toList();
      }

      final lastSync = _prefs?.getString(_lastSyncSetlists);
      final endpoint = lastSync != null
          ? '/setlists?since=$lastSync&limit=$limit'
          : '/setlists?limit=$limit';

      debugPrint('🔄 Syncing setlists from: $endpoint');
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> setlistsJson = response.data;
        final setlists = setlistsJson.map((json) => Setlist.fromJson(json)).toList();

        await _mergeCachedSetlists(setlists);
        await _prefs?.setString(_lastSyncSetlists, DateTime.now().toIso8601String());

        final allCached = await _getCachedSetlists();
        debugPrint('✅ Synced ${setlists.length} setlists, total cached: ${allCached.length}');
        return allCached.take(limit).toList();
      } else {
        throw Exception('Failed to sync setlists: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error syncing setlists: $e');
      final cached = await _getCachedSetlists();
      return cached.take(limit).toList();
    }
  }

  /// Background sync for setlists
  void _syncSetlistsInBackground() {
    Timer(const Duration(seconds: 6), () async {
      try {
        await _syncSetlists();
        debugPrint('🔄 Background sync completed for setlists');
      } catch (e) {
        debugPrint('❌ Background sync failed for setlists: $e');
      }
    });
  }

  /// Merge setlists with existing cache
  Future<void> _mergeCachedSetlists(List<Setlist> newSetlists) async {
    try {
      final existingSetlists = await _getCachedSetlists();
      final Map<String, Setlist> setlistMap = {for (var setlist in existingSetlists) setlist.id: setlist};

      for (var newSetlist in newSetlists) {
        setlistMap[newSetlist.id] = newSetlist;
      }

      final mergedSetlists = setlistMap.values.toList();
      await _cacheSetlists(mergedSetlists);
      debugPrint('🔄 Merged ${newSetlists.length} setlists with ${existingSetlists.length} existing');
    } catch (e) {
      debugPrint('❌ Error merging setlists: $e');
      await _cacheSetlists(newSetlists);
    }
  }

  /// Cache setlists
  Future<void> _cacheSetlists(List<Setlist> setlists) async {
    try {
      final setlistsJson = setlists.map((setlist) => setlist.toJson()).toList();
      await _prefs?.setString(_setlistsKey, json.encode(setlistsJson));
      debugPrint('💾 Cached ${setlists.length} setlists');
    } catch (e) {
      debugPrint('❌ Error caching setlists: $e');
    }
  }

  /// Clear setlist cache to force refresh
  Future<void> clearSetlistCache([String? specificSetlistId]) async {
    try {
      if (specificSetlistId != null) {
        // Clear specific setlist from cache
        debugPrint('🗑️ Clearing cache for specific setlist: $specificSetlistId');
        final cachedSetlists = await _getCachedSetlists();
        final updatedSetlists = cachedSetlists.where((s) => s.id != specificSetlistId).toList();
        await _cacheSetlists(updatedSetlists);
        debugPrint('✅ Removed setlist $specificSetlistId from cache');
      } else {
        // Clear all setlists cache
        await _prefs?.remove(_setlistsKey);
        debugPrint('🗑️ Cleared all setlist cache');
      }
    } catch (e) {
      debugPrint('❌ Error clearing setlist cache: $e');
    }
  }

  /// Get cached setlists
  Future<List<Setlist>> _getCachedSetlists() async {
    try {
      final cachedData = _prefs?.getString(_setlistsKey);
      if (cachedData == null) return [];

      final List<dynamic> setlistsJson = json.decode(cachedData);
      return setlistsJson.map((json) => Setlist.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error reading cached setlists: $e');
      return [];
    }
  }

  /// Get a specific setlist by ID from cache or API
  Future<Setlist?> getSetlistById(String setlistId, {bool forceRefresh = false}) async {
    await _ensureInitialized();

    if (!forceRefresh) {
      // Try to find in cache first
      final cachedSetlists = await _getCachedSetlists();
      final cachedSetlist = cachedSetlists.firstWhere(
        (s) => s.id == setlistId,
        orElse: () => Setlist(
          id: '',
          name: '',
          customerId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          songs: [],
        ),
      );

      if (cachedSetlist.id.isNotEmpty) {
        debugPrint('📱 Returning cached setlist: ${cachedSetlist.name}');
        return cachedSetlist;
      }
    }

    // Fetch from API if not in cache or force refresh
    try {
      if (!await isOnline) {
        debugPrint('📱 Offline: setlist not found in cache');
        return null;
      }

      debugPrint('🔄 Fetching setlist $setlistId from API');
      final response = await _apiService.get('/setlists/$setlistId');

      if (response.statusCode == 200) {
        final setlist = Setlist.fromJson(response.data);

        // Update cache with this setlist
        final cachedSetlists = await _getCachedSetlists();
        final updatedSetlists = [...cachedSetlists];
        final existingIndex = updatedSetlists.indexWhere((s) => s.id == setlistId);

        if (existingIndex >= 0) {
          updatedSetlists[existingIndex] = setlist;
        } else {
          updatedSetlists.add(setlist);
        }

        await _cacheSetlists(updatedSetlists);
        debugPrint('✅ Fetched and cached setlist: ${setlist.name}');
        return setlist;
      } else {
        throw Exception('Failed to fetch setlist: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching setlist $setlistId: $e');
      return null;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    await _ensureInitialized();

    final homeSections = await _getCachedHomeSections();
    final songs = await _getCachedSongs();
    final artists = await _getCachedArtists();
    final collections = await _getCachedCollections();
    final setlists = await _getCachedSetlists();

    return {
      'homeSections': homeSections.length,
      'songs': songs.length,
      'artists': artists.length,
      'collections': collections.length,
      'setlists': setlists.length,
      'lastSyncHomeSections': _prefs?.getString(_lastSyncHomeSections),
      'lastSyncSongs': _prefs?.getString(_lastSyncSongs),
      'lastSyncArtists': _prefs?.getString(_lastSyncArtists),
      'lastSyncCollections': _prefs?.getString(_lastSyncCollections),
      'lastSyncSetlists': _prefs?.getString(_lastSyncSetlists),
      'isOnline': await isOnline,
      'cacheVersion': _prefs?.getString(_cacheVersionKey),
    };
  }
}
