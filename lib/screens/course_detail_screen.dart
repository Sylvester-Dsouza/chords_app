import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../services/user_progress_service.dart';
import 'lesson_detail_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _timelineController;
  int currentDay = 1;
  bool isEnrolled = false;
  Course? course;
  bool isLoading = true;
  String? error;
  CourseProgress? userProgress;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _timelineController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Load course data and user progress in parallel
      final courseService = CourseService();
      final futures = await Future.wait([
        courseService.getCourseById(widget.courseId),
        UserProgressService.getCourseProgress(widget.courseId),
      ]);

      final loadedCourse = futures[0] as Course;
      final loadedProgress = futures[1] as CourseProgress;

      setState(() {
        course = loadedCourse;
        userProgress = loadedProgress;
        currentDay = loadedProgress.currentDay;
        isEnrolled = loadedProgress.isEnrolled;
        isLoading = false;
      });

      // Start animation after data is loaded
      _timelineController.forward();
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timelineController.dispose();
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
            title: course?.title ?? 'Course Details',
          ),

          // Main Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: course != null ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load course',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontFamily: AppTheme.primaryFontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCourseData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (course == null) {
      return const Center(
        child: Text(
          'Course not found',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Course Header
        SliverToBoxAdapter(
          child: _buildCourseHeader(),
        ),

        // Timeline Section
        SliverToBoxAdapter(
          child: _buildTimelineHeader(),
        ),

        // Daily Timeline
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final day = index + 1;
              return _buildTimelineDay(day);
            },
            childCount: course!.totalDays,
          ),
        ),

        // Bottom Padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildCourseHeader() {
    final courseColor = _getCourseColor();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Badge and Stats
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: courseColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: courseColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  course!.level,
                  style: TextStyle(
                    color: courseColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${course!.totalDays} Day Journey',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Course Title and Description
          Text(
            course!.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),

          const SizedBox(height: 8),

          if (course!.subtitle != null)
            Text(
              course!.subtitle!,
              style: TextStyle(
                color: courseColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),

          const SizedBox(height: 16),

          Text(
            course!.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 15,
              height: 1.5,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),

          const SizedBox(height: 24),

          // Course Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildStatItem('${course!.totalDays}', 'Days', Icons.calendar_today_rounded),
                _buildStatDivider(),
                _buildStatItem('${course!.totalLessons}', 'Lessons', Icons.play_lesson_rounded),
                _buildStatDivider(),
                _buildStatItem('${course!.estimatedHours}h', 'Hours', Icons.schedule_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCourseColor() {
    // Return color based on course type or level
    switch (course!.level.toLowerCase()) {
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

  Widget _buildStatItem(String number, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            number,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.1),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildTimelineHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.timeline_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Learning Journey',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              Text(
                'One day at a time, one song at a time',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDay(int day) {
    // Get the actual lesson for this day
    final actualLesson = course?.lessons?.firstWhere(
      (l) => l.dayNumber == day,
      orElse: () => course!.lessons!.first,
    );

    final isCompleted = userProgress?.completedLessons.contains(actualLesson?.id) ?? false;
    final isCurrent = day == currentDay;
    final isLocked = day > currentDay || !isEnrolled;
    final lesson = _getDayLesson(day);

    return AnimatedBuilder(
      animation: _timelineController,
      builder: (context, child) {
        final animationValue = _timelineController.value;
        final dayProgress = ((day - 1) / course!.totalDays).clamp(0.0, 1.0);
        final shouldAnimate = animationValue >= dayProgress;

        return Transform.translate(
          offset: Offset(shouldAnimate ? 0 : 50, 0),
          child: Opacity(
            opacity: shouldAnimate ? 1.0 : 0.3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Line and Node
                  _buildTimelineNode(day, isCompleted, isCurrent, isLocked),

                  const SizedBox(width: 20),

                  // Day Content
                  Expanded(
                    child: _buildDayContent(day, lesson, isCompleted, isCurrent, isLocked),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineNode(int day, bool isCompleted, bool isCurrent, bool isLocked) {
    final courseColor = _getCourseColor();

    return Column(
      children: [
        // Timeline Node
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppTheme.primaryColor
                : isCurrent
                    ? courseColor
                    : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted
                  ? AppTheme.primaryColor
                  : isCurrent
                      ? courseColor
                      : Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: isCurrent ? [
              BoxShadow(
                color: courseColor.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 20,
                  )
                : isLocked
                    ? Icon(
                        Icons.lock_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 16,
                      )
                    : Text(
                        '$day',
                        style: TextStyle(
                          color: isCurrent ? Colors.black : Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
          ),
        ),

        // Timeline Line (if not last day)
        if (day < course!.totalDays)
          Container(
            width: 2,
            height: 60,
            color: isCompleted
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
      ],
    );
  }

  Widget _buildDayContent(int day, Map<String, dynamic> lesson, bool isCompleted, bool isCurrent, bool isLocked) {
    final courseColor = _getCourseColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isCurrent
            ? courseColor.withValues(alpha: 0.1)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? courseColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: isCurrent ? [
          BoxShadow(
            color: courseColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : () => _openLesson(day, lesson),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Header
                Row(
                  children: [
                    Text(
                      'Day $day',
                      style: TextStyle(
                        color: isCurrent
                            ? courseColor
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                    const Spacer(),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Completed',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTheme.primaryFontFamily,
                          ),
                        ),
                      ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: courseColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(
                            color: courseColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTheme.primaryFontFamily,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Lesson Title
                Text(
                  lesson['title'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),

                const SizedBox(height: 8),

                // Lesson Description
                Text(
                  lesson['description'] as String,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),

                const SizedBox(height: 16),

                // Practice Song
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
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
                              'Practice Song',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontFamily: AppTheme.primaryFontFamily,
                              ),
                            ),
                            Text(
                              lesson['song'] as String,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTheme.primaryFontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (!isLocked)
                        Icon(
                          Icons.play_arrow_rounded,
                          color: _getCourseColor(),
                          size: 20,
                        ),
                    ],
                  ),
                ),

                if (!isLocked) ...[
                  const SizedBox(height: 12),

                  // Lesson Duration
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${lesson['duration']} min lesson',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _enrollInCourse(),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.black,
      icon: Icon(
        isEnrolled ? Icons.play_arrow_rounded : Icons.school_rounded,
        color: Colors.black,
      ),
      label: Text(
        isEnrolled ? 'Continue Learning' : course!.isFree ? 'Start Free Course' : 'Start Course - ${course!.formattedPrice}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontFamily: AppTheme.primaryFontFamily,
        ),
      ),
    );
  }



  Map<String, dynamic> _getDayLesson(int day) {
    // Get lesson from real course data
    if (course?.lessons != null && course!.lessons!.isNotEmpty) {
      // Find lesson for this day
      final lesson = course!.lessons!.firstWhere(
        (l) => l.dayNumber == day,
        orElse: () => course!.lessons!.first,
      );

      return {
        'title': lesson.title,
        'description': lesson.description,
        'duration': lesson.duration,
        'song': lesson.practiceSongTitle ?? 'Practice Song',
      };
    }

    // Fallback for when no lessons are available
    return {
      'title': 'Day $day Lesson',
      'description': 'Complete your daily vocal training',
      'duration': 15,
      'song': 'Practice Song',
    };
  }

  Future<void> _enrollInCourse() async {
    try {
      await UserProgressService.enrollInCourse(widget.courseId);

      // Reload progress to update UI
      final updatedProgress = await UserProgressService.getCourseProgress(widget.courseId);

      setState(() {
        userProgress = updatedProgress;
        isEnrolled = updatedProgress.isEnrolled;
        currentDay = updatedProgress.currentDay;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully enrolled in course!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enroll: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openLesson(int day, Map<String, dynamic> lesson) {
    // Find the actual lesson from course data
    if (course?.lessons != null && course!.lessons!.isNotEmpty) {
      final actualLesson = course!.lessons!.firstWhere(
        (l) => l.dayNumber == day,
        orElse: () => course!.lessons!.first,
      );

      // Navigate to lesson detail screen with completion callback
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonDetailScreen(
            lesson: actualLesson,
            course: course!,
            dayNumber: day,
            onLessonCompleted: (completed) => _onLessonCompleted(actualLesson.id, day, completed),
          ),
        ),
      ).then((_) {
        // Refresh progress when returning from lesson
        _loadCourseData();
      });
    } else {
      // Fallback if no lesson data available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lesson data not available for Day $day'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onLessonCompleted(String lessonId, int dayNumber, bool completed) async {
    try {
      if (completed) {
        final unlockedNextDay = await UserProgressService.completeLesson(
          widget.courseId,
          dayNumber,
          lessonId,
        );

        if (unlockedNextDay) {
          // Show celebration for unlocking next day
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 Congratulations! Day ${dayNumber + 1} unlocked!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        await UserProgressService.markLessonIncomplete(
          widget.courseId,
          dayNumber,
          lessonId,
        );
      }

      // Refresh progress
      final updatedProgress = await UserProgressService.getCourseProgress(widget.courseId);
      if (mounted) {
        setState(() {
          userProgress = updatedProgress;
          currentDay = updatedProgress.currentDay;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}