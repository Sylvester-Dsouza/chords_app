import 'package:flutter/material.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../config/theme.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  @override
  void initState() {
    super.initState();
    // No need to sync with navigation provider as this is handled by MainNavigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const InnerScreenAppBar(
        title: 'Resources',
        showBackButton: false,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: List.generate(8, (index) {
          return _buildBlogCard();
        }),
      ),
      // Removed bottom navigation bar since it's already provided by MainNavigation
    );
  }

  Widget _buildBlogCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.accent2, // Use theme accent color
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          // Blog title
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Our Blogs',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // Blog image
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'mint',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
