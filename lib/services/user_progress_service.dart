import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserProgressService {
  static const String _progressKey = 'user_course_progress';

  // Get user's progress for a specific course
  static Future<CourseProgress> getCourseProgress(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('${_progressKey}_$courseId');

    if (progressJson != null) {
      final progressData = json.decode(progressJson);
      return CourseProgress.fromJson(progressData);
    }

    // Return default progress if none exists
    return CourseProgress(
      courseId: courseId,
      currentDay: 1,
      completedLessons: [],
      isEnrolled: false,
      enrollmentDate: null,
      lastAccessDate: DateTime.now(),
    );
  }

  // Save user's progress for a specific course
  static Future<void> saveCourseProgress(CourseProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = json.encode(progress.toJson());
    await prefs.setString('${_progressKey}_${progress.courseId}', progressJson);

    debugPrint('📚 Saved progress for course ${progress.courseId}: Day ${progress.currentDay}');
  }

  // Enroll user in a course
  static Future<void> enrollInCourse(String courseId) async {
    final progress = await getCourseProgress(courseId);
    final updatedProgress = progress.copyWith(
      isEnrolled: true,
      enrollmentDate: DateTime.now(),
      lastAccessDate: DateTime.now(),
    );
    await saveCourseProgress(updatedProgress);

    debugPrint('🎓 User enrolled in course: $courseId');
  }

  // Complete a lesson and unlock next day if needed
  static Future<bool> completeLesson(String courseId, int dayNumber, String lessonId) async {
    final progress = await getCourseProgress(courseId);

    // Add lesson to completed list if not already completed
    if (!progress.completedLessons.contains(lessonId)) {
      final updatedCompletedLessons = [...progress.completedLessons, lessonId];

      // Calculate new current day (unlock next day if current lesson completed)
      int newCurrentDay = progress.currentDay;
      if (dayNumber == progress.currentDay) {
        newCurrentDay = dayNumber + 1;
      }

      final updatedProgress = progress.copyWith(
        completedLessons: updatedCompletedLessons,
        currentDay: newCurrentDay,
        lastAccessDate: DateTime.now(),
      );

      await saveCourseProgress(updatedProgress);

      debugPrint('✅ Completed lesson $lessonId (Day $dayNumber)');
      debugPrint('🔓 Unlocked Day $newCurrentDay');

      return dayNumber == progress.currentDay; // Return true if this unlocked next day
    }

    return false; // Lesson was already completed
  }

  // Mark lesson as incomplete (for testing/debugging)
  static Future<void> markLessonIncomplete(String courseId, int dayNumber, String lessonId) async {
    final progress = await getCourseProgress(courseId);

    final updatedCompletedLessons = progress.completedLessons.where((id) => id != lessonId).toList();

    // If this was the lesson that unlocked the current day, go back one day
    int newCurrentDay = progress.currentDay;
    if (dayNumber == progress.currentDay - 1) {
      newCurrentDay = dayNumber;
    }

    final updatedProgress = progress.copyWith(
      completedLessons: updatedCompletedLessons,
      currentDay: newCurrentDay,
      lastAccessDate: DateTime.now(),
    );

    await saveCourseProgress(updatedProgress);

    debugPrint('❌ Marked lesson $lessonId as incomplete (Day $dayNumber)');
  }

  // Check if a lesson is completed
  static Future<bool> isLessonCompleted(String courseId, String lessonId) async {
    final progress = await getCourseProgress(courseId);
    return progress.completedLessons.contains(lessonId);
  }

  // Check if user is enrolled in course
  static Future<bool> isEnrolledInCourse(String courseId) async {
    final progress = await getCourseProgress(courseId);
    return progress.isEnrolled;
  }

  // Get all enrolled courses
  static Future<List<String>> getEnrolledCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_progressKey)).toList();

    List<String> enrolledCourses = [];
    for (String key in keys) {
      final courseId = key.replaceFirst('${_progressKey}_', '');
      final isEnrolled = await isEnrolledInCourse(courseId);
      if (isEnrolled) {
        enrolledCourses.add(courseId);
      }
    }

    return enrolledCourses;
  }

  // Clear all progress (for testing/debugging)
  static Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_progressKey)).toList();

    for (String key in keys) {
      await prefs.remove(key);
    }

    debugPrint('🗑️ Cleared all course progress');
  }
}

class CourseProgress {
  final String courseId;
  final int currentDay;
  final List<String> completedLessons;
  final bool isEnrolled;
  final DateTime? enrollmentDate;
  final DateTime lastAccessDate;

  const CourseProgress({
    required this.courseId,
    required this.currentDay,
    required this.completedLessons,
    required this.isEnrolled,
    this.enrollmentDate,
    required this.lastAccessDate,
  });

  CourseProgress copyWith({
    String? courseId,
    int? currentDay,
    List<String>? completedLessons,
    bool? isEnrolled,
    DateTime? enrollmentDate,
    DateTime? lastAccessDate,
  }) {
    return CourseProgress(
      courseId: courseId ?? this.courseId,
      currentDay: currentDay ?? this.currentDay,
      completedLessons: completedLessons ?? this.completedLessons,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      lastAccessDate: lastAccessDate ?? this.lastAccessDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'currentDay': currentDay,
      'completedLessons': completedLessons,
      'isEnrolled': isEnrolled,
      'enrollmentDate': enrollmentDate?.toIso8601String(),
      'lastAccessDate': lastAccessDate.toIso8601String(),
    };
  }

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['courseId'] as String,
      currentDay: json['currentDay'] as int,
      completedLessons: List<String>.from(json['completedLessons'] ?? []),
      isEnrolled: json['isEnrolled'] as bool,
      enrollmentDate: json['enrollmentDate'] != null
          ? DateTime.parse(json['enrollmentDate'] as String)
          : null,
      lastAccessDate: DateTime.parse(json['lastAccessDate'] as String),
    );
  }

  @override
  String toString() {
    return 'CourseProgress(courseId: $courseId, currentDay: $currentDay, completed: ${completedLessons.length}, enrolled: $isEnrolled)';
  }
}
