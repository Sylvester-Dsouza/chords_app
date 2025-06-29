import 'package:flutter/material.dart';
import '../models/setlist.dart';
import '../config/theme.dart';

class SetlistCard extends StatelessWidget {
  final Setlist setlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;

  const SetlistCard({
    super.key,
    required this.setlist,
    required this.onTap,
    required this.onDelete,
    this.onEdit,
    this.onShare,
  });

  // Generate a consistent color based on setlist name
  Color _generateColor(String name) {
    final int hash = name.hashCode;
    final List<Color> colors = [
      AppTheme.accent4, // Red
      AppTheme.accent3, // Orange
      AppTheme.accent3, // Orange (replacing yellow for better contrast)
      AppTheme.accent2, // Green
      AppTheme.primary, // Primary blue
      AppTheme.accent1, // Purple
      AppTheme.accent4, // Red (replacing pink)
      AppTheme.accent2, // Green (replacing teal)
    ];

    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = _generateColor(setlist.name);
    final int songCount = setlist.songs?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10), // Reduced margin
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5), // Smaller radius
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
          borderRadius: BorderRadius.circular(5), // Smaller radius
          child: Ink(
            decoration: AppTheme.cardDecorationWithRadius(5).copyWith(
              border: Border.all(
                color: cardColor.withAlpha(40), // Keep the dynamic accent border
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // Smaller padding
              child: Row(
                children: [
                  // Setlist icon
                  Container(
                    padding: const EdgeInsets.all(6), // Smaller padding
                    decoration: BoxDecoration(
                      color: cardColor.withAlpha(40), // Using withAlpha
                      borderRadius: BorderRadius.circular(5), // Smaller radius
                    ),
                    child: Icon(
                      Icons.queue_music_rounded, // Rounded icon
                      color: cardColor,
                      size: 20, // Smaller icon
                    ),
                  ),
                  const SizedBox(width: 10), // Smaller spacing

                  // Setlist info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Setlist name with status tags
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center, // Center align vertically
                          children: [
                            Expanded(
                              child: Text(
                                setlist.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16, // Smaller font
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Status tags
                            if (setlist.isSharedWithMe) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(40),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: AppTheme.primary.withAlpha(80),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  'Joined',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: AppTheme.primaryFontFamily,
                                  ),
                                ),
                              ),
                            ] else if (setlist.isShared && setlist.shareCode != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withAlpha(40),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: AppTheme.success.withAlpha(80),
                                    width: 0.5,
                                  ),
                                ),
                                child: const Text(
                                  'Shared',
                                  style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            // Shared tag
                            if (setlist.isSharedWithMe == true)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.info.withAlpha(51),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: AppTheme.info.withAlpha(128),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'SHARED',
                                  style: TextStyle(
                                    color: AppTheme.info,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Song count
                        Text(
                          '$songCount ${songCount == 1 ? 'song' : 'songs'}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
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
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        color: AppTheme.textPrimary,
                        size: 18,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    color: AppTheme.surface,
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
                                color: AppTheme.success.withAlpha(40),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Icon(
                                Icons.share_rounded,
                                color: AppTheme.success,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Share',
                              style: TextStyle(color: AppTheme.textPrimary),
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
                                color: AppTheme.warning.withAlpha(40),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: AppTheme.warning,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Edit',
                              style: TextStyle(color: AppTheme.textPrimary),
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
                                color: AppTheme.error.withAlpha(40),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppTheme.error,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Delete',
                              style: TextStyle(color: AppTheme.textPrimary),
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
