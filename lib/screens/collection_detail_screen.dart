import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/song_placeholder.dart';
import '../widgets/animated_bottom_nav_bar.dart';
import '../models/collection.dart';
import '../models/song.dart';
import '../services/collection_service.dart';
import '../services/liked_songs_service.dart';
import '../providers/navigation_provider.dart';

class CollectionDetailScreen extends StatefulWidget {
  final String collectionName;
  final String? collectionId;

  const CollectionDetailScreen({
    super.key,
    required this.collectionName,
    this.collectionId,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  int _currentIndex = 2; // Set to 2 for Search tab

  // Services
  final CollectionService _collectionService = CollectionService();
  final LikedSongsService _likedSongsService = LikedSongsService();

  // Data
  Collection? _collection;
  List<Song> _songs = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCollectionData();
  }

  // Load collection data and songs
  Future<void> _loadCollectionData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      Collection? collection;

      // If we have a collection ID, use it
      if (widget.collectionId != null && widget.collectionId != 'unknown') {
        try {
          collection = await _collectionService.getCollectionById(widget.collectionId!);
          debugPrint('Loaded collection by ID: ${collection.title}');
        } catch (e) {
          debugPrint('Error loading collection by ID: $e');
          // Fall back to loading by name
          collection = await _collectionService.getCollectionByName(widget.collectionName);
        }
      } else {
        // Try to get collection by name
        collection = await _collectionService.getCollectionByName(widget.collectionName);
        debugPrint('Loaded collection by name: ${collection?.title}');
      }

      if (collection != null) {
        // Get songs in collection
        final songsData = await _collectionService.getSongsInCollection(collection.id);
        final List<Song> songs = [];

        // Parse songs
        for (var songData in songsData) {
          try {
            final song = Song.fromJson(songData);
            songs.add(song);
          } catch (e) {
            debugPrint('Error parsing song: $e');
          }
        }

        // Get liked songs to update status
        final likedSongs = await _likedSongsService.getLikedSongs();

        // Update liked status
        for (var song in songs) {
          song.isLiked = likedSongs.any((likedSong) => likedSong.id == song.id);
        }

        if (mounted) {
          setState(() {
            _collection = collection;
            _songs = songs;
            _isLoading = false;
          });
        }
      } else {
        // If collection not found, create a basic collection object
        if (mounted) {
          setState(() {
            _collection = Collection(
              id: widget.collectionId ?? 'unknown',
              title: widget.collectionName,
              color: const Color(0xFF3498DB),
            );
            _songs = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading collection data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Toggle like status of a song
  Future<void> _toggleLike(Song song) async {
    final wasLiked = song.isLiked;

    try {
      final success = await _likedSongsService.toggleLike(song);
      if (success && mounted) {
        setState(() {
          song.isLiked = !wasLiked;
        });

        // Show feedback
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
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update like status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      // Update the navigation provider
      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
      navigationProvider.updateIndex(index);

      // Navigate to the main navigation screen
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          _collection?.title ?? widget.collectionName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load collection data',
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC701),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _loadCollectionData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Collection header with image
                    _buildCollectionHeader(),

                    // Collection description
                    _buildCollectionDescription(),

                    // Divider
                    const Divider(
                      color: Color(0xFF333333),
                      thickness: 1,
                      height: 1,
                    ),

                    // Songs list
                    Expanded(
                      child: _songs.isEmpty
                          ? Center(
                              child: Text(
                                'No songs found in this collection',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _songs.length,
                              itemBuilder: (context, index) {
                                final song = _songs[index];
                                return _buildSongItem(
                                  song.title,
                                  song.artist,
                                  song.key,
                                  song.isLiked,
                                  song: song,
                                );
                              },
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCollectionHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _collection?.color ?? Colors.grey[800], // Use collection color or fallback
        image: _collection?.imageUrl != null
            ? DecorationImage(
                image: NetworkImage(_collection!.imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
                onError: (exception, stackTrace) {
                  debugPrint('Error loading collection image: $exception');
                },
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Collection name
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  (_collection?.title ?? widget.collectionName).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // "MUSIC" text
            const Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "MUSIC",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Song count
            Positioned(
              bottom: 10,
              left: 16,
              child: Text(
                "${_songs.length} ${_songs.length == 1 ? 'Song' : 'Songs'}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),

            // Likes count
            Positioned(
              bottom: 10,
              right: 16,
              child: Row(
                children: [
                  Text(
                    "${_collection?.likes ?? 0}",
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

  Widget _buildCollectionDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Text(
        _collection?.description ?? 'No description available',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSongItem(String title, String artist, String key, bool isLiked, {Song? song}) {
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
        leading: const SongPlaceholder(size: 48),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFFC701),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          artist,
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
                key,
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
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                if (song != null) {
                  _toggleLike(song);
                }
              },
            ),
          ],
        ),
        onTap: () {
          // Navigate to song detail
          if (song != null) {
            Navigator.pushNamed(
              context,
              '/song_detail',
              arguments: song,
            );
          }
        },
      ),
    );
  }
}
