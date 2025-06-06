import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../services/collection_service.dart';
import '../services/auth_service.dart';
import '../widgets/skeleton_loader.dart';

class LikedCollectionsScreen extends StatefulWidget {
  const LikedCollectionsScreen({super.key});

  @override
  State<LikedCollectionsScreen> createState() => _LikedCollectionsScreenState();
}

class _LikedCollectionsScreenState extends State<LikedCollectionsScreen> {
  // Removed _currentIndex as we don't need it anymore
  final CollectionService _collectionService = CollectionService();
  final AuthService _authService = AuthService();

  List<Collection> _likedCollections = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadLikedCollections();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
    }
  }

  Future<void> _loadLikedCollections() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check if user is logged in
      if (!_isLoggedIn) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You need to be logged in to view liked collections';
        });
        return;
      }

      // Get liked collections
      final likedCollections = await _collectionService.getLikedCollections();

      if (mounted) {
        setState(() {
          _likedCollections = likedCollections;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading liked collections: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading liked collections: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Removed navigation methods as we don't need them anymore

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Liked Collections'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: _buildBody(),
      // Bottom navigation bar removed from inner screens
    );
  }

  // Build loading skeleton
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 6, // Show 6 skeleton items
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ShimmerEffect(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[600]!,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                // Collection image skeleton
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                // Collection info skeleton
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title skeleton
                        Container(
                          width: double.infinity,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Description skeleton
                        Container(
                          width: 150,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const Spacer(),
                        // Song count skeleton
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!_isLoggedIn)
              ElevatedButton(
                onPressed: () {
                  // Navigate to login screen
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Log In'),
              ),
          ],
        ),
      );
    }

    if (_likedCollections.isEmpty) {
      return const Center(
        child: Text(
          'You haven\'t liked any collections yet',
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
      itemCount: _likedCollections.length,
      itemBuilder: (context, index) {
        final collection = _likedCollections[index];
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
        ).then((_) => _loadLikedCollections()); // Refresh after returning
      },
      child: Stack(
        children: [
          // Collection background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
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

          // Gradient overlay for text visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(179), // 0.7 * 255 = 179
                  ],
                ),
              ),
            ),
          ),

          // Collection title
          if (collection.imageUrl != null)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                collection.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Like count and icon
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(128),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Text(
                    "${collection.likeCount}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
