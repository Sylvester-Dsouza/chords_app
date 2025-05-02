import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

import '../widgets/inner_screen_app_bar.dart';
import '../widgets/song_placeholder.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';
import '../services/song_service.dart';
import '../services/artist_service.dart';
import '../services/collection_service.dart';
import '../services/liked_songs_service.dart';
import '../services/liked_songs_notifier.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 2; // Set to 2 for Search tab
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  String _screenTitle = 'Song Chords & Lyrics';
  String _searchHint = 'Search for Songs';

  // Services
  final SongService _songService = SongService();
  final ArtistService _artistService = ArtistService();
  final CollectionService _collectionService = CollectionService();
  final LikedSongsService _likedSongsService = LikedSongsService();
  final LikedSongsNotifier _likedSongsNotifier = LikedSongsNotifier();

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Register as an observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Listen for liked songs changes
    _likedSongsNotifier.addListener(_handleLikedSongsChanged);

    // Sync with navigation provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
      navigationProvider.updateIndex(2); // Search screen is index 2
      setState(() {
        _currentIndex = 2;
      });
    });

    // Load initial data
    _fetchSongs();
    _fetchArtists();
    _fetchCollections();

    // Check liked status of songs
    _updateLikedStatus();
  }

  // Handle liked songs changes
  void _handleLikedSongsChanged() {
    debugPrint('Liked songs changed, updating UI');
    _updateLikedStatus();
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

  // Fetch songs
  Future<void> _fetchSongs() async {
    if (mounted) {
      setState(() {
        _isLoadingSongs = true;
      });
    }

    try {
      final songs = await _songService.getAllSongs();

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
      debugPrint('Error fetching songs: $e');
      if (mounted) {
        setState(() {
          _songs = [];
          _isLoadingSongs = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load songs: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fetch artists
  Future<void> _fetchArtists() async {
    if (mounted) {
      setState(() {
        _isLoadingArtists = true;
      });
    }

    try {
      final artists = await _artistService.getAllArtists();
      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoadingArtists = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching artists: $e');
      if (mounted) {
        setState(() {
          _artists = [];
          _isLoadingArtists = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load artists: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fetch collections
  Future<void> _fetchCollections() async {
    if (mounted) {
      setState(() {
        _isLoadingCollections = true;
      });
    }

    try {
      final collections = await _collectionService.getAllCollections();
      if (mounted) {
        setState(() {
          _collections = collections;
          _isLoadingCollections = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching collections: $e');
      if (mounted) {
        setState(() {
          _collections = [];
          _isLoadingCollections = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load collections: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
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
            _searchHint = 'Search for Songs';
            break;
          case 1:
            _screenTitle = 'Find Chords by Artists';
            _searchHint = 'Search for Artists';
            break;
          case 2:
            _screenTitle = 'Search Collections';
            _searchHint = 'Search for Collections';
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

  // Search songs
  Future<void> _searchSongs(String query) async {
    if (mounted) {
      setState(() {
        _isLoadingSongs = true;
      });
    }

    try {
      final songs = await _songService.searchSongs(query);

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
            backgroundColor: Colors.red,
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
      final artists = await _artistService.searchArtists(query);
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
            backgroundColor: Colors.red,
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
      final collections = await _collectionService.searchCollections(query);
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _likedSongsNotifier.removeListener(_handleLikedSongsChanged);
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: InnerScreenAppBar(
        title: _screenTitle,
        centerTitle: true,
        showBackButton: false,
      ),
      body: Column(
        children: [
          // Search Bar and Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _searchHint,
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        _handleSearch(value);
                      },
                    ),
                  ),
                ),

                // Filter Button
                Container(
                  margin: const EdgeInsets.only(left: 8.0),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: () {
                      // Show filter options
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Center(
                    child: _buildTabItem('Songs', 0),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildTabItem('Artists', 1),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildTabItem('Collections', 2),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            margin: const EdgeInsets.only(top: 1.0),
            height: 1,
            color: const Color(0xFF333333),
          ),

          // Add some spacing
          const SizedBox(height: 8),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Songs Tab
                _buildSongsTab(),

                // Artists Tab
                _buildArtistsTab(),

                // Collections Tab
                _buildCollectionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    bool isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: title.length * 6.0, // Slightly narrower for better appearance
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFC701) : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search result text
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _searchQuery.isEmpty ? 'All Songs' : 'Search results for: $_searchQuery',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),

        // Songs list
        Expanded(
          child: _isLoadingSongs
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC701)))
            : _songs.isEmpty
              ? Center(child: Text('No songs found', style: TextStyle(color: Colors.grey[400])))
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return _buildSongItem(song);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildArtistsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search result text
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _searchQuery.isEmpty ? 'All Artists' : 'Search results for: $_searchQuery',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),

        // Artists list
        Expanded(
          child: _isLoadingArtists
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC701)))
            : _artists.isEmpty
              ? Center(child: Text('No artists found', style: TextStyle(color: Colors.grey[400])))
              : ListView.builder(
                  itemCount: _artists.length,
                  itemBuilder: (context, index) {
                    final artist = _artists[index];
                    return _buildArtistItem(artist.name, '${artist.songCount} Songs');
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildArtistItem(String name, String songCount) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF333333),
            width: 1.0,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: const SongPlaceholder(),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          songCount,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
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
    );
  }

  Widget _buildCollectionsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search result text
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _searchQuery.isEmpty ? 'All Collections' : 'Search results for: $_searchQuery',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),

        // Collections grid
        Expanded(
          child: _isLoadingCollections
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC701)))
            : _collections.isEmpty
              ? Center(child: Text('No collections found', style: TextStyle(color: Colors.grey[400])))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _collections.length,
                  itemBuilder: (context, index) {
                    final collection = _collections[index];
                    return Column(
                      children: [
                        _buildCollectionCard(
                          collection.title,
                          '${collection.songCount} Songs',
                          collection.color,
                          collection.likes
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(String title, String songCount, Color bgColor, int likes) {
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
      borderRadius: BorderRadius.circular(8.0),
      child: Ink(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bgColor,
              bgColor.withAlpha(150),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Title
            Positioned(
              left: 16,
              top: 16,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Song count
            Positioned(
              left: 16,
              bottom: 16,
              child: Text(
                songCount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),

            // Likes count
            Positioned(
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Text(
                    likes.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.thumb_up,
                    color: Colors.white,
                    size: 16,
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
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF333333),
            width: 1.0,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: const SongPlaceholder(),
        title: Text(
          song.title,
          style: const TextStyle(
            color: Color(0xFFFFC701),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          song.artist,
          style: const TextStyle(
            color: Colors.grey,
          ),
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
            const SizedBox(width: 16),
            // Like Button
            IconButton(
              icon: Icon(
                song.isLiked ? Icons.favorite : Icons.favorite_border,
                color: song.isLiked ? Colors.red : Colors.white,
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
                      backgroundColor: wasLiked ? Colors.grey : Colors.green,
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
    );
  }
}
