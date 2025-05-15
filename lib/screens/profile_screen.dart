import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../widgets/auth_wrapper.dart';
import '../providers/user_provider.dart';
import '../providers/navigation_provider.dart';
import '../utils/toast_util.dart';
import '../config/theme.dart';

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
              // Modern Profile Header
              _buildProfileHeader(isLoggedIn, userData),

              const Divider(color: Color(0xFF333333)),

              // Settings Sections
              _buildSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isLoggedIn, Map<String, dynamic>? userData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(width: 20),

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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Email
                Text(
                  isLoggedIn ? (userData?['email'] ?? 'No email') : 'Not logged in',
                  style: TextStyle(
                    color: AppTheme.subtitleColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Show joined date for logged in users or login button for guests
                isLoggedIn
                  ? Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppTheme.subtitleColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Joined January 2023',
                          style: TextStyle(
                            color: AppTheme.subtitleColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        // Login Button
                        SizedBox(
                          height: 36,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            icon: const Icon(
                              Icons.login,
                              size: 16,
                            ),
                            label: const Text('Login'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              textStyle: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isLoggedIn = userProvider.isLoggedIn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsCard([
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
          ]),
          const SizedBox(height: 24),

          // App Section
          _buildSectionHeader('App'),
          _buildSettingsCard([
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
          ]),
          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingsCard([
            _buildSettingsItem(
              Icons.volunteer_activism,
              'Support Us',
              onTap: () {
                Navigator.pushNamed(context, '/support');
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Logout (only if logged in)
          if (isLoggedIn) ...[
            _buildLogoutButton(userProvider),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildLogoutButton(UserProvider userProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
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
                    child: Text('Cancel', style: TextStyle(color: AppTheme.primaryColor)),
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
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withAlpha(51), // 0.2 * 255 = 51
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
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
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? AppTheme.primaryColor.withAlpha(51) // 0.2 * 255 = 51
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(
                icon,
                color: isHighlighted
                    ? AppTheme.primaryColor
                    : Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),

            // Arrow
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
