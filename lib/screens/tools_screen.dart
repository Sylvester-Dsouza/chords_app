import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/inner_screen_app_bar.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  int _currentIndex = 3; // Set to 3 for Tools tab (replacing Resources)

  @override
  void initState() {
    super.initState();

    // Sync with navigation provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
      navigationProvider.updateIndex(3); // Tools screen is index 3 (replacing Resources)
      setState(() {
        _currentIndex = 3;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const InnerScreenAppBar(
        title: 'Music Tools',
        showBackButton: false,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: [
          _buildToolCard(
            'Guitar Tuner',
            Icons.tune,
            const Color(0xFF1E88E5), // Blue
            () => Navigator.pushNamed(context, '/tools/tuner'),
          ),
          _buildToolCard(
            'Metronome',
            Icons.timer,
            const Color(0xFF43A047), // Green
            () => Navigator.pushNamed(context, '/tools/metronome'),
          ),
          _buildToolCard(
            'Chord Library',
            Icons.grid_view,
            const Color(0xFFE53935), // Red
            () => Navigator.pushNamed(context, '/tools/chords'),
          ),
          _buildToolCard(
            'Scale Explorer',
            Icons.piano,
            const Color(0xFF8E24AA), // Purple
            () => Navigator.pushNamed(context, '/tools/scales'),
          ),
          _buildToolCard(
            'Capo Calculator',
            Icons.calculate,
            const Color(0xFFFFB300), // Amber
            () => Navigator.pushNamed(context, '/tools/capo'),
          ),
          _buildToolCard(
            'Circle of Fifths',
            Icons.donut_large,
            const Color(0xFFFF6D00), // Orange
            () => Navigator.pushNamed(context, '/tools/circle-of-fifths'),
          ),
          _buildToolCard(
            'Resources',
            Icons.menu_book,
            const Color(0xFF00897B), // Teal
            () => Navigator.pushNamed(context, '/resources'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
