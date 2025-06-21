import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/song_placeholder.dart';
import '../models/collection.dart';
import '../models/song.dart';
import '../services/collection_service.dart';
import '../services/liked_songs_service.dart';
import '../widgets/memory_efficient_image.dart';
import '../widgets/skeleton_loader.dart';
import '../config/theme.dart';

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
  // Removed _currentIndex as we don't need it anymore

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will be called when the screen is resumed
    if (_collection != null) {
      _refreshLikeStatus();
    }
  }

  @override
  void didUpdateWidget(CollectionDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh like status when widget is updated
    if (_collection != null) {
      _refreshLikeStatus();
    }
  }

  @override
  void activate() {
    super.activate();
    // This will be called when the screen is resumed from being paused
    if (_collection != null) {
      _refreshLikeStatus();
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    // Note: Services are stateless and don't need disposal
    super.dispose();
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
          collection = await _collectionService.getCollectionById(
            widget.collectionId!,
          );
          debugPrint('Loaded collection by ID: ${collection.title}');
        } catch (e) {
          debugPrint('Error loading collection by ID: $e');
          // Fall back to loading by name
          collection = await _collectionService.getCollectionByName(
            widget.collectionName,
          );
        }
      } else {
        // Try to get collection by name
        collection = await _collectionService.getCollectionByName(
          widget.collectionName,
        );
        debugPrint('Loaded collection by name: ${collection?.title}');
      }

      if (collection != null) {
        // Get songs in collection
        final songsData = await _collectionService.getSongsInCollection(
          collection.id,
        );
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
                  : 'Added "${song.title}" to liked songs',
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

  // Refresh the like status of the current collection
  Future<void> _refreshLikeStatus() async {
    if (_collection == null) return;

    try {
      // Get the current Firebase user to check login status
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return; // Not logged in, no need to refresh

      // Get the like status for this collection
      final result = await _collectionService.getLikeStatus(_collection!.id);

      if (result['success'] == true && mounted) {
        final bool isLiked = result['data']['isLiked'] ?? false;

        // Only update if the like status has changed
        if (isLiked != _collection!.isLiked) {
          setState(() {
            // Create a new collection with updated like status
            _collection = Collection(
              id: _collection!.id,
              title: _collection!.title,
              description: _collection!.description,
              songCount: _collection!.songCount,
              likeCount: _collection!.likeCount,
              isLiked: isLiked,
              color: _collection!.color,
              imageUrl: _collection!.imageUrl,
              songs: _collection!.songs,
              isPublic: _collection!.isPublic,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error refreshing like status: $e');
      // Don't show an error message to the user for background refresh
    }
  }

  // Toggle like status of the collection
  Future<void> _toggleCollectionLike() async {
    if (_collection == null) return;

    final wasLiked = _collection!.isLiked;
    final oldLikeCount = _collection!.likeCount;

    try {
      // Get the current Firebase user to check login status
      final firebaseUser = FirebaseAuth.instance.currentUser;

      // Check if user is logged in using Firebase directly
      if (firebaseUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'You need to be logged in to like collections',
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Login',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),
            ),
          );
        }
        return;
      }

      // Immediately update UI for responsive feedback
      if (mounted) {
        setState(() {
          // Create a new collection with updated like status
          _collection = Collection(
            id: _collection!.id,
            title: _collection!.title,
            description: _collection!.description,
            songCount: _collection!.songCount,
            likeCount:
                oldLikeCount +
                (wasLiked ? -1 : 1), // Optimistically update like count
            isLiked: !wasLiked, // Immediately toggle like status
            color: _collection!.color,
            imageUrl: _collection!.imageUrl,
            songs: _collection!.songs,
            isPublic: _collection!.isPublic,
          );
        });
      }

      // Show immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasLiked
                ? 'Removed "${_collection!.title}" from liked collections'
                : 'Added "${_collection!.title}" to liked collections',
          ),
          backgroundColor: wasLiked ? Colors.grey : Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      // Make API call in the background
      final result = await _collectionService.toggleLike(_collection!.id);

      // If API call fails, revert the UI changes
      if (result['success'] != true && mounted) {
        setState(() {
          // Revert to original state
          _collection = Collection(
            id: _collection!.id,
            title: _collection!.title,
            description: _collection!.description,
            songCount: _collection!.songCount,
            likeCount: oldLikeCount, // Revert to original like count
            isLiked: wasLiked, // Revert to original like status
            color: _collection!.color,
            imageUrl: _collection!.imageUrl,
            songs: _collection!.songs,
            isPublic: _collection!.isPublic,
          );
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update like status'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (result['success'] == true && mounted) {
        // Update with the actual like count from the server if different
        final serverLikeCount = result['data']['likeCount'];
        if (serverLikeCount != null &&
            serverLikeCount != _collection!.likeCount) {
          setState(() {
            _collection = Collection(
              id: _collection!.id,
              title: _collection!.title,
              description: _collection!.description,
              songCount: _collection!.songCount,
              likeCount: serverLikeCount,
              isLiked: !wasLiked,
              color: _collection!.color,
              imageUrl: _collection!.imageUrl,
              songs: _collection!.songs,
              isPublic: _collection!.isPublic,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error toggling collection like: $e');

      // Revert UI changes on error
      if (mounted) {
        setState(() {
          // Revert to original state
          _collection = Collection(
            id: _collection!.id,
            title: _collection!.title,
            description: _collection!.description,
            songCount: _collection!.songCount,
            likeCount: oldLikeCount, // Revert to original like count
            isLiked: wasLiked, // Revert to original like status
            color: _collection!.color,
            imageUrl: _collection!.imageUrl,
            songs: _collection!.songs,
            isPublic: _collection!.isPublic,
          );
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update like status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build loading skeleton
  Widget _buildLoadingSkeleton() {
    return Column(
      children: [
        // Collection header skeleton
        SizedBox(
          height: 200,
          width: double.infinity,
          child: ShimmerEffect(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Container(color: Colors.grey[800]),
          ),
        ),

        // Collection info skeleton
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ShimmerEffect(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Collection name skeleton
                Container(
                  width: 250,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 12),
                // Description skeleton
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Divider
        const Divider(color: Color(0xFF333333), thickness: 1, height: 1),

        // Songs list skeleton
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: 8, // Show 8 skeleton items
            itemBuilder: (context, index) => const SongListItemSkeleton(),
          ),
        ),
      ],
    );
  }

  // Removed _onItemTapped method as we don't need it anymore

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true, // Ensures content goes behind the app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.transparent,
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
        // Title removed to make image more visible
        title: null,
      ),
      body:
          _isLoading
              ? _buildLoadingSkeleton()
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
                        backgroundColor: AppTheme.primary,
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
                    child:
                        _songs.isEmpty
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
      // Bottom navigation bar removed from inner screens
    );
  }

  Widget _buildCollectionHeader() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          // Background image or color
          _collection?.imageUrl != null
              ? MemoryEfficientImage(
                imageUrl: _collection!.imageUrl!,
                width: 800, // Use reasonable fixed size instead of infinity
                height: 200,
                fit: BoxFit.cover,
                backgroundColor: _collection?.color ?? Colors.grey[800]!,
                errorWidget: Container(
                  color: _collection?.color ?? Colors.grey[800],
                  child: Center(
                    child: Icon(
                      Icons.collections_bookmark,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              )
              : Container(
                color: _collection?.color ?? Colors.grey[800],
                child: Center(
                  child: Icon(
                    Icons.collections_bookmark,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(179), // 0.7 * 255 = 179
                ],
              ),
            ),
            child: Stack(
              children: [
                // Song count
                Positioned(
                  bottom: 10,
                  left: 16,
                  child: Text(
                    "${_songs.length} ${_songs.length == 1 ? 'Song' : 'Songs'}",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),

                // Likes count and like button
                Positioned(
                  bottom: 10,
                  right: 16,
                  child: Row(
                    children: [
                      Text(
                        "${_collection?.likeCount ?? 0}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Wrap in a Material widget for better touch feedback
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _toggleCollectionLike,
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              _collection?.isLiked == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  _collection?.isLiked == true
                                      ? Colors.red
                                      : Colors.white,
                              size: 28, // Increased size
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collection name (moved from image)
          Text(
            (_collection?.title ?? widget.collectionName).isNotEmpty
                ? '${(_collection?.title ?? widget.collectionName)[0].toUpperCase()}${(_collection?.title ?? widget.collectionName).substring(1).toLowerCase()}'
                : '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            _collection?.description ?? 'No description available',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSongItem(
    String title,
    String artist,
    String key,
    bool isLiked, {
    Song? song,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF333333), width: 1.0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: const SongPlaceholder(size: 48),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(artist, style: const TextStyle(color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Song Key
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                key,
                style: const TextStyle(color: Colors.white, fontSize: 12),
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
            Navigator.pushNamed(context, '/song_detail', arguments: song);
          }
        },
      ),
    );
  }
}
