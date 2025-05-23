import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

import '../widgets/inner_screen_app_bar.dart';
import '../widgets/song_placeholder.dart';
import '../widgets/search_filter_dialog.dart';
import '../widgets/animated_search_bar.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';
import '../models/search_filters.dart';
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
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  String _screenTitle = 'Song Chords & Lyrics';
  String _searchHint = 'Search for Songs...';

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

  // Filters
  SongSearchFilters _songFilters = SongSearchFilters();
  ArtistSearchFilters _artistFilters = ArtistSearchFilters();
  CollectionSearchFilters _collectionFilters = CollectionSearchFilters();

  // Filter active states
  bool _isSongFilterActive = false;
  bool _isArtistFilterActive = false;
  bool _isCollectionFilterActive = false;

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
    showDialog(
      context: context,
      builder: (context) => SearchFilterDialog(
        tabIndex: _tabController.index,
        songFilters: _songFilters,
        artistFilters: _artistFilters,
        collectionFilters: _collectionFilters,
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
          // Fixed header with search bar and tabs
          Container(
            color: const Color(0xFF121212), // Solid background color
            child: Column(
              children: [
                // Animated Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: AnimatedSearchBar(
                    controller: _searchController,
                    hintText: _searchHint,
                    isFilterActive: _getFilterActiveForCurrentTab(),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _handleSearch(value);
                    },
                    onFilterPressed: _showFilterDialog,
                    primaryColor: const Color(0xFFC19FFF), // Light purple/lavender
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
              ],
            ),
          ),

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
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
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
            _getSearchResultText(0),
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),

        // Songs list
        Expanded(
          child: _isLoadingSongs
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
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
            _getSearchResultText(1),
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),

        // Artists list
        Expanded(
          child: _isLoadingArtists
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
            : _artists.isEmpty
              ? Center(child: Text('No artists found', style: TextStyle(color: Colors.grey[400])))
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
        subtitle: Row(
          children: [
            Icon(
              Icons.music_note,
              color: Colors.grey,
              size: 14,
            ),
            SizedBox(width: 4),
            Text(
              songCount,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
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
            _getSearchResultText(2),
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),

        // Collections grid
        Expanded(
          child: _isLoadingCollections
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
            : _collections.isEmpty
              ? Center(child: Text('No collections found', style: TextStyle(color: Colors.grey[400])))
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
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8.0),
        ),
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
                      color: Colors.white,
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
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),

                      // Likes count
                      Row(
                        children: [
                          Text(
                            likeCount.toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            collection.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: collection.isLiked ? Colors.red : Colors.grey,
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
        leading: const SongPlaceholder(size: placeholderSize),
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
