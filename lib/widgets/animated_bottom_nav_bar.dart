import 'package:flutter/material.dart';
import '../config/theme.dart';

class AnimatedBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool keepState;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.keepState = true,
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(AnimatedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index != widget.currentIndex) {
      // Just call the onTap callback provided by the parent widget
      // The parent widget will handle the actual navigation
      widget.onTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.navigationBar,
        border: const Border(
          top: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: AppTheme.navigationBar,
        selectedItemColor: AppTheme.primary, // Primary color used sparingly for selected items
        unselectedItemColor: AppTheme.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: AppTheme.bottomNavLabelStyle.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTheme.bottomNavLabelStyle,
        items: [
          _buildNavItem(Icons.home_filled, 'Home', 0),
          _buildNavItem(Icons.queue_music, 'My Setlist', 1),
          _buildNavItem(Icons.search, 'Search', 2),
          _buildNavItem(Icons.record_voice_over_rounded, 'Vocals', 3),
          _buildNavItem(Icons.person, 'Profile', 4),
        ],
        currentIndex: widget.currentIndex,
        onTap: (index) => _handleNavigation(context, index),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    // Determine if this item is the current or previous selected item
    final bool isSelected = index == widget.currentIndex;
    final bool wasSelected = index == _previousIndex;

    // Create animations for the icon
    Widget iconWidget = Icon(icon);

    // If this is the current or previous item, animate it
    if (isSelected || wasSelected) {
      // Animate the icon size
      final Animation<double> sizeAnimation = Tween<double>(
        begin: isSelected ? 1.0 : 1.2,
        end: isSelected ? 1.2 : 1.0,
      ).animate(_animation);

      // Animate the icon color
      final Animation<Color?> colorAnimation = ColorTween(
        begin: isSelected ? AppTheme.textSecondary : AppTheme.primary,
        end: isSelected ? AppTheme.primary : AppTheme.textSecondary,
      ).animate(_animation);

      iconWidget = AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: sizeAnimation.value,
            child: Icon(
              icon,
              color: colorAnimation.value,
            ),
          );
        },
      );
    }

    return BottomNavigationBarItem(
      icon: iconWidget,
      label: label,
    );
  }
}
