import 'package:flutter/material.dart';
import '../config/theme.dart';

class InnerScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const InnerScreenAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // Update status bar color to match app bar
    AppTheme.updateStatusBarColor();

    return AppBar(
      backgroundColor: AppTheme.appBar,
      elevation: 0,
      scrolledUnderElevation: 0, // Prevents elevation change when scrolling
      surfaceTintColor: Colors.transparent, // Prevents blue tinting from primary color
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackPressed ?? () {
                // Use a smooth fade transition when going back
                Navigator.of(context).pop();
              },
            )
          : null,
      automaticallyImplyLeading: showBackButton,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
