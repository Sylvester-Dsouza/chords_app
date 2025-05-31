import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/page_transitions.dart';
import '../config/theme.dart';
import '../screens/setlist_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/resources_screen.dart';
import '../screens/search_screen.dart';
import '../screens/song_request_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/login_screen.dart';
import '../screens/vocal_warmups_screen.dart';
import '../screens/vocal_exercises_screen.dart';
import '../screens/courses_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bool isLoggedIn = userProvider.isLoggedIn;

    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Modern header with logo
                    _buildDrawerHeader(context),

                    const SizedBox(height: 16),

                    // Features Section
                    _buildSectionHeader(context, 'Features'),
                    _buildMenuItem(
                      context,
                      Icons.music_note_outlined,
                      'Request a Song',
                      routeName: '/song_request',
                    ),
                    _buildMenuItem(
                      context,
                      Icons.favorite_border_outlined,
                      'Liked Collections',
                      routeName: '/liked-collections',
                    ),
                    _buildMenuItem(
                      context,
                      Icons.mic_outlined,
                      'Vocal Warm-ups',
                      routeName: '/vocal-warmups',
                    ),
                    _buildMenuItem(
                      context,
                      Icons.music_note_outlined,
                      'Vocal Exercises',
                      routeName: '/vocal-exercises',
                    ),
                    _buildMenuItem(
                      context,
                      Icons.school_outlined,
                      'Vocal Courses',
                      routeName: '/vocal-courses',
                    ),

                    const SizedBox(height: 16),

                    // Support Section
                    _buildSectionHeader(context, 'Support'),
                    _buildMenuItem(
                      context,
                      Icons.help_outline,
                      'Help & Support',
                      routeName: '/help-support',
                    ),
                    _buildMenuItem(
                      context,
                      Icons.info_outline,
                      'About Us',
                      routeName: '/about_us',
                    ),
                    _buildMenuItem(
                      context,
                      Icons.mail_outline,
                      'Contact Us',
                      routeName: '/contact-us',
                    ),

                    const SizedBox(height: 16),

                    // Contribute Section
                    _buildSectionHeader(context, 'Contribute'),
                    _buildMenuItem(
                      context,
                      Icons.handshake_outlined,
                      'Contribute Songs',
                      routeName: '/contribute',
                    ),
                    _buildMenuItem(
                      context,
                      Icons.volunteer_activism_outlined,
                      'Support Us',
                      routeName: '/support',
                    ),

                    // Add some bottom padding to ensure there's enough space
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Fixed login/logout button at the bottom
            _buildBottomSection(context, isLoggedIn, userProvider),
          ],
        ),
      ),
    );
  }

  // Modern drawer header with logo
  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and app name
          Row(
            children: [
              // Stuthi logo
              Image.asset(
                AppLogos.getDrawerLogo(),
                height: 44,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              // App name and description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stuthi',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Christian Chords & Lyrics',
                    style: TextStyle(
                      color: AppTheme.subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceColor,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  // Section header
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.subtitleColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom section with login/logout
  Widget _buildBottomSection(BuildContext context, bool isLoggedIn, UserProvider userProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: const Border(
          top: BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      child: isLoggedIn
        ? ElevatedButton.icon(
            onPressed: () => _showLogoutConfirmationDialog(context),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withAlpha(51), // 0.2 * 255 = 51
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        : ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    {String? routeName}
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        // Close the drawer
        Navigator.pop(context);

        // If routeName is provided, navigate to that route
        if (routeName != null) {
          _navigateWithTransition(context, routeName);
        } else {
          // Handle navigation based on the menu item title as fallback
          switch (title) {
            case 'Request a Song':
              _navigateWithTransition(context, '/song_request');
              break;
            case 'Liked Collections':
              _navigateWithTransition(context, '/liked-collections');
              break;
            case 'Vocal Warm-ups':
              _navigateWithTransition(context, '/vocal-warmups');
              break;
            case 'Vocal Exercises':
              _navigateWithTransition(context, '/vocal-exercises');
              break;
            case 'Vocal Courses':
              _navigateWithTransition(context, '/vocal-courses');
              break;
            case 'Help & Support':
              _navigateWithTransition(context, '/help-support');
              break;
            case 'About Us':
              _navigateWithTransition(context, '/about_us');
              break;
            case 'Contact Us':
              // Navigate to contact screen when available
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Contact page coming soon!'),
                  backgroundColor: AppTheme.primaryColor,
                  duration: const Duration(seconds: 2),
                ),
              );
              break;
            case 'Contribute Songs':
              // Navigate to contribute screen when available
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Contribute page coming soon!'),
                  backgroundColor: AppTheme.primaryColor,
                  duration: const Duration(seconds: 2),
                ),
              );
              break;
            case 'Support Us':
              _navigateWithTransition(context, '/support');
              break;
            case 'Logout':
              _showLogoutConfirmationDialog(context);
              break;
          }
        }
      },
    );
  }

  // Show confirmation dialog before logout
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                _performLogout(context);
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Perform the actual logout
  void _performLogout(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.logout();

    // Navigate to login screen and clear the navigation stack
    // This prevents going back to protected screens after logout
    if (context.mounted) {
      // Use a custom transition for logout
      Navigator.of(context).pushAndRemoveUntil(
        FadePageRoute(page: const LoginScreen()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  // Helper method to navigate with a smooth transition
  void _navigateWithTransition(BuildContext context, String routeName, {Object? arguments}) {
    // Get the page widget for the route
    Widget? page;

    switch (routeName) {
      case '/setlist':
        page = const SetlistScreen();
        break;
      case '/profile':
        page = const ProfileScreen();
        break;
      case '/resources':
        page = const ResourcesScreen();
        break;
      case '/search':
        page = const SearchScreen();
        break;
      case '/song_request':
        page = const SongRequestScreen();
        break;
      case '/about_us':
        page = const AboutUsScreen();
        break;
      case '/notifications':
        page = const NotificationScreen();
        break;
      case '/vocal-warmups':
        page = const VocalWarmupsScreen();
        break;
      case '/vocal-exercises':
        page = const VocalExercisesScreen();
        break;
      case '/vocal-courses':
        page = const VocalCoursesScreen();
        break;
      // Premium content removed to fix crashing issues
      // case '/premium-content':
      //   page = const PremiumContentScreen();
      //   break;
      default:
        // If we don't have a specific case, use the named route
        Navigator.pushNamed(context, routeName, arguments: arguments);
        return;
    }

    // Navigate with a custom transition
    Navigator.of(context).push(FadeSlidePageRoute(page: page));
  }
}
