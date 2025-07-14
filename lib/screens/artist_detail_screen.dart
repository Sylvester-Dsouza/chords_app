import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/song_placeholder.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../services/song_service.dart';
import '../services/artist_service.dart';
import '../services/liked_songs_service.dart';
import '../providers/app_data_provider.dart';
import '../widgets/memory_efficient_image.dart';
import '../widgets/skeleton_loader.dart';
import '../config/theme.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistName;

  const ArtistDetailScreen({super.key, required this.artistName});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  // Removed _currentIndex as we don't need it anymore

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

  @override
  void dispose() {
    // Clean up any resources if needed
    // Note: Services are stateless and don't need disposal
    super.dispose();
  }

  // Load artist data and songs with caching optimization
  Future<void> _loadArtistData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final appDataProvider = Provider.of<AppDataProvider>(
        context,
        listen: false,
      );

      // Try to find artist in cached data first
      Artist? artist = appDataProvider.artists.firstWhere(
        (a) => a.name.toLowerCase() == widget.artistName.toLowerCase(),
        orElse: () => Artist(id: '', name: '', songCount: 0),
      );

      if (artist.id.isEmpty) {
        // Fallback to API if not found in cache
        debugPrint('Artist not found in cache, fetching from API');
        artist = await _artistService.getArtistByName(widget.artistName);
      } else {
        debugPrint('Using cached artist data for: ${artist.name}');
      }

      List<Song> songs = [];

      if (artist != null && artist.id.isNotEmpty) {
        // Try to get songs from cached data first
        songs =
            appDataProvider.songs
                .where(
                  (song) =>
                      song.artist.toLowerCase() ==
                      widget.artistName.toLowerCase(),
                )
                .toList();

        if (songs.isEmpty) {
          // Fallback to API if no songs found in cache
          debugPrint('Songs not found in cache, fetching from API');
          songs = await _songService.getSongsByArtist(artist.id);
        } else {
          debugPrint('Using cached songs for artist: ${songs.length} songs');
        }

        // Get liked songs to update status (this is user-specific, so always fetch)
        final likedSongs = await _likedSongsService.getLikedSongs();
        for (var song in songs) {
          song.isLiked = likedSongs.any((likedSong) => likedSong.id == song.id);
        }

        if (mounted) {
          setState(() {
            _artist = artist;
            _songs = songs;
            _isLoading = false;
          });

          // Debug the loaded artist data
          debugPrint('=== LOADED ARTIST DATA ===');
          debugPrint('Artist: ${artist.name}');
          debugPrint('Bio: ${artist.bio}');
          debugPrint('Website: ${artist.website}');
          debugPrint('SocialLinks object: ${artist.socialLinks}');
          if (artist.socialLinks != null) {
            debugPrint('Facebook: ${artist.socialLinks!.facebook}');
            debugPrint('Instagram: ${artist.socialLinks!.instagram}');
            debugPrint('Twitter: ${artist.socialLinks!.twitter}');
            debugPrint('YouTube: ${artist.socialLinks!.youtube}');
          }
          debugPrint('========================');
        }
      } else {
        // If artist not found, try to get songs by artist name from cache
        songs =
            appDataProvider.songs
                .where(
                  (song) =>
                      song.artist.toLowerCase() ==
                      widget.artistName.toLowerCase(),
                )
                .toList();

        if (songs.isEmpty) {
          // Fallback to API
          songs = await _songService.getSongsByArtistName(widget.artistName);
        }

        // Get liked songs to update status
        final likedSongs = await _likedSongsService.getLikedSongs();
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

  // Build loading skeleton
  Widget _buildLoadingSkeleton() {
    return Column(
      children: [
        // Artist header skeleton
        SizedBox(
          height: 200,
          width: double.infinity,
          child: ShimmerEffect(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Container(color: Colors.grey[800]),
          ),
        ),

        // Artist info skeleton
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ShimmerEffect(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artist name skeleton
                Container(
                  width: 200,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 8),
                // Song count skeleton
                Container(
                  width: 120,
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: _buildLoadingSkeleton(),
      );
    }
    
    if (_hasError) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          title: Text(
            widget.artistName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: AppTheme.displayFontFamily,
                  fontWeight: FontWeight.w700,
                ),
          ),
          iconTheme: IconThemeData(color: AppTheme.textPrimary),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load artist data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                ),
                onPressed: _loadArtistData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Main content with collapsing header
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Collapsing App Bar
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.background,
            elevation: 0,
            leadingWidth: 56.0, // Ensure enough space for the back button
            titleSpacing: 0, // Remove default title spacing
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56.0, bottom: 16.0), // Position after back button with less spacing
              title: Text(
                _artist?.name ?? widget.artistName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: AppTheme.displayFontFamily,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Artist image
                  _artist?.imageUrl != null
                      ? MemoryEfficientImage(
                          imageUrl: _artist!.imageUrl!,
                          width: 800,
                          height: 250,
                          fit: BoxFit.cover,
                          backgroundColor: AppTheme.surface,
                          errorWidget: Container(
                            color: AppTheme.surface,
                            child: Center(
                              child: Icon(Icons.person, color: AppTheme.textPrimary, size: 64),
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.surface,
                          child: Center(
                            child: Icon(Icons.person, color: AppTheme.textPrimary, size: 64),
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
                          AppTheme.background.withAlpha(180),
                          AppTheme.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Bio info icon in top right app bar
              if (_artist?.bio != null && _artist!.bio!.isNotEmpty)
                IconButton(
                  icon: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withAlpha(100),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.info_outline, color: AppTheme.textPrimary),
                    ),
                  ),
                  onPressed: () {
                    // Show artist bio
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: AppTheme.surface,
                          title: Text(
                            _artist?.name ?? widget.artistName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          content: SingleChildScrollView(
                            child: Text(
                              _artist?.bio ?? '',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text('Close', style: TextStyle(color: AppTheme.primary)),
                              onPressed: () => Navigator.of(dialogContext).pop(),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
          
          // Artist info section
          SliverToBoxAdapter(
            child: _buildArtistInfo(),
          ),
          
          // Divider
          SliverToBoxAdapter(
            child: Divider(
              color: AppTheme.separator,
              thickness: 1,
              height: 1,
            ),
          ),
          
          // Songs list
          _songs.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No songs found for ${_artist?.name ?? widget.artistName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = _songs[index];
                      return _buildSongItem(
                        song.title,
                        song.artist,
                        song.key,
                        song.isLiked,
                        song: song,
                      );
                    },
                    childCount: _songs.length,
                  ),
                ),
        ],
      ),
    ); // Bottom navigation bar removed from inner screens
  }

  // Artist header is now handled by SliverAppBar

  Widget _buildArtistInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Artist avatar and song count
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child:
                    _artist?.imageUrl != null
                        ? ClipOval(
                          child: MemoryEfficientImage(
                            imageUrl: _artist!.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            backgroundColor: AppTheme.surface,
                            errorWidget: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.surface,
                              ),
                              child: Icon(
                                Icons.person,
                                color: AppTheme.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        )
                        : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surface,
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppTheme.textPrimary,
                            size: 20,
                          ),
                        ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Songs',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${_songs.length} ${_songs.length == 1 ? 'song' : 'songs'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Dynamic social media icons and website
          _buildSocialMediaIcons(),
        ],
      ),
    );
  }

  // Launch URL helper method
  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build dynamic social media icons
  Widget _buildSocialMediaIcons() {
    List<Widget> socialIcons = [];

    // Debug logging
    debugPrint('=== SOCIAL MEDIA DEBUG ===');
    debugPrint('Artist: ${_artist?.name}');
    debugPrint('Artist ID: ${_artist?.id}');
    debugPrint('Website: ${_artist?.website}');
    debugPrint('Social Links: ${_artist?.socialLinks}');
    if (_artist?.socialLinks != null) {
      debugPrint('Facebook: ${_artist!.socialLinks!.facebook}');
      debugPrint('Instagram: ${_artist!.socialLinks!.instagram}');
      debugPrint('Twitter: ${_artist!.socialLinks!.twitter}');
      debugPrint('YouTube: ${_artist!.socialLinks!.youtube}');
    }
    debugPrint('========================');

    if (_artist?.socialLinks != null) {
      final socialLinks = _artist!.socialLinks!;

      // Facebook
      if (socialLinks.facebook != null && socialLinks.facebook!.isNotEmpty) {
        debugPrint('Adding Facebook icon for: ${socialLinks.facebook}');
        socialIcons.add(
          IconButton(
            icon: const Text(
              'f',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => _launchUrl(socialLinks.facebook!),
            tooltip: 'Facebook',
            iconSize: 24,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        );
      }

      // Instagram
      if (socialLinks.instagram != null && socialLinks.instagram!.isNotEmpty) {
        debugPrint('Adding Instagram icon for: ${socialLinks.instagram}');
        socialIcons.add(
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            onPressed: () => _launchUrl(socialLinks.instagram!),
            tooltip: 'Instagram',
            iconSize: 24,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        );
      }

      // Twitter/X
      if (socialLinks.twitter != null && socialLinks.twitter!.isNotEmpty) {
        debugPrint('Adding Twitter/X icon for: ${socialLinks.twitter}');
        socialIcons.add(
          IconButton(
            icon: const Text(
              '𝕏',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => _launchUrl(socialLinks.twitter!),
            tooltip: 'Twitter/X',
            iconSize: 24,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        );
      }

      // YouTube
      if (socialLinks.youtube != null && socialLinks.youtube!.isNotEmpty) {
        debugPrint('Adding YouTube icon for: ${socialLinks.youtube}');
        socialIcons.add(
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
            onPressed: () => _launchUrl(socialLinks.youtube!),
            tooltip: 'YouTube',
            iconSize: 24,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        );
      }
    }

    // Website
    if (_artist?.website != null && _artist!.website!.isNotEmpty) {
      debugPrint('Adding Website icon for: ${_artist!.website}');
      socialIcons.add(
        IconButton(
          icon: const Icon(Icons.language, color: Colors.white, size: 16),
          onPressed: () => _launchUrl(_artist!.website!),
          tooltip: 'Website',
          iconSize: 24,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      );
    }

    // Return row with social icons or empty container if no links
    if (socialIcons.isNotEmpty) {
      return Row(children: socialIcons);
    } else {
      // Show a debug message if no social icons are found
      debugPrint(
        'No social icons to display - check if backend data is being parsed correctly',
      );
      return const SizedBox.shrink();
    }
  }

  Widget _buildSongItem(
    String title,
    String artist,
    String key,
    bool isLiked, {
    Song? song,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.separator, width: 1.0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.0,
        ),
        leading: const SongPlaceholder(size: 40),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          artist,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Song Key
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 3.0,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                key,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            // Like Button
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? AppTheme.error : AppTheme.textSecondary,
                size: 20,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
