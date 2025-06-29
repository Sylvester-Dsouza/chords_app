import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/community_provider.dart';
import '../models/community_setlist.dart';
import '../widgets/community_setlist_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/error_widget.dart';
import 'community_setlist_detail_screen.dart';

class CommunitySetlistsScreen extends StatefulWidget {
  const CommunitySetlistsScreen({super.key});

  @override
  State<CommunitySetlistsScreen> createState() => _CommunitySetlistsScreenState();
}

class _CommunitySetlistsScreenState extends State<CommunitySetlistsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedSort = 'newest';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CommunityProvider>(context, listen: false);
      provider.loadCommunitySetlists();
      provider.loadTrendingSetlists();
    });

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<CommunityProvider>(context, listen: false);
      if (_tabController.index == 0) {
        provider.loadMoreCommunitySetlists();
      } else if (_tabController.index == 2) {
        provider.loadMoreLikedSetlists();
      }
    }
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _selectedSort = sortBy;
    });
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    provider.loadCommunitySetlists(sortBy: sortBy, search: _searchQuery);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    provider.loadCommunitySetlists(
      sortBy: _selectedSort,
      search: query.isNotEmpty ? query : null,
      refresh: true,
    );
  }

  void _onRefresh() {
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    switch (_tabController.index) {
      case 0:
        provider.loadCommunitySetlists(
          sortBy: _selectedSort,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          refresh: true,
        );
        break;
      case 1:
        provider.loadTrendingSetlists(refresh: true);
        break;
      case 2:
        provider.loadLikedSetlists(refresh: true);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Community Setlists',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            fontFamily: AppTheme.primaryFontFamily,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          if (_tabController.index == 0)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: AppTheme.textPrimary),
              onSelected: _onSortChanged,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'newest',
                  child: Text('Newest'),
                ),
                const PopupMenuItem(
                  value: 'oldest',
                  child: Text('Oldest'),
                ),
                const PopupMenuItem(
                  value: 'mostLiked',
                  child: Text('Most Liked'),
                ),
                const PopupMenuItem(
                  value: 'mostViewed',
                  child: Text('Most Viewed'),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _onRefresh,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search setlists...',
                    hintStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
              ),
              
              // Tab bar
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Trending'),
                  Tab(text: 'Liked'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllSetlistsTab(),
          _buildTrendingTab(),
          _buildLikedTab(),
        ],
      ),
    );
  }

  Widget _buildAllSetlistsTab() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.communitySetlists.isEmpty) {
          return _buildLoadingState();
        }

        if (provider.error != null && provider.communitySetlists.isEmpty) {
          return _buildErrorState(provider.error!);
        }

        if (provider.communitySetlists.isEmpty) {
          return _buildEmptyState('No community setlists found');
        }

        return RefreshIndicator(
          onRefresh: () async => _onRefresh(),
          color: AppTheme.primary,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: provider.communitySetlists.length +
                      (provider.hasMoreCommunity ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.communitySetlists.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final setlist = provider.communitySetlists[index];
              return CommunitySetlistCard(
                setlist: setlist,
                onTap: () => _navigateToSetlistDetail(setlist),
                onLike: () => _toggleLike(setlist),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTrendingTab() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingTrending && provider.trendingSetlists.isEmpty) {
          return _buildLoadingState();
        }

        if (provider.trendingSetlists.isEmpty) {
          return _buildEmptyState('No trending setlists found');
        }

        return RefreshIndicator(
          onRefresh: () async => _onRefresh(),
          color: AppTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: provider.trendingSetlists.length,
            itemBuilder: (context, index) {
              final setlist = provider.trendingSetlists[index];
              return CommunitySetlistCard(
                setlist: setlist,
                onTap: () => _navigateToSetlistDetail(setlist),
                onLike: () => _toggleLike(setlist),
                showTrendingBadge: true,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLikedTab() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingLiked && provider.likedSetlists.isEmpty) {
          return _buildLoadingState();
        }

        if (provider.likedSetlists.isEmpty) {
          return _buildEmptyState('No liked setlists yet');
        }

        return RefreshIndicator(
          onRefresh: () async => _onRefresh(),
          color: AppTheme.primary,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: provider.likedSetlists.length +
                      (provider.hasMoreLiked ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.likedSetlists.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final setlist = provider.likedSetlists[index];
              return CommunitySetlistCard(
                setlist: setlist,
                onTap: () => _navigateToSetlistDetail(setlist),
                onLike: () => _toggleLike(setlist),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LoadingSkeleton(height: 120),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: CustomErrorWidget(
        message: error,
        onRetry: _onRefresh,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontFamily: AppTheme.primaryFontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToSetlistDetail(CommunitySetlist setlist) {
    // Increment view count
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    provider.incrementViewCount(setlist.id);

    // Navigate to community setlist detail
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunitySetlistDetailScreen(
          setlistId: setlist.id,
        ),
      ),
    );
  }

  void _toggleLike(CommunitySetlist setlist) {
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    if (setlist.isLikedByUser) {
      provider.unlikeSetlist(setlist.id);
    } else {
      provider.likeSetlist(setlist.id);
    }
  }
}
