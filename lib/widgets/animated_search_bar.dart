import 'package:flutter/material.dart';

class AnimatedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback onFilterPressed;
  final bool isFilterActive;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color hintColor;
  final Color iconColor;
  final Color activeFilterColor;

  const AnimatedSearchBar({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onFilterPressed,
    this.isFilterActive = false,
    this.primaryColor = const Color(0xFFC19FFF),
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.textColor = Colors.white,
    this.hintColor = Colors.grey,
    this.iconColor = Colors.grey,
    this.activeFilterColor = const Color(0xFFC19FFF),
  }) : super(key: key);

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search Bar
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: _isFocused ? [
                BoxShadow(
                  color: widget.primaryColor.withAlpha(76), // 0.3 * 255 = 76
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ] : null,
            ),
            child: Row(
              children: [
                // Search Icon
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Icon(
                        Icons.search,
                        color: _isFocused
                            ? Color.lerp(widget.iconColor, widget.primaryColor, _fadeAnimation.value)
                            : widget.iconColor,
                        size: 20,
                      );
                    },
                  ),
                ),

                // Text Field
                Expanded(
                  child: Center(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: widget.hintColor,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: widget.onChanged,
                    ),
                  ),
                ),

                // Clear Button (only shown when text is entered)
                if (widget.controller.text.isNotEmpty)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return ScaleTransition(
                        scale: _scaleAnimation,
                        child: IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: widget.iconColor,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            widget.controller.clear();
                            widget.onChanged('');
                          },
                        ),
                      );
                    },
                  ),

                const SizedBox(width: 8),
              ],
            ),
          ),
        ),

        // Filter Button
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(left: 8.0),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: widget.isFilterActive ? [
              BoxShadow(
                color: widget.activeFilterColor.withAlpha(76), // 0.3 * 255 = 76
                blurRadius: 8,
                spreadRadius: 1,
              )
            ] : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: widget.onFilterPressed,
              child: Center(
                child: Icon(
                  Icons.filter_list,
                  color: widget.isFilterActive
                      ? widget.activeFilterColor
                      : widget.iconColor,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
