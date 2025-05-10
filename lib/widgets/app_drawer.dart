import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/page_transitions.dart';
import '../screens/playlist_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/resources_screen.dart';
import '../screens/search_screen.dart';
import '../screens/song_request_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/login_screen.dart';
import '../screens/remove_ads_screen.dart';
import '../screens/premium_content_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: SafeArea(
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Logo and close button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Logo
                          Row(
                            children: [
                              // Flame icon
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                child: Icon(
                                  Icons.local_fire_department,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // App name
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Worship',
                                      style: TextStyle(color: Color(0xFFFFC701)),
                                    ),
                                    TextSpan(
                                      text: '\nParadise',
                                      style: TextStyle(color: Color(0xFFFFC701)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Close button
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Color(0xFF333333)),

                    // Main menu items
                    _buildMenuItem(context, Icons.music_note, 'Request a Song'),
                    _buildMenuItem(context, Icons.school, 'Resources'),

                    const Divider(color: Color(0xFF333333)),

                    // Support menu items
                    _buildMenuItem(context, Icons.help, 'Help & Support'),
                    _buildMenuItem(context, Icons.info, 'About us'),
                    _buildMenuItem(context, Icons.mail, 'Contact us'),

                    const Divider(color: Color(0xFF333333)),

                    // Additional options
                    _buildMenuItem(context, Icons.handshake, 'Contribute'),
                    _buildMenuItem(context, Icons.block_flipped, 'Remove Ads'),
                    _buildMenuItem(context, Icons.star, 'Premium Content'),

                    // Add some bottom padding to ensure there's enough space
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Fixed logout button at the bottom
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(color: Color(0xFF333333)),
                // Logout (only shown when logged in)
                Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    if (userProvider.isLoggedIn) {
                      return _buildMenuItem(context, Icons.logout, 'Logout');
                    } else {
                      return const SizedBox.shrink(); // Hide when not logged in
                    }
                  },
                ),
                const SizedBox(height: 8), // Small padding at the bottom
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.grey,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
      onTap: () {
        // Close the drawer
        Navigator.pop(context);

        // Handle navigation based on the menu item
        switch (title) {
          case 'Home':
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 'My Playlist':
            _navigateWithTransition(context, '/playlist');
            break;
          case 'Profile':
            _navigateWithTransition(context, '/profile');
            break;
          case 'Resources':
            _navigateWithTransition(context, '/resources');
            break;
          case 'Artists':
            // Navigate to artists screen when available
            // For now, show a message that it's coming soon
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Artists page coming soon!'),
                backgroundColor: Color(0xFFFFC701),
                duration: Duration(seconds: 2),
              ),
            );
            break;
          case 'Collections':
            // Navigate to collections screen when available
            // For now, show a message that it's coming soon
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Collections page coming soon!'),
                backgroundColor: Color(0xFFFFC701),
                duration: Duration(seconds: 2),
              ),
            );
            break;
          case 'Search Chords':
            _navigateWithTransition(context, '/search');
            break;
          case 'Request a Song':
            _navigateWithTransition(context, '/song_request');
            break;
          case 'Help & Support':
            // Navigate to help screen when available
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Help & Support page coming soon!'),
                backgroundColor: Color(0xFFFFC701),
                duration: Duration(seconds: 2),
              ),
            );
            break;
          case 'About us':
            _navigateWithTransition(context, '/about_us');
            break;
          case 'Contact us':
            // Navigate to contact screen when available
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact us page coming soon!'),
                backgroundColor: Color(0xFFFFC701),
                duration: Duration(seconds: 2),
              ),
            );
            break;
          case 'Contribute':
            // Navigate to contribute screen when available
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contribute page coming soon!'),
                backgroundColor: Color(0xFFFFC701),
                duration: Duration(seconds: 2),
              ),
            );
            break;
          case 'Remove Ads':
            // Navigate to remove ads screen
            _navigateWithTransition(context, '/remove-ads');
            break;
          case 'Premium Content':
            // Navigate to premium content screen
            _navigateWithTransition(context, '/premium-content');
            break;
          case 'Logout':
            _showLogoutConfirmationDialog(context);
            break;
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
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(color: Colors.white),
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                _performLogout(context);
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFFFFC701)),
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
      case '/playlist':
        page = const PlaylistScreen();
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
      case '/remove-ads':
        page = const RemoveAdsScreen();
        break;
      case '/premium-content':
        page = const PremiumContentScreen();
        break;
      default:
        // If we don't have a specific case, use the named route
        Navigator.pushNamed(context, routeName, arguments: arguments);
        return;
    }

    // Navigate with a custom transition
    Navigator.of(context).push(FadeSlidePageRoute(page: page));
  }
}
