import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
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
  @override
  void initState() {
    super.initState();

    // Sync with navigation provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationProvider = Provider.of<NavigationProvider>(
        context,
        listen: false,
      );
      navigationProvider.updateIndex(4); // Profile screen is index 4
    });
  }

  // Generate a Christian-themed avatar URL from email
  String _generateChristianAvatarUrl(String email) {
    final emailBytes = utf8.encode(email.toLowerCase().trim());
    final hash = md5.convert(emailBytes).toString();

    // Use the hash to select from a list of Christian-themed avatars
    final hashInt = int.parse(hash.substring(0, 8), radix: 16);
    final avatarIndex = hashInt % _christianAvatars.length;

    return _christianAvatars[avatarIndex];
  }

  // List of Christian-themed playful avatar URLs using different styles
  static const List<String> _christianAvatars = [
    // Using fun-emoji style with Christian-themed seeds
    'https://api.dicebear.com/7.x/fun-emoji/svg?seed=angel&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/fun-emoji/svg?seed=cross&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/fun-emoji/svg?seed=dove&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/fun-emoji/svg?seed=heart&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/fun-emoji/svg?seed=light&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/fun-emoji/svg?seed=peace&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/fun-emoji/svg?seed=hope&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/fun-emoji/svg?seed=faith&backgroundColor=f0f0f0',
    // Using adventurer style with Christian names
    'https://api.dicebear.com/7.x/adventurer/svg?seed=grace&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=joy&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=love&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=blessed&backgroundColor=f0f0f0',
    // Using personas style with Christian themes
    'https://api.dicebear.com/7.x/personas/svg?seed=worship&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/personas/svg?seed=praise&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/personas/svg?seed=prayer&backgroundColor=f0f0f0',
    'https://api.dicebear.com/7.x/personas/svg?seed=miracle&backgroundColor=f0f0f0',
    // Using initials style with Christian symbols
    'https://api.dicebear.com/7.x/initials/svg?seed=✝&backgroundColor=c19fff&textColor=ffffff',
    'https://api.dicebear.com/7.x/initials/svg?seed=♥&backgroundColor=9575cd&textColor=ffffff',
    'https://api.dicebear.com/7.x/initials/svg?seed=☮&backgroundColor=c19fff&textColor=ffffff',
    'https://api.dicebear.com/7.x/initials/svg?seed=✨&backgroundColor=9575cd&textColor=ffffff',
  ];

  // Get profile picture URL based on login method
  String? _getProfilePictureUrl(Map<String, dynamic>? userData) {
    if (userData == null) return null;

    // Check if user has a profile picture URL in their data
    if (userData['profilePicture'] != null &&
        userData['profilePicture'].toString().isNotEmpty) {
      return userData['profilePicture'] as String?;
    }

    // Check auth provider
    final authProvider = userData['authProvider']?.toString().toUpperCase();

    if (authProvider == 'GOOGLE') {
      // For Google users, try to get photo from Firebase
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser?.photoURL != null) {
        return firebaseUser!.photoURL;
      }
    }

    // For email users or fallback, generate Christian-themed avatar
    final email = userData['email']?.toString();
    if (email != null && email.isNotEmpty) {
      return _generateChristianAvatarUrl(email);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bool isLoggedIn = userProvider.isLoggedIn;
    final userData = userProvider.userData;

    return AuthWrapper(
      requireAuth: false, // Allow both logged in and guest users
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const InnerScreenAppBar(
          title: 'Profile',
          showBackButton: false,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Modern Profile Header
              _buildProfileHeader(isLoggedIn, userData),

              Divider(color: AppTheme.separator),

              // Settings Sections
              _buildSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isLoggedIn, Map<String, dynamic>? userData) {
    final profilePictureUrl =
        isLoggedIn ? _getProfilePictureUrl(userData) : null;
    final displayName =
        isLoggedIn ? (userData?['name'] ?? 'User') : 'Guest User';
    final displayEmail =
        isLoggedIn ? (userData?['email'] ?? 'No email') : 'Not logged in';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Profile Image - Made smaller
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceSecondary,
              border: Border.all(color: AppTheme.primary, width: 1.5),
            ),
            child:
                profilePictureUrl != null
                    ? ClipOval(
                      child: Image.network(
                        profilePictureUrl,
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: AppTheme.textPrimary,
                            size: 32,
                          );
                        },
                      ),
                    )
                    : const Icon(
                      Icons.person,
                      color: AppTheme.textPrimary,
                      size: 32,
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
                  displayName as String,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Email
                Text(
                  displayEmail as String,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Show joined date for logged in users or login button for guests
                isLoggedIn
                    ? Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Joined January 2023',
                          style: TextStyle(
                            color: AppTheme.textMuted,
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
                            icon: const Icon(Icons.login, size: 16),
                            label: const Text('Login'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              textStyle: const TextStyle(fontSize: 14),
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
      padding: const EdgeInsets.only(left: 4.0, bottom: 6.0, top: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppTheme.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> items) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children:
            items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    Divider(height: 1, color: AppTheme.separator, indent: 60),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(UserProvider userProvider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      child: ElevatedButton.icon(
        onPressed: () async {
          // Show confirmation dialog
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: AppTheme.surface,
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                content: const Text(
                  'Are you sure you want to logout?',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.primary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                ],
              );
            },
          );

          if (confirm == true) {
            _handleLogout(userProvider);
          }
        },
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Logout', style: TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.error.withAlpha(30),
          foregroundColor: AppTheme.error,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: AppTheme.error.withAlpha(100), width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
          backgroundColor: AppTheme.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Logging out...',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
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
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
            // Icon - Smaller and more compact
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    isHighlighted
                        ? AppTheme.primary.withAlpha(40)
                        : AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                icon,
                color:
                    isHighlighted ? AppTheme.primary : AppTheme.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Title - Smaller font
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Arrow - Smaller
            Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}
