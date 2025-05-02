import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import './list_screen.dart';

class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({super.key});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> {

  // Services
  final CollectionService _collectionService = CollectionService();
  final SongService _songService = SongService();
  final ArtistService _artistService = ArtistService();

  // Data
  List<Collection> _seasonalCollections = [];
  List<Collection> _beginnerFriendlyCollections = [];
  List<Song> _trendingSongs = [];
  List<Artist> _topArtists = [];
  List<Song> _newSongs = [];
  int _unreadNotificationCount = 0;

  // Loading states
  bool _isLoadingSeasonalCollections = true;
  bool _isLoadingBeginnerCollections = true;
  bool _isLoadingTrendingSongs = true;
  bool _isLoadingTopArtists = true;
  bool _isLoadingNewSongs = true;
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    // Check login state after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginState();

      // Sync with navigation provider
      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
      navigationProvider.updateIndex(0); // Home screen is index 0
    });

    // Load data
    _fetchSeasonalCollections();
    _fetchBeginnerFriendlyCollections();
    _fetchTrendingSongs();
    _fetchTopArtists();
    _fetchNewSongs();
    _fetchUnreadNotificationCount();
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
      // In a real implementation, you would have an API endpoint for top artists
      // For now, we'll just get all artists and limit to 10
      final artists = await _artistService.getAllArtists();
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

  // Navigate to the appropriate list screen based on the section title
  void _navigateToSeeMore(String sectionTitle) {
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

            // Seasonal Collections
            _buildSectionHeader('Seasonal Collections'),
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
            _buildSectionHeader('Trending Song Chords'),
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
            _buildSectionHeader('Beginner Friendly'),
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
            _buildSectionHeader('Top Artist of the Month'),
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
            _buildSectionHeader('Discover new songs'),
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

            // Bottom Banner
            Container(
              height: 180,
              margin: const EdgeInsets.symmetric(vertical: 16.0),
              child: Stack(
                children: [
                  // Placeholder for banner image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(
                            128,
                            0,
                            128,
                            0.7,
                          ), // Purple with opacity
                          Colors.black,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'DONT LOOK BACK',
                        style: TextStyle(
                          color: Colors.pink,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Dots indicator
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromRGBO(
                              255,
                              255,
                              255,
                              0.5,
                            ), // White with opacity
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromRGBO(
                              255,
                              255,
                              255,
                              0.5,
                            ), // White with opacity
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ad banner
            Container(
              height: 50,
              color: const Color(0xFF2A4D69),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text(
                    'Nice job! You\'re displaying a 320 x 50 test ad from AdMob.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Extra space at bottom to ensure all content is visible above bottom nav bar
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                color: const Color(0xFFFFC701),
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
              // Navigate to the appropriate list screen based on the section title
              _navigateToSeeMore(title);
            },
            child: const Text(
              'See more',
              style: TextStyle(color: Color(0xFFFFC701), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalScrollSection(List<Widget> items) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120, // Further increased minimum height for added spacing
        maxHeight: 170, // Further increased maximum height
      ),
      height: 140, // Further increased default height
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        children: items,
      ),
    );
  }

  // Special horizontal scroll section for collections with increased height
  Widget _buildCollectionsScrollSection(List<Widget> items) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 146, // Height based on 16:9 ratio for 260px width
        maxHeight: 180, // Maximum height for collections
      ),
      height: 160, // Optimal height for collections
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        children: items,
      ),
    );
  }

  // Special loading indicator for collections with increased height
  Widget _buildCollectionsLoadingIndicator() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 146, // Height based on 16:9 ratio for 260px width
        maxHeight: 180, // Maximum height for collections
      ),
      height: 160, // Optimal height for collections
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
        ),
      ),
    );
  }

  // Special empty state for collections with increased height
  Widget _buildCollectionsEmptyState(String message) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 146, // Height based on 16:9 ratio for 260px width
        maxHeight: 180, // Maximum height for collections
      ),
      height: 160, // Optimal height for collections
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[400]),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120, // Further increased minimum height to match horizontal scroll section
        maxHeight: 170, // Further increased maximum height
      ),
      height: 140, // Further increased default height
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120, // Further increased minimum height to match horizontal scroll section
        maxHeight: 170, // Further increased maximum height
      ),
      height: 140, // Further increased default height
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
              image: collection?.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(collection!.imageUrl!),
                    fit: BoxFit.cover, // Ensures image covers the full area
                  )
                : null,
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
                      image: song?.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(song!.imageUrl!),
                            fit: BoxFit.cover, // Ensures image covers the full area
                            onError: (exception, stackTrace) {
                              debugPrint('Error loading song image: ${song.title} - ${song.imageUrl}');
                              debugPrint('Error details: $exception');
                            },
                          )
                        : null,
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
                  ),
                ),

                // Add spacing between image and text
                const SizedBox(height: 4.0),

                // Title
                SizedBox(
                  height: textHeight,
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 12), // Increased font size
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
                    image: artist?.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(artist!.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  ),
                  child: artist?.imageUrl == null && color == const Color(0xFFFFC701)
                      ? Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: imageSize * 0.5, // Responsive icon size
                        )
                      : null,
                ),

                // Add spacing between image and text
                const SizedBox(height: 4.0),

                // Name
                SizedBox(
                  height: textHeight,
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 12), // Increased font size
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
}
