import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';
import '../models/setlist.dart';
import '../services/home_section_service.dart';
import '../services/song_service.dart';
import '../services/artist_service.dart';
import '../services/offline_service.dart';
import '../services/collection_service.dart';
import '../services/setlist_service.dart';
import '../services/liked_songs_service.dart';
import '../services/cache_service.dart';
import '../services/smart_data_manager.dart';
import '../core/error_handler.dart';
import '../core/service_locator.dart';

enum DataState { loading, loaded, error, refreshing }

class AppDataProvider extends ChangeNotifier {
  static final AppDataProvider _instance = AppDataProvider._internal();
  factory AppDataProvider() => _instance;
  AppDataProvider._internal() {
    // Add notification throttling
    _setupNotificationThrottling();

    // Set up memory management
    _setupMemoryManagement();
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
  final SmartDataManager _smartDataManager = SmartDataManager();

  // Data States
  DataState _homeState = DataState.loading;
  DataState _songsState = DataState.loading;
  DataState _artistsState = DataState.loading;
  DataState _collectionsState = DataState.loading;
  DataState _setlistsState = DataState.loading;
  DataState _likedSongsState = DataState.loading;

  // Data Storage - Use smaller initial capacity and lazy loading
  List<HomeSection> _homeSections = <HomeSection>[];
  List<Song> _songs = <Song>[];
  List<Artist> _artists = <Artist>[];
  List<Collection> _collections = <Collection>[];
  List<Setlist> _setlists = <Setlist>[];
  List<Song> _likedSongs = <Song>[];

  // Memory management
  static const int _maxSongsInMemory = 100; // Limit songs in memory
  static const int _maxArtistsInMemory = 50; // Limit artists in memory
  static const int _maxCollectionsInMemory = 20; // Limit collections in memory

  // Cache Timestamps (only for setlists and liked songs that still use old caching)
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
    debugPrint('🚀 AppDataProvider: Initializing app data with smart loading...');

    // Initialize smart data manager
    await _smartDataManager.initialize();

    // Load only essential data immediately (home sections)
    await _loadEssentialDataOnly();

    // Don't load other data - it will be loaded when needed
    debugPrint('✅ App data initialization complete - other data will load on demand');
  }

  // Initialize app data after login - lighter version for faster login
  Future<void> initializeAfterLogin() async {
    debugPrint('🚀 AppDataProvider: Initializing app data after login...');

    // Load only essential data (home sections)
    await _loadEssentialDataOnly();

    // Other data will be loaded on demand
    debugPrint('✅ Post-login initialization complete');
  }

  // Load only essential data (home sections) for immediate UI
  Future<void> _loadEssentialDataOnly() async {
    try {
      // Load home sections using smart data manager
      final homeSections = await _smartDataManager.getHomeSections();

      if (homeSections.isNotEmpty) {
        _homeSections = homeSections;
        _homeState = DataState.loaded;
        debugPrint('📱 Loaded ${_homeSections.length} home sections (smart cache)');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading essential data: $e');
      _homeState = DataState.error;
      notifyListeners();
    }
  }





  // Get home sections with smart caching
  Future<List<HomeSection>> getHomeSections({bool forceRefresh = false}) async {
    try {
      // Use smart data manager for efficient loading
      final homeSections = await _smartDataManager.getHomeSections(forceRefresh: forceRefresh);

      // Update local state
      _homeSections = homeSections;
      _homeState = DataState.loaded;

      notifyListeners();
      return homeSections;
    } catch (e) {
      debugPrint('❌ Error getting home sections: $e');
      _homeState = DataState.error;
      notifyListeners();
      return _homeSections; // Return cached data as fallback
    }
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

      notifyListeners();
      debugPrint('✅ Home sections refreshed: ${sections.length} sections');

      return sections;
    } catch (e) {
      final errorMessage = ErrorHandler.handleErrorWithContext('Home sections refresh', e);
      debugPrint('❌ Error refreshing home sections: $errorMessage');

      if (!background) {
        _homeState = DataState.error;
        notifyListeners();
      }

      // Return cached data on error as fallback
      return _homeSections;
    }
  }

  // Get songs with smart caching (lazy loading)
  Future<List<Song>> getSongs({bool forceRefresh = false, int limit = 50}) async {
    try {
      _songsState = DataState.loading;
      notifyListeners();

      // Use smart data manager for efficient loading
      final songs = await _smartDataManager.getSongs(forceRefresh: forceRefresh, limit: limit);

      // Update local state with limited data
      _songs = songs.take(_maxSongsInMemory).toList();
      _songsState = DataState.loaded;

      notifyListeners();
      debugPrint('📱 Loaded ${_songs.length} songs (smart cache, limited)');
      return _songs;
    } catch (e) {
      debugPrint('❌ Error getting songs: $e');
      _songsState = DataState.error;
      notifyListeners();
      return _songs; // Return cached data as fallback
    }
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
          notifyListeners();
          debugPrint('✅ Offline songs loaded: ${offlineSongs.length} songs');
          return offlineSongs;
        }
      }

      debugPrint('🔄 Fetching songs from API (background: $background)');
      final songs = await _songService.getAllSongs(forceRefresh: true);

      _songs = songs;
      _songsState = DataState.loaded;

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

  // Get artists with smart caching (lazy loading)
  Future<List<Artist>> getArtists({bool forceRefresh = false, int limit = 30}) async {
    try {
      _artistsState = DataState.loading;
      notifyListeners();

      // Use smart data manager for efficient loading
      final artists = await _smartDataManager.getArtists(forceRefresh: forceRefresh, limit: limit);

      // Update local state with limited data
      _artists = artists.take(_maxArtistsInMemory).toList();
      _artistsState = DataState.loaded;

      notifyListeners();
      debugPrint('📱 Loaded ${_artists.length} artists (smart cache, limited)');
      return _artists;
    } catch (e) {
      debugPrint('❌ Error getting artists: $e');
      _artistsState = DataState.error;
      notifyListeners();
      return _artists; // Return cached data as fallback
    }
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

  // Get collections with smart caching (lazy loading)
  Future<List<Collection>> getCollections({bool forceRefresh = false, int limit = 20}) async {
    try {
      _collectionsState = DataState.loading;
      notifyListeners();

      // Use smart data manager for efficient loading
      final collections = await _smartDataManager.getCollections(forceRefresh: forceRefresh, limit: limit);

      // Update local state with limited data
      _collections = collections.take(_maxCollectionsInMemory).toList();
      _collectionsState = DataState.loaded;

      notifyListeners();
      debugPrint('📱 Loaded ${_collections.length} collections (smart cache, limited)');
      return _collections;
    } catch (e) {
      debugPrint('❌ Error getting collections: $e');
      _collectionsState = DataState.error;
      notifyListeners();
      return _collections; // Return cached data as fallback
    }
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

    _lastSetlistsRefresh = null;
    _lastLikedSongsRefresh = null;

    await _cacheService.clearAllCache();

    notifyListeners();
    debugPrint('✅ All data and cache cleared');
  }

  // Set up memory management callbacks
  void _setupMemoryManagement() {
    try {
      final memoryManager = serviceLocator.memoryManager;

      // Add memory pressure callback
      memoryManager.addMemoryPressureCallback(() {
        debugPrint('⚠️ Memory pressure detected - cleaning up AppDataProvider');
        cleanupMemory();
      });

      // Add critical memory callback
      memoryManager.addCriticalMemoryCallback(() {
        debugPrint('🚨 Critical memory pressure - aggressive cleanup');
        _aggressiveCleanup();
      });

      debugPrint('🧠 Memory management callbacks set up for AppDataProvider');
    } catch (e) {
      debugPrint('❌ Error setting up memory management: $e');
    }
  }

  // Memory cleanup method
  void cleanupMemory() {
    debugPrint('🧹 Cleaning up memory in AppDataProvider...');

    // Keep only essential data and clear the rest
    if (_songs.length > _maxSongsInMemory) {
      _songs = _songs.take(_maxSongsInMemory).toList();
      debugPrint('🧹 Trimmed songs to ${_songs.length}');
    }

    if (_artists.length > _maxArtistsInMemory) {
      _artists = _artists.take(_maxArtistsInMemory).toList();
      debugPrint('🧹 Trimmed artists to ${_artists.length}');
    }

    if (_collections.length > _maxCollectionsInMemory) {
      _collections = _collections.take(_maxCollectionsInMemory).toList();
      debugPrint('🧹 Trimmed collections to ${_collections.length}');
    }

    // Force garbage collection
    debugPrint('🧹 Memory cleanup completed');
  }

  // Aggressive cleanup for critical memory situations
  void _aggressiveCleanup() {
    debugPrint('🚨 Aggressive memory cleanup in AppDataProvider...');

    // Clear all non-essential data
    _songs.clear();
    _artists.clear();
    _collections.clear();
    _setlists.clear();
    _likedSongs.clear();

    // Keep only home sections (most essential)
    if (_homeSections.length > 3) {
      _homeSections = _homeSections.take(3).toList();
    }

    // Reset states to force reload when needed
    _songsState = DataState.loading;
    _artistsState = DataState.loading;
    _collectionsState = DataState.loading;
    _setlistsState = DataState.loading;
    _likedSongsState = DataState.loading;

    debugPrint('🚨 Aggressive cleanup completed');
    notifyListeners();
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
