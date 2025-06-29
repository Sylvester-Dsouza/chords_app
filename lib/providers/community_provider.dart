import 'package:flutter/foundation.dart';
import '../models/community_setlist.dart';
import '../services/community_service.dart';

class CommunityProvider with ChangeNotifier {
  final CommunityService _communityService;

  CommunityProvider(this._communityService);

  // Community setlists state
  List<CommunitySetlist> _communitySetlists = [];
  bool _isLoading = false;
  bool _hasMoreCommunity = true;
  int _currentPage = 1;
  String? _error;

  // Trending setlists state
  List<CommunitySetlist> _trendingSetlists = [];
  bool _isLoadingTrending = false;

  // Liked setlists state
  List<CommunitySetlist> _likedSetlists = [];
  bool _isLoadingLiked = false;
  bool _hasMoreLiked = true;
  int _currentLikedPage = 1;

  // Getters
  List<CommunitySetlist> get communitySetlists => _communitySetlists;
  bool get isLoading => _isLoading;
  bool get hasMoreCommunity => _hasMoreCommunity;
  String? get error => _error;

  List<CommunitySetlist> get trendingSetlists => _trendingSetlists;
  bool get isLoadingTrending => _isLoadingTrending;

  List<CommunitySetlist> get likedSetlists => _likedSetlists;
  bool get isLoadingLiked => _isLoadingLiked;
  bool get hasMoreLiked => _hasMoreLiked;

  // Load community setlists
  Future<void> loadCommunitySetlists({
    String sortBy = 'newest',
    String? search,
    bool refresh = false,
  }) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMoreCommunity = true;
      _communitySetlists.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _communityService.getCommunitySetlists(
        page: _currentPage,
        sortBy: sortBy,
        search: search,
      );

      if (refresh) {
        _communitySetlists = response.setlists;
      } else {
        _communitySetlists.addAll(response.setlists);
      }

      _hasMoreCommunity = response.hasMore;
      _currentPage = response.page + 1;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading community setlists: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more community setlists (pagination)
  Future<void> loadMoreCommunitySetlists({String sortBy = 'newest'}) async {
    if (!_hasMoreCommunity || _isLoading) return;
    await loadCommunitySetlists(sortBy: sortBy);
  }

  // Load trending setlists
  Future<void> loadTrendingSetlists({bool refresh = false}) async {
    if (_isLoadingTrending && !refresh) return;

    _isLoadingTrending = true;
    notifyListeners();

    try {
      final response = await _communityService.getTrendingSetlists();
      _trendingSetlists = response.setlists;
    } catch (e) {
      debugPrint('Error loading trending setlists: $e');
    } finally {
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  // Load liked setlists
  Future<void> loadLikedSetlists({bool refresh = false}) async {
    if (_isLoadingLiked && !refresh) return;

    if (refresh) {
      _currentLikedPage = 1;
      _hasMoreLiked = true;
      _likedSetlists.clear();
    }

    _isLoadingLiked = true;
    notifyListeners();

    try {
      final response = await _communityService.getMyLikedSetlists(
        page: _currentLikedPage,
      );

      if (refresh) {
        _likedSetlists = response.setlists;
      } else {
        _likedSetlists.addAll(response.setlists);
      }

      _hasMoreLiked = response.hasMore;
      _currentLikedPage = response.page + 1;
    } catch (e) {
      debugPrint('Error loading liked setlists: $e');
    } finally {
      _isLoadingLiked = false;
      notifyListeners();
    }
  }

  // Load more liked setlists (pagination)
  Future<void> loadMoreLikedSetlists() async {
    if (!_hasMoreLiked || _isLoadingLiked) return;
    await loadLikedSetlists();
  }

  // Like a setlist
  Future<void> likeSetlist(String setlistId) async {
    try {
      final result = await _communityService.likeSetlist(setlistId);
      
      if (result['success'] == true) {
        _updateSetlistLikeStatus(setlistId, true, result['likeCount'] as int);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error liking setlist: $e');
    }
  }

  // Unlike a setlist
  Future<void> unlikeSetlist(String setlistId) async {
    try {
      final result = await _communityService.unlikeSetlist(setlistId);
      
      if (result['success'] == true) {
        _updateSetlistLikeStatus(setlistId, false, result['likeCount'] as int);
        
        // Remove from liked setlists if currently viewing liked tab
        _likedSetlists.removeWhere((setlist) => setlist.id == setlistId);
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error unliking setlist: $e');
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String setlistId) async {
    try {
      final result = await _communityService.incrementViewCount(setlistId);
      
      if (result['success'] == true) {
        _updateSetlistViewCount(setlistId, result['viewCount'] as int);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  // Helper method to update like status across all lists
  void _updateSetlistLikeStatus(String setlistId, bool isLiked, int newLikeCount) {
    // Update in community setlists
    final communityIndex = _communitySetlists.indexWhere((s) => s.id == setlistId);
    if (communityIndex != -1) {
      _communitySetlists[communityIndex] = _communitySetlists[communityIndex].copyWith(
        isLikedByUser: isLiked,
        likeCount: newLikeCount,
      );
    }

    // Update in trending setlists
    final trendingIndex = _trendingSetlists.indexWhere((s) => s.id == setlistId);
    if (trendingIndex != -1) {
      _trendingSetlists[trendingIndex] = _trendingSetlists[trendingIndex].copyWith(
        isLikedByUser: isLiked,
        likeCount: newLikeCount,
      );
    }

    // Update in liked setlists
    final likedIndex = _likedSetlists.indexWhere((s) => s.id == setlistId);
    if (likedIndex != -1) {
      _likedSetlists[likedIndex] = _likedSetlists[likedIndex].copyWith(
        isLikedByUser: isLiked,
        likeCount: newLikeCount,
      );
    }
  }

  // Helper method to update view count across all lists
  void _updateSetlistViewCount(String setlistId, int newViewCount) {
    // Update in community setlists
    final communityIndex = _communitySetlists.indexWhere((s) => s.id == setlistId);
    if (communityIndex != -1) {
      _communitySetlists[communityIndex] = _communitySetlists[communityIndex].copyWith(
        viewCount: newViewCount,
      );
    }

    // Update in trending setlists
    final trendingIndex = _trendingSetlists.indexWhere((s) => s.id == setlistId);
    if (trendingIndex != -1) {
      _trendingSetlists[trendingIndex] = _trendingSetlists[trendingIndex].copyWith(
        viewCount: newViewCount,
      );
    }

    // Update in liked setlists
    final likedIndex = _likedSetlists.indexWhere((s) => s.id == setlistId);
    if (likedIndex != -1) {
      _likedSetlists[likedIndex] = _likedSetlists[likedIndex].copyWith(
        viewCount: newViewCount,
      );
    }
  }

  // Clear all data (useful for logout)
  void clear() {
    _communitySetlists.clear();
    _trendingSetlists.clear();
    _likedSetlists.clear();
    _isLoading = false;
    _isLoadingTrending = false;
    _isLoadingLiked = false;
    _hasMoreCommunity = true;
    _hasMoreLiked = true;
    _currentPage = 1;
    _currentLikedPage = 1;
    _error = null;
    notifyListeners();
  }
}
