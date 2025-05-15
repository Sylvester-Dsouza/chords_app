import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:url_launcher/url_launcher.dart';
// AdMob imports removed to fix crashing issues
// import '../widgets/banner_ad_widget.dart';
// import '../services/ad_service.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_drawer.dart';
import '../providers/user_provider.dart';
import '../models/collection.dart';
import '../models/song.dart';
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
  final HomeSectionService _homeSectionService = HomeSectionService();
  // AdService removed to fix crashing issues
  // final AdService _adService = AdService();

  // Data
  List<HomeSection> _homeSections = [];
  int _unreadNotificationCount = 0;

  // Loading states
  bool _isLoadingHomeSections = true;
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

    // Load dynamic home sections
    _fetchHomeSections();

    // Load notification count
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
        builder: (context) => ListScreen(
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
          'Stuthi Christian Chords & Lyrics',
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
            // Top spacing
            const SizedBox(height: 16.0),

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
                    else
                      ...[
                        _buildSectionHeader(section.title, sectionType: section.type),
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
      padding: const EdgeInsets.only(top: 16.0), // Add consistent top padding between sections
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 8.0), // Standard spacing between header and content
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
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120, // Minimum height to match horizontal scroll section
        maxHeight: 170, // Maximum height to match horizontal scroll section
      ),
      height: 140, // Default height to match horizontal scroll section
      margin: const EdgeInsets.only(bottom: 16.0), // Reduced bottom margin
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
      margin: const EdgeInsets.only(bottom: 16.0), // Reduced bottom margin
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

            // Calculate the size of the square image
            final imageSize = availableHeight - textHeight - 10.0; // Subtract text height and spacing

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
                              fadeInDuration: const Duration(milliseconds: 300),
                              cacheKey: '${song.imageUrl}_${DateTime.now().day}',
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                debugPrint('Error loading song image: ${song.title} - $url');
                                final timestamp = DateTime.now().millisecondsSinceEpoch;
                                final refreshedUrl = '$url?t=$timestamp';
                                return CachedNetworkImage(
                                  imageUrl: refreshedUrl,
                                  fit: BoxFit.cover,
                                  fadeInDuration: const Duration(milliseconds: 300),
                                  cacheKey: '${refreshedUrl}_retry_$timestamp',
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
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
            arguments: {
              'artistName': artist.name,
            },
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
            final imageSize = ((availableHeight - textHeight - 4.0) * 0.95).clamp(65.0, 95.0);

            // Calculate the total height needed
            final totalContentHeight = imageSize + 4.0 + textHeight;
            // Calculate top padding to center the content vertically
            final topPadding = (availableHeight - totalContentHeight) / 2;

            return Padding(
              padding: EdgeInsets.only(top: topPadding > 0 ? topPadding : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
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
                    child: artist?.imageUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: artist!.imageUrl!,
                              fit: BoxFit.cover,
                              width: imageSize,
                              height: imageSize,
                              fadeInDuration: const Duration(milliseconds: 300),
                              cacheKey: '${artist.imageUrl}_${DateTime.now().day}',
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                debugPrint('Error loading artist image: ${artist.name} - $url');
                                final timestamp = DateTime.now().millisecondsSinceEpoch;
                                final refreshedUrl = '$url?t=$timestamp';
                                return CachedNetworkImage(
                                  imageUrl: refreshedUrl,
                                  fit: BoxFit.cover,
                                  width: imageSize,
                                  height: imageSize,
                                  fadeInDuration: const Duration(milliseconds: 300),
                                  cacheKey: '${refreshedUrl}_retry_$timestamp',
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
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
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0), // Consistent spacing between sections
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
