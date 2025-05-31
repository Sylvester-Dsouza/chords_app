import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../providers/course_provider.dart';
import '../models/course.dart';

class VocalCoursesScreen extends StatefulWidget {
  const VocalCoursesScreen({super.key});

  @override
  State<VocalCoursesScreen> createState() => _VocalCoursesScreenState();
}

class _VocalCoursesScreenState extends State<VocalCoursesScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize course data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      courseProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Custom App Bar
          InnerScreenAppBar(
            title: 'Course Training',
          ),

          // Main Content
          Expanded(
            child: Consumer<CourseProvider>(
              builder: (context, courseProvider, child) {
                if (courseProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                if (courseProvider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load courses',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          courseProvider.error ?? 'Unknown error',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => courseProvider.loadCourses(forceRefresh: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => courseProvider.refresh(),
                  color: AppTheme.primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Header Section
                        _buildHeader(courseProvider),

                        // Category Filter
                        _buildCategoryFilter(courseProvider),

                        // Featured Course
                        if (courseProvider.featuredCourses.isNotEmpty)
                          _buildFeaturedCourse(courseProvider.featuredCourses.first),

                        // Course List
                        _buildCoursesList(courseProvider),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(CourseProvider courseProvider) {
    final totalCourses = courseProvider.courses.length;
    final totalLessons = courseProvider.courses.fold<int>(
      0, (sum, course) => sum + course.totalLessons);
    final totalSongs = courseProvider.courses.fold<int>(
      0, (sum, course) => sum + course.totalDays);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Course Training',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Journey-based learning for worship ministry',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              _buildStatCard(totalCourses.toString(), 'Courses', Icons.book_rounded),
              const SizedBox(width: 12),
              _buildStatCard(totalLessons.toString(), 'Lessons', Icons.play_lesson_rounded),
              const SizedBox(width: 12),
              _buildStatCard(totalSongs.toString(), 'Songs', Icons.music_note_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String number, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
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
      ),
    );
  }

  Widget _buildCategoryFilter(CourseProvider courseProvider) {
    final categories = ['All', 'Beginner', 'Intermediate', 'Advanced'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse by level',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = courseProvider.selectedLevel == category;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      courseProvider.setSelectedLevel(category);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCourse(Course course) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.2),
            AppTheme.primaryColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'FEATURED',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.star_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            course.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),

          if (course.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              course.subtitle!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ],

          const SizedBox(height: 8),

          Text(
            course.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              _buildCourseInfo('${course.totalDays} Days', Icons.calendar_today_rounded),
              const SizedBox(width: 16),
              _buildCourseInfo(course.level, Icons.trending_up_rounded),
              const SizedBox(width: 16),
              _buildCourseInfo('${course.totalLessons} Lessons', Icons.music_note_rounded),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openCourseDetail(course),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                course.isFree ? 'Start Free Course' : 'Start Course - ${course.formattedPrice}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfo(String text, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.7),
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesList(CourseProvider courseProvider) {
    final courses = courseProvider.filteredCourses;

    if (courses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No courses available',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new courses',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Courses (${courses.length})',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildCourseCard(course);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          course.courseTypeEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            course.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: AppTheme.primaryFontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (course.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        course.subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getLevelColor(course.level).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getLevelColor(course.level).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      course.level,
                      style: TextStyle(
                        color: _getLevelColor(course.level),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ),
                  if (!course.isFree) ...[
                    const SizedBox(height: 8),
                    Text(
                      course.formattedPrice,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            course.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontFamily: AppTheme.primaryFontFamily,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _buildCourseInfo('${course.totalDays} Days', Icons.calendar_today_rounded),
              const SizedBox(width: 16),
              _buildCourseInfo('${course.totalLessons} Lessons', Icons.play_lesson_rounded),
              const SizedBox(width: 16),
              _buildCourseInfo('${course.estimatedHours}h', Icons.access_time_rounded),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openCourseDetail(course),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                course.isFree ? 'Start Free Course' : 'View Course',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }

  void _openCourseDetail(Course course) {
    Navigator.pushNamed(
      context,
      '/course_detail',
      arguments: {
        'courseId': course.id,
      },
    );
  }
}