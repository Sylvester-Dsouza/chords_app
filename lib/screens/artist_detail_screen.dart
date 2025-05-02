import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/song_placeholder.dart';
import '../widgets/animated_bottom_nav_bar.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../services/song_service.dart';
import '../services/artist_service.dart';
import '../services/liked_songs_service.dart';
import '../providers/navigation_provider.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistName;

  const ArtistDetailScreen({
    super.key,
    required this.artistName,
  });

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  int _currentIndex = 2; // Set to 2 for Search tab

  // Services
  final SongService _songService = SongService();
  final ArtistService _artistService = ArtistService();
  final LikedSongsService _likedSongsService = LikedSongsService();

  // Data
  Artist? _artist;
  List<Song> _songs = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadArtistData();
  }

  // Load artist data and songs
  Future<void> _loadArtistData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Try to get artist by name
      final artist = await _artistService.getArtistByName(widget.artistName);

      if (artist != null) {
        // Get songs by artist ID
        final songs = await _songService.getSongsByArtist(artist.id);

        // Get liked songs to update status
        final likedSongs = await _likedSongsService.getLikedSongs();

        // Update liked status
        for (var song in songs) {
          song.isLiked = likedSongs.any((likedSong) => likedSong.id == song.id);
        }

        if (mounted) {
          setState(() {
            _artist = artist;
            _songs = songs;
            _isLoading = false;
          });
        }
      } else {
        // If artist not found by name, try to get songs by artist name
        final songs = await _songService.getSongsByArtistName(widget.artistName);

        // Get liked songs to update status
        final likedSongs = await _likedSongsService.getLikedSongs();

        // Update liked status
        for (var song in songs) {
          song.isLiked = likedSongs.any((likedSong) => likedSong.id == song.id);
        }

        if (mounted) {
          setState(() {
            // Create a basic artist object with just the name
            _artist = Artist(
              id: 'unknown',
              name: widget.artistName,
              songCount: songs.length,
            );
            _songs = songs;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading artist data: $e');
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
                        'Failed to load artist data',
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
                        onPressed: _loadArtistData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Artist header with image
                    _buildArtistHeader(),

                    // Artist info
                    _buildArtistInfo(),

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
                                'No songs found for ${_artist?.name ?? widget.artistName}',
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

  Widget _buildArtistHeader() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[800], // Fallback color
        image: _artist?.imageUrl != null
            ? DecorationImage(
                image: NetworkImage(_artist!.imageUrl!),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  debugPrint('Error loading artist image: $exception');
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
              Colors.black.withAlpha(180),
              Colors.black,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              _artist?.name ?? widget.artistName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Artist avatar and song count
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[800],
                  image: _artist?.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_artist!.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Songs',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_songs.length} ${_songs.length == 1 ? 'song' : 'songs'}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Bio button if available
          if (_artist?.bio != null && _artist!.bio!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () {
                // Show artist bio
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      title: Text(
                        _artist?.name ?? widget.artistName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      content: SingleChildScrollView(
                        child: Text(
                          _artist?.bio ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Close'),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),

          // Social media icons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.facebook, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.alternate_email, color: Colors.white), // Using @ symbol as Twitter/X replacement
                onPressed: () {},
              ),
            ],
          ),
        ],
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
            fontSize: 12,
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
                color: isLiked ? Colors.red : Colors.white,
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
