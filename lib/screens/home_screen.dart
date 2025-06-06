import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/navigation_provider.dart';
import '../providers/app_data_provider.dart';
import '../providers/screen_state_provider.dart';
import '../widgets/app_drawer.dart';
import '../providers/user_provider.dart';
import '../models/collection.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../widgets/sliding_banner.dart';
import '../widgets/memory_efficient_image.dart';
import '../widgets/skeleton_loader.dart';
import '../services/notification_service.dart';
import '../services/cache_service.dart';
import '../services/home_section_service.dart';
import '../core/service_locator.dart';
import '../config/theme.dart';
import './list_screen.dart';
import '../widgets/connectivity_status_widget.dart';
import '../services/connectivity_service.dart';

class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({super.key});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew>
    with WidgetsBindingObserver {
  // Services
  // AdService removed to fix crashing issues
  // final AdService _adService = AdService();

  // Data
  List<HomeSection> _homeSections = [];
  int _unreadNotificationCount = 0;

  // Loading states
  bool _isLoadingHomeSections = true;
  bool _isLoadingNotifications = true;

  // Track if data is already loaded to prevent unnecessary refreshes
  bool _dataInitiallyLoaded = false; // Can't be final as we need to update it

  // Track the last time data was refreshed to prevent frequent refreshes
  int _lastRefreshTime = 0;

  // Minimum time between refreshes in milliseconds (5 minutes)
  static const int _minRefreshInterval = 5 * 60 * 1000;

  @override
  void initState() {
    super.initState();
    // Register this object as an observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Listen to AppDataProvider changes for automatic updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appDataProvider = Provider.of<AppDataProvider>(
        context,
        listen: false,
      );
      appDataProvider.addListener(_onAppDataProviderChanged);
    });

    // Check login state after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginState();

      // Sync with navigation provider and screen state
      final navigationProvider = Provider.of<NavigationProvider>(
        context,
        listen: false,
      );
      final screenStateProvider = Provider.of<ScreenStateProvider>(
        context,
        listen: false,
      );

      navigationProvider.updateIndex(0); // Home screen is index 0
      screenStateProvider.navigateToScreen(ScreenType.home);
      screenStateProvider.markScreenInitialized(ScreenType.home);

      // Complete notification setup now that user is on home screen
      _completeNotificationSetup();

      // Check if we already have data from AppDataProvider
      final appDataProvider = Provider.of<AppDataProvider>(
        context,
        listen: false,
      );

      if (appDataProvider.homeSections.isNotEmpty &&
          appDataProvider.homeState == DataState.loaded) {
        // Use existing data from AppDataProvider
        debugPrint(
          'Home: Using existing data from AppDataProvider (${appDataProvider.homeSections.length} sections)',
        );
        setState(() {
          _homeSections = appDataProvider.homeSections;
          _isLoadingHomeSections = false;
          _dataInitiallyLoaded = true;
          _lastRefreshTime = DateTime.now().millisecondsSinceEpoch;
        });

        // Check if background refresh is needed
        _checkForBackgroundRefresh();
      } else if (!_dataInitiallyLoaded) {
        // Only load data if we don't have it yet
        debugPrint('Home: No existing data, loading from cache/API...');

        // Clear image cache only on first load
        _clearImageCache();

        // Initialize app data if needed
        if (appDataProvider.homeState == DataState.loading &&
            appDataProvider.homeSections.isEmpty) {
          debugPrint('Home: App data not initialized, initializing now...');
          appDataProvider.initializeAfterLogin().catchError((e) {
            debugPrint('Error initializing app data from home screen: $e');
          });
        }

        // Load home sections
        _fetchHomeSections();
      } else {
        debugPrint('Home: Data already loaded, skipping refresh');
        _checkForBackgroundRefresh();
      }
    });

    // Load notification count
    _fetchUnreadNotificationCount();
  }

  @override
  void dispose() {
    // Unregister this object as an observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);

    // Remove listener from AppDataProvider
    try {
      final appDataProvider = Provider.of<AppDataProvider>(
        context,
        listen: false,
      );
      appDataProvider.removeListener(_onAppDataProviderChanged);
    } catch (e) {
      debugPrint('Error removing AppDataProvider listener: $e');
    }

    super.dispose();
  }

  // Listen to AppDataProvider changes and update home sections automatically
  void _onAppDataProviderChanged() {
    if (!mounted) return;

    final appDataProvider = Provider.of<AppDataProvider>(
      context,
      listen: false,
    );

    // Only update if we have new data and it's different from current data
    if (appDataProvider.homeSections.isNotEmpty &&
        appDataProvider.homeState == DataState.loaded &&
        (_homeSections.length != appDataProvider.homeSections.length ||
            _hasContentChanged(_homeSections, appDataProvider.homeSections))) {
      debugPrint(
        '📱 Home: AppDataProvider updated, refreshing UI with new data',
      );
      setState(() {
        _homeSections = appDataProvider.homeSections;
        _isLoadingHomeSections = false;
        _dataInitiallyLoaded = true;
        _lastRefreshTime = DateTime.now().millisecondsSinceEpoch;
      });
    }
  }

  // Check if we need to refresh data in the background
  void _checkForBackgroundRefresh() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastRefresh = now - _lastRefreshTime;

    // Only refresh in background if it's been more than the minimum interval
    if (timeSinceLastRefresh > _minRefreshInterval) {
      debugPrint(
        'Background refresh check: Last refresh was ${timeSinceLastRefresh}ms ago, triggering background refresh via AppDataProvider',
      );

      // Use AppDataProvider for background refresh instead of direct service call
      final appDataProvider = Provider.of<AppDataProvider>(
        context,
        listen: false,
      );
      appDataProvider.getHomeSections(
        forceRefresh: false,
      ); // This will trigger background refresh if needed

      _lastRefreshTime = now;
    } else {
      debugPrint(
        'Background refresh check: Last refresh was ${timeSinceLastRefresh}ms ago, skipping refresh',
      );
    }
  }

  // Helper method to check if content has changed
  bool _hasContentChanged(
    List<HomeSection> oldSections,
    List<HomeSection> newSections,
  ) {
    if (oldSections.length != newSections.length) return true;

    for (int i = 0; i < oldSections.length; i++) {
      if (oldSections[i].id != newSections[i].id ||
          oldSections[i].title != newSections[i].title ||
          oldSections[i].items.length != newSections[i].items.length) {
        return true;
      }
    }

    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in the foreground and visible to the user
        debugPrint('App resumed - checking if background refresh needed');

        // Only trigger background refresh if data is stale and we're on home screen
        if (_dataInitiallyLoaded) {
          _checkForBackgroundRefresh();
        }
        break;
      case AppLifecycleState.inactive:
        // App is inactive, might be entering background
        // This happens when notification shade is pulled down
        // Don't do anything here to prevent refreshes when notification shade is pulled
        debugPrint('App inactive - no action needed');
        break;
      case AppLifecycleState.paused:
        // App is in the background
        debugPrint('App paused - no action needed');
        // Don't clear caches or trigger refreshes
        break;
      case AppLifecycleState.detached:
        // App is detached (terminated)
        debugPrint('App detached - no action needed');
        // Don't clear cache on detach, as we want to keep data for next launch
        break;
      default:
        break;
    }
  }

  // Clear the image cache to ensure fresh images - only used on first load
  void _clearImageCache() {
    try {
      // Don't clear the entire cache, just clear live images
      // This is less aggressive and prevents unnecessary network requests
      PaintingBinding.instance.imageCache.clearLiveImages();
      debugPrint('Cleared live images from cache');
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  // Cache banner image URLs for future comparison
  Future<void> _cacheBannerImages(List<String> imageUrls) async {
    try {
      final cacheService = CacheService();
      await cacheService.cacheBannerImages(imageUrls);
      debugPrint('🖼️ Cached ${imageUrls.length} banner image URLs');
    } catch (e) {
      debugPrint('Error caching banner images: $e');
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

  // Fetch dynamic home sections using global data provider
  Future<void> _fetchHomeSections({bool forceRefresh = false}) async {
    try {
      // Check connectivity before attempting to fetch data
      final connectivityService = serviceLocator.connectivityService;
      if (!connectivityService.isFullyOnline && forceRefresh) {
        debugPrint('📱 Home: No connectivity, skipping data fetch');
        // Show a message to user about connectivity issue
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(connectivityService.getConnectivityMessage()),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final appDataProvider = Provider.of<AppDataProvider>(
        context,
        listen: false,
      );
      final screenStateProvider = Provider.of<ScreenStateProvider>(
        context,
        listen: false,
      );

      // Check if we already have fresh data and don't need to refresh
      if (!forceRefresh && _dataInitiallyLoaded && _homeSections.isNotEmpty) {
        debugPrint('📱 Home: Data already loaded and fresh, skipping fetch');
        return;
      }

      // Only show loading indicator if we don't have any data yet
      if (_homeSections.isEmpty) {
        setState(() {
          _isLoadingHomeSections = true;
        });
      }

      // Get sections from global provider (uses smart caching)
      final sections = await appDataProvider.getHomeSections(
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _homeSections = sections;
          _isLoadingHomeSections = false;
          _dataInitiallyLoaded = true; // Mark data as loaded
          _lastRefreshTime =
              DateTime.now().millisecondsSinceEpoch; // Update last refresh time
        });

        // Mark data as refreshed in screen state provider
        screenStateProvider.markDataRefreshed(ScreenType.home);

        debugPrint(
          '📱 Home: Loaded ${sections.length} sections from global provider',
        );
      }
    } catch (e) {
      debugPrint('❌ Home: Error fetching sections: $e');
      if (mounted) {
        setState(() {
          _isLoadingHomeSections = false;
          // Don't set _dataInitiallyLoaded to true if there was an error
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

  // Complete notification setup when user reaches home screen
  void _completeNotificationSetup() {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Only setup notifications if user is logged in
      if (userProvider.isLoggedIn) {
        debugPrint('🏠 Home: User is logged in, completing notification setup...');

        // Import service locator to access notification service
        final notificationService = serviceLocator.notificationService;

        // Complete notification setup in background (non-blocking)
        notificationService.completeSetupAfterLogin().catchError((e) {
          debugPrint('❌ Home: Error completing notification setup: $e');
        });
      } else {
        debugPrint('🏠 Home: User not logged in, skipping notification setup');
      }
    } catch (e) {
      debugPrint('❌ Home: Error accessing notification service: $e');
    }
  }

  // Helper method to create a color with opacity using the new API
  Color _getColorWithOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // Navigate to the appropriate list screen based on the section title and type
  void _navigateToSeeMore(String sectionTitle, {SectionType? sectionType}) {
    // Find the section by title
    HomeSection? section;
    for (var s in _homeSections) {
      if (s.title == sectionTitle && s.type == sectionType) {
        section = s;
        break;
      }
    }

    if (section == null) {
      debugPrint('Section not found: $sectionTitle');
      return;
    }

    // Determine the list type based on section type
    ListType listType;

    if (sectionType != null) {
      switch (sectionType) {
        case SectionType.COLLECTIONS:
          listType = ListType.collections;
          break;
        case SectionType.SONGS:
        case SectionType.SONG_LIST:
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
    } else {
      // Default to songs if no section type is provided
      listType = ListType.songs;
    }

    // Navigate to the list screen with the section ID if available
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ListScreen(
              title: sectionTitle,
              listType: listType,
              sectionId: section?.id,
              sectionType: sectionType,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppTheme.appBar,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevents elevation change when scrolling
        surfaceTintColor:
            Colors.transparent, // Prevents blue tinting from primary color
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
          'Stuthi Chords & Lyrics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          // Connectivity indicator
          ConnectivityIndicator(
            margin: const EdgeInsets.only(right: 8.0),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications').then((_) {
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
                      borderRadius: BorderRadius.circular(5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99
                          ? '99+'
                          : _unreadNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
            // Top spacing
            const SizedBox(height: 16.0),

            // Connectivity Status Widget
            ConnectivityStatusWidget(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              onRetryPressed: () {
                // Retry loading home sections when connectivity is restored
                _fetchHomeSections(forceRefresh: true);
              },
            ),

            // Dynamic Home Sections
            if (_isLoadingHomeSections)
              _buildLoadingIndicator()
            else
              // Render dynamic sections
              for (var section in _homeSections)
                if (section.isActive != false) // Skip inactive sections
                ...[
                  // For banner sections, don't show header with title and "See more"
                  if (section.type == SectionType.BANNER)
                    _buildBannerSection(section)
                  else ...[
                    _buildSectionHeader(
                      section.title,
                      sectionType: section.type,
                    ),
                    _buildSectionContent(section),
                  ],
                ],

            // Support Us section
            _buildSupportUsSection(),

            // Extra space at bottom to ensure all content is visible above bottom nav bar
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {SectionType? sectionType}) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 16.0,
      ), // Add consistent top padding between sections
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
                    'See all',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Add consistent spacing between section header and content
          const SizedBox(
            height: 8.0,
          ), // Standard spacing between header and content
        ],
      ),
    );
  }

  Widget _buildHorizontalScrollSection(List<Widget> items) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120, // Minimum height for content
        maxHeight: 170, // Maximum height for content
      ),
      height: 10, // Default height
      margin: const EdgeInsets.only(bottom: 8.0), // Consistent bottom margin
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        children: items,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        HomeSectionSkeleton(type: SectionType.COLLECTIONS),
        HomeSectionSkeleton(type: SectionType.SONGS),
        HomeSectionSkeleton(type: SectionType.ARTISTS),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120, // Minimum height to match horizontal scroll section
        maxHeight: 170, // Maximum height to match horizontal scroll section
      ),
      height: 140, // Default height to match horizontal scroll section
      margin: const EdgeInsets.only(bottom: 16.0), // Reduced bottom margin
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey[400])),
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
      Colors.indigo,
      Colors.cyan,
      Colors.deepPurple,
    ];

    // Return a random color from the list
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }

  Widget _buildCollectionItem(
    String title,
    Color color, {
    Collection? collection,
  }) {
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
          aspectRatio: 16 / 9, // 16:9 aspect ratio
          child: Container(
            decoration: BoxDecoration(
              color: _getColorWithOpacity(color, 0.3),
              borderRadius: BorderRadius.circular(5),
              // No gradient overlay to keep image clear
            ),
            child:
                collection?.imageUrl != null
                    ? MemoryEfficientImage(
                      imageUrl: collection!.imageUrl!,
                      width:
                          400, // Use reasonable fixed size instead of infinity
                      height: 225, // 16:9 aspect ratio (400 * 9/16 = 225)
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(5),
                      placeholder: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: Center(
                        child: Icon(
                          Icons.collections_bookmark,
                          color: Colors.white,
                          size: 40,
                        ),
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
          Navigator.pushNamed(context, '/song_detail', arguments: song);
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

            // Calculate the size of the square image
            final imageSize =
                availableHeight -
                textHeight -
                10.0; // Subtract text height and spacing

            // Calculate the total height needed
            final totalContentHeight = imageSize + 10.0 + textHeight;
            // Calculate top padding to center the content vertically
            final topPadding = (availableHeight - totalContentHeight) / 2;

            return Padding(
              padding: EdgeInsets.only(top: topPadding > 0 ? topPadding : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Song image with square aspect ratio
                  SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getColorWithOpacity(color, 0.3),
                        borderRadius: BorderRadius.circular(5),
                        // Fallback gradient if no image is available
                        gradient:
                            song?.imageUrl == null
                                ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _getColorWithOpacity(color, 0.7),
                                    Color.fromRGBO(
                                      0,
                                      0,
                                      0,
                                      0.9,
                                    ), // Black with opacity
                                  ],
                                )
                                : null,
                      ),
                      child:
                          song?.imageUrl != null
                              ? MemoryEfficientImage(
                                imageUrl: song!.imageUrl!,
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(5),
                                placeholder: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 40,
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
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
            arguments: {'artistName': artist.name},
          );
        }
      },
      child: Container(
        width: 100, // Fixed width for artist items (same as song items)
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available height for the image and text
            final availableHeight = constraints.maxHeight;
            // Minimize text height to give more space to the image
            final textHeight = (availableHeight * 0.14).clamp(12.0, 16.0);
            // Increase artist image size - make it larger
            final imageSize = ((availableHeight - textHeight - 4.0) * 0.95)
                .clamp(65.0, 95.0);

            // Calculate the total height needed
            final totalContentHeight = imageSize + 4.0 + textHeight;
            // Calculate top padding to center the content vertically
            final topPadding = (availableHeight - totalContentHeight) / 2;

            return Padding(
              padding: EdgeInsets.only(top: topPadding > 0 ? topPadding : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center horizontally
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
                    ),
                    child:
                        artist?.imageUrl != null
                            ? ClipOval(
                              child: MemoryEfficientImage(
                                imageUrl: artist!.imageUrl!,
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                                placeholder: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: imageSize * 0.5,
                                ),
                              ),
                            )
                            : Icon(
                              Icons.person,
                              color: Colors.white,
                              size: imageSize * 0.5,
                            ),
                  ),

                  // Minimal spacing between image and text for artist items
                  const SizedBox(height: 4.0),

                  // Name
                  SizedBox(
                    height: textHeight,
                    child: Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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

    // Extract image URLs for caching
    List<String> imageUrls = [];

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
                  arguments: {'collectionId': targetId},
                );
                break;
              case 'ARTIST':
                Navigator.pushNamed(
                  context,
                  '/artist_detail',
                  arguments: {'artistId': targetId},
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
        // Add to image URLs list for caching
        imageUrls.add(imageUrl);

        bannerItems.add(
          BannerItem(
            imageUrl: imageUrl,
            onTap:
                onTap as void Function()? ??
                () {
                  debugPrint('Banner item tapped, but no target specified');
                },
          ),
        );
      }
    }

    // Cache banner image URLs for future comparison
    _cacheBannerImages(imageUrls);

    // If we couldn't create any banner items, show a placeholder
    if (bannerItems.isEmpty) {
      return _buildEmptyState('No valid banner items available');
    }

    // Return a sliding banner with the items
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        16.0,
      ), // Consistent spacing between sections
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
          borderRadius: BorderRadius.circular(5),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              const Text(
                'Stuthi is and will always be free for everyone. If you find value in our app, consider supporting us to help with server costs and new features.',
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
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  'Support Us',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 24.0,
              bottom:
                  24.0 +
                  MediaQuery.of(
                    context,
                  ).padding.bottom, // Add safe area bottom padding
            ),
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
    const playStoreUrl = 'market://details?id=com.stuti.chords';
    // For iOS
    const appStoreUrl = 'https://apps.apple.com/app/stuti/id123456789';

    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        launchUrl(
          Uri.parse(playStoreUrl),
          mode: LaunchMode.externalApplication,
        );
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        launchUrl(Uri.parse(appStoreUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch store: $e');
      // Fallback to web URL if app store doesn't open
      launchUrl(
        Uri.parse('https://stuti.com/app'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // Share app with others
  void _shareApp() {
    // Use URL launcher to open a share intent
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.stuti.chords',
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
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
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
              section.items
                  .map(
                    (collection) => _buildCollectionItem(
                      collection.title,
                      collection.color,
                      collection: collection,
                    ),
                  )
                  .toList(),
            );

      case SectionType.SONGS:
        return section.items.isEmpty
            ? _buildEmptyState('No songs available')
            : _buildHorizontalScrollSection(
              section.items
                  .map(
                    (song) => _buildSongItem(
                      song.title,
                      _getRandomColor(),
                      song: song,
                    ),
                  )
                  .toList(),
            );

      case SectionType.ARTISTS:
        return section.items.isEmpty
            ? _buildEmptyState('No artists available')
            : _buildHorizontalScrollSection(
              section.items
                  .map(
                    (artist) => _buildArtistItem(
                      artist.name,
                      _getRandomColor(),
                      artist: artist,
                    ),
                  )
                  .toList(),
            );

      case SectionType.BANNER:
        // Banner sections are now handled by _buildBannerSection
        return _buildEmptyState('Banner section (should not be shown here)');

      case SectionType.SONG_LIST:
        debugPrint(
          'Building SONG_LIST section: ${section.title} with ${section.items.length} items',
        );

        // Convert items to Song objects manually to ensure proper conversion
        List<Song> songs = [];
        for (var item in section.items) {
          try {
            if (item is Song) {
              songs.add(item);
            } else if (item is Map<String, dynamic>) {
              songs.add(Song.fromJson(item));
            } else {
              debugPrint('Unknown item type: ${item.runtimeType}');
            }
          } catch (e) {
            debugPrint('Error converting item to Song: $e');
          }
        }

        debugPrint('Converted ${songs.length} items to Song objects');

        return songs.isEmpty
            ? _buildEmptyState('No songs available')
            : _buildSongListSection(songs);
    }
  }

  // Build a compact song list section
  Widget _buildSongListSection(List<Song> songs) {
    debugPrint('Building song list section with ${songs.length} songs');
    if (songs.isEmpty) {
      return _buildEmptyState('No songs available');
    }

    if (songs.isNotEmpty) {
      debugPrint('First song: ${songs.first.title} by ${songs.first.artist}');
    }

    // Ensure we have valid songs with required fields
    final validSongs =
        songs
            .where((song) => song.id.isNotEmpty && song.title.isNotEmpty)
            .toList();

    debugPrint('Found ${validSongs.length} valid songs out of ${songs.length}');

    if (validSongs.isEmpty) {
      return _buildEmptyState('No valid songs available');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount:
            validSongs.length > 8
                ? 8
                : validSongs.length, // Limit to 8 songs for a compact view
        itemBuilder: (context, index) {
          final song = validSongs[index];
          debugPrint('Building song item $index: ${song.title}');
          return _buildCompactSongItem(song);
        },
      ),
    );
  }

  // Build a compact song item for the list layout
  Widget _buildCompactSongItem(Song song) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/song_detail', arguments: song);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // Song thumbnail
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getColorWithOpacity(_getRandomColor(), 0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child:
                      song.imageUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: CachedNetworkImage(
                              imageUrl: song.imageUrl!,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 300),
                              placeholder:
                                  (context, url) => Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                            ),
                          )
                          : const Center(
                            child: Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                ),

                const SizedBox(width: 16),

                // Song info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Song title
                      Text(
                        song.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Artist name only
                      Text(
                        song.artist,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Song key
                if (song.key.isNotEmpty)
                  Text(
                    song.key,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Add a subtle separator that starts from the song title
        Padding(
          padding: const EdgeInsets.only(left: 66.0, right: 16.0),
          child: Container(
            height: 0.5,
            color: _getColorWithOpacity(Colors.grey, 0.15),
          ),
        ),
      ],
    );
  }
}
