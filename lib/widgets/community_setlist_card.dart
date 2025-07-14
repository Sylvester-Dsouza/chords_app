import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/community_setlist.dart';

class CommunitySetlistCard extends StatelessWidget {
  final CommunitySetlist setlist;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool showTrendingBadge;
  final bool showLikedBadge;

  const CommunitySetlistCard({
    super.key,
    required this.setlist,
    required this.onTap,
    required this.onLike,
    this.showTrendingBadge = false,
    this.showLikedBadge = false,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shadowColor: AppTheme.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppTheme.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with setlist name and trending badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        setlist.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.primaryFontFamily,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showTrendingBadge) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.trending_up,
                              size: 12,
                              color: AppTheme.primary,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Trending',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTheme.primaryFontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

              // Description (if available)
              if (setlist.description != null && setlist.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  setlist.description!,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontFamily: AppTheme.primaryFontFamily,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

                const SizedBox(height: 12),

                // Creator info and stats in a more compact layout
                Row(
                  children: [
                    // Creator name
                    Expanded(
                      child: Text(
                        'By ${setlist.creator.name}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Date
                    Text(
                      _formatDate(setlist.sharedAt),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),


                // Stats row - simplified and more compact
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.border.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Song count
                      _buildCompactStat(
                        icon: Icons.queue_music,
                        value: '${setlist.songCount} songs',
                        color: AppTheme.textSecondary,
                        isSmall: true,
                      ),
                      const Spacer(),
                      // Views
                      _buildCompactStat(
                        icon: Icons.visibility_outlined,
                        value: _formatNumber(setlist.viewCount),
                        color: AppTheme.textSecondary,
                        isSmall: true,
                      ),
                      const SizedBox(width: 16),
                      // Likes with action
                      InkWell(
                        onTap: onLike,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: _buildCompactStat(
                            icon: setlist.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                            value: _formatNumber(setlist.likeCount),
                            color: setlist.isLikedByUser ? Colors.red : AppTheme.textSecondary,
                            isSmall: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStat({
    required IconData icon,
    required String value,
    required Color color,
    required bool isSmall,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isSmall ? 14 : 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isSmall ? 12 : 14,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
      ],
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
