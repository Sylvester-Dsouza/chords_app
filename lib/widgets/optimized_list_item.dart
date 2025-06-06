import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';

/// A widget that optimizes rendering of list items by only rebuilding
/// when its data changes, not when the parent rebuilds.
class OptimizedListItem extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;
  final String? imageUrl;
  final String? subtitle;
  final bool isLoading;

  const OptimizedListItem({
    super.key,
    required this.title,
    required this.color,
    required this.onTap,
    this.imageUrl,
    this.subtitle,
    this.isLoading = false,
  });

  /// Factory constructor for creating a song item
  factory OptimizedListItem.fromSong(Song song, {required VoidCallback onTap}) {
    return OptimizedListItem(
      title: song.title,
      subtitle: song.artist,
      color: Colors.blue.withValues(alpha: 0.3), // Default color
      imageUrl: song.imageUrl,
      onTap: onTap,
    );
  }

  /// Factory constructor for creating an artist item
  factory OptimizedListItem.fromArtist(Artist artist, {required VoidCallback onTap}) {
    return OptimizedListItem(
      title: artist.name,
      color: Colors.purple.withValues(alpha: 0.3), // Default color
      imageUrl: artist.imageUrl,
      onTap: onTap,
    );
  }

  /// Factory constructor for creating a collection item
  factory OptimizedListItem.fromCollection(Collection collection, {required VoidCallback onTap}) {
    return OptimizedListItem(
      title: collection.title,
      color: collection.color,
      imageUrl: collection.imageUrl,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingItem();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            debugPrint('Error loading image: $imageUrl');
                          },
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? const Center(
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white70,
                          size: 40,
                        ),
                      )
                    : null,
              ),
            ),

            // Title and subtitle
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer effect for image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ),
          ),

          // Shimmer effect for text
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
