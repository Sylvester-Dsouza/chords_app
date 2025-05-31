import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';

/// Service to handle offline functionality and data caching
class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // Cache keys
  static const String _keyOfflineSongs = 'offline_songs';
  static const String _keyOfflineArtists = 'offline_artists';
  static const String _keyOfflineCollections = 'offline_collections';
  static const String _keyOfflineSetlists = 'offline_setlists';
  static const String _keyLastOnlineSync = 'last_online_sync';
  static const String _keyOfflineMode = 'offline_mode_enabled';

  // Connectivity
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  bool _offlineModeEnabled = false;

  // Getters
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get offlineModeEnabled => _offlineModeEnabled;

  /// Initialize offline service
  Future<void> initialize() async {
    debugPrint('🔌 Initializing OfflineService...');

    // Check initial connectivity
    await _checkConnectivity();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Load offline mode preference
    await _loadOfflineModePreference();

    debugPrint('🔌 OfflineService initialized - Online: $_isOnline, Offline Mode: $_offlineModeEnabled');
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      _isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
      debugPrint('🔌 Connectivity check: ${_isOnline ? "Online" : "Offline"}');
    } catch (e) {
      debugPrint('🔌 Error checking connectivity: $e');
      _isOnline = false; // Assume offline on error
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      debugPrint('🔌 Connectivity changed: ${_isOnline ? "Online" : "Offline"}');

      if (_isOnline) {
        _onBackOnline();
      } else {
        _onGoOffline();
      }
    }
  }

  /// Called when device comes back online
  void _onBackOnline() {
    debugPrint('🔌 Device back online - syncing data...');
    // Trigger data sync when back online
    _syncDataWhenOnline();
  }

  /// Called when device goes offline
  void _onGoOffline() {
    debugPrint('🔌 Device went offline - switching to cached data');
  }

  /// Sync data when online
  Future<void> _syncDataWhenOnline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastOnlineSync, DateTime.now().toIso8601String());
      debugPrint('🔌 Data sync timestamp updated');
    } catch (e) {
      debugPrint('🔌 Error updating sync timestamp: $e');
    }
  }

  /// Load offline mode preference
  Future<void> _loadOfflineModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _offlineModeEnabled = prefs.getBool(_keyOfflineMode) ?? false;
    } catch (e) {
      debugPrint('🔌 Error loading offline mode preference: $e');
      _offlineModeEnabled = false;
    }
  }

  /// Enable/disable offline mode
  Future<void> setOfflineModeEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOfflineMode, enabled);
      _offlineModeEnabled = enabled;
      debugPrint('🔌 Offline mode ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('🔌 Error setting offline mode: $e');
    }
  }

  /// Cache songs for offline use
  Future<void> cacheSongsForOffline(List<Song> songs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJson = songs.map((song) => song.toJson()).toList();
      await prefs.setString(_keyOfflineSongs, jsonEncode(songsJson));
      debugPrint('🔌 Cached ${songs.length} songs for offline use');
    } catch (e) {
      debugPrint('🔌 Error caching songs: $e');
    }
  }

  /// Get cached songs for offline use
  Future<List<Song>?> getCachedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsString = prefs.getString(_keyOfflineSongs);

      if (songsString != null) {
        final List<dynamic> songsJson = jsonDecode(songsString);
        final songs = songsJson.map((json) => Song.fromJson(json)).toList();
        debugPrint('🔌 Retrieved ${songs.length} cached songs');
        return songs;
      }
    } catch (e) {
      debugPrint('🔌 Error retrieving cached songs: $e');
    }
    return null;
  }

  /// Cache artists for offline use
  Future<void> cacheArtistsForOffline(List<Artist> artists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final artistsJson = artists.map((artist) => artist.toJson()).toList();
      await prefs.setString(_keyOfflineArtists, jsonEncode(artistsJson));
      debugPrint('🔌 Cached ${artists.length} artists for offline use');
    } catch (e) {
      debugPrint('🔌 Error caching artists: $e');
    }
  }

  /// Get cached artists for offline use
  Future<List<Artist>?> getCachedArtists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final artistsString = prefs.getString(_keyOfflineArtists);

      if (artistsString != null) {
        final List<dynamic> artistsJson = jsonDecode(artistsString);
        final artists = artistsJson.map((json) => Artist.fromJson(json)).toList();
        debugPrint('🔌 Retrieved ${artists.length} cached artists');
        return artists;
      }
    } catch (e) {
      debugPrint('🔌 Error retrieving cached artists: $e');
    }
    return null;
  }

  /// Cache collections for offline use
  Future<void> cacheCollectionsForOffline(List<Collection> collections) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collectionsJson = collections.map((collection) => collection.toJson()).toList();
      await prefs.setString(_keyOfflineCollections, jsonEncode(collectionsJson));
      debugPrint('🔌 Cached ${collections.length} collections for offline use');
    } catch (e) {
      debugPrint('🔌 Error caching collections: $e');
    }
  }

  /// Get cached collections for offline use
  Future<List<Collection>?> getCachedCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collectionsString = prefs.getString(_keyOfflineCollections);

      if (collectionsString != null) {
        final List<dynamic> collectionsJson = jsonDecode(collectionsString);
        final collections = collectionsJson.map((json) => Collection.fromJson(json)).toList();
        debugPrint('🔌 Retrieved ${collections.length} cached collections');
        return collections;
      }
    } catch (e) {
      debugPrint('🔌 Error retrieving cached collections: $e');
    }
    return null;
  }

  /// Check if we have sufficient offline data
  Future<bool> hasOfflineData() async {
    try {
      final songs = await getCachedSongs();
      final artists = await getCachedArtists();
      final collections = await getCachedCollections();

      return (songs?.isNotEmpty ?? false) ||
             (artists?.isNotEmpty ?? false) ||
             (collections?.isNotEmpty ?? false);
    } catch (e) {
      debugPrint('🔌 Error checking offline data: $e');
      return false;
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncString = prefs.getString(_keyLastOnlineSync);

      if (syncString != null) {
        return DateTime.parse(syncString);
      }
    } catch (e) {
      debugPrint('🔌 Error getting last sync time: $e');
    }
    return null;
  }

  /// Clear all offline data
  Future<void> clearOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOfflineSongs);
      await prefs.remove(_keyOfflineArtists);
      await prefs.remove(_keyOfflineCollections);
      await prefs.remove(_keyOfflineSetlists);
      await prefs.remove(_keyLastOnlineSync);
      debugPrint('🔌 Cleared all offline data');
    } catch (e) {
      debugPrint('🔌 Error clearing offline data: $e');
    }
  }

  /// Check if device should use offline data
  bool shouldUseOfflineData() {
    return isOffline || offlineModeEnabled;
  }

  /// Get offline status message
  String getOfflineStatusMessage() {
    if (isOffline && offlineModeEnabled) {
      return 'You\'re offline. Using cached data.';
    } else if (isOffline) {
      return 'No internet connection. Limited functionality available.';
    } else if (offlineModeEnabled) {
      return 'Offline mode enabled. Using cached data.';
    } else {
      return 'Online';
    }
  }

  /// Dispose resources
  void dispose() {
    // Cancel any subscriptions if needed
    debugPrint('🔌 OfflineService disposed');
  }
}
