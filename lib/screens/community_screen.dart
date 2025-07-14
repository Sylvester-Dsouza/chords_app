import 'package:flutter/material.dart';
import '../config/theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
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
          'Community',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            fontFamily: AppTheme.primaryFontFamily,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            _buildWelcomeSection(),
            const SizedBox(height: 24),

            // Community features grid
            _buildCommunityFeatures(),
            const SizedBox(height: 24),

            // Coming soon section
            _buildComingSoonSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.1),
            AppTheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, color: AppTheme.primary, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Welcome to Community',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Discover, share, and connect with fellow worship musicians. Explore community-shared setlists, collaborate on music, and grow together in worship.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontFamily: AppTheme.primaryFontFamily,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Community Features',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildFeatureCard(
              icon: Icons.queue_music,
              title: 'Setlists',
              description: 'Discover and share worship setlists',
              color: AppTheme.primary.withValues(alpha: 0.9),
              onTap: _navigateToCommunitySetlists,
              isActive: true,
            ),
            _buildFeatureCard(
              icon: Icons.group,
              title: 'Collaborations',
              description: 'Collaborate with other musicians',
              color: AppTheme.textSecondary,
              onTap: () => _showComingSoon('Collaborations'),
              isActive: false,
            ),
            _buildFeatureCard(
              icon: Icons.event,
              title: 'Events',
              description: 'Find worship events near you',
              color: AppTheme.textSecondary,
              onTap: () => _showComingSoon('Events'),
              isActive: false,
            ),
            _buildFeatureCard(
              icon: Icons.forum,
              title: 'Forums',
              description: 'Discuss worship music and techniques',
              color: AppTheme.textSecondary,
              onTap: () => _showComingSoon('Forums'),
              isActive: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final isComingSoon = !isActive;

    return InkWell(
      onTap: isActive ? onTap : () => _showComingSoon(title),
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.7,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.border.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (isComingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Coming Soon',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color:
                      isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color:
                      isActive
                          ? AppTheme.textSecondary
                          : AppTheme.textSecondary.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.3),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface.withValues(alpha: 0.8), AppTheme.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rocket_launch_outlined,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Coming Soon',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Musician profiles and connections\n• Community song contributions\n• Worship event listings\n• Collaborative songwriting tools\n• Live streaming integration',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontFamily: AppTheme.primaryFontFamily,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCommunitySetlists() {
    Navigator.pushNamed(context, '/community_setlists');
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
