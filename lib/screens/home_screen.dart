import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/ad_service.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_drawer.dart';
import '../providers/user_provider.dart';
import '../services/collection_service.dart';
import '../models/collection.dart';
import '../services/song_service.dart';
import '../models/song.dart';
import '../services/artist_service.dart';
import '../models/artist.dart';
import '../widgets/sliding_banner.dart';
import '../services/notification_service.dart';
import '../services/home_section_service.dart';
import './list_screen.dart';

class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({super.key});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> with WidgetsBindingObserver {

  // Services
  final CollectionService _collectionService = CollectionService();
  final SongService _songService = SongService();
  final ArtistService _artistService = ArtistService();
  final HomeSectionService _homeSectionService = HomeSectionService();
  final AdService _adService = AdService();

  // Data
  List<HomeSection> _homeSections = [];
  List<Collection> _seasonalCollections = [];
  List<Collection> _beginnerFriendlyCollections = [];
  List<Song> _trendingSongs = [];
  List<Artist> _topArtists = [];
  List<Song> _newSongs = [];
  int _unreadNotificationCount = 0;

  // Loading states
  bool _isLoadingHomeSections = true;
  bool _isLoadingSeasonalCollections = true;
  bool _isLoadingBeginnerCollections = true;
  bool _isLoadingTrendingSongs = true;
  bool _isLoadingTopArtists = true;
  bool _isLoadingNewSongs = true;
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    // Register this object as an observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Check login state after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginState();

      // Sync with navigation provider
      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
      navigationProvider.updateIndex(0); // Home screen is index 0

      // Clear image cache to ensure fresh images
      _clearImageCache();

      // Check if app was recently opened (within last 5 seconds)
      // This helps identify app startup vs normal navigation
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastOpenTime = _getLastOpenTime();
      final timeSinceLastOpen = now - lastOpenTime;

      if (timeSinceLastOpen > 5000) { // More than 5 seconds since last open
        debugPrint('App was reopened after ${timeSinceLastOpen}ms, refreshing data...');
        // Force refresh on app reopen
        _fetchHomeSections(forceRefresh: true);
      } else {
        debugPrint('Normal navigation to home screen, using cached data if available');
        _fetchHomeSections();
      }

      // Save current time as last open time
      _saveLastOpenTime(now);
    });

    // Load dynamic home sections first (will use cache initially)
    _fetchHomeSections();

    // Also load traditional sections as fallback
    _fetchSeasonalCollections();
    _fetchBeginnerFriendlyCollections();
    _fetchTrendingSongs();
    _fetchTopArtists();
    _fetchNewSongs();
    _fetchUnreadNotificationCount();
  }

  @override
  void dispose() {
    // Unregister this object as an observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in the foreground and visible to the user
        debugPrint('App resumed - refreshing data');
        _fetchHomeSections(forceRefresh: true);
        break;
      case AppLifecycleState.inactive:
        // App is inactive, might be entering background
        debugPrint('App inactive');
        break;
      case AppLifecycleState.paused:
        // App is in the background
        debugPrint('App paused - saving state');
        // Save any important state here
        break;
      case AppLifecycleState.detached:
        // App is detached (terminated)
        debugPrint('App detached - clearing cache');
        _clearCache();
        break;
      default:
        break;
    }
  }

  // Clear all caches when app is closed
  void _clearCache() {
    try {
      // Clear image cache
      _clearImageCache();

      // Clear other caches if needed
      // This is a good place to clear any temporary data
      debugPrint('Cleared all caches on app close');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Clear the image cache to ensure fresh images
  void _clearImageCache() {
    try {
      // Clear the CachedNetworkImage cache
      DefaultCacheManager().emptyCache();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      debugPrint('Cleared image cache to ensure fresh images');
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  // Fetch unread notification count
  Future<void> _fetchUnreadNotificationCount() async {
    try {
      setState(() {
        _isLoadingNotifications = true;
      });

      final NotificationService notificationService = NotificationService();
      final count = await notificationService.getUnreadNotificationCount();

      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching unread notification count: $e');
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }

  // Fetch seasonal collections
  Future<void> _fetchSeasonalCollections() async {
    try {
      final collections = await _collectionService.getSeasonalCollections(limit: 10);
      if (mounted) {
        setState(() {
          _seasonalCollections = collections;
          _isLoadingSeasonalCollections = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching seasonal collections: $e');
      if (mounted) {
        setState(() {
          _isLoadingSeasonalCollections = false;
        });
      }
    }
  }

  // Fetch beginner friendly collections
  Future<void> _fetchBeginnerFriendlyCollections() async {
    try {
      final collections = await _collectionService.getBeginnerFriendlyCollections(limit: 10);
      if (mounted) {
        setState(() {
          _beginnerFriendlyCollections = collections;
          _isLoadingBeginnerCollections = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching beginner friendly collections: $e');
      if (mounted) {
        setState(() {
          _isLoadingBeginnerCollections = false;
        });
      }
    }
  }

  // Fetch trending songs
  Future<void> _fetchTrendingSongs() async {
    try {
      // In a real implementation, you would have an API endpoint for trending songs
      // For now, we'll just get all songs and limit to 10
      final songs = await _songService.getAllSongs();
      // Log image URLs for debugging
      for (var song in songs.take(10)) {
        debugPrint('Song: ${song.title}, Image URL: ${song.imageUrl}');
      }

      if (mounted) {
        setState(() {
          _trendingSongs = songs.take(10).toList();
          _isLoadingTrendingSongs = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching trending songs: $e');
      if (mounted) {
        setState(() {
          _isLoadingTrendingSongs = false;
        });
      }
    }
  }

  // Fetch top artists
  Future<void> _fetchTopArtists() async {
    try {
      // First try to get cached artists to show something quickly
      List<Artist> artists = [];

      try {
        // Get cached artists first for quick display
        artists = await _artistService.getAllArtists();

        if (mounted && artists.isNotEmpty) {
          setState(() {
            _topArtists = artists.take(10).toList();
            // Keep loading state true as we'll refresh from API
          });
        }
      } catch (cacheError) {
        debugPrint('Error fetching cached artists: $cacheError');
        // Continue to fetch from API
      }

      // Then force a refresh from the API to get the latest data
      artists = await _artistService.getAllArtists(forceRefresh: true);

      // Log artist data for debugging
      debugPrint('Fetched ${artists.length} artists from API');
      for (var artist in artists.take(10)) {
        debugPrint('Artist after refresh: ${artist.name}, Image URL: ${artist.imageUrl}');
      }

      if (mounted) {
        setState(() {
          _topArtists = artists.take(10).toList();
          _isLoadingTopArtists = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching top artists: $e');
      if (mounted) {
        setState(() {
          _isLoadingTopArtists = false;
        });
      }
    }
  }

  // Fetch new songs
  Future<void> _fetchNewSongs() async {
    try {
      // In a real implementation, you would have an API endpoint for new songs
      // For now, we'll just get all songs, sort by date, and limit to 10
      final songs = await _songService.getAllSongs();
      if (mounted) {
        setState(() {
          _newSongs = songs.take(10).toList();
          _isLoadingNewSongs = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching new songs: $e');
      if (mounted) {
        setState(() {
          _isLoadingNewSongs = false;
        });
      }
    }
  }

  // Get the last time the app was opened from shared preferences
  int _getLastOpenTime() {
    try {
      // Use shared preferences to get the last open time
      // For simplicity, we're using a static variable here
      // In a real app, you would use SharedPreferences
      return _HomeScreenNewState._lastOpenTime;
    } catch (e) {
      debugPrint('Error getting last open time: $e');
      return 0; // Default to 0 if not found
    }
  }

  // Save the current time as the last open time
  void _saveLastOpenTime(int timestamp) {
    try {
      // Use shared preferences to save the last open time
      // For simplicity, we're using a static variable here
      // In a real app, you would use SharedPreferences
      _HomeScreenNewState._lastOpenTime = timestamp;
    } catch (e) {
      debugPrint('Error saving last open time: $e');
    }
  }

  // Static variable to store last open time
  // In a real app, you would use SharedPreferences instead
  static int _lastOpenTime = 0;

  // Fetch dynamic home sections
  Future<void> _fetchHomeSections({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoadingHomeSections = true;
      });

      final sections = await _homeSectionService.getHomeSections(forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _homeSections = sections;
          _isLoadingHomeSections = false;
        });

        debugPrint('Fetched ${sections.length} dynamic home sections');
      }
    } catch (e) {
      debugPrint('Error fetching home sections: $e');
      if (mounted) {
        setState(() {
          _isLoadingHomeSections = false;
        });
      }
    }
  }

  Future<void> _checkLoginState() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Add a timeout to prevent getting stuck
    try {
      await Future.any([
        userProvider.isAuthenticated(),
        Future.delayed(const Duration(seconds: 3), () {
          debugPrint('Authentication check timed out, proceeding anyway');
          throw Exception('Authentication check timeout');
        }),
      ]);
    } catch (e) {
      debugPrint('Error checking login state: $e');
      // Continue with the app even if authentication check fails
    }

    // If you want to force login, uncomment the next lines
    if (!userProvider.isLoggedIn) {
      debugPrint('User is not logged in, but not forcing login');
      // Uncomment to force login
      // Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Helper method to create a color with opacity without using withOpacity
  Color _getColorWithOpacity(Color color, double opacity) {
    // For now, we'll use withOpacity but suppress the warning
    // This is a temporary solution until we can properly implement it
    // ignore: deprecated_member_use
    return color.withOpacity(opacity);
  }

  // Navigate to the appropriate list screen based on the section title and type
  void _navigateToSeeMore(String sectionTitle, {SectionType? sectionType}) {
    // If we have a section type from a dynamic section, use it to determine the list type
    if (sectionType != null) {
      ListType listType;
      String? filterType;

      switch (sectionType) {
        case SectionType.COLLECTIONS:
          listType = ListType.collections;
          break;
        case SectionType.SONGS:
          listType = ListType.songs;
          break;
        case SectionType.ARTISTS:
          listType = ListType.artists;
          break;
        case SectionType.BANNER:
          // For banner sections, default to songs
          listType = ListType.songs;
          break;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ListScreen(
            title: sectionTitle,
            listType: listType,
            filterType: filterType,
          ),
        ),
      );
      return;
    }

    // For traditional hardcoded sections, use the title to determine the list type
    switch (sectionTitle) {
      case 'Seasonal Collections':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ListScreen(
              title: 'Seasonal Collections',
              listType: ListType.collections,
              filterType: 'seasonal',
            ),
          ),
        );
        break;
      case 'Trending Song Chords':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ListScreen(
              title: 'Trending Song Chords',
              listType: ListType.songs,
              filterType: 'trending',
            ),
          ),
        );
        break;
      case 'Beginner Friendly':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ListScreen(
              title: 'Beginner Friendly',
              listType: ListType.collections,
              filterType: 'beginner',
            ),
          ),
        );
        break;
      case 'Top Artist of the Month':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ListScreen(
              title: 'Top Artists',
              listType: ListType.artists,
              filterType: 'top',
            ),
          ),
        );
        break;
      case 'Discover new songs':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ListScreen(
              title: 'New Songs',
              listType: ListType.songs,
              filterType: 'new',
            ),
          ),
        );
        break;
      default:
        // Default case for any other section titles
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListScreen(
              title: sectionTitle,
              listType: ListType.songs,
            ),
          ),
        );
        break;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        title: const Text(
          'Worship Paradise',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/notifications',
                  ).then((_) {
                    // Refresh notification count when returning from notification screen
                    _fetchUnreadNotificationCount();
                  });
                },
              ),
              if (_isLoadingNotifications)
                Positioned(
                  right: 8,
                  top: 8,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              else if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Banner - Auto Sliding
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 4.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: SlidingBanner(
                  autoSlideDuration: const Duration(seconds: 5),
                  items: [
                    BannerItem(
                      imagePath: 'assets/images/banner1.jpg',
                      onTap: () {
                        // Navigate to featured content
                        debugPrint('Banner 1 tapped');
                      },
                    ),
                    BannerItem(
                      imagePath: 'assets/images/banner2.jpg',
                      onTap: () {
                        // Navigate to event details
                        debugPrint('Banner 2 tapped');
                      },
                    ),
                    BannerItem(
                      imagePath: 'assets/images/banner3.jpg',
                      onTap: () {
                        // Navigate to top songs
                        debugPrint('Banner 3 tapped');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Add extra space after the top banner
            const SizedBox(height: 32.0), // Increased for consistent spacing

            // Dynamic Home Sections
            if (_isLoadingHomeSections)
              _buildLoadingIndicator()
            else if (_homeSections.isEmpty)
              ...[
                // Fallback to traditional sections if no dynamic sections are available
                // Seasonal Collections
                _buildSectionHeader('Seasonal Collections', sectionType: SectionType.COLLECTIONS),
                _isLoadingSeasonalCollections
                  ? _buildLoadingIndicator()
                  : _seasonalCollections.isEmpty
                    ? _buildEmptyState('No seasonal collections available')
                    : _buildHorizontalScrollSection(
                        _seasonalCollections.map((collection) =>
                          _buildCollectionItem(
                            collection.title,
                            collection.color,
                            collection: collection,
                          )
                        ).toList(),
                      ),

                // Trending Song Chords
                _buildSectionHeader('Trending Song Chords', sectionType: SectionType.SONGS),
                _isLoadingTrendingSongs
                  ? _buildLoadingIndicator()
                  : _trendingSongs.isEmpty
                    ? _buildEmptyState('No trending songs available')
                    : _buildHorizontalScrollSection(
                        _trendingSongs.map((song) =>
                          _buildSongItem(
                            song.title,
                            _getRandomColor(),
                            song: song,
                          )
                        ).toList(),
                      ),

                // Beginner Friendly
                _buildSectionHeader('Beginner Friendly', sectionType: SectionType.COLLECTIONS),
                _isLoadingBeginnerCollections
                  ? _buildLoadingIndicator()
                  : _beginnerFriendlyCollections.isEmpty
                    ? _buildEmptyState('No beginner friendly collections available')
                    : _buildHorizontalScrollSection(
                        _beginnerFriendlyCollections.map((collection) =>
                          _buildCollectionItem(
                            collection.title,
                            collection.color,
                            collection: collection,
                          )
                        ).toList(),
                      ),

                // Top Artist of the Month
                _buildSectionHeader('Top Artist of the Month', sectionType: SectionType.ARTISTS),
                _isLoadingTopArtists
                  ? _buildLoadingIndicator()
                  : _topArtists.isEmpty
                    ? _buildEmptyState('No top artists available')
                    : _buildHorizontalScrollSection(
                        _topArtists.map((artist) =>
                          _buildArtistItem(
                            artist.name,
                            _getRandomColor(),
                            artist: artist,
                          )
                        ).toList(),
                      ),

                // Discover new songs
                _buildSectionHeader('Discover new songs', sectionType: SectionType.SONGS),
                _isLoadingNewSongs
                  ? _buildLoadingIndicator()
                  : _newSongs.isEmpty
                    ? _buildEmptyState('No new songs available')
                    : _buildHorizontalScrollSection(
                        _newSongs.map((song) =>
                          _buildSongItem(
                            song.title,
                            _getRandomColor(),
                            song: song,
                          )
                        ).toList(),
                      ),
              ]
            else
              // Render dynamic sections
              for (var section in _homeSections)
                if (section.isActive != false) // Skip inactive sections
                  ...[
                    // For banner sections, don't show header with title and "See more"
                    if (section.type == SectionType.BANNER)
                      _buildBannerSection(section)
                    else
                      ...[
                        _buildSectionHeader(section.title, sectionType: section.type),
                        _buildSectionContent(section),
                      ],
                  ],

            // Support Us section
            _buildSupportUsSection(),

            // Banner ad (only shown if user hasn't removed ads)
            if (!_adService.isAdFree) ...[
              const SizedBox(height: 16),
              const Center(child: BannerAdWidget()),
            ],

            // Extra space at bottom to ensure all content is visible above bottom nav bar
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {SectionType? sectionType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add top padding to create consistent spacing between sections
        const SizedBox(height: 8.0),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    color: Theme.of(context).colorScheme.primary,
                    margin: const EdgeInsets.only(right: 8.0),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to the appropriate list screen based on the section title and type
                  _navigateToSeeMore(title, sectionType: sectionType);
                },
                child: Text(
                  'See more',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14),
                ),
              ),
            ],
          ),
        ),

        // Add consistent spacing between section header and content
        const SizedBox(height: 12.0), // Adjusted for consistent spacing
      ],
    );
  }

  Widget _buildHorizontalScrollSection(List<Widget> items) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120, // Minimum height for content
        maxHeight: 170, // Maximum height for content
      ),
      height: 140, // Default height
      margin: const EdgeInsets.only(top: 0.0, bottom: 24.0), // Increased bottom margin for more space between sections
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        children: items,
      ),
    );
  }



  Widget _buildLoadingIndicator() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120, // Minimum height to match horizontal scroll section
        maxHeight: 170, // Maximum height to match horizontal scroll section
      ),
      height: 140, // Default height to match horizontal scroll section
      margin: const EdgeInsets.only(top: 0.0, bottom: 24.0), // Increased bottom margin to match horizontal scroll section
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120, // Minimum height to match horizontal scroll section
        maxHeight: 170, // Maximum height to match horizontal scroll section
      ),
      height: 140, // Default height to match horizontal scroll section
      margin: const EdgeInsets.only(top: 0.0, bottom: 24.0), // Increased bottom margin to match horizontal scroll section
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[400]),
        ),
      ),
    );
  }

  Color _getRandomColor() {
    // List of predefined colors
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];

    // Return a random color from the list
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }

  Widget _buildCollectionItem(String title, Color color, {Collection? collection}) {
    return GestureDetector(
      onTap: () {
        if (collection != null) {
          Navigator.pushNamed(
            context,
            '/collection_detail',
            arguments: {
              'collectionName': collection.title,
              'collectionId': collection.id,
            },
          );
        }
      },
      child: Container(
        width: 260, // Optimal width for rectangular collection items
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: AspectRatio(
          aspectRatio: 16/9, // 16:9 aspect ratio
          child: Container(
            decoration: BoxDecoration(
              color: _getColorWithOpacity(color, 0.3),
              borderRadius: BorderRadius.circular(8.0),
              // No gradient overlay to keep image clear
            ),
            child: collection?.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: collection!.imageUrl!,
                    fit: BoxFit.cover,
                    // Use these settings for better image loading
                    fadeInDuration: const Duration(milliseconds: 300),
                    // Add a cache key with timestamp to force refresh
                    cacheKey: '${collection.imageUrl}_${DateTime.now().day}',
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      debugPrint('Error loading collection image: ${collection.title} - $url');
                      debugPrint('Error details: $error');

                      // Try to refresh the image by adding a timestamp to the URL
                      final timestamp = DateTime.now().millisecondsSinceEpoch;
                      final refreshedUrl = '$url?t=$timestamp';

                      // Return a new CachedNetworkImage with the refreshed URL
                      return CachedNetworkImage(
                        imageUrl: refreshedUrl,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 300),
                        // Force network request with a unique cache key
                        cacheKey: '${refreshedUrl}_retry_$timestamp',
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          // If still failing, show fallback icon
                          return Center(
                            child: Icon(
                              Icons.collections_bookmark,
                              color: Colors.white,
                              size: 40,
                            ),
                          );
                        },
                      );
                    },
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.collections_bookmark,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongItem(String title, Color color, {Song? song}) {
    return GestureDetector(
      onTap: () {
        if (song != null) {
          Navigator.pushNamed(
            context,
            '/song_detail',
            arguments: song,
          );
        }
      },
      child: Container(
        width: 100, // Fixed width for song items
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available height for the image and text
            final availableHeight = constraints.maxHeight;
            // Reserve about 18% of height for text to accommodate larger font
            final textHeight = (availableHeight * 0.18).clamp(16.0, 22.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Song image with square aspect ratio
                AspectRatio(
                  aspectRatio: 1, // Square aspect ratio for song images
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getColorWithOpacity(color, 0.3),
                      borderRadius: BorderRadius.circular(8.0),
                      // Fallback gradient if no image is available
                      gradient: song?.imageUrl == null ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getColorWithOpacity(color, 0.7),
                          Color.fromRGBO(0, 0, 0, 0.9), // Black with opacity
                        ],
                      ) : null,
                    ),
                    child: song?.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: CachedNetworkImage(
                            imageUrl: song!.imageUrl!,
                            fit: BoxFit.cover,
                            // Use these settings for better image loading
                            fadeInDuration: const Duration(milliseconds: 300),
                            // Add a cache key with timestamp to force refresh
                            cacheKey: '${song.imageUrl}_${DateTime.now().day}',
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              debugPrint('Error loading song image: ${song.title} - $url');
                              debugPrint('Error details: $error');

                              // Try to refresh the image by adding a timestamp to the URL
                              final timestamp = DateTime.now().millisecondsSinceEpoch;
                              final refreshedUrl = '$url?t=$timestamp';

                              // Return a new CachedNetworkImage with the refreshed URL
                              return CachedNetworkImage(
                                imageUrl: refreshedUrl,
                                fit: BoxFit.cover,
                                fadeInDuration: const Duration(milliseconds: 300),
                                // Force network request with a unique cache key
                                cacheKey: '${refreshedUrl}_retry_$timestamp',
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  // If still failing, show fallback icon
                                  return Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 40,
                                  );
                                },
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                  ),
                ),

                // Add spacing between image and text
                const SizedBox(height: 10.0),

                // Title
                SizedBox(
                  height: textHeight,
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 14), // Increased font size
                    maxLines: 1, // Only one line to save space
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildArtistItem(String name, Color color, {Artist? artist}) {
    return GestureDetector(
      onTap: () {
        if (artist != null) {
          Navigator.pushNamed(
            context,
            '/artist_detail',
            arguments: {
              'artistName': artist.name,
            },
          );
        }
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available height for the image and text
            final availableHeight = constraints.maxHeight;
            // Reserve about 20% of height for text with increased spacing
            final textHeight = (availableHeight * 0.2).clamp(16.0, 25.0);
            // Adjust image size to account for the added spacing
            final imageSize = ((availableHeight - textHeight - 4.0) * 0.9).clamp(50.0, 80.0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Placeholder for artist image (circular)
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getColorWithOpacity(color, 0.3),
                    gradient: RadialGradient(
                      colors: [color, Colors.black],
                      stops: const [0.5, 1.0],
                    ),
                    // No image here, we'll use a child instead
                  ),
                  child: artist?.imageUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: artist!.imageUrl!,
                            fit: BoxFit.cover,
                            width: imageSize,
                            height: imageSize,
                            // Use these settings for better image loading
                            fadeInDuration: const Duration(milliseconds: 300),
                            // Add a cache key with timestamp to force refresh
                            cacheKey: '${artist.imageUrl}_${DateTime.now().day}',
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              debugPrint('Error loading artist image: ${artist.name} - $url');
                              debugPrint('Error details: $error');

                              // Try to refresh the image by adding a timestamp to the URL
                              // This forces a network fetch instead of using cache
                              final timestamp = DateTime.now().millisecondsSinceEpoch;
                              final refreshedUrl = '$url?t=$timestamp';

                              // Return a new CachedNetworkImage with the refreshed URL
                              return CachedNetworkImage(
                                imageUrl: refreshedUrl,
                                fit: BoxFit.cover,
                                width: imageSize,
                                height: imageSize,
                                fadeInDuration: const Duration(milliseconds: 300),
                                // Force network request with a unique cache key
                                cacheKey: '${refreshedUrl}_retry_$timestamp',
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  // If still failing, show fallback icon
                                  return Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: imageSize * 0.5,
                                  );
                                },
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.white,
                          size: imageSize * 0.5, // Responsive icon size
                        ),
                ),

                // Add spacing between image and text
                const SizedBox(height: 10.0),

                // Name
                SizedBox(
                  height: textHeight,
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 14), // Increased font size
                    textAlign: TextAlign.center,
                    maxLines: 1, // Only one line to save space
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Build banner section without header and "See more"
  Widget _buildBannerSection(HomeSection section) {
    if (section.items.isEmpty) {
      return _buildEmptyState('No banner items available');
    }

    // Create banner items from the section items
    List<BannerItem> bannerItems = [];

    for (var item in section.items) {
      // Check if the item has an imageUrl property
      String? imageUrl;
      Function? onTap;

      if (item is Map<String, dynamic>) {
        imageUrl = item['imageUrl'];

        // If there's a targetId and targetType, create an onTap function
        if (item['targetId'] != null && item['targetType'] != null) {
          final targetId = item['targetId'];
          final targetType = item['targetType'];

          onTap = () {
            // Navigate based on target type
            switch (targetType) {
              case 'SONG':
                Navigator.pushNamed(
                  context,
                  '/song_detail',
                  arguments: {'songId': targetId},
                );
                break;
              case 'COLLECTION':
                Navigator.pushNamed(
                  context,
                  '/collection_detail',
                  arguments: {
                    'collectionId': targetId,
                  },
                );
                break;
              case 'ARTIST':
                Navigator.pushNamed(
                  context,
                  '/artist_detail',
                  arguments: {
                    'artistId': targetId,
                  },
                );
                break;
              default:
                debugPrint('Unknown target type: $targetType');
            }
          };
        }
      }

      // If we have an image URL, create a banner item
      if (imageUrl != null) {
        bannerItems.add(
          BannerItem(
            imageUrl: imageUrl,
            onTap: onTap as void Function()? ?? () {
              debugPrint('Banner item tapped, but no target specified');
            },
          ),
        );
      }
    }

    // If we couldn't create any banner items, show a placeholder
    if (bannerItems.isEmpty) {
      return _buildEmptyState('No valid banner items available');
    }

    // Return a sliding banner with the items
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 32.0), // Increased bottom padding for more space after banner
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SlidingBanner(
          autoSlideDuration: const Duration(seconds: 5),
          items: bannerItems,
        ),
      ),
    );
  }

  // Build a modern, minimal support section
  Widget _buildSupportUsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
      child: Container(
        decoration: BoxDecoration(
          // Very subtle gradient background
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(15),
              Theme.of(context).colorScheme.primary.withAlpha(5),
            ],
          ),
          borderRadius: BorderRadius.circular(16.0),
          // Thin border with primary color
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha(50),
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Simple row with heart icon and title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Free Forever',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              const Text(
                'Worship Paradise is and will always be free for everyone. If you find value in our app, consider supporting us to help with server costs and new features.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Minimal support button
              OutlinedButton(
                onPressed: () {
                  // Show support options
                  debugPrint('Support button tapped');
                  _showSupportOptions();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Support Us',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show support options dialog
  void _showSupportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Support Options',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),

            // Support options list
            ...[
              _buildSupportOption(
                icon: Icons.payments_outlined,
                title: 'Financial Support',
                description: 'Donate via various payment methods',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/support');
                },
              ),
              _buildSupportOption(
                icon: Icons.star,
                title: 'Rate the app',
                description: 'Help others find us',
                onTap: () {
                  Navigator.pop(context);
                  _launchAppStore();
                },
              ),
              _buildSupportOption(
                icon: Icons.share,
                title: 'Share with friends',
                description: 'Spread the word',
                onTap: () {
                  Navigator.pop(context);
                  _shareApp();
                },
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Launch app store for rating
  void _launchAppStore() {
    // For Android
    const playStoreUrl = 'market://details?id=com.worshipparadise.chords';
    // For iOS
    const appStoreUrl = 'https://apps.apple.com/app/worship-paradise/id123456789';

    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication);
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        launchUrl(Uri.parse(appStoreUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch store: $e');
      // Fallback to web URL if app store doesn't open
      launchUrl(
        Uri.parse('https://worshipparadise.com/app'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // Share app with others
  void _shareApp() {
    // Use URL launcher to open a share intent
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.worshipparadise.chords'
    );
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // Build a support option item
  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }

  // Build section content based on section type
  Widget _buildSectionContent(HomeSection section) {
    switch (section.type) {
      case SectionType.COLLECTIONS:
        return section.items.isEmpty
          ? _buildEmptyState('No collections available')
          : _buildHorizontalScrollSection(
              section.items.map((collection) =>
                _buildCollectionItem(
                  collection.title,
                  collection.color,
                  collection: collection,
                )
              ).toList(),
            );

      case SectionType.SONGS:
        return section.items.isEmpty
          ? _buildEmptyState('No songs available')
          : _buildHorizontalScrollSection(
              section.items.map((song) =>
                _buildSongItem(
                  song.title,
                  _getRandomColor(),
                  song: song,
                )
              ).toList(),
            );

      case SectionType.ARTISTS:
        return section.items.isEmpty
          ? _buildEmptyState('No artists available')
          : _buildHorizontalScrollSection(
              section.items.map((artist) =>
                _buildArtistItem(
                  artist.name,
                  _getRandomColor(),
                  artist: artist,
                )
              ).toList(),
            );

      case SectionType.BANNER:
        // Banner sections are now handled by _buildBannerSection
        return _buildEmptyState('Banner section (should not be shown here)');
    }
  }
}
