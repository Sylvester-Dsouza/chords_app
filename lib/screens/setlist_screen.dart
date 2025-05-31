import 'package:flutter/material.dart';
import '../models/setlist.dart';
import '../models/song.dart';
import '../services/setlist_service.dart';
import '../services/liked_songs_service.dart';
import '../services/liked_songs_notifier.dart';

import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/app_data_provider.dart';
import '../providers/screen_state_provider.dart';

// Import our new widgets
import '../widgets/setlist_card.dart';
import '../widgets/empty_setlist_state.dart';
import '../widgets/create_setlist_dialog.dart';
import '../widgets/enhanced_setlist_share_dialog.dart';
import '../widgets/song_placeholder.dart';
import '../widgets/skeleton_loader.dart';

class SetlistScreen extends StatefulWidget {
  const SetlistScreen({super.key});

  @override
  State<SetlistScreen> createState() => _SetlistScreenState();
}

class _SetlistScreenState extends State<SetlistScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  final SetlistService _setlistService = SetlistService();
  final LikedSongsService _likedSongsService = LikedSongsService();
  final LikedSongsNotifier _likedSongsNotifier = LikedSongsNotifier();

  List<Setlist> _setlists = [];
  List<Song> _likedSongs = [];
  bool _isLoading = true;
  bool _isLoadingLikedSongs = false;
  bool _isLoggedIn = false;

  // Last time setlists were fetched
  DateTime? _lastFetchTime;

  // Define the fetchSetlists method with enhanced caching, aggressive debouncing, and robust error handling
  Future<void> _fetchSetlists({bool forceRefresh = false}) async {
    // Safety check: if we've tried too many times in succession, abort to prevent loops
    if (_fetchSetlistsAttempts >= _maxFetchAttempts) {
      debugPrint('⚠️ Too many consecutive setlist fetch attempts ($_fetchSetlistsAttempts). Aborting to prevent infinite loop.');
      // Reset all loading states
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingSetlists = false;
        });
      }
      // Reset the counter after a delay
      Future.delayed(const Duration(seconds: 5), () {
        _fetchSetlistsAttempts = 0;
      });
      return;
    }

    // Increment attempt counter
    _fetchSetlistsAttempts++;

    // Implement aggressive debouncing - don't allow fetches less than 1 second apart
    final now = DateTime.now();
    if (_lastFetchSetlistsStartTime != null) {
      final timeSinceLastFetch = now.difference(_lastFetchSetlistsStartTime!).inMilliseconds;
      if (timeSinceLastFetch < 1000) {
        debugPrint('Debouncing setlists fetch - too soon since last fetch ($timeSinceLastFetch ms)');
        return;
      }
    }
    _lastFetchSetlistsStartTime = now;

    // If we're already fetching, don't start another fetch
    if (_isFetchingSetlists) {
      debugPrint('Already fetching setlists, skipping duplicate fetch');
      return;
    }

    // If we already have setlists and it's not a forced refresh, don't show loading
    bool shouldShowLoading = _setlists.isEmpty || forceRefresh;

    // Check if we need to fetch (if forced or if cache is older than 5 minutes)
    bool shouldFetch = forceRefresh ||
                      _lastFetchTime == null ||
                      DateTime.now().difference(_lastFetchTime!).inMinutes > 5;

    // If we don't need to fetch and have data, return immediately
    if (!shouldFetch && _setlists.isNotEmpty) {
      debugPrint('Using cached setlists, skipping fetch');
      // Reset attempt counter on successful cache use
      _fetchSetlistsAttempts = 0;
      return;
    }

    // Set the flag to indicate we're fetching
    _isFetchingSetlists = true;

    debugPrint('Fetching setlists... (force: $forceRefresh, attempt: $_fetchSetlistsAttempts/$_maxFetchAttempts)');
    if (mounted && shouldShowLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Double-check authentication status with UserProvider
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final isAuthenticated = userProvider.isLoggedIn;

      // Update local login state if needed
      if (_isLoggedIn != isAuthenticated) {
        setState(() {
          _isLoggedIn = isAuthenticated;
        });
      }

      // Only fetch setlists if user is logged in
      if (_isLoggedIn) {
        debugPrint('User is logged in, fetching setlists from service');

        // Get Firebase token to ensure we have a valid token
        try {
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            // Force refresh the token to ensure it's valid
            await firebaseUser.getIdToken(true);
            debugPrint('Firebase token refreshed before fetching setlists');
          } else {
            debugPrint('No Firebase user found, but isLoggedIn is true');
            // This is a mismatch - update login state
            if (mounted) {
              setState(() {
                _isLoggedIn = false;
              });
            }
            return;
          }
        } catch (e) {
          debugPrint('Error refreshing Firebase token: $e');
          // Continue anyway - the API service will handle token issues
        }

        final setlists = await _setlistService.getSetlists();
        debugPrint('Received ${setlists.length} setlists from service');

        if (mounted) {
          setState(() {
            _setlists = setlists;
            _isLoading = false;
            _lastFetchTime = DateTime.now(); // Update last fetch time
          });
          debugPrint('Updated state with ${_setlists.length} setlists');

          // Reset attempt counter on successful fetch
          _fetchSetlistsAttempts = 0;
        }
      } else {
        debugPrint('User is not logged in, clearing setlists');
        if (mounted) {
          setState(() {
            _setlists = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching setlists: $e');
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // If authentication error, check Firebase auth status
        if (e.toString().contains('Authentication required') ||
            (e is DioException && e.response?.statusCode == 401)) {

          // Check Firebase auth status
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            // We have a Firebase user but got auth error - token might be invalid
            // Don't change _isLoggedIn yet, let the user try again
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication issue. Please try again.'),
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            // No Firebase user, definitely not logged in
            setState(() {
              _isLoggedIn = false;
              _setlists = [];
            });
          }
        }
      }
    } finally {
      // Always reset the fetching flag when done, whether successful or not
      _isFetchingSetlists = false;
      debugPrint('Finished fetching setlists (attempt: $_fetchSetlistsAttempts/$_maxFetchAttempts)');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize the last tab index to the current tab
    _lastTabIndex = _tabController.index;

    // Only call _checkLoginStatus() which will call _fetchSetlists() if authenticated
    _checkLoginStatus();

    // Register as an observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Listen for liked songs changes
    _likedSongsNotifier.addListener(_handleLikedSongsChanged);

    // Add listener for tab changes
    _tabController.addListener(_handleTabSelection);

    // Sync with navigation provider and screen state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
      final screenStateProvider = Provider.of<ScreenStateProvider>(context, listen: false);

      navigationProvider.updateIndex(1); // Setlist screen is index 1
      screenStateProvider.navigateToScreen(ScreenType.setlist);
      screenStateProvider.markScreenInitialized(ScreenType.setlist);
    });

    // Load data instantly from global provider cache
    _loadDataInstantly();
  }

  // Track the last time we received a liked songs change notification
  DateTime? _lastLikedSongsChangeTime;

  // Counter to track notification cycles and prevent loops
  int _notificationCounter = 0;

  // Handle liked songs changes with aggressive debouncing and loop prevention
  void _handleLikedSongsChanged() {
    // Increment counter to track potential loops
    _notificationCounter++;

    // If we've received too many notifications in a short time, it's likely a loop
    if (_notificationCounter > 3) {
      debugPrint('⚠️ Potential notification loop detected! Resetting state...');
      _notificationCounter = 0;
      _isLoading = false;
      _isFetchingSetlists = false;
      _isLoadingLikedSongs = false;
      _isFetchingLikedSongs = false;
      return;
    }

    debugPrint('Liked songs changed notification received (count: $_notificationCounter)');

    // Implement aggressive debouncing - don't process notifications less than 2 seconds apart
    final now = DateTime.now();
    if (_lastLikedSongsChangeTime != null) {
      final timeSinceLastChange = now.difference(_lastLikedSongsChangeTime!).inMilliseconds;
      if (timeSinceLastChange < 2000) {
        debugPrint('Debouncing liked songs change - too soon since last change ($timeSinceLastChange ms)');
        return;
      }
    }
    _lastLikedSongsChangeTime = now;

    // Reset counter after successful debounce
    _notificationCounter = 0;

    // Only refresh if we're on the liked songs tab and not already loading
    if (_tabController.index == 1 && !_isFetchingLikedSongs && !_isLoadingLikedSongs) {
      debugPrint('On liked songs tab, updating with latest data');

      // Use a longer delay to ensure any pending operations complete
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // Reset loading state first to ensure clean start
          setState(() {
            _isLoading = false;
            _isFetchingSetlists = false;
            _isLoadingLikedSongs = false;
            _isFetchingLikedSongs = false;
          });

          // Then fetch with a slight additional delay
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && !_isLoadingLikedSongs && !_isFetchingLikedSongs) {
              _fetchLikedSongs(forceRefresh: true);
            }
          });
        }
      });
    } else {
      debugPrint('Not on liked songs tab or already loading, skipping immediate refresh');
    }
  }

  // Track the last tab index to prevent unnecessary refreshes
  int _lastTabIndex = 0;

  // Track the last time we switched tabs to prevent rapid tab changes from causing issues
  DateTime? _lastTabChangeTime;

  void _handleTabSelection() {
    // Only process if the tab is actually changing
    if (_tabController.indexIsChanging) {
      final currentIndex = _tabController.index;

      // Implement debouncing for tab changes
      final now = DateTime.now();
      if (_lastTabChangeTime != null) {
        final timeSinceLastTabChange = now.difference(_lastTabChangeTime!).inMilliseconds;
        if (timeSinceLastTabChange < 500) {
          debugPrint('Debouncing tab change - too soon since last change ($timeSinceLastTabChange ms)');
          return;
        }
      }
      _lastTabChangeTime = now;

      // Only fetch data if we're switching TO a tab, not FROM it
      // This prevents continuous refreshing when already on a tab
      if (currentIndex != _lastTabIndex) {
        debugPrint('Tab changed from $_lastTabIndex to $currentIndex');

        // Reset loading states when switching tabs to prevent stale states
        setState(() {
          _isLoading = false;
          _isFetchingSetlists = false;
          _isLoadingLikedSongs = false;
          _isFetchingLikedSongs = false;
        });

        // If switching to setlists tab and we don't have data yet or it's stale
        if (currentIndex == 0) {
          bool needsRefresh = _setlists.isEmpty ||
                             _lastFetchTime == null ||
                             DateTime.now().difference(_lastFetchTime!).inMinutes > 5;

          if (needsRefresh) {
            debugPrint('Switching to setlists tab, data needs refresh');
            // Add a slight delay to ensure UI has updated before starting fetch
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _tabController.index == 0) {
                _fetchSetlists(forceRefresh: false);
              }
            });
          } else {
            debugPrint('Switching to setlists tab, using cached data');
          }
        }
        // If switching to liked songs tab and we don't have data yet or it's stale
        else if (currentIndex == 1) {
          bool needsRefresh = _likedSongs.isEmpty ||
                             _lastLikedSongsFetchTime == null ||
                             DateTime.now().difference(_lastLikedSongsFetchTime!).inMinutes > 5;

          if (needsRefresh) {
            debugPrint('Switching to liked songs tab, data needs refresh');
            // Add a slight delay to ensure UI has updated before starting fetch
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _tabController.index == 1) {
                _fetchLikedSongs(forceRefresh: false);
              }
            });
          } else {
            debugPrint('Switching to liked songs tab, using cached data');
          }
        }

        // Update the last tab index
        _lastTabIndex = currentIndex;
      }

      // Update UI for tab selection
      setState(() {});
    }
  }

  // Last time liked songs were fetched
  DateTime? _lastLikedSongsFetchTime;

  // Track if we're currently fetching setlists to prevent multiple simultaneous fetches
  bool _isFetchingSetlists = false;

  // Track the last time we started fetching setlists to implement debouncing
  DateTime? _lastFetchSetlistsStartTime;

  // Track if we're currently fetching liked songs to prevent multiple simultaneous fetches
  bool _isFetchingLikedSongs = false;

  // Track the last time we started fetching liked songs to implement debouncing
  DateTime? _lastFetchLikedSongsStartTime;

  // Maximum number of consecutive fetch attempts to prevent infinite loops
  int _fetchSetlistsAttempts = 0;
  int _fetchLikedSongsAttempts = 0;
  static const int _maxFetchAttempts = 3;

  // Track if we've attempted to load data
  bool _hasAttemptedLoadSetlists = false;
  bool _hasAttemptedLoadLikedSongs = false;

  // Keep the state alive when navigating away
  @override
  bool get wantKeepAlive => true;

  // Load data instantly from global provider cache (no loading states)
  void _loadDataInstantly() {
    final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);

    // Get cached data immediately without loading states
    final cachedSetlists = appDataProvider.setlists;
    final cachedLikedSongs = appDataProvider.likedSongs;

    // Set data immediately if available
    if (cachedSetlists.isNotEmpty || cachedLikedSongs.isNotEmpty) {
      setState(() {
        _setlists = cachedSetlists;
        _likedSongs = cachedLikedSongs;
        _isLoading = false;
        _isFetchingSetlists = false;
        _isLoadingLikedSongs = false;
        _isFetchingLikedSongs = false;
        _hasAttemptedLoadSetlists = true;
        _hasAttemptedLoadLikedSongs = true;
      });

      debugPrint('📱 Setlist: Loaded cached data instantly - ${cachedSetlists.length} setlists, ${cachedLikedSongs.length} liked songs');
    } else {
      // If no cached data, fall back to existing loading logic
      debugPrint('📱 Setlist: No cached data, using existing loading logic...');
      setState(() {
        _hasAttemptedLoadSetlists = true;
        _hasAttemptedLoadLikedSongs = true;
      });
      _checkLoginStatus();
    }
  }

  // Fetch liked songs with enhanced caching, aggressive debouncing, and robust error handling
  Future<void> _fetchLikedSongs({bool forceRefresh = false}) async {
    // Safety check: if we've tried too many times in succession, abort to prevent loops
    if (_fetchLikedSongsAttempts >= _maxFetchAttempts) {
      debugPrint('⚠️ Too many consecutive fetch attempts ($_fetchLikedSongsAttempts). Aborting to prevent infinite loop.');
      // Reset all loading states
      if (mounted) {
        setState(() {
          _isLoadingLikedSongs = false;
          _isFetchingLikedSongs = false;
        });
      }
      // Reset the counter after a delay
      Future.delayed(const Duration(seconds: 5), () {
        _fetchLikedSongsAttempts = 0;
      });
      return;
    }

    // Increment attempt counter
    _fetchLikedSongsAttempts++;

    // Implement aggressive debouncing - don't allow fetches less than 1 second apart
    final now = DateTime.now();
    if (_lastFetchLikedSongsStartTime != null) {
      final timeSinceLastFetch = now.difference(_lastFetchLikedSongsStartTime!).inMilliseconds;
      if (timeSinceLastFetch < 1000) {
        debugPrint('Debouncing liked songs fetch - too soon since last fetch ($timeSinceLastFetch ms)');
        return;
      }
    }
    _lastFetchLikedSongsStartTime = now;

    // If we're already fetching, don't start another fetch
    if (_isFetchingLikedSongs) {
      debugPrint('Already fetching liked songs, skipping duplicate fetch');
      return;
    }

    // If we already have liked songs and it's not a forced refresh, don't show loading
    bool shouldShowLoading = _likedSongs.isEmpty || forceRefresh;

    // Check if we need to fetch (if forced or if cache is older than 5 minutes)
    bool shouldFetch = forceRefresh ||
                      _lastLikedSongsFetchTime == null ||
                      DateTime.now().difference(_lastLikedSongsFetchTime!).inMinutes > 5;

    // If we don't need to fetch and have data, return immediately
    if (!shouldFetch && _likedSongs.isNotEmpty) {
      debugPrint('Using cached liked songs, skipping fetch');
      // Reset attempt counter on successful cache use
      _fetchLikedSongsAttempts = 0;
      return;
    }

    // Set the flag to indicate we're fetching
    _isFetchingLikedSongs = true;

    debugPrint('Fetching liked songs... (force: $forceRefresh, attempt: $_fetchLikedSongsAttempts/$_maxFetchAttempts)');
    if (mounted && shouldShowLoading) {
      setState(() {
        _isLoadingLikedSongs = true;
      });
    }

    try {
      // Only fetch liked songs if user is logged in
      if (_isLoggedIn) {
        debugPrint('User is logged in, fetching liked songs from service');

        // Get Firebase token to ensure we have a valid token
        try {
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            // Force refresh the token to ensure it's valid
            await firebaseUser.getIdToken(true);
            debugPrint('Firebase token refreshed before fetching liked songs');
          } else {
            debugPrint('No Firebase user found, but isLoggedIn is true');
            // This is a mismatch - update login state
            if (mounted) {
              setState(() {
                _isLoggedIn = false;
                _isLoadingLikedSongs = false;
              });
            }
            _isFetchingLikedSongs = false;
            return;
          }
        } catch (e) {
          debugPrint('Error refreshing Firebase token: $e');
          // Continue anyway - the API service will handle token issues
        }

        // Use the updated LikedSongsService which syncs with the server
        final likedSongs = await _likedSongsService.getLikedSongs(forceSync: forceRefresh);
        debugPrint('Received ${likedSongs.length} liked songs from service');

        // Check if we're still mounted before updating state
        if (mounted) {
          setState(() {
            _likedSongs = likedSongs;
            _isLoadingLikedSongs = false;
            _lastLikedSongsFetchTime = DateTime.now(); // Update last fetch time
          });
          debugPrint('Updated state with ${_likedSongs.length} liked songs');

          // Reset attempt counter on successful fetch
          _fetchLikedSongsAttempts = 0;
        }
      } else {
        debugPrint('User is not logged in, clearing liked songs');
        if (mounted) {
          setState(() {
            _likedSongs = [];
            _isLoadingLikedSongs = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching liked songs: $e');
      // Make sure we update the loading state even on error
      if (mounted) {
        setState(() {
          _isLoadingLikedSongs = false;
        });
      }
    } finally {
      // Always reset the fetching flag when done, whether successful or not
      _isFetchingLikedSongs = false;
      debugPrint('Finished fetching liked songs (attempt: $_fetchLikedSongsAttempts/$_maxFetchAttempts)');
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Use the UserProvider to check authentication status
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // First check if the provider already knows the user is logged in
      if (userProvider.isLoggedIn) {
        debugPrint('User is already logged in according to UserProvider');
        if (!_isLoggedIn) {
          setState(() {
            _isLoggedIn = true;
          });
          // Fetch data since login status changed
          await _fetchSetlists(forceRefresh: true);
          await _fetchLikedSongs(forceRefresh: true);
        }
        return;
      }

      // If not, check authentication with the server
      final isAuthenticated = await userProvider.isAuthenticated();
      debugPrint('Authentication check result: $isAuthenticated');

      // Only update state if login status changed
      bool loginStatusChanged = _isLoggedIn != isAuthenticated;

      if (loginStatusChanged) {
        setState(() {
          _isLoggedIn = isAuthenticated;
        });
      }

      // If not authenticated, clear any stale data
      if (!isAuthenticated) {
        setState(() {
          _setlists = [];
          _likedSongs = [];
          _lastFetchTime = null; // Reset cache timestamp
        });
      } else {
        // If authenticated, fetch setlists and liked songs
        // Only force refresh if login status changed
        await _fetchSetlists(forceRefresh: loginStatusChanged);
        await _fetchLikedSongs(forceRefresh: loginStatusChanged);
      }

      debugPrint('Login status checked: $_isLoggedIn');
    } catch (e) {
      debugPrint('Error checking login status: $e');

      // Check if widget is still mounted before accessing context
      if (!mounted) {
        debugPrint('Widget no longer mounted, skipping error handling');
        return;
      }

      // Don't automatically set to false on error, check token first
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isLoggedIn) {
        // If provider says we're logged in, trust it
        setState(() {
          _isLoggedIn = true;
        });
        await _fetchSetlists(forceRefresh: false);
        await _fetchLikedSongs(forceRefresh: false);
      } else {
        // Only set to false if provider also says we're not logged in
        setState(() {
          _isLoggedIn = false;
          _setlists = [];
          _lastFetchTime = null; // Reset cache timestamp
        });
      }
    }
  }



  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _likedSongsNotifier.removeListener(_handleLikedSongsChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, refresh data only if it's been a while since the last fetch
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed, checking if data refresh is needed');

      // Check which tab is active
      final currentTab = _tabController.index;

      // Only refresh if it's been more than 5 minutes since the last fetch
      if (currentTab == 0) {
        // Setlist tab
        final shouldRefresh = _lastFetchTime == null ||
                             DateTime.now().difference(_lastFetchTime!).inMinutes > 5;

        if (shouldRefresh) {
          debugPrint('Refreshing setlists after app resume');
          _fetchSetlists(forceRefresh: false);
        } else {
          debugPrint('Skipping setlist refresh, data is recent');
        }
      } else if (currentTab == 1) {
        // Liked songs tab
        final shouldRefresh = _lastLikedSongsFetchTime == null ||
                             DateTime.now().difference(_lastLikedSongsFetchTime!).inMinutes > 5;

        if (shouldRefresh) {
          debugPrint('Refreshing liked songs after app resume');
          _fetchLikedSongs(forceRefresh: false);
        } else {
          debugPrint('Skipping liked songs refresh, data is recent');
        }
      }
    }
  }

  Widget _buildLikedSongsTab() {
    // If not logged in, show login prompt
    if (!_isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please log in to view your liked songs',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Log In'),
            ),
          ],
        ),
      );
    }

    // Create a stack with the content and loading indicator
    return Stack(
      children: [
        // Content (always visible, even when loading)
        _likedSongs.isEmpty && !_isLoadingLikedSongs
            ? (_hasAttemptedLoadLikedSongs
                ? _buildEmptyLikedSongsView()
                : Center(
                    child: Text(
                      'Loading liked songs...',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ))
            : RefreshIndicator(
                onRefresh: () => _fetchLikedSongs(forceRefresh: true),
                color: Theme.of(context).colorScheme.primary,
                child: ListView.builder(
                  // Key helps Flutter identify this list when it needs to be rebuilt
                  key: const PageStorageKey('liked_songs_list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _likedSongs.length + 1, // +1 for the extra space at the bottom
                  itemBuilder: (context, index) {
                    if (index == _likedSongs.length) {
                      // Add extra space at the bottom for better UX
                      return const SizedBox(height: 80);
                    }

                    final song = _likedSongs[index];
                    return _buildLikedSongItem(song);
                  },
                ),
              ),

        // Loading indicator (only visible when loading)
        if (_isLoadingLikedSongs)
          Expanded(
            child: ListView.builder(
              itemCount: 6, // Show 6 skeleton items
              itemBuilder: (context, index) => const SongListItemSkeleton(),
            ),
          ),
      ],
    );
  }

  // Widget for empty liked songs state
  Widget _buildEmptyLikedSongsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No liked songs yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Like songs to add them to this list',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Browse Songs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              // Navigate to search screen
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLikedSongItem(Song song) {
    // Get the song placeholder size
    const double placeholderSize = 48.0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF333333),
            width: 1.0,
          ),
        ),
      ),
      child: ListTile(
        // Reduce vertical padding to decrease space between items
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: SongPlaceholder(size: placeholderSize),
        title: Text(
          song.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          // Ensure text doesn't wrap unnecessarily
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          style: const TextStyle(
            color: Colors.grey,
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
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                song.key,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Unlike button
            IconButton(
              icon: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                // Set isLiked to false before calling the service
                song.isLiked = false;

                // Unlike the song
                final success = await _likedSongsService.unlikeSong(song);
                if (success && mounted) {
                  setState(() {
                    // Remove from liked songs
                    _likedSongs.removeWhere((s) => s.id == song.id);
                  });

                  // Notify other screens about the change
                  _likedSongsNotifier.notifySongLikeChanged(song);

                  // Show feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed "${song.title}" from liked songs'),
                      backgroundColor: Colors.grey,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                } else if (mounted) {
                  // If the operation failed, revert the isLiked state
                  song.isLiked = true;
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
    );
  }



  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Consumer<AppDataProvider>(
      builder: (context, appDataProvider, child) {
        // Auto-update data when global provider has new data
        // Use addPostFrameCallback to avoid calling setState during build
        if ((!_hasAttemptedLoadSetlists && appDataProvider.setlists.isNotEmpty) ||
            (!_hasAttemptedLoadLikedSongs && appDataProvider.likedSongs.isNotEmpty)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadDataInstantly();
            }
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Setlists',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/join-setlist');
              if (result == true) {
                // Refresh setlists after successful join
                _fetchSetlists(forceRefresh: true);
              }
            },
            tooltip: 'Join Setlist',
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAnimatedTabItem('My Setlists', 0),
                  ),
                  Expanded(
                    child: _buildAnimatedTabItem('Liked Songs', 1),
                  ),
                ],
              ),
            ),
          ),

          // Add some spacing
          const SizedBox(height: 16),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // My Setlists Tab
                _buildSetlistsTab(),

                // All Liked Songs Tab
                _buildLikedSongsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
        label: Text(
          'New Setlist',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          // Show dialog to create a new setlist
          _showCreateSetlistDialog();
        },
      ),
        );
      },
    );
  }

  Widget _buildSetlistsTab() {
    // If not logged in, show login prompt
    if (!_isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please log in to view your setlists',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create and manage your setlists after logging in',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // If loading, show skeleton loading
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: 4, // Show 4 skeleton items
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: const SongListItemSkeleton(),
        ),
      );
    }

    // If no setlists, show empty state or loading message
    if (_setlists.isEmpty) {
      if (_hasAttemptedLoadSetlists) {
        return const EmptySetlistState();
      } else {
        return Center(
          child: Text(
            'Loading setlists...',
            style: TextStyle(color: Colors.grey[400]),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () => _fetchSetlists(forceRefresh: true),
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: _setlists.length + 1, // +1 for the extra space at the bottom
          itemBuilder: (context, index) {
            if (index == _setlists.length) {
              // Extra space at the bottom for FAB
              return const SizedBox(height: 100);
            }

            final setlist = _setlists[index];
            return SetlistCard(
              setlist: setlist,
              onTap: () {
                // Navigate to setlist details
                Navigator.pushNamed(
                  context,
                  '/setlist_detail',
                  arguments: {
                    'setlistId': setlist.id,
                    'setlistName': setlist.name,
                  },
                ).then((result) {
                  // Only refresh if something changed (like songs added/removed)
                  if (result == true) {
                    // Force refresh only if explicitly told to
                    _fetchSetlists(forceRefresh: true);
                  }
                });
              },
              onDelete: () => _showDeleteSetlistDialog(setlist.id, setlist.name),
              onEdit: () => _showEditSetlistDialog(setlist),
              onShare: () => _shareSetlist(setlist),
            );
          },
        ),
      ),
    );
  }



  // New animated tab item
  Widget _buildAnimatedTabItem(String title, int index) {
    bool isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }



  void _showCreateSetlistDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CreateSetlistDialog(
          onCreateSetlist: (name, description) async {
            Navigator.of(dialogContext).pop();

            // Show loading indicator
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Creating setlist...'),
                duration: Duration(seconds: 1),
                backgroundColor: Color(0xFF1E1E1E),
              ),
            );

            try {
              // Check if user is logged in first
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              if (!userProvider.isLoggedIn) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Please log in to create setlists'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Proceed with creation
              final createdSetlist = await _setlistService.createSetlist(
                name,
                description: description,
              );

              debugPrint('Created setlist: ${createdSetlist.id} - ${createdSetlist.name}');

              // Refresh setlists with force refresh
              await _fetchSetlists(forceRefresh: true);

              // Show success message
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Setlist "$name" created successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              // Show error message
              if (mounted) {
                // Check if it's an authentication error
                if (e.toString().contains('Authentication required') ||
                    (e is DioException && e.response?.statusCode == 401)) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to create setlists'),
                      backgroundColor: Colors.red,
                    ),
                  );

                  // Don't automatically log out or redirect
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to create setlist: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
        );
      },
    );
  }

  void _showDeleteSetlistDialog(String setlistId, String setlistName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with warning icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Delete Setlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Warning message
                Text(
                  'Are you sure you want to delete "$setlistName"?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone and all songs in this setlist will be removed.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel button
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[400],
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),

                    // Delete button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();

                        // Show loading indicator
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Deleting setlist...'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Color(0xFF1E1E1E),
                          ),
                        );

                        try {
                          // Check if user is logged in first
                          final userProvider = Provider.of<UserProvider>(context, listen: false);
                          if (!userProvider.isLoggedIn) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please log in to delete setlists'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Proceed with deletion
                          await _setlistService.deleteSetlist(setlistId);

                          // Refresh setlists with force refresh
                          await _fetchSetlists(forceRefresh: true);

                          // Show success message
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Setlist "$setlistName" deleted successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          // Show error message
                          if (mounted) {
                            // Check if it's an authentication error
                            if (e.toString().contains('Authentication required') ||
                                (e is DioException && e.response?.statusCode == 401)) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Please log in to delete setlists'),
                                  backgroundColor: Colors.red,
                                ),
                              );

                              // Don't automatically log out or redirect
                            } else {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete setlist: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to show edit setlist dialog
  void _showEditSetlistDialog(Setlist setlist) {
    // Create text editing controllers with initial values
    final nameController = TextEditingController(text: setlist.name);
    final descriptionController = TextEditingController(text: setlist.description ?? '');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with edit icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Edit Setlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name field
                const Text(
                  'Name',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter setlist name',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Description field
                const Text(
                  'Description (Optional)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter setlist description',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel button
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[400],
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),

                    // Save button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        // Validate input
                        final name = nameController.text.trim();
                        final description = descriptionController.text.trim();

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a setlist name'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.of(dialogContext).pop();

                        // Show loading indicator
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Updating setlist...'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Color(0xFF1E1E1E),
                          ),
                        );

                        try {
                          // Check if user is logged in first
                          final userProvider = Provider.of<UserProvider>(context, listen: false);
                          if (!userProvider.isLoggedIn) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please log in to edit setlists'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Proceed with update
                          await _setlistService.updateSetlist(
                            setlist.id,
                            name,
                            description: description.isNotEmpty ? description : null,
                          );

                          // Refresh setlists with force refresh
                          await _fetchSetlists(forceRefresh: true);

                          // Show success message
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Setlist "$name" updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          // Show error message
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setlist: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to share setlist
  void _shareSetlist(Setlist setlist) {
    showDialog(
      context: context,
      builder: (context) => EnhancedSetlistShareDialog(
        setlist: setlist,
        onSetlistUpdated: () {
          // Refresh setlists after sharing
          _fetchSetlists(forceRefresh: true);
        },
      ),
    );
  }
}