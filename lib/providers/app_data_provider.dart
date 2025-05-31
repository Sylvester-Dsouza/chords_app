import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';
import '../models/setlist.dart';
import '../models/course.dart';
import '../services/home_section_service.dart';
import '../services/song_service.dart';
import '../services/artist_service.dart';
import '../services/offline_service.dart';
import '../services/collection_service.dart';
import '../services/setlist_service.dart';
import '../services/liked_songs_service.dart';
import '../services/cache_service.dart';

enum DataState { loading, loaded, error, refreshing }

class AppDataProvider extends ChangeNotifier {
  static final AppDataProvider _instance = AppDataProvider._internal();
  factory AppDataProvider() => _instance;
  AppDataProvider._internal() {
    // Add notification throttling
    _setupNotificationThrottling();
  }

  // Notification throttling
  Timer? _notificationTimer;
  bool _hasPendingNotification = false;
  static const Duration _notificationDelay = Duration(milliseconds: 100);

  void _setupNotificationThrottling() {
    // Setup throttled notification system
  }

  @override
  void notifyListeners() {
    // Throttle notifications to prevent loops
    if (_notificationTimer?.isActive == true) {
      _hasPendingNotification = true;
      return;
    }

    super.notifyListeners();

    _notificationTimer = Timer(_notificationDelay, () {
      if (_hasPendingNotification) {
        _hasPendingNotification = false;
        super.notifyListeners();
      }
    });
  }

  // Services
  final HomeSectionService _homeSectionService = HomeSectionService();
  final SongService _songService = SongService();
  final ArtistService _artistService = ArtistService();
  final CollectionService _collectionService = CollectionService();
  final SetlistService _setlistService = SetlistService();
  final LikedSongsService _likedSongsService = LikedSongsService();
  final CacheService _cacheService = CacheService();
  final OfflineService _offlineService = OfflineService();

  // Data States
  DataState _homeState = DataState.loading;
  DataState _songsState = DataState.loading;
  DataState _artistsState = DataState.loading;
  DataState _collectionsState = DataState.loading;
  DataState _setlistsState = DataState.loading;
  DataState _likedSongsState = DataState.loading;

  // Data Storage
  List<HomeSection> _homeSections = [];
  List<Song> _songs = [];
  List<Artist> _artists = [];
  List<Collection> _collections = [];
  List<Setlist> _setlists = [];
  List<Song> _likedSongs = [];

  // Cache Timestamps
  DateTime? _lastHomeRefresh;
  DateTime? _lastSongsRefresh;
  DateTime? _lastArtistsRefresh;
  DateTime? _lastCollectionsRefresh;
  DateTime? _lastSetlistsRefresh;
  DateTime? _lastLikedSongsRefresh;

  // Cache Duration (in minutes)
  static const int _cacheValidityMinutes = 5;
  static const int _backgroundRefreshMinutes = 2;

  // Getters for data
  List<HomeSection> get homeSections => List.unmodifiable(_homeSections);
  List<Song> get songs => List.unmodifiable(_songs);
  List<Artist> get artists => List.unmodifiable(_artists);
  List<Collection> get collections => List.unmodifiable(_collections);
  List<Setlist> get setlists => List.unmodifiable(_setlists);
  List<Song> get likedSongs => List.unmodifiable(_likedSongs);

  // Getters for states
  DataState get homeState => _homeState;
  DataState get songsState => _songsState;
  DataState get artistsState => _artistsState;
  DataState get collectionsState => _collectionsState;
  DataState get setlistsState => _setlistsState;
  DataState get likedSongsState => _likedSongsState;

  // Check if data is fresh (within cache validity period)
  bool _isDataFresh(DateTime? lastRefresh) {
    if (lastRefresh == null) return false;
    return DateTime.now().difference(lastRefresh).inMinutes < _cacheValidityMinutes;
  }

  // Check if data needs background refresh
  bool _needsBackgroundRefresh(DateTime? lastRefresh) {
    if (lastRefresh == null) return true;
    return DateTime.now().difference(lastRefresh).inMinutes >= _backgroundRefreshMinutes;
  }

  // Initialize app data - called once when app starts
  Future<void> initializeAppData() async {
    debugPrint('🚀 AppDataProvider: Initializing app data...');

    // Load cached data first for instant UI
    await _loadCachedData();

    // Then refresh data in background
    _refreshAllDataInBackground();
  }

  // Initialize app data after login - lighter version for faster login
  Future<void> initializeAfterLogin() async {
    debugPrint('🚀 AppDataProvider: Initializing app data after login...');

    // Load only essential cached data first
    await _loadEssentialCachedData();

    // Then refresh data in background
    _refreshAllDataInBackground();
  }

  // Load only essential cached data for faster startup
  Future<void> _loadEssentialCachedData() async {
    try {
      // Load home sections from cache (most important for home screen)
      final cachedHomeSections = await _homeSectionService.getCachedHomeSections(checkOnly: true);
      if (cachedHomeSections != null && cachedHomeSections.isNotEmpty) {
        _homeSections = cachedHomeSections;
        _homeState = DataState.loaded;
        _lastHomeRefresh = DateTime.now();
        debugPrint('📱 Loaded ${_homeSections.length} home sections from cache');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading essential cached data: $e');
    }
  }

  // Load cached data for instant UI
  Future<void> _loadCachedData() async {
    try {
      // Load home sections from cache
      final cachedHomeSections = await _homeSectionService.getCachedHomeSections(checkOnly: true);
      if (cachedHomeSections != null && cachedHomeSections.isNotEmpty) {
        _homeSections = cachedHomeSections;
        _homeState = DataState.loaded;
        _lastHomeRefresh = DateTime.now();
        debugPrint('📱 Loaded ${_homeSections.length} home sections from cache');
      }

      // Load songs from cache
      final cachedSongs = await _cacheService.getCachedSongs();
      if (cachedSongs != null && cachedSongs.isNotEmpty) {
        _songs = cachedSongs;
        _songsState = DataState.loaded;
        _lastSongsRefresh = DateTime.now();
        debugPrint('📱 Loaded ${_songs.length} songs from cache');
      }

      // Load artists from cache
      final cachedArtists = await _cacheService.getCachedArtists();
      if (cachedArtists != null && cachedArtists.isNotEmpty) {
        _artists = cachedArtists;
        _artistsState = DataState.loaded;
        _lastArtistsRefresh = DateTime.now();
        debugPrint('📱 Loaded ${_artists.length} artists from cache');
      }

      // Load collections from cache (using seasonal collections as fallback)
      final cachedCollections = await _cacheService.getCachedSeasonalCollections();
      if (cachedCollections != null && cachedCollections.isNotEmpty) {
        _collections = cachedCollections;
        _collectionsState = DataState.loaded;
        _lastCollectionsRefresh = DateTime.now();
        debugPrint('📱 Loaded ${_collections.length} collections from cache');
      }

      // Notify listeners if we have any cached data
      if (_homeSections.isNotEmpty || _songs.isNotEmpty || _artists.isNotEmpty || _collections.isNotEmpty) {
        notifyListeners();
        debugPrint('📱 Notified listeners with cached data');
      }
    } catch (e) {
      debugPrint('❌ Error loading cached data: $e');
    }
  }

  // Refresh all data in background
  void _refreshAllDataInBackground() {
    debugPrint('🔄 Starting background data refresh...');

    // Refresh home sections
    if (!_isDataFresh(_lastHomeRefresh)) {
      _refreshHomeSections(background: true);
    }

    // Refresh songs
    if (!_isDataFresh(_lastSongsRefresh)) {
      _refreshSongs(background: true);
    }

    // Refresh artists
    if (!_isDataFresh(_lastArtistsRefresh)) {
      _refreshArtists(background: true);
    }

    // Refresh collections
    if (!_isDataFresh(_lastCollectionsRefresh)) {
      _refreshCollections(background: true);
    }
  }

  // Get home sections with smart caching
  Future<List<HomeSection>> getHomeSections({bool forceRefresh = false}) async {
    // If we have fresh data and not forcing refresh, return immediately
    if (!forceRefresh && _isDataFresh(_lastHomeRefresh) && _homeSections.isNotEmpty) {
      debugPrint('📱 Returning cached home sections');

      // Check if background refresh is needed
      if (_needsBackgroundRefresh(_lastHomeRefresh)) {
        _refreshHomeSections(background: true);
      }

      return _homeSections;
    }

    // If forcing refresh or no fresh data, fetch from API
    return await _refreshHomeSections(background: false);
  }

  // Refresh home sections
  Future<List<HomeSection>> _refreshHomeSections({bool background = false}) async {
    try {
      if (!background) {
        _homeState = _homeSections.isEmpty ? DataState.loading : DataState.refreshing;
        notifyListeners();
      }

      debugPrint('🔄 Fetching home sections from API (background: $background)');
      final sections = await _homeSectionService.getHomeSections(forceRefresh: true);

      _homeSections = sections;
      _homeState = DataState.loaded;
      _lastHomeRefresh = DateTime.now();

      notifyListeners();
      debugPrint('✅ Home sections refreshed: ${sections.length} sections');

      return sections;
    } catch (e) {
      debugPrint('❌ Error refreshing home sections: $e');
      if (!background) {
        _homeState = DataState.error;
        notifyListeners();
      }
      return _homeSections; // Return cached data on error
    }
  }

  // Get songs with smart caching
  Future<List<Song>> getSongs({bool forceRefresh = false}) async {
    if (!forceRefresh && _isDataFresh(_lastSongsRefresh) && _songs.isNotEmpty) {
      debugPrint('📱 Returning cached songs');

      if (_needsBackgroundRefresh(_lastSongsRefresh)) {
        _refreshSongs(background: true);
      }

      return _songs;
    }

    return await _refreshSongs(background: false);
  }

  // Refresh songs
  Future<List<Song>> _refreshSongs({bool background = false}) async {
    try {
      if (!background) {
        _songsState = _songs.isEmpty ? DataState.loading : DataState.refreshing;
        notifyListeners();
      }

      // Check if we should use offline data
      if (_offlineService.shouldUseOfflineData()) {
        debugPrint('🔄 Using offline songs data');
        final offlineSongs = await _offlineService.getCachedSongs();
        if (offlineSongs != null && offlineSongs.isNotEmpty) {
          _songs = offlineSongs;
          _songsState = DataState.loaded;
          _lastSongsRefresh = DateTime.now();
          notifyListeners();
          debugPrint('✅ Offline songs loaded: ${offlineSongs.length} songs');
          return offlineSongs;
        }
      }

      debugPrint('🔄 Fetching songs from API (background: $background)');
      final songs = await _songService.getAllSongs(forceRefresh: true);

      _songs = songs;
      _songsState = DataState.loaded;
      _lastSongsRefresh = DateTime.now();

      // Cache songs for offline use
      if (_offlineService.isOnline) {
        await _offlineService.cacheSongsForOffline(songs);
      }

      notifyListeners();
      debugPrint('✅ Songs refreshed: ${songs.length} songs');

      return songs;
    } catch (e) {
      debugPrint('❌ Error refreshing songs: $e');

      // Try to use offline data as fallback
      if (_offlineService.isOffline) {
        final offlineSongs = await _offlineService.getCachedSongs();
        if (offlineSongs != null && offlineSongs.isNotEmpty) {
          _songs = offlineSongs;
          _songsState = DataState.loaded;
          notifyListeners();
          debugPrint('✅ Using offline songs as fallback: ${offlineSongs.length} songs');
          return offlineSongs;
        }
      }

      if (!background) {
        _songsState = DataState.error;
        notifyListeners();
      }
      return _songs;
    }
  }

  // Get artists with smart caching
  Future<List<Artist>> getArtists({bool forceRefresh = false}) async {
    if (!forceRefresh && _isDataFresh(_lastArtistsRefresh) && _artists.isNotEmpty) {
      debugPrint('📱 Returning cached artists');

      if (_needsBackgroundRefresh(_lastArtistsRefresh)) {
        _refreshArtists(background: true);
      }

      return _artists;
    }

    return await _refreshArtists(background: false);
  }

  // Refresh artists
  Future<List<Artist>> _refreshArtists({bool background = false}) async {
    try {
      if (!background) {
        _artistsState = _artists.isEmpty ? DataState.loading : DataState.refreshing;
        notifyListeners();
      }

      debugPrint('🔄 Fetching artists from API (background: $background)');
      final artists = await _artistService.getAllArtists(forceRefresh: true);

      _artists = artists;
      _artistsState = DataState.loaded;
      _lastArtistsRefresh = DateTime.now();

      notifyListeners();
      debugPrint('✅ Artists refreshed: ${artists.length} artists');

      return artists;
    } catch (e) {
      debugPrint('❌ Error refreshing artists: $e');
      if (!background) {
        _artistsState = DataState.error;
        notifyListeners();
      }
      return _artists;
    }
  }

  // Get collections with smart caching
  Future<List<Collection>> getCollections({bool forceRefresh = false}) async {
    if (!forceRefresh && _isDataFresh(_lastCollectionsRefresh) && _collections.isNotEmpty) {
      debugPrint('📱 Returning cached collections');

      if (_needsBackgroundRefresh(_lastCollectionsRefresh)) {
        _refreshCollections(background: true);
      }

      return _collections;
    }

    return await _refreshCollections(background: false);
  }

  // Refresh collections
  Future<List<Collection>> _refreshCollections({bool background = false}) async {
    try {
      if (!background) {
        _collectionsState = _collections.isEmpty ? DataState.loading : DataState.refreshing;
        notifyListeners();
      }

      debugPrint('🔄 Fetching collections from API (background: $background)');
      final collections = await _collectionService.getAllCollections();

      _collections = collections;
      _collectionsState = DataState.loaded;
      _lastCollectionsRefresh = DateTime.now();

      notifyListeners();
      debugPrint('✅ Collections refreshed: ${collections.length} collections');

      return collections;
    } catch (e) {
      debugPrint('❌ Error refreshing collections: $e');
      if (!background) {
        _collectionsState = DataState.error;
        notifyListeners();
      }
      return _collections;
    }
  }

  // Get setlists with smart caching
  Future<List<Setlist>> getSetlists({bool forceRefresh = false}) async {
    if (!forceRefresh && _isDataFresh(_lastSetlistsRefresh) && _setlists.isNotEmpty) {
      debugPrint('📱 Returning cached setlists');

      if (_needsBackgroundRefresh(_lastSetlistsRefresh)) {
        _refreshSetlists(background: true);
      }

      return _setlists;
    }

    return await _refreshSetlists(background: false);
  }

  // Refresh setlists
  Future<List<Setlist>> _refreshSetlists({bool background = false}) async {
    try {
      if (!background) {
        _setlistsState = _setlists.isEmpty ? DataState.loading : DataState.refreshing;
        notifyListeners();
      }

      debugPrint('🔄 Fetching setlists from API (background: $background)');
      final setlists = await _setlistService.getSetlists();

      _setlists = setlists;
      _setlistsState = DataState.loaded;
      _lastSetlistsRefresh = DateTime.now();

      notifyListeners();
      debugPrint('✅ Setlists refreshed: ${setlists.length} setlists');

      return setlists;
    } catch (e) {
      debugPrint('❌ Error refreshing setlists: $e');
      if (!background) {
        _setlistsState = DataState.error;
        notifyListeners();
      }
      return _setlists;
    }
  }

  // Get liked songs with smart caching
  Future<List<Song>> getLikedSongs({bool forceRefresh = false}) async {
    if (!forceRefresh && _isDataFresh(_lastLikedSongsRefresh) && _likedSongs.isNotEmpty) {
      debugPrint('📱 Returning cached liked songs');

      if (_needsBackgroundRefresh(_lastLikedSongsRefresh)) {
        _refreshLikedSongs(background: true);
      }

      return _likedSongs;
    }

    return await _refreshLikedSongs(background: false);
  }

  // Refresh liked songs
  Future<List<Song>> _refreshLikedSongs({bool background = false}) async {
    try {
      if (!background) {
        _likedSongsState = _likedSongs.isEmpty ? DataState.loading : DataState.refreshing;
        notifyListeners();
      }

      debugPrint('🔄 Fetching liked songs from API (background: $background)');
      final likedSongs = await _likedSongsService.getLikedSongs(forceSync: true);

      _likedSongs = likedSongs;
      _likedSongsState = DataState.loaded;
      _lastLikedSongsRefresh = DateTime.now();

      notifyListeners();
      debugPrint('✅ Liked songs refreshed: ${likedSongs.length} songs');

      return likedSongs;
    } catch (e) {
      debugPrint('❌ Error refreshing liked songs: $e');
      if (!background) {
        _likedSongsState = DataState.error;
        notifyListeners();
      }
      return _likedSongs;
    }
  }

  // Force refresh all data
  Future<void> refreshAllData() async {
    debugPrint('🔄 Force refreshing all data...');

    await Future.wait<dynamic>([
      _refreshHomeSections(background: false),
      _refreshSongs(background: false),
      _refreshArtists(background: false),
      _refreshCollections(background: false),
      _refreshSetlists(background: false),
      _refreshLikedSongs(background: false),
    ]);

    debugPrint('✅ All data refreshed');
  }

  // Clear all data and cache
  Future<void> clearAllData() async {
    debugPrint('🗑️ Clearing all data and cache...');

    _homeSections.clear();
    _songs.clear();
    _artists.clear();
    _collections.clear();
    _setlists.clear();
    _likedSongs.clear();

    _homeState = DataState.loading;
    _songsState = DataState.loading;
    _artistsState = DataState.loading;
    _collectionsState = DataState.loading;
    _setlistsState = DataState.loading;
    _likedSongsState = DataState.loading;

    _lastHomeRefresh = null;
    _lastSongsRefresh = null;
    _lastArtistsRefresh = null;
    _lastCollectionsRefresh = null;
    _lastSetlistsRefresh = null;
    _lastLikedSongsRefresh = null;

    await _cacheService.clearAllCache();

    notifyListeners();
    debugPrint('✅ All data and cache cleared');
  }

  @override
  void dispose() {
    // Cancel any pending notification timer
    _notificationTimer?.cancel();
    _notificationTimer = null;

    // Clear all data
    _homeSections.clear();
    _songs.clear();
    _artists.clear();
    _collections.clear();
    _setlists.clear();
    _likedSongs.clear();

    super.dispose();
  }
}
