import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../widgets/auth_wrapper.dart';
import '../providers/user_provider.dart';
import '../providers/navigation_provider.dart';
import '../utils/toast_util.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 4; // Set to 4 for Profile tab

  @override
  void initState() {
    super.initState();

    // Sync with navigation provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
      navigationProvider.updateIndex(4); // Profile screen is index 4
      setState(() {
        _currentIndex = 4;
      });
    });
  }



  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bool isLoggedIn = userProvider.isLoggedIn;
    final userData = userProvider.userData;

    return AuthWrapper(
      requireAuth: false, // Allow both logged in and guest users
      child: Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const InnerScreenAppBar(
        title: 'Profile',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header - Compact layout with image on left, text on right
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[800],
                      border: Border.all(
                        color: const Color(0xFFFFC701),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Name
                        Text(
                          isLoggedIn ? (userData?['name'] ?? 'User') : 'Guest User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Email
                        Text(
                          isLoggedIn ? (userData?['email'] ?? 'No email') : 'Not logged in',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Profile Button
                        SizedBox(
                          width: double.infinity,
                          child: isLoggedIn
                            ? ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/personal-details');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text('Edit Profile'),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFC701),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text('Login'),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF333333)),

            // Stats Section - More compact
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Playlists', '12'),
                  _buildStatItem('Favorites', '48'),
                  _buildStatItem('Contributions', '5'),
                ],
              ),
            ),

            const Divider(color: Color(0xFF333333)),

            // Settings Section
            _buildSettingsSection(),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFC701),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isLoggedIn = userProvider.isLoggedIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Menu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Account Section
        _buildSectionHeader('Account'),
        _buildSettingsItem(
          Icons.person,
          'Personal Details',
          onTap: () {
            Navigator.pushNamed(context, '/personal-details');
          },
        ),
        _buildSettingsItem(
          Icons.notifications,
          'Notifications',
          onTap: () {
            Navigator.pushNamed(context, '/notifications');
          },
        ),

        // App Section
        _buildSectionHeader('App'),
        _buildSettingsItem(
          Icons.info,
          'About Us',
          onTap: () {
            Navigator.pushNamed(context, '/about_us');
          },
        ),
        _buildSettingsItem(
          Icons.privacy_tip,
          'Privacy Policy',
          onTap: () {
            Navigator.pushNamed(context, '/privacy-policy');
          },
        ),
        _buildSettingsItem(
          Icons.help,
          'Help & Support',
          onTap: () {
            Navigator.pushNamed(context, '/help-support');
          },
        ),
        _buildSettingsItem(
          Icons.star,
          'Rate the App',
          onTap: () {
            Navigator.pushNamed(context, '/rate-app');
          },
        ),

        // Contribute Section
        _buildSectionHeader('Contribute'),
        _buildSettingsItem(
          Icons.music_note,
          'Contribute Songs',
          onTap: () {
            Navigator.pushNamed(context, '/contribute');
          },
          isHighlighted: true,
        ),

        // Logout (only if logged in)
        if (isLoggedIn) ...[
          const SizedBox(height: 24),
          _buildSettingsItem(
            Icons.logout,
            'Logout',
            isLogout: true,
            onTap: () async {
              // Show confirmation dialog
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    title: const Text('Logout', style: TextStyle(color: Colors.white)),
                    content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFFFFC701))),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                // Use a separate method to handle logout to avoid BuildContext issues
                _handleLogout(userProvider);
              }
            },
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Handle logout with proper context management
  Future<void> _handleLogout(UserProvider userProvider) async {
    if (!mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const AlertDialog(
          backgroundColor: Color(0xFF1E1E1E),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Logging out...', style: TextStyle(color: Colors.white)),
            ],
          ),
        );
      },
    );

    try {
      // Perform logout
      await userProvider.logout();

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ToastUtil.showSuccess(context, 'Logged out successfully');

      // Clear navigation history and go to login screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false, // Remove all previous routes
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ToastUtil.showError(context, 'Error logging out: $e');
    }
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title, {
    bool isLogout = false,
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout
          ? Colors.red
          : isHighlighted
            ? const Color(0xFFFFC701)
            : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout
            ? Colors.red
            : isHighlighted
              ? const Color(0xFFFFC701)
              : Colors.white,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isLogout
          ? null
          : const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
      onTap: onTap,
    );
  }
}
