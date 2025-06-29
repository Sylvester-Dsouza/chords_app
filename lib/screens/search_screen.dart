import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/app_data_provider.dart';
import '../providers/screen_state_provider.dart';
import '../config/theme.dart';

import '../widgets/song_placeholder.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/search_filter_dialog.dart';
import '../widgets/animated_search_bar.dart';
import '../widgets/search_suggestions_widget.dart';
import '../widgets/voice_search_dialog.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';
import '../models/search_filters.dart';
import '../services/song_service.dart';
import '../services/artist_service.dart';
import '../services/collection_service.dart';
import '../services/liked_songs_service.dart';
import '../services/liked_songs_notifier.dart';
import '../services/search_history_service.dart';
import '../services/voice_search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late ScrollController _scrollController;

  String _screenTitle = 'Song Chords & Lyrics';
  String _searchHint = 'Search for Songs...';

  // Services
  final SongService _songService = SongService();
  final ArtistService _artistService = ArtistService();
  final CollectionService _collectionService = CollectionService();
  final LikedSongsService _likedSongsService = LikedSongsService();
  final LikedSongsNotifier _likedSongsNotifier = LikedSongsNotifier();
  final SearchHistoryService _searchHistoryService = SearchHistoryService();
  final VoiceSearchService _voiceSearchService = VoiceSearchService();

  // Data
  List<Song> _songs = [];
  List<Artist> _artists = [];
  List<Collection> _collections = [];

  // Loading states
  bool _isLoadingSongs = false;
  bool _isLoadingArtists = false;
  bool _isLoadingCollections = false;

  // Search query
  String _searchQuery = '';

  // Filters
  SongSearchFilters _songFilters = SongSearchFilters();
  ArtistSearchFilters _artistFilters = ArtistSearchFilters();
  CollectionSearchFilters _collectionFilters = CollectionSearchFilters();

  // Filter active states
  bool _isSongFilterActive = false;
  bool _isArtistFilterActive = false;
  bool _isCollectionFilterActive = false;

  // Track if we've attempted to load data
  bool _hasAttemptedLoad = false;

  // Search suggestions and voice search
  bool _showSuggestions = false;
  bool _isVoiceSearchAvailable = false;
  FocusNode? _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _searchFocusNode = FocusNode();
    _searchFocusNode!.addListener(_handleSearchFocusChange);

    // Initialize scroll controller
    _scrollController = ScrollController();

    // Register as an observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Listen for liked songs changes
    _likedSongsNotifier.addListener(_handleLikedSongsChanged);

    // Sync with navigation provider and screen state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
      final screenStateProvider = Provider.of<ScreenStateProvider>(context, listen: false);

      navigationProvider.updateIndex(2); // Search screen is index 2
      screenStateProvider.navigateToScreen(ScreenType.search);
      screenStateProvider.markScreenInitialized(ScreenType.search);
    });

    // Load data instantly from global provider cache
    _loadDataInstantly();

    // Check liked status of songs
    _updateLikedStatus();

    // Initialize search services
    _initializeSearchServices();
  }

  // Handle liked songs changes
  void _handleLikedSongsChanged() {
    debugPrint('Liked songs changed, updating UI');
    _updateLikedStatus();
  }

  // Check if filter is active for current tab
  bool _getFilterActiveForCurrentTab() {
    switch (_tabController.index) {
      case 0:
        return _isSongFilterActive;
      case 1:
        return _isArtistFilterActive;
      case 2:
        return _isCollectionFilterActive;
      default:
        return false;
    }
  }

  // Get current search type based on tab
  SearchType _getCurrentSearchType() {
    switch (_tabController.index) {
      case 0:
        return SearchType.songs;
      case 1:
        return SearchType.artists;
      case 2:
        return SearchType.collections;
      default:
        return SearchType.songs;
    }
  }

  // Get search result text based on tab index
  String _getSearchResultText(int tabIndex) {
    bool hasQuery = _searchQuery.isNotEmpty;
    bool hasFilter = false;

    switch (tabIndex) {
      case 0: // Songs
        hasFilter = _isSongFilterActive;
        if (!hasQuery && !hasFilter) return 'All Songs';
        if (hasQuery && !hasFilter) return 'Search results for: $_searchQuery';
        if (!hasQuery && hasFilter) return 'Filtered Songs';
        return 'Search results for: $_searchQuery (Filtered)';

      case 1: // Artists
        hasFilter = _isArtistFilterActive;
        if (!hasQuery && !hasFilter) return 'All Artists';
        if (hasQuery && !hasFilter) return 'Search results for: $_searchQuery';
        if (!hasQuery && hasFilter) return 'Filtered Artists';
        return 'Search results for: $_searchQuery (Filtered)';

      case 2: // Collections
        hasFilter = _isCollectionFilterActive;
        if (!hasQuery && !hasFilter) return 'All Collections';
        if (hasQuery && !hasFilter) return 'Search results for: $_searchQuery';
        if (!hasQuery && hasFilter) return 'Filtered Collections';
        return 'Search results for: $_searchQuery (Filtered)';

      default:
        return 'Search Results';
    }
  }

  // Update liked status of songs
  Future<void> _updateLikedStatus() async {
    try {
      final likedSongs = await _likedSongsService.getLikedSongs();
      if (mounted) {
        setState(() {
          // Update liked status of songs
          for (var song in _songs) {
            song.isLiked = likedSongs.any((likedSong) => likedSong.id == song.id);
          }
        });
      }
    } catch (e) {
      debugPrint('Error updating liked status: $e');
    }
  }

  // Load data instantly from global provider cache (no loading states)
  void _loadDataInstantly() {
    final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);

    // Get cached data immediately without loading states
    final cachedSongs = appDataProvider.songs;
    final cachedArtists = appDataProvider.artists;
    final cachedCollections = appDataProvider.collections;

    // Set data immediately if available
    if (cachedSongs.isNotEmpty || cachedArtists.isNotEmpty || cachedCollections.isNotEmpty) {
      setState(() {
        _songs = cachedSongs;
        _artists = cachedArtists;
        _collections = cachedCollections;
        _isLoadingSongs = false;
        _isLoadingArtists = false;
        _isLoadingCollections = false;
        _hasAttemptedLoad = true; // Mark that we've loaded data
      });

      debugPrint('📱 Search: Loaded cached data instantly - ${cachedSongs.length} songs, ${cachedArtists.length} artists, ${cachedCollections.length} collections');

      // Update liked status for songs
      _updateLikedStatus();
    } else {
      // If no cached data, fall back to loading with background refresh
      debugPrint('📱 Search: No cached data, loading in background...');
      setState(() {
        _hasAttemptedLoad = true; // Mark that we've attempted to load
      });
      _loadInitialData();
    }
  }

  // Load initial data using global provider (fallback for when no cache exists)
  Future<void> _loadInitialData() async {
    final screenStateProvider = Provider.of<ScreenStateProvider>(context, listen: false);

    // Check if we need to refresh data
    final needsRefresh = screenStateProvider.needsDataRefresh(ScreenType.search);

    // Load songs, artists, and collections concurrently
    await Future.wait([
      _fetchSongs(forceRefresh: needsRefresh),
      _fetchArtists(forceRefresh: needsRefresh),
      _fetchCollections(forceRefresh: needsRefresh),
    ]);

    // Mark data as refreshed
    screenStateProvider.markDataRefreshed(ScreenType.search);
  }

  // Fetch songs using global provider
  Future<void> _fetchSongs({bool forceRefresh = false}) async {
    try {
      final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);

      if (mounted && appDataProvider.songsState == DataState.loading) {
        setState(() {
          _isLoadingSongs = true;
        });
      }

      // Get songs from global provider (uses smart caching)
      final songs = await appDataProvider.getSongs(forceRefresh: forceRefresh);

      // Get liked songs to update status
      final likedSongs = await _likedSongsService.getLikedSongs();

      // Update liked status
      for (var song in songs) {
        song.isLiked = likedSongs.any((likedSong) => likedSong.id == song.id);
      }

      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoadingSongs = false;
        });
        debugPrint('📱 Search: Loaded ${songs.length} songs from global provider');
      }
    } catch (e) {
      debugPrint('❌ Search: Error fetching songs: $e');
      if (mounted) {
        setState(() {
          _songs = [];
          _isLoadingSongs = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load songs: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // Fetch artists using global provider
  Future<void> _fetchArtists({bool forceRefresh = false}) async {
    try {
      final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);

      if (mounted && appDataProvider.artistsState == DataState.loading) {
        setState(() {
          _isLoadingArtists = true;
        });
      }

      // Get artists from global provider (uses smart caching)
      final artists = await appDataProvider.getArtists(forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoadingArtists = false;
        });
        debugPrint('📱 Search: Loaded ${artists.length} artists from global provider');
      }
    } catch (e) {
      debugPrint('❌ Search: Error fetching artists: $e');
      if (mounted) {
        setState(() {
          _artists = [];
          _isLoadingArtists = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load artists: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // Fetch collections using global provider
  Future<void> _fetchCollections({bool forceRefresh = false}) async {
    try {
      final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);

      if (mounted && appDataProvider.collectionsState == DataState.loading) {
        setState(() {
          _isLoadingCollections = true;
        });
      }

      // Get collections from global provider (uses smart caching)
      final collections = await appDataProvider.getCollections(forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _collections = collections;
          _isLoadingCollections = false;
        });
        debugPrint('📱 Search: Loaded ${collections.length} collections from global provider');
      }
    } catch (e) {
      debugPrint('❌ Search: Error fetching collections: $e');
      if (mounted) {
        setState(() {
          _collections = [];
          _isLoadingCollections = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load collections: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _screenTitle = 'Song Chords & Lyrics';
            _searchHint = 'Search for Songs...';
            break;
          case 1:
            _screenTitle = 'Find Chords by Artists';
            _searchHint = 'Search for Artists...';
            break;
          case 2:
            _screenTitle = 'Search Collections';
            _searchHint = 'Search for Collections...';
            break;
        }
      });

      // Clear search when changing tabs
      _searchController.clear();
      setState(() {
        _searchQuery = '';
      });

      // Refresh data for the selected tab
      _handleSearch('');
    } else {
      // Update UI for tab selection even when not changing tabs
      setState(() {});
    }
  }

  // Handle search based on current tab
  Future<void> _handleSearch(String query) async {
    // Add to search history if query is not empty
    if (query.trim().isNotEmpty) {
      _addToSearchHistory(query);
    }

    switch (_tabController.index) {
      case 0:
        await _searchSongs(query);
        break;
      case 1:
        await _searchArtists(query);
        break;
      case 2:
        await _searchCollections(query);
        break;
    }
  }

  // Show filter dialog
  void _showFilterDialog() {
    // Get original unfiltered data from AppDataProvider
    final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => SearchFilterDialog(
        tabIndex: _tabController.index,
        songFilters: _songFilters,
        artistFilters: _artistFilters,
        collectionFilters: _collectionFilters,
        // Pass original unfiltered data for dynamic filtering
        availableSongs: appDataProvider.songs,
        availableArtists: appDataProvider.artists,
        availableCollections: appDataProvider.collections,
        onSongFiltersApplied: (filters) {
          setState(() {
            _songFilters = filters;
            _isSongFilterActive = filters.isActive;
          });
          _searchSongs(_searchQuery);
        },
        onArtistFiltersApplied: (filters) {
          setState(() {
            _artistFilters = filters;
            _isArtistFilterActive = filters.isActive;
          });
          _searchArtists(_searchQuery);
        },
        onCollectionFiltersApplied: (filters) {
          setState(() {
            _collectionFilters = filters;
            _isCollectionFilterActive = filters.isActive;
          });
          _searchCollections(_searchQuery);
        },
      ),
    );
  }

  // Search songs
  Future<void> _searchSongs(String query) async {
    if (mounted) {
      setState(() {
        _isLoadingSongs = true;
      });
    }

    try {
      final songs = await _songService.searchSongs(
        query,
        filters: _isSongFilterActive ? _songFilters : null,
      );

      // Get liked songs to update status
      final likedSongs = await _likedSongsService.getLikedSongs();

      // Update liked status
      for (var song in songs) {
        song.isLiked = likedSongs.any((likedSong) => likedSong.id == song.id);
      }

      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoadingSongs = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching songs: $e');
      if (mounted) {
        setState(() {
          _songs = [];
          _isLoadingSongs = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to search songs: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // Search artists
  Future<void> _searchArtists(String query) async {
    if (mounted) {
      setState(() {
        _isLoadingArtists = true;
      });
    }

    try {
      final artists = await _artistService.searchArtists(
        query,
        filters: _isArtistFilterActive ? _artistFilters : null,
      );

      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoadingArtists = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching artists: $e');
      if (mounted) {
        setState(() {
          _artists = [];
          _isLoadingArtists = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to search artists: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // Search collections
  Future<void> _searchCollections(String query) async {
    if (mounted) {
      setState(() {
        _isLoadingCollections = true;
      });
    }

    try {
      final collections = await _collectionService.searchCollections(
        query,
        filters: _isCollectionFilterActive ? _collectionFilters : null,
      );

      if (mounted) {
        setState(() {
          _collections = collections;
          _isLoadingCollections = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching collections: $e');
      if (mounted) {
        setState(() {
          _collections = [];
          _isLoadingCollections = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to search collections: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // Initialize search services
  Future<void> _initializeSearchServices() async {
    try {
      // Initialize search history service
      await _searchHistoryService.initialize();

      // Initialize voice search service
      final isVoiceAvailable = await _voiceSearchService.initialize();

      if (mounted) {
        setState(() {
          _isVoiceSearchAvailable = isVoiceAvailable;
        });
      }

      debugPrint('📱 Search: Services initialized - Voice: $isVoiceAvailable');
    } catch (e) {
      debugPrint('❌ Search: Error initializing services: $e');
    }
  }

  // Handle voice search with visual feedback
  Future<void> _handleVoiceSearch() async {
    if (!_isVoiceSearchAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_voiceSearchService.lastError.isNotEmpty
              ? _voiceSearchService.lastError
              : 'Voice search is not available on this device'),
          backgroundColor: AppTheme.warning,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Double-check permissions before showing dialog
    try {
      final isStillAvailable = await _voiceSearchService.initialize();
      if (!isStillAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_voiceSearchService.lastError.isNotEmpty
                  ? _voiceSearchService.lastError
                  : 'Voice search is not available. Please check your permissions.'),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize voice search: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Show voice search dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return ListenableBuilder(
            listenable: _voiceSearchService,
            builder: (context, child) {
              return VoiceSearchDialog(
                isListening: _voiceSearchService.isListening,
                recognizedText: _voiceSearchService.lastWords,
                confidence: _voiceSearchService.confidence,
                onCancel: () {
                  _voiceSearchService.cancel();
                  Navigator.of(context).pop();
                },
                onRetry: () {
                  _startVoiceListening();
                },
              );
            },
          );
        },
      ),
    );

    // Start listening
    _startVoiceListening();
  }

  // Start voice listening with proper error handling
  Future<void> _startVoiceListening() async {
    try {
      await _voiceSearchService.startListening(
        onResult: (result) {
          if (result.isNotEmpty && mounted) {
            // Close the dialog
            Navigator.of(context).pop();

            // Update search with the result
            _searchController.text = result;
            setState(() {
              _searchQuery = result;
              _showSuggestions = false;
            });
            _handleSearch(result);
            _addToSearchHistory(result);

            // Show success feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Voice search: "$result"'),
                backgroundColor: AppTheme.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('Error with voice search: $e');
      if (mounted) {
        // Close dialog if open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Show user-friendly error message
        String errorMessage = 'Voice search failed. Please try again.';
        if (_voiceSearchService.lastError.isNotEmpty) {
          errorMessage = _voiceSearchService.lastError;
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please enable microphone and speech recognition permissions.';
        } else if (e.toString().contains('not available')) {
          errorMessage = 'Voice search is not available on this device.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Settings',
              textColor: AppTheme.textPrimary,
              onPressed: () {
                // This could open app settings in the future
              },
            ),
          ),
        );
      }
    }
  }

  // Add search query to history
  void _addToSearchHistory(String query) {
    if (query.trim().isEmpty) return;

    SearchType searchType;
    switch (_tabController.index) {
      case 0:
        searchType = SearchType.songs;
        break;
      case 1:
        searchType = SearchType.artists;
        break;
      case 2:
        searchType = SearchType.collections;
        break;
      default:
        searchType = SearchType.songs;
    }

    _searchHistoryService.addToHistory(query, searchType);
  }

  // Handle search focus changes
  void _handleSearchFocusChange() {
    setState(() {
      _showSuggestions = _searchFocusNode?.hasFocus ?? false;
    });
  }

  // Handle suggestion tap
  void _handleSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    setState(() {
      _searchQuery = suggestion;
      _showSuggestions = false;
    });
    _searchFocusNode?.unfocus();
    _handleSearch(suggestion);
    _addToSearchHistory(suggestion);
  }

  // Handle history item removal
  void _handleHistoryItemRemove(SearchHistoryItem item) {
    _searchHistoryService.removeFromHistory(item);
  }

  // Handle clear history
  void _handleClearHistory() {
    SearchType searchType;
    switch (_tabController.index) {
      case 0:
        searchType = SearchType.songs;
        break;
      case 1:
        searchType = SearchType.artists;
        break;
      case 2:
        searchType = SearchType.collections;
        break;
      default:
        searchType = SearchType.songs;
    }

    _searchHistoryService.clearHistory(type: searchType);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _searchFocusNode?.dispose();
    _scrollController.dispose();
    _likedSongsNotifier.removeListener(_handleLikedSongsChanged);
    _voiceSearchService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, refresh liked status
    if (state == AppLifecycleState.resumed) {
      _updateLikedStatus();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, appDataProvider, child) {
        // Auto-update data when global provider has new data
        // Use addPostFrameCallback to avoid calling setState during build
        if (!_hasAttemptedLoad && (appDataProvider.songs.isNotEmpty || appDataProvider.artists.isNotEmpty || appDataProvider.collections.isNotEmpty)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadDataInstantly();
            }
          });
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              // Main content with custom scroll view
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Animated app bar - Fixed to prevent transparency and blue tinting
                  SliverAppBar(
                    backgroundColor: AppTheme.appBar,
                    elevation: 0,
                    scrolledUnderElevation: 0, // Prevents elevation change when scrolling
                    surfaceTintColor: Colors.transparent, // Prevents blue tinting from primary color
                    floating: true,
                    snap: true,
                    pinned: false,
                    automaticallyImplyLeading: false,
                    expandedHeight: 60,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        _screenTitle,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Tab content
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSongsTab(),
                        _buildArtistsTab(),
                        _buildCollectionsTab(),
                      ],
                    ),
                  ),
                ],
              ),

              // Sticky search bar and tabs
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                  ),
                  child: Column(
                    children: [
                      // Enhanced Search Bar with Suggestions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        child: SearchSuggestionsOverlay(
                          showSuggestions: _showSuggestions && _searchHistoryService.isLoaded,
                          query: _searchQuery,
                          searchType: _getCurrentSearchType(),
                          searchHistoryService: _searchHistoryService,
                          onSuggestionTap: _handleSuggestionTap,
                          onHistoryItemRemove: _handleHistoryItemRemove,
                          onClearHistory: _handleClearHistory,
                          child: AnimatedSearchBar(
                            controller: _searchController,
                            hintText: _searchHint,
                            isFilterActive: _getFilterActiveForCurrentTab(),
                            showVoiceSearch: _isVoiceSearchAvailable,
                            showSuggestions: _showSuggestions,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                              _handleSearch(value);
                            },
                            onFilterPressed: _showFilterDialog,
                            onVoicePressed: _handleVoiceSearch,
                            onFocusChanged: _handleSearchFocusChange,
                            primaryColor: AppTheme.primary,
                            backgroundColor: AppTheme.surface,
                            textColor: AppTheme.textPrimary,
                            hintColor: AppTheme.textSecondary,
                            iconColor: AppTheme.textSecondary,
                            activeFilterColor: AppTheme.primary,
                          ),
                        ),
                      ),

                      // Compact Tabs with reduced spacing
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Center(
                                child: _buildCompactTabItem('Songs', 0),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: _buildCompactTabItem('Artists', 1),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: _buildCompactTabItem('Collections', 2),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Compact Divider
                      Container(
                        margin: const EdgeInsets.only(top: 2.0),
                        height: 1,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF333333),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactTabItem(String title, int index) {
    bool isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab text with compact styling
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
                height: 1.1,
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 4),

            // Compact animated underline
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: 2,
              width: isSelected ? title.length * 6.0 : 0,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsTab() {
    // Calculate the actual sticky header height more precisely
    final stickyHeaderHeight = MediaQuery.of(context).padding.top + 50; // Ultra-compact

    return Padding(
      padding: EdgeInsets.only(top: stickyHeaderHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search result text with zero top padding
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 4.0),
            child: Text(
              _getSearchResultText(0),
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),

          // Songs list
          Expanded(
            child: _isLoadingSongs
              ? ListView.builder(
                  itemCount: 8, // Show 8 skeleton items
                  itemBuilder: (context, index) => const SongListItemSkeleton(),
                )
              : _songs.isEmpty
                ? Center(
                    child: Text(
                      _hasAttemptedLoad ? 'No songs found' : 'Loading songs...',
                      style: TextStyle(color: AppTheme.textSecondary)
                    )
                  )
                : ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      return _buildSongItem(song);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsTab() {
    // Calculate the actual sticky header height more precisely
    final stickyHeaderHeight = MediaQuery.of(context).padding.top + 50; // Ultra-compact

    return Padding(
      padding: EdgeInsets.only(top: stickyHeaderHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search result text with zero top padding
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 4.0),
            child: Text(
              _getSearchResultText(1),
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),

          // Artists list
          Expanded(
            child: _isLoadingArtists
              ? ListView.builder(
                  itemCount: 6, // Show 6 skeleton items
                  itemBuilder: (context, index) => const SongListItemSkeleton(),
                )
              : _artists.isEmpty
                ? Center(
                    child: Text(
                      _hasAttemptedLoad ? 'No artists found' : 'Loading artists...',
                      style: TextStyle(color: AppTheme.textSecondary)
                    )
                  )
                : ListView.builder(
                    itemCount: _artists.length,
                    itemBuilder: (context, index) {
                      final artist = _artists[index];
                      // Debug the song count
                      debugPrint('Artist: ${artist.name}, Song Count: ${artist.songCount}');

                      // Format the song count text appropriately
                      String songCountText = artist.songCount == 1
                          ? '1 Song'
                          : '${artist.songCount} Songs';

                      return _buildArtistItem(artist.name, songCountText);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistItem(String name, String songCount) {
    const double placeholderSize = 48.0;
    const double horizontalPadding = 16.0;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          leading: const SongPlaceholder(size: placeholderSize),
          title: Text(
            name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                Icons.music_note,
                color: AppTheme.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                songCount,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppTheme.textSecondary,
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/artist_detail',
              arguments: {
                'artistName': name,
              },
            );
          },
        ),
        // Custom divider that only extends to the image
        Container(
          height: 0.5,
          margin: EdgeInsets.only(left: horizontalPadding + placeholderSize + 12, right: 0),
          color: AppTheme.separator,
        ),
      ],
    );
  }

  Widget _buildCollectionsTab() {
    // Calculate the actual sticky header height more precisely
    final stickyHeaderHeight = MediaQuery.of(context).padding.top + 50; // Ultra-compact

    return Padding(
      padding: EdgeInsets.only(top: stickyHeaderHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search result text with zero top padding
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 4.0),
            child: Text(
              _getSearchResultText(2),
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),

          // Collections grid
          Expanded(
            child: _isLoadingCollections
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: 4, // Show 4 skeleton items
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: const SongListItemSkeleton(),
                  ),
                )
              : _collections.isEmpty
                ? Center(
                    child: Text(
                      _hasAttemptedLoad ? 'No collections found' : 'Loading collections...',
                      style: TextStyle(color: AppTheme.textSecondary)
                    )
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: _collections.length,
                    itemBuilder: (context, index) {
                      final collection = _collections[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildCollectionCard(
                          collection.title,
                          '${collection.songCount} Songs',
                          collection.color,
                          collection.likeCount
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(String title, String songCount, Color bgColor, int likeCount) {
    // Find the collection by title
    final collection = _collections.firstWhere(
      (c) => c.title == title,
      orElse: () => Collection(id: 'unknown', title: title, color: bgColor),
    );

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/collection_detail',
          arguments: {
            'collectionName': title,
            'collectionId': collection.id,
          },
        );
      },
      borderRadius: BorderRadius.circular(5),
      child: Container(
        decoration: AppTheme.cardDecorationWithRadius(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
                // Use image if available, otherwise use gradient
                image: collection.imageUrl != null && collection.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(collection.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: collection.imageUrl == null || collection.imageUrl!.isEmpty
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          bgColor,
                          bgColor.withAlpha(150),
                        ],
                      )
                    : null,
              ),
            ),

            // Info Container
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Song count and likes in a row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Song count
                      Text(
                        songCount,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),

                      // Likes count
                      Row(
                        children: [
                          Text(
                            likeCount.toString(),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            collection.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: collection.isLiked ? AppTheme.error : AppTheme.textSecondary,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongItem(Song song) {
    // Get the song placeholder size
    const double placeholderSize = 48.0;
    const double horizontalPadding = 16.0;

    return Column(
      children: [
        ListTile(
        // Reduce vertical padding to decrease space between items
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: const SongPlaceholder(size: placeholderSize),
        title: Text(
          song.title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          // Ensure text doesn't wrap unnecessarily
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          style: const TextStyle(
            color: AppTheme.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Song Key
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                song.key,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Like Button
            IconButton(
              icon: Icon(
                song.isLiked ? Icons.favorite : Icons.favorite_border,
                color: song.isLiked ? AppTheme.error : AppTheme.textPrimary,
              ),
              onPressed: () async {
                // Store the current state before toggling
                final wasLiked = song.isLiked;

                // Toggle like status
                final success = await _likedSongsService.toggleLike(song);
                if (success && mounted) {
                  setState(() {
                    // Update UI immediately
                    song.isLiked = !wasLiked;
                  });

                  // Show feedback with correct message based on the new state
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        wasLiked
                          ? 'Removed "${song.title}" from liked songs'
                          : 'Added "${song.title}" to liked songs'
                      ),
                      backgroundColor: wasLiked ? AppTheme.textSecondary : AppTheme.success,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        onTap: () {
          // Navigate to song detail
          Navigator.pushNamed(
            context,
            '/song_detail',
            arguments: song,
          );
        },
      ),
        // Custom divider that only extends to the image
        Container(
          height: 0.5,
          margin: EdgeInsets.only(left: horizontalPadding + placeholderSize + 12, right: 0),
          color: AppTheme.separator,
        ),
      ],
    );
  }
}
