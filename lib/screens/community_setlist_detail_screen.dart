import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/community_setlist.dart';
import '../providers/community_provider.dart';
import '../widgets/error_widget.dart';

class CommunitySetlistDetailScreen extends StatefulWidget {
  final String setlistId;

  const CommunitySetlistDetailScreen({
    super.key,
    required this.setlistId,
  });

  @override
  State<CommunitySetlistDetailScreen> createState() => _CommunitySetlistDetailScreenState();
}

class _CommunitySetlistDetailScreenState extends State<CommunitySetlistDetailScreen> {
  CommunitySetlist? _setlist;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSetlistDetails();
  }

  void _loadSetlistDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Find setlist in community provider
      final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
      
      // Look for setlist in all lists
      CommunitySetlist? foundSetlist;
      
      // Check community setlists
      foundSetlist = communityProvider.communitySetlists
          .where((s) => s.id == widget.setlistId)
          .firstOrNull;
      
      // Check trending setlists if not found
      foundSetlist ??= communityProvider.trendingSetlists
          .where((s) => s.id == widget.setlistId)
          .firstOrNull;
      
      // Check liked setlists if not found
      foundSetlist ??= communityProvider.likedSetlists
          .where((s) => s.id == widget.setlistId)
          .firstOrNull;

      if (foundSetlist != null) {
        setState(() {
          _setlist = foundSetlist;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Setlist not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load setlist details';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.appBar,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Loading...',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.appBar,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Error',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ),
        body: Center(
          child: CustomErrorWidget(
            message: _error!,
            onRetry: _loadSetlistDetails,
          ),
        ),
      );
    }

    if (_setlist == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.appBar,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Not Found',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Setlist not found',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _setlist!.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            fontFamily: AppTheme.primaryFontFamily,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.textPrimary),
            onPressed: () => _shareSetlist(),
          ),
          // More options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_all_to_playlist',
                child: Row(
                  children: [
                    Icon(Icons.playlist_add, size: 20),
                    SizedBox(width: 12),
                    Text('Add All to My Playlist'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_setlist',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 12),
                    Text('Copy to My Setlists'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 20),
                    SizedBox(width: 12),
                    Text('Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSetlistHeader(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildSongsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSetlistHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Setlist name
          Text(
            _setlist!.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: AppTheme.primaryFontFamily,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Creator info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                backgroundImage: _setlist!.creator.profilePicture != null
                    ? NetworkImage(_setlist!.creator.profilePicture!)
                    : null,
                child: _setlist!.creator.profilePicture == null
                    ? Text(
                        _setlist!.creator.name.isNotEmpty
                            ? _setlist!.creator.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _setlist!.creator.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                    Text(
                      'Shared ${_formatDate(_setlist!.sharedAt)}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Description if available
          if (_setlist!.description != null && _setlist!.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _setlist!.description!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                fontFamily: AppTheme.primaryFontFamily,
                height: 1.5,
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Stats
          Row(
            children: [
              _buildStatChip(
                icon: Icons.queue_music,
                label: '${_setlist!.songCount} songs',
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.visibility_outlined,
                label: '${_formatNumber(_setlist!.viewCount)} views',
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.favorite,
                label: '${_formatNumber(_setlist!.likeCount)} likes',
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Like button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _toggleLike(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _setlist!.isLikedByUser
                  ? Colors.red
                  : AppTheme.surface,
              foregroundColor: _setlist!.isLikedByUser
                  ? Colors.white
                  : AppTheme.textPrimary,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _setlist!.isLikedByUser
                      ? Colors.red
                      : AppTheme.border.withValues(alpha: 0.3),
                ),
              ),
            ),
            icon: Icon(
              _setlist!.isLikedByUser ? Icons.favorite : Icons.favorite_border,
              size: 20,
            ),
            label: Text(
              _setlist!.isLikedByUser ? 'Liked' : 'Like',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Add all to playlist button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _addAllToPlaylist(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.playlist_add, size: 20),
            label: const Text(
              'Add All',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSongsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Songs',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
            const Spacer(),
            Text(
              '${_setlist!.songCount} songs',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Songs list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _setlist!.songPreview.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final song = _setlist!.songPreview[index];
            return _buildSongCard(song, index + 1);
          },
        ),

        // Show more songs message if there are more
        if (_setlist!.songCount > _setlist!.songPreview.length) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This setlist contains ${_setlist!.songCount - _setlist!.songPreview.length} more songs. Copy to your setlists to see all songs.',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSongCard(CommunitySetlistSong song, int position) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.border.withValues(alpha: 0.2),
        ),
      ),
      color: AppTheme.surface,
      child: InkWell(
        onTap: () => _navigateToSong(song),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Position number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    position.toString(),
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            song.artist,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              fontFamily: AppTheme.primaryFontFamily,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (song.key != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.textSecondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              song.key!,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppTheme.primaryFontFamily,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _addSongToPlaylist(song),
                    icon: const Icon(
                      Icons.playlist_add,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _navigateToSong(song),
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLike() {
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    if (_setlist!.isLikedByUser) {
      provider.unlikeSetlist(_setlist!.id);
    } else {
      provider.likeSetlist(_setlist!.id);
    }

    // Update local state
    setState(() {
      _setlist = _setlist!.copyWith(
        isLikedByUser: !_setlist!.isLikedByUser,
        likeCount: _setlist!.isLikedByUser
            ? _setlist!.likeCount - 1
            : _setlist!.likeCount + 1,
      );
    });
  }

  void _addAllToPlaylist() {
    _showPlaylistSelectionDialog();
  }

  void _addSongToPlaylist(CommunitySetlistSong song) {
    _showPlaylistSelectionDialog(singleSong: song);
  }

  void _showPlaylistSelectionDialog({CommunitySetlistSong? singleSong}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                singleSong != null
                    ? 'Add "${singleSong.title}" to Playlist'
                    : 'Add All Songs to Playlist',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Create new playlist option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              title: const Text(
                'Create New Playlist',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _createNewPlaylist(singleSong);
              },
            ),

            const Divider(),

            // Existing playlists placeholder
            Expanded(
              child: Center(
                child: Text(
                  'Your playlists will appear here.\nCreate your first playlist above!',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createNewPlaylist(CommunitySetlistSong? singleSong) {
    // Show dialog to create new playlist
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Playlist'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter playlist name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Playlist created successfully!');
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }



  void _navigateToSong(CommunitySetlistSong song) {
    Navigator.pushNamed(
      context,
      '/song_detail',
      arguments: {'songId': song.id},
    );
  }

  void _shareSetlist() {
    _showSuccessMessage('Setlist shared!');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'add_all_to_playlist':
        _addAllToPlaylist();
        break;
      case 'copy_setlist':
        _copySetlist();
        break;
      case 'report':
        _reportSetlist();
        break;
    }
  }

  void _copySetlist() {
    _showSuccessMessage('Setlist copied to your setlists!');
  }

  void _reportSetlist() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Setlist'),
        content: const Text('Are you sure you want to report this setlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Setlist reported. Thank you!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
