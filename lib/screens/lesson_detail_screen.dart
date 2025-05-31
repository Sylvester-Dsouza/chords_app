import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../models/course.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  final Course course;
  final int dayNumber;
  final Function(bool completed)? onLessonCompleted;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.course,
    required this.dayNumber,
    this.onLessonCompleted,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool isCompleted = false;
  bool isPlaying = false;
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Custom App Bar
          InnerScreenAppBar(
            title: 'Day ${widget.dayNumber}',
            actions: [
              IconButton(
                onPressed: () => _showLessonOptions(),
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),

          // Main Content
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Compact Lesson Header
                SliverToBoxAdapter(
                  child: _buildCompactHeader(),
                ),

                // PRIMARY: Media Player Section (Main Focus)
                SliverToBoxAdapter(
                  child: _buildMediaPlayerSection(),
                ),

                // SECONDARY: Collapsible Additional Content
                SliverToBoxAdapter(
                  child: _buildSecondaryContent(),
                ),

                // Bottom Padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // Compact header with just essential info
  Widget _buildCompactHeader() {
    final courseColor = _getCourseColor();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  // Day Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: courseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Day ${widget.dayNumber}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Lesson Title (Compact)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lesson.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTheme.primaryFontFamily,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.lesson.duration} min • ${widget.course.level}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontFamily: AppTheme.primaryFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // PRIMARY: Main Media Player Section (Focus of the lesson)
  Widget _buildMediaPlayerSection() {
    final courseColor = _getCourseColor();
    final hasVideo = widget.lesson.videoUrl != null;
    final hasAudio = widget.lesson.audioUrl != null;

    if (!hasVideo && !hasAudio) {
      return _buildNoMediaPlaceholder();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Container(
              margin: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media Player Card (Main Focus)
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          courseColor.withValues(alpha: 0.2),
                          courseColor.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: courseColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background Pattern
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 1.0,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Media Content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Large Play Button
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: courseColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: courseColor.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _playMainMedia(),
                                    borderRadius: BorderRadius.circular(40),
                                    child: Icon(
                                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.black,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Media Title
                              Text(
                                hasVideo ? 'Video Lesson' : 'Audio Lesson',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: AppTheme.primaryFontFamily,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Media Description
                              Text(
                                hasVideo
                                    ? 'Watch the complete lesson'
                                    : 'Listen to the audio guide',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                  fontFamily: AppTheme.primaryFontFamily,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Progress Bar
                              Container(
                                width: 200,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: courseColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Time Display
                              Text(
                                '${(progress * widget.lesson.duration).toInt()}:00 / ${widget.lesson.duration}:00',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  fontFamily: AppTheme.primaryFontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Media Type Badge
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasVideo ? Icons.videocam_rounded : Icons.headphones_rounded,
                                  color: courseColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  hasVideo ? 'VIDEO' : 'AUDIO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: AppTheme.primaryFontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Media Controls Row
                  if (hasVideo && hasAudio)
                    _buildMediaToggleControls(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // No media placeholder when lesson has no video/audio
  Widget _buildNoMediaPlaceholder() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.play_disabled_rounded,
            color: Colors.white.withValues(alpha: 0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No Media Content',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This lesson contains text-based instructions only',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontFamily: AppTheme.primaryFontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Media toggle controls when both video and audio are available
  Widget _buildMediaToggleControls() {
    return Row(
      children: [
        Expanded(
          child: _buildMediaToggleButton(
            icon: Icons.videocam_rounded,
            label: 'Video',
            isSelected: true, // For now, default to video
            onTap: () => _switchToVideo(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMediaToggleButton(
            icon: Icons.headphones_rounded,
            label: 'Audio',
            isSelected: false,
            onTap: () => _switchToAudio(),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final courseColor = _getCourseColor();

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? courseColor.withValues(alpha: 0.2) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? courseColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? courseColor : Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? courseColor : Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // SECONDARY: Collapsible additional content (less prominent)
  Widget _buildSecondaryContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Expandable sections for secondary content
          _buildExpandableSection(
            title: 'Lesson Details',
            icon: Icons.info_outline_rounded,
            child: _buildLessonDetailsContent(),
          ),

          const SizedBox(height: 12),

          if (widget.lesson.instructions.isNotEmpty)
            _buildExpandableSection(
              title: 'Instructions',
              icon: Icons.list_alt_rounded,
              child: _buildInstructionsContent(),
            ),

          if (widget.lesson.instructions.isNotEmpty)
            const SizedBox(height: 12),

          if (widget.lesson.practiceSongTitle != null)
            _buildExpandableSection(
              title: 'Practice Song',
              icon: Icons.music_note_rounded,
              child: _buildPracticeSongContent(),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Icon(
            icon,
            color: _getCourseColor(),
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          iconColor: Colors.white.withValues(alpha: 0.7),
          collapsedIconColor: Colors.white.withValues(alpha: 0.7),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonDetailsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.lesson.description,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 15,
            height: 1.5,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildDetailChip(
              icon: Icons.timer_rounded,
              label: '${widget.lesson.duration} min',
            ),
            const SizedBox(width: 12),
            _buildDetailChip(
              icon: Icons.school_rounded,
              label: widget.course.level,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructionsContent() {
    return Text(
      widget.lesson.instructions,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 15,
        height: 1.6,
        fontFamily: AppTheme.primaryFontFamily,
      ),
    );
  }

  Widget _buildPracticeSongContent() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCourseColor().withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.music_note_rounded,
            color: _getCourseColor(),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.lesson.practiceSongTitle!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              Text(
                'Practice with this song',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _openPracticeSong(),
          icon: Icon(
            Icons.open_in_new_rounded,
            color: _getCourseColor(),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _getCourseColor(),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  // Action methods for media controls
  void _playMainMedia() {
    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying) {
        // Simulate progress
        progress = 0.3; // Example progress
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPlaying ? 'Playing lesson...' : 'Paused lesson',
        ),
        backgroundColor: isPlaying ? Colors.green : Colors.orange,
      ),
    );
  }

  void _switchToVideo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Switched to video mode'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _switchToAudio() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Switched to audio mode'),
        backgroundColor: Colors.purple,
      ),
    );
  }



  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _toggleLessonCompletion(),
      backgroundColor: isCompleted ? Colors.green : AppTheme.primaryColor,
      foregroundColor: Colors.black,
      icon: Icon(
        isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
        color: Colors.black,
      ),
      label: Text(
        isCompleted ? 'Completed' : 'Start Lesson',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontFamily: AppTheme.primaryFontFamily,
        ),
      ),
    );
  }

  Color _getCourseColor() {
    switch (widget.course.level.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF00D4AA);
      case 'intermediate':
        return const Color(0xFF6366F1);
      case 'advanced':
        return const Color(0xFFEC4899);
      default:
        return AppTheme.primaryColor;
    }
  }

  void _showLessonOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Lesson Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),

            const SizedBox(height: 20),

            _buildOptionTile(
              icon: Icons.bookmark_outline_rounded,
              title: 'Bookmark Lesson',
              onTap: () => Navigator.pop(context),
            ),

            _buildOptionTile(
              icon: Icons.share_rounded,
              title: 'Share Lesson',
              onTap: () => Navigator.pop(context),
            ),

            _buildOptionTile(
              icon: Icons.report_outlined,
              title: 'Report Issue',
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white.withValues(alpha: 0.8),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontFamily: AppTheme.primaryFontFamily,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _toggleLessonCompletion() {
    setState(() {
      isCompleted = !isCompleted;
      if (isCompleted) {
        progress = 1.0;
      } else {
        progress = 0.0;
      }
    });

    // Call the completion callback if provided
    widget.onLessonCompleted?.call(isCompleted);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCompleted ? 'Lesson marked as completed!' : 'Lesson marked as incomplete',
        ),
        backgroundColor: isCompleted ? Colors.green : AppTheme.primaryColor,
      ),
    );
  }

  void _openPracticeSong() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening practice song: ${widget.lesson.practiceSongTitle}'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }


}
