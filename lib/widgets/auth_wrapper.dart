import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/// A widget that wraps screens that require authentication.
/// It handles back button navigation to prevent returning to authenticated screens after logout.
class AuthWrapper extends StatelessWidget {
  final Widget child;
  final bool requireAuth;
  
  const AuthWrapper({
    super.key,
    required this.child,
    this.requireAuth = true,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    // If authentication is required but user is not logged in, redirect to login
    if (requireAuth && !userProvider.isLoggedIn) {
      // Use a post-frame callback to avoid build-time navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      
      // Return an empty container while redirecting
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Use WillPopScope to handle back button navigation
    return WillPopScope(
      onWillPop: () async {
        // If this is a protected screen and user is not logged in,
        // prevent going back and redirect to login
        if (requireAuth && !userProvider.isLoggedIn) {
          Navigator.of(context).pushReplacementNamed('/login');
          return false;
        }
        
        // Allow normal back button behavior
        return true;
      },
      child: child,
    );
  }
}
