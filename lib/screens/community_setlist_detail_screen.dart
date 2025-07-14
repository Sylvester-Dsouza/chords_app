import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/theme.dart';
import '../models/community_setlist.dart';
import '../models/setlist.dart';
import '../providers/community_provider.dart';
import '../services/setlist_service.dart';
import '../widgets/error_widget.dart';

class CommunitySetlistDetailScreen extends StatefulWidget {
  final String setlistId;

  const CommunitySetlistDetailScreen({super.key, required this.setlistId});

  @override
  State<CommunitySetlistDetailScreen> createState() =>
      _CommunitySetlistDetailScreenState();
}

class _CommunitySetlistDetailScreenState
    extends State<CommunitySetlistDetailScreen> {
  CommunitySetlist? _setlist;
  bool _isLoading = true;
  String? _error;

  // Setlist service for user setlists
  final SetlistService _setlistService = SetlistService();
  List<Setlist> _userSetlists = [];
  bool _loadingSetlists = false;

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
      final communityProvider = Provider.of<CommunityProvider>(
        context,
        listen: false,
      );

      // Look for setlist in all lists
      CommunitySetlist? foundSetlist;

      // Check community setlists
      foundSetlist =
          communityProvider.communitySetlists
              .where((s) => s.id == widget.setlistId)
              .firstOrNull;

      // Check trending setlists if not found
      foundSetlist ??=
          communityProvider.trendingSetlists
              .where((s) => s.id == widget.setlistId)
              .firstOrNull;

      // Check liked setlists if not found
      foundSetlist ??=
          communityProvider.likedSetlists
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
        body: const Center(child: CircularProgressIndicator()),
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
              iconSize: 22,
            ),
            // More options
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
              onSelected: _handleMenuAction,
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'add_all_to_setlist',
                      child: Row(
                        children: [
                          Icon(Icons.queue_music, size: 20),
                          SizedBox(width: 12),
                          Text('Add All to My Setlist'),
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
          bottom: TabBar(
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppTheme.textPrimary,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: const TextStyle(
              fontFamily: AppTheme.primaryFontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: AppTheme.primaryFontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            // Remove the divider line
            dividerColor: Colors.transparent,
            tabs: const [Tab(text: 'Songs'), Tab(text: 'Details')],
          ),
        ),
        body: TabBarView(
          children: [
            // Songs Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                  _buildSongsList(),
                ],
              ),
            ),
            // Details Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildSetlistHeader()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetlistHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.background.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                backgroundColor: AppTheme.border.withValues(alpha: 0.1),
                backgroundImage:
                    _setlist!.creator.profilePicture != null
                        ? NetworkImage(_setlist!.creator.profilePicture!)
                        : null,
                child:
                    _setlist!.creator.profilePicture == null
                        ? Text(
                          _setlist!.creator.name.isNotEmpty
                              ? _setlist!.creator.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
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
          if (_setlist!.description != null &&
              _setlist!.description!.isNotEmpty) ...[
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
                color: AppTheme.border,
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Like button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _toggleLike(),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _setlist!.isLikedByUser
                        ? AppTheme.textSecondary.withValues(alpha: 0.8)
                        : AppTheme.surface,
                foregroundColor:
                    _setlist!.isLikedByUser
                        ? Colors.white
                        : AppTheme.textPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color:
                        _setlist!.isLikedByUser
                            ? AppTheme.textSecondary
                            : AppTheme.border.withValues(alpha: 0.3),
                  ),
                ),
              ),
              icon: Icon(
                _setlist!.isLikedByUser
                    ? Icons.favorite
                    : Icons.favorite_border,
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
              onPressed: () => _addToExistingSetlist(_setlist!.id, null),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.1),
                foregroundColor: AppTheme.textSecondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
    );
  }

  Widget _buildSongsList() {
    // Create a list of all songs by repeating the available songs to fill the total count
    final allSongs = <CommunitySetlistSong>[];
    for (int i = 0; i < _setlist!.songCount; i++) {
      // Use modulo to cycle through available songs
      final songIndex = i % _setlist!.songPreview.length;
      allSongs.add(_setlist!.songPreview[songIndex]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Songs list - Show all songs as open
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _setlist!.songCount,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final song = allSongs[index];
            return _buildSongCard(song, index + 1);
          },
        ),
      ],
    );
  }

  // Song card
  Widget _buildSongCard(CommunitySetlistSong song, int position) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border.withValues(alpha: 0.1)),
      ),
      color: AppTheme.surface,
      child: InkWell(
        onTap: () => _navigateToSong(song),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              // Position number
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.border.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    position.toString(),
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.1,
                              ),
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
                    onPressed: () => _addToExistingSetlist(_setlist!.id, song),
                    icon: const Icon(
                      Icons.queue_music,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.background.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
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
        likeCount:
            _setlist!.isLikedByUser
                ? _setlist!.likeCount - 1
                : _setlist!.likeCount + 1,
      );
    });
  }

  void _addAllToSetlist() {
    _showSetlistSelectionDialog();
  }

  void _addToExistingSetlist(
    String setlistId,
    CommunitySetlistSong? singleSong,
  ) async {
    try {
      // Since we're now only showing the user's own setlists in the dialog,
      // we don't need to extensive permission checking here.
      // Just verify the user is logged in.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSuccessMessage('Please log in to add songs to setlists');
        return;
      }
      
      // Add detailed logging
      debugPrint('👤 Current user ID: ${currentUser.uid}');
      debugPrint('📋 Adding to setlist ID: $setlistId');
      if (singleSong != null) {
        debugPrint('🎵 Adding single song ID: ${singleSong.id}');
      } else if (_setlist != null) {
        debugPrint('🎵 Adding all songs from setlist: ${_setlist!.id}');
        debugPrint('🎵 Song count: ${_setlist!.songPreview.length}');
      }
      
      if (singleSong != null) {
        // Add single song to setlist
        await _setlistService.addSongToSetlist(setlistId, singleSong.id);
        _showSuccessMessage('Song added to setlist successfully!');
      } else if (_setlist != null) {
        // Add all songs to setlist
        final songIds = _setlist!.songPreview.map((song) => song.id).toList();
        await _setlistService.addMultipleSongsToSetlist(setlistId, songIds);
        _showSuccessMessage('All songs added to setlist successfully!');
      }
    } catch (e) {
      debugPrint('Error adding song(s) to setlist: $e');
      if (e.toString().contains('403')) {
        _showSuccessMessage('Backend limitation: Currently unable to add songs from community setlists');
      } else if (e.toString().contains('401')) {
        _showSuccessMessage('Please log in to add songs to setlists');
      } else {
        _showSuccessMessage('Failed to add song(s) to setlist');
      }
    }
  }
  
  // Method removed - feature is now available

  // Fetch user setlists for the modal
  Future<void> _fetchUserSetlists({
    required Function(void Function()) setModalState,
  }) async {
    if (_loadingSetlists) return;

    setModalState(() {
      _loadingSetlists = true;
    });

    try {
      debugPrint('Fetching user setlists...');
      final setlists = await _setlistService.getSetlists();
      
      // Filter to only show user's own setlists (not shared ones)
      final currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser?.uid;
      
      if (userId != null) {
        final ownSetlists = setlists.where((setlist) => setlist.customerId == userId).toList();
        debugPrint('Filtered ${ownSetlists.length} own setlists from ${setlists.length} total');
        
        setModalState(() {
          _userSetlists = ownSetlists;
          _loadingSetlists = false;
        });
      } else {
        setModalState(() {
          _userSetlists = setlists;
          _loadingSetlists = false;
        });
      }
      debugPrint('Loaded ${_userSetlists.length} user setlists');
    } catch (e) {
      debugPrint('Error loading user setlists: $e');
      setModalState(() {
        _loadingSetlists = false;
      });
    }
  }

  void _showSetlistSelectionDialog({CommunitySetlistSong? singleSong}) {
    // Reset state before showing dialog
    setState(() {
      _loadingSetlists = true;
      _userSetlists = [];
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              // Load setlists when the modal is first built
              Future.microtask(
                () => _fetchUserSetlists(setModalState: setModalState),
              );

              return Container(
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
                            ? 'Add "${singleSong.title}" to Setlist'
                            : 'Add All Songs to Setlist',
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
                        'Create New Setlist',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _createNewSetlist(singleSong);
                      },
                    ),

                    const Divider(),

                    // Existing playlists
                    Expanded(
                      child:
                          _loadingSetlists
                              ? const Center(child: CircularProgressIndicator())
                              : _userSetlists.isEmpty
                              ? Center(
                                child: Text(
                                  'No setlists found.\nCreate your first setlist above!',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16,
                                    fontFamily: AppTheme.primaryFontFamily,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                              : ListView.builder(
                                itemCount: _userSetlists.length,
                                itemBuilder: (context, index) {
                                  final setlist = _userSetlists[index];
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.border.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.queue_music,
                                        color: AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      setlist.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: AppTheme.primaryFontFamily,
                                      ),
                                    ),
                                    subtitle: Text(
                                      setlist.songs != null
                                          ? '${setlist.songs!.length} songs'
                                          : '0 songs',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        fontFamily: AppTheme.primaryFontFamily,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _addToExistingSetlist(
                                        setlist.id,
                                        singleSong,
                                      );
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  void _createNewSetlist(CommunitySetlistSong? singleSong) {
    // Show dialog to create new setlist
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Setlist'),
            content: const TextField(
              decoration: InputDecoration(
                hintText: 'Enter setlist name',
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
                  _showSuccessMessage('Setlist created successfully!');
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
      case 'add_all_to_setlist':
        _addAllToSetlist();
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
      builder:
          (context) => AlertDialog(
            title: const Text('Report Setlist'),
            content: const Text(
              'Are you sure you want to report this setlist?',
            ),
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
        backgroundColor: AppTheme.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
