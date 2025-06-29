import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/community_setlist.dart';

class CommunitySetlistCard extends StatelessWidget {
  final CommunitySetlist setlist;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool showTrendingBadge;

  const CommunitySetlistCard({
    super.key,
    required this.setlist,
    required this.onTap,
    required this.onLike,
    this.showTrendingBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shadowColor: AppTheme.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppTheme.border.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        color: AppTheme.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
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
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppTheme.primaryFontFamily,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showTrendingBadge) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary,
                              AppTheme.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'Hot',
                              style: TextStyle(
                                color: Colors.white,
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
                const SizedBox(height: 8),
                Text(
                  setlist.description!,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

                const SizedBox(height: 12),

                // Creator info - compact and responsive
                Row(
                  children: [
                    CircleAvatar(
                      radius: isSmallScreen ? 12 : 14,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      backgroundImage: setlist.creator.profilePicture != null
                          ? NetworkImage(setlist.creator.profilePicture!)
                          : null,
                      child: setlist.creator.profilePicture == null
                          ? Text(
                              setlist.creator.name.isNotEmpty
                                  ? setlist.creator.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: isSmallScreen ? 10 : 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTheme.primaryFontFamily,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        setlist.creator.name,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '• ${_formatDate(setlist.sharedAt)}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: isSmallScreen ? 11 : 12,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stats and actions row - responsive layout
                Row(
                  children: [
                    // Stats - responsive spacing
                    Expanded(
                      child: Row(
                        children: [
                          _buildCompactStat(
                            icon: Icons.queue_music,
                            value: setlist.songCount.toString(),
                            color: AppTheme.primary,
                            isSmall: isSmallScreen,
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          _buildCompactStat(
                            icon: Icons.visibility_outlined,
                            value: _formatNumber(setlist.viewCount),
                            color: Colors.blue,
                            isSmall: isSmallScreen,
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          _buildCompactStat(
                            icon: setlist.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                            value: _formatNumber(setlist.likeCount),
                            color: setlist.isLikedByUser ? Colors.red : AppTheme.textSecondary,
                            isSmall: isSmallScreen,
                          ),
                        ],
                      ),
                    ),

                    // Like button - responsive size
                    Container(
                      width: isSmallScreen ? 36 : 40,
                      height: isSmallScreen ? 36 : 40,
                      decoration: BoxDecoration(
                        color: setlist.isLikedByUser
                            ? Colors.red.withValues(alpha: 0.1)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: setlist.isLikedByUser
                              ? Colors.red.withValues(alpha: 0.3)
                              : AppTheme.border.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: onLike,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          setlist.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                          color: setlist.isLikedByUser ? Colors.red : AppTheme.textSecondary,
                          size: isSmallScreen ? 18 : 20,
                        ),
                      ),
                    ),
                  ],
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
