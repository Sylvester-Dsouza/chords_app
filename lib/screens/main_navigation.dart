import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/animated_bottom_nav_bar.dart';
import '../config/theme.dart';
import 'home_screen.dart';
import 'setlist_screen.dart';
import 'search_screen.dart';
import 'vocals_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Create a list of all screens
  final List<Widget> _screens = [
    const HomeScreenNew(),
    const SetlistScreen(),
    const SearchScreen(),
    const VocalsScreen(),
    const ProfileScreen(),
  ];

  // Use a PageController to manage the page transitions
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    // Initialize the PageController with the current index from the NavigationProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
      debugPrint('MainNavigation: initializing with index ${navigationProvider.currentIndex}');
      setState(() {
        _pageController = PageController(initialPage: navigationProvider.currentIndex);
      });
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  // Add a key for the Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Handle back button press via a method that can be called from a back button
  void _handleBackPress() {
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);

    // If we're not on the home tab (index 0), navigate to home tab
    if (navigationProvider.currentIndex != 0) {
      navigationProvider.updateIndex(0);
      _pageController?.jumpToPage(0);
    } else {
      // Show a confirmation dialog if we're on the home tab
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Exit App?', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to exit the app?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No', style: TextStyle(color: AppTheme.primary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // This will exit the app safely
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Yes', style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current index from the navigation provider
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final currentIndex = navigationProvider.currentIndex;

    // Initialize the PageController if it hasn't been initialized yet
    if (!mounted) return const SizedBox.shrink();

    // Make sure the PageController is initialized
    if (_pageController == null) {
      debugPrint('MainNavigation: PageController is null, initializing now');
      _pageController = PageController(initialPage: currentIndex);
    }

    // If the page controller has clients and the current page is different from the current index,
    // jump to the new page
    try {
      if (_pageController!.hasClients && _pageController!.page?.round() != currentIndex) {
        _pageController!.jumpToPage(currentIndex);
      }
    } catch (e) {
      debugPrint('MainNavigation: Error checking PageController: $e');
      // If there's an error, recreate the PageController
      _pageController = PageController(initialPage: currentIndex);
    }

    // Create a BackButtonListener widget
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: AppTheme.appBar, // Use theme app bar color
        elevation: 0,
        scrolledUnderElevation: 0, // Prevents elevation change when scrolling
        surfaceTintColor: Colors.transparent, // Prevents blue tinting
        automaticallyImplyLeading: false, // Don't show back button
        // Custom back button that handles our navigation logic
        leading: BackButton(
          color: Colors.white,
          onPressed: _handleBackPress,
        ),
        title: const Text(''),
        toolbarHeight: 0, // Make the AppBar invisible but keep the back button handler
      ),
      body: PageView(
        controller: _pageController!,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        children: _screens,
        onPageChanged: (index) {
          debugPrint('MainNavigation: Page changed to $index');
          // Update the navigation provider when the page changes
          navigationProvider.updateIndex(index);
        },
      ),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          debugPrint('MainNavigation: Bottom nav tapped index $index');
          // Update the navigation provider
          navigationProvider.updateIndex(index);

          // Jump to the selected page immediately
          try {
            _pageController!.jumpToPage(index);
          } catch (e) {
            debugPrint('MainNavigation: Error jumping to page: $e');
            // If there's an error, recreate the PageController and try again
            setState(() {
              _pageController = PageController(initialPage: index);
            });
          }
        },
      ),
    );
  }
}
