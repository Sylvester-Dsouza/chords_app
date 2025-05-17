import 'package:flutter/material.dart';
import '../models/playlist.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
    required this.onDelete,
    this.onEdit,
    this.onShare,
  });

  // Generate a consistent color based on playlist name
  Color _generateColor(String name) {
    final int hash = name.hashCode;
    final List<Color> colors = [
      const Color(0xFFE57373), // Red
      const Color(0xFFFFB74D), // Orange
      const Color(0xFFFFF176), // Yellow
      const Color(0xFFAED581), // Light Green
      const Color(0xFF4FC3F7), // Light Blue
      const Color(0xFF9575CD), // Purple
      const Color(0xFFF06292), // Pink
      const Color(0xFF4DB6AC), // Teal
    ];

    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = _generateColor(playlist.name);
    final int songCount = playlist.songs?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10), // Reduced margin
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // Smaller radius
        boxShadow: [
          BoxShadow(
            color: cardColor.withAlpha(30), // Using withAlpha instead of withOpacity
            blurRadius: 4, // Smaller blur
            offset: const Offset(0, 1), // Smaller offset
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12), // Smaller radius
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A), // Simpler background
              borderRadius: BorderRadius.circular(12), // Smaller radius
              border: Border.all(
                color: cardColor.withAlpha(40), // Using withAlpha
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // Smaller padding
              child: Row(
                children: [
                  // Playlist icon
                  Container(
                    padding: const EdgeInsets.all(6), // Smaller padding
                    decoration: BoxDecoration(
                      color: cardColor.withAlpha(40), // Using withAlpha
                      borderRadius: BorderRadius.circular(6), // Smaller radius
                    ),
                    child: Icon(
                      Icons.queue_music_rounded, // Rounded icon
                      color: cardColor,
                      size: 20, // Smaller icon
                    ),
                  ),
                  const SizedBox(width: 10), // Smaller spacing

                  // Playlist info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Playlist name
                        Text(
                          playlist.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Smaller font
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Song count
                        Text(
                          '$songCount ${songCount == 1 ? 'song' : 'songs'}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12, // Smaller font
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu button
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: const Color(0xFF1E1E1E),
                    elevation: 4,
                    offset: const Offset(0, 8),
                    itemBuilder: (context) => [
                      // Share option
                      PopupMenuItem<String>(
                        value: 'share',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.share_rounded,
                                color: Colors.green,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Share',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      // Edit option
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.orange,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Edit',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      // Delete option
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Delete',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'share':
                          onShare?.call();
                          break;
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
