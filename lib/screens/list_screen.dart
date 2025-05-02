import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';
import '../services/song_service.dart';
import '../services/artist_service.dart';
import '../services/collection_service.dart';

enum ListType {
  songs,
  artists,
  collections,
}

class ListScreen extends StatefulWidget {
  final String title;
  final ListType listType;
  final String? filterType; // Optional filter type (e.g., "trending", "new", "seasonal")

  const ListScreen({
    super.key,
    required this.title,
    required this.listType,
    this.filterType,
  });

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final SongService _songService = SongService();
  final ArtistService _artistService = ArtistService();
  final CollectionService _collectionService = CollectionService();

  bool _isLoading = true;
  String? _errorMessage;

  // Data lists
  List<Song> _songs = [];
  List<Artist> _artists = [];
  List<Collection> _collections = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      switch (widget.listType) {
        case ListType.songs:
          await _loadSongs();
          break;
        case ListType.artists:
          await _loadArtists();
          break;
        case ListType.collections:
          await _loadCollections();
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSongs() async {
    try {
      List<Song> songs;

      // Apply filter if specified
      if (widget.filterType == 'trending') {
        // For trending songs, we'll just get all songs for now
        // In a real app, you'd have a specific API endpoint for trending songs
        songs = await _songService.getAllSongs();
      } else if (widget.filterType == 'new') {
        // For new songs, we'll just get all songs for now
        // In a real app, you'd have a specific API endpoint for new songs
        songs = await _songService.getAllSongs();
      } else {
        // Default: get all songs
        songs = await _songService.getAllSongs();
      }

      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading songs: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadArtists() async {
    try {
      List<Artist> artists;

      // Apply filter if specified
      if (widget.filterType == 'top') {
        // For top artists, we'll just get all artists for now
        // In a real app, you'd have a specific API endpoint for top artists
        artists = await _artistService.getAllArtists();
      } else {
        // Default: get all artists
        artists = await _artistService.getAllArtists();
      }

      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading artists: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCollections() async {
    try {
      List<Collection> collections;

      // Apply filter if specified
      if (widget.filterType == 'seasonal') {
        collections = await _collectionService.getSeasonalCollections();
      } else if (widget.filterType == 'beginner') {
        collections = await _collectionService.getBeginnerFriendlyCollections();
      } else {
        // Default: get all collections
        collections = await _collectionService.getAllCollections();
      }

      if (mounted) {
        setState(() {
          _collections = collections;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading collections: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC701)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                'Error loading data',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC701),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Return the appropriate list based on the list type
    switch (widget.listType) {
      case ListType.songs:
        return _buildSongsList();
      case ListType.artists:
        return _buildArtistsList();
      case ListType.collections:
        return _buildCollectionsList();
    }
  }

  Widget _buildSongsList() {
    if (_songs.isEmpty) {
      return const Center(
        child: Text(
          'No songs available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return _buildSongListItem(song);
      },
    );
  }

  Widget _buildSongListItem(Song song) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8.0),
          image: song.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(song.imageUrl!),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    debugPrint('Error loading song image: ${song.title} - ${song.imageUrl}');
                  },
                )
              : null,
        ),
        child: song.imageUrl == null
            ? const Icon(Icons.music_note, color: Colors.white70)
            : null,
      ),
      title: Text(
        song.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        song.artist,
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/song_detail',
          arguments: song,
        );
      },
    );
  }

  Widget _buildArtistsList() {
    if (_artists.isEmpty) {
      return const Center(
        child: Text(
          'No artists available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return _buildArtistGridItem(artist);
      },
    );
  }

  Widget _buildArtistGridItem(Artist artist) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/artist_detail',
          arguments: {
            'artistName': artist.name,
          },
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[800],
                image: artist.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(artist.imageUrl!),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          debugPrint('Error loading artist image: ${artist.name} - ${artist.imageUrl}');
                        },
                      )
                    : null,
              ),
              child: artist.imageUrl == null
                  ? const Icon(Icons.person, color: Colors.white70, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            artist.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionsList() {
    if (_collections.isEmpty) {
      return const Center(
        child: Text(
          'No collections available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 16/9, // 16:9 aspect ratio for collection items
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: _collections.length,
      itemBuilder: (context, index) {
        final collection = _collections[index];
        return _buildCollectionGridItem(collection);
      },
    );
  }

  Widget _buildCollectionGridItem(Collection collection) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/collection_detail',
          arguments: {
            'collectionName': collection.title,
            'collectionId': collection.id,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.grey[800],
          image: collection.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(collection.imageUrl!),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    debugPrint('Error loading collection image: ${collection.title} - ${collection.imageUrl}');
                  },
                )
              : null,
        ),
        child: collection.imageUrl == null
            ? Center(
                child: Text(
                  collection.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : null,
      ),
    );
  }
}
