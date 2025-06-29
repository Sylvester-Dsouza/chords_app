import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';
import '../services/song_service.dart';
import '../services/artist_service.dart';
import '../services/collection_service.dart';
import '../services/home_section_service.dart';
import '../providers/app_data_provider.dart';
import '../widgets/song_placeholder.dart';
import '../config/theme.dart';

enum ListType { songs, artists, collections }

class ListScreen extends StatefulWidget {
  final String title;
  final ListType listType;
  final String?
  filterType; // Optional filter type (e.g., "trending", "new", "seasonal")
  final String? sectionId; // Optional section ID for fetching specific items
  final SectionType? sectionType; // Optional section type

  const ListScreen({
    super.key,
    required this.title,
    required this.listType,
    this.filterType,
    this.sectionId,
    this.sectionType,
  });

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final SongService _songService = SongService();
  final ArtistService _artistService = ArtistService();
  final CollectionService _collectionService = CollectionService();
  final HomeSectionService _homeSectionService = HomeSectionService();

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

  @override
  void dispose() {
    // Clean up any resources if needed
    // Note: Services are stateless and don't need disposal
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If we have a section ID and section type, load items from that section
      if (widget.sectionId != null && widget.sectionType != null) {
        await _loadSectionItems();
      } else {
        // Otherwise, load all items of the specified type
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
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  // Load items from a specific section using cached data
  Future<void> _loadSectionItems() async {
    try {
      debugPrint('Loading items from section ${widget.sectionId} using cached data');

      final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);

      // Find the section in cached home sections
      final homeSections = appDataProvider.homeSections;
      final section = homeSections.firstWhere(
        (s) => s.id == widget.sectionId,
        orElse: () => throw Exception('Section not found in cache'),
      );

      if (mounted) {
        setState(() {
          switch (widget.listType) {
            case ListType.songs:
              _songs = section.items.cast<Song>();
              break;
            case ListType.artists:
              _artists = section.items.cast<Artist>();
              break;
            case ListType.collections:
              _collections = section.items.cast<Collection>();
              break;
          }
          _isLoading = false;
        });

        debugPrint(
          'Loaded ${section.items.length} cached items from section ${widget.sectionId}',
        );
      }
    } catch (e) {
      debugPrint('Error loading from cache, falling back to API: $e');
      // Fallback to API if cache fails
      try {
        final items = await _homeSectionService.getSectionItems(
          widget.sectionId!,
          widget.sectionType!,
        );

        if (mounted) {
          setState(() {
            switch (widget.listType) {
              case ListType.songs:
                _songs = items.cast<Song>();
                break;
              case ListType.artists:
                _artists = items.cast<Artist>();
                break;
              case ListType.collections:
                _collections = items.cast<Collection>();
                break;
            }
            _isLoading = false;
          });

          debugPrint(
            'Fallback: Loaded ${items.length} items from API for section ${widget.sectionId}',
          );
        }
      } catch (apiError) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error loading section items: $apiError';
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _loadSongs() async {
    try {
      final appDataProvider = Provider.of<AppDataProvider>(
        context,
        listen: false,
      );
      List<Song> songs;

      // Try to get from cache first
      if (appDataProvider.songs.isNotEmpty) {
        songs = appDataProvider.songs;
        debugPrint('Using cached songs: ${songs.length} items');
      } else {
        // Fallback to API if cache is empty
        debugPrint('Cache miss - fetching songs from API');
        if (widget.filterType == 'trending') {
          songs = await _songService.getAllSongs();
        } else if (widget.filterType == 'new') {
          songs = await _songService.getAllSongs();
        } else {
          songs = await _songService.getAllSongs();
        }
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
      final appDataProvider = Provider.of<AppDataProvider>(
        context,
        listen: false,
      );
      List<Artist> artists;

      // Try to get from cache first
      if (appDataProvider.artists.isNotEmpty) {
        artists = appDataProvider.artists;
        debugPrint('Using cached artists: ${artists.length} items');
      } else {
        // Fallback to API if cache is empty
        debugPrint('Cache miss - fetching artists from API');
        if (widget.filterType == 'top') {
          artists = await _artistService.getAllArtists();
        } else {
          artists = await _artistService.getAllArtists();
        }
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
      final appDataProvider = Provider.of<AppDataProvider>(
        context,
        listen: false,
      );
      List<Collection> collections;

      // Try to get from cache first
      if (appDataProvider.collections.isNotEmpty) {
        collections = appDataProvider.collections;
        debugPrint('Using cached collections: ${collections.length} items');

        // Apply filter if specified (for now, just return all collections)
        // TODO: Add proper filtering based on collection metadata
        if (widget.filterType == 'seasonal') {
          // Filter by title/description containing seasonal keywords
          collections =
              collections
                  .where(
                    (c) =>
                        c.title.toLowerCase().contains('christmas') ||
                        c.title.toLowerCase().contains('easter') ||
                        c.title.toLowerCase().contains('seasonal') ||
                        c.description?.toLowerCase().contains('seasonal') ==
                            true,
                  )
                  .toList();
        } else if (widget.filterType == 'beginner') {
          // Filter by title/description containing beginner keywords
          collections =
              collections
                  .where(
                    (c) =>
                        c.title.toLowerCase().contains('beginner') ||
                        c.title.toLowerCase().contains('easy') ||
                        c.description?.toLowerCase().contains('beginner') ==
                            true,
                  )
                  .toList();
        }
      } else {
        // Fallback to API if cache is empty
        debugPrint('Cache miss - fetching collections from API');
        if (widget.filterType == 'seasonal') {
          collections = await _collectionService.getSeasonalCollections();
        } else if (widget.filterType == 'beginner') {
          collections =
              await _collectionService.getBeginnerFriendlyCollections();
        } else {
          collections = await _collectionService.getAllCollections();
        }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBar,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
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
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading data',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.title,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),

        // Songs list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 0),
            itemCount: _songs.length,
            itemBuilder: (context, index) {
              final song = _songs[index];
              return _buildSongListItem(song);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSongListItem(Song song) {
    // Get the song placeholder size
    const double placeholderSize = 48.0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.separator, width: 1.0),
        ),
      ),
      child: ListTile(
        // Reduce vertical padding to decrease space between items
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.0,
        ),
        leading: SongPlaceholder(size: placeholderSize),
        title: Text(
          song.title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          // Ensure text doesn't wrap unnecessarily
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          style: const TextStyle(color: AppTheme.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
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
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                song.key,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            // Chevron
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
        onTap: () {
          // Navigate to song detail
          if (mounted) {
            Navigator.pushNamed(context, '/song_detail', arguments: song);
          }
        },
      ),
    );
  }

  Widget _buildArtistsList() {
    if (_artists.isEmpty) {
      return const Center(
        child: Text(
          'No artists available',
          style: TextStyle(color: AppTheme.textSecondary),
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
          arguments: {'artistName': artist.name},
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceSecondary,
                image:
                    artist.imageUrl != null
                        ? DecorationImage(
                          image: NetworkImage(artist.imageUrl!),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            debugPrint(
                              'Error loading artist image: ${artist.name} - ${artist.imageUrl}',
                            );
                          },
                        )
                        : null,
              ),
              child:
                  artist.imageUrl == null
                      ? const Icon(
                        Icons.person,
                        color: AppTheme.textSecondary,
                        size: 40,
                      )
                      : null,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            artist.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
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
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.title,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),

        // Collections list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: _collections.length,
            itemBuilder: (context, index) {
              final collection = _collections[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildCollectionCard(collection),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(Collection collection) {
    return InkWell(
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
      borderRadius: BorderRadius.circular(5),
      child: Container(
        decoration: AppTheme.cardDecorationWithRadius(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container with exact 16:9 aspect ratio
            AspectRatio(
              aspectRatio: 16 / 9, // Exact 16:9 aspect ratio
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                  // Use image if available, otherwise use gradient
                  image:
                      collection.imageUrl != null
                          ? DecorationImage(
                            image: NetworkImage(collection.imageUrl!),
                            fit: BoxFit.contain,
                            onError: (exception, stackTrace) {
                              debugPrint(
                                'Error loading collection image: ${collection.title} - ${collection.imageUrl}',
                              );
                            },
                          )
                          : null,
                  gradient:
                      collection.imageUrl == null
                          ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              collection.color,
                              collection.color.withAlpha(150),
                            ],
                          )
                          : null,
                ),
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
                    collection.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
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
                        "${collection.songCount} Songs",
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),

                      // Likes count
                      Row(
                        children: [
                          Text(
                            collection.likeCount.toString(),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            collection.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                collection.isLiked ? AppTheme.error : AppTheme.textSecondary,
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
}
