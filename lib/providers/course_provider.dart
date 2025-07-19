import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../services/course_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum CourseLoadingState { idle, loading, loaded, error, refreshing }

class CourseProvider with ChangeNotifier {
  static final CourseProvider _instance = CourseProvider._internal();
  factory CourseProvider() => _instance;
  CourseProvider._internal();

  final CourseService _courseService = CourseService();

  // State
  CourseLoadingState _loadingState = CourseLoadingState.idle;
  List<Course> _courses = [];
  List<Course> _featuredCourses = [];
  List<Enrollment> _enrollments = [];
  String? _error;
  String _selectedLevel = 'All';
  String _selectedCourseType = 'vocal';

  // Cache keys
  static const String _coursesKey = 'courses_cache';
  static const String _featuredCoursesKey = 'featured_courses_cache';
  static const String _enrollmentsKey = 'enrollments_cache';
  static const Duration _cacheExpiry = Duration(hours: 1);

  // Getters
  CourseLoadingState get loadingState => _loadingState;
  List<Course> get courses => _courses;
  List<Course> get featuredCourses => _featuredCourses;
  List<Enrollment> get enrollments => _enrollments;
  String? get error => _error;
  String get selectedLevel => _selectedLevel;
  String get selectedCourseType => _selectedCourseType;

  bool get isLoading => _loadingState == CourseLoadingState.loading;
  bool get isLoaded => _loadingState == CourseLoadingState.loaded;
  bool get hasError => _loadingState == CourseLoadingState.error;
  bool get isRefreshing => _loadingState == CourseLoadingState.refreshing;

  // Filtered courses based on selected level
  List<Course> get filteredCourses {
    if (_selectedLevel == 'All') {
      return _courses;
    }
    return _courses.where((course) => course.level == _selectedLevel).toList();
  }

  // Courses by type
  List<Course> get vocalCourses =>
      _courses.where((course) => course.courseType == 'vocal').toList();
  List<Course> get guitarCourses =>
      _courses.where((course) => course.courseType == 'guitar').toList();
  List<Course> get pianoCourses =>
      _courses.where((course) => course.courseType == 'piano').toList();

  // Enrolled courses
  List<Course> get enrolledCourses {
    final enrolledCourseIds = _enrollments.map((e) => e.courseId).toSet();
    return _courses
        .where((course) => enrolledCourseIds.contains(course.id))
        .toList();
  }

  // Active enrollments
  List<Enrollment> get activeEnrollments =>
      _enrollments.where((e) => e.isActive).toList();

  // Completed enrollments
  List<Enrollment> get completedEnrollments =>
      _enrollments.where((e) => e.isCompleted).toList();

  // Initialize and load data
  Future<void> initialize() async {
    if (_loadingState == CourseLoadingState.loaded) {
      return; // Already loaded
    }

    await loadCourses();
  }

  // Load all courses
  Future<void> loadCourses({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        _setLoadingState(CourseLoadingState.refreshing);
      } else {
        _setLoadingState(CourseLoadingState.loading);
      }

      // Try to load from cache first
      if (!forceRefresh) {
        await _loadFromCache();
        if (_courses.isNotEmpty) {
          _setLoadingState(CourseLoadingState.loaded);
          return;
        }
      }

      // Load from API
      await _loadFromApi();

      // Cache the data
      await _cacheData();

      _setLoadingState(CourseLoadingState.loaded);
    } catch (e) {
      debugPrint('❌ Error loading courses: $e');
      _error = e.toString();
      _setLoadingState(CourseLoadingState.error);
    }
  }

  // Load featured courses
  Future<void> loadFeaturedCourses({bool forceRefresh = false}) async {
    try {
      // Load from API
      _featuredCourses = await _courseService.getFeaturedCourses();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading featured courses: $e');
    }
  }

  // Load user enrollments
  Future<void> loadEnrollments({bool forceRefresh = false}) async {
    try {
      // Load from API
      _enrollments = await _courseService.getUserEnrollments();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading enrollments: $e');
    }
  }

  // Set selected level filter
  void setSelectedLevel(String level) {
    if (_selectedLevel != level) {
      _selectedLevel = level;
      notifyListeners();
    }
  }

  // Set selected course type
  void setSelectedCourseType(String courseType) {
    if (_selectedCourseType != courseType) {
      _selectedCourseType = courseType;
      notifyListeners();
    }
  }

  // Search courses
  Future<List<Course>> searchCourses(String query) async {
    try {
      return await _courseService.searchCourses(query);
    } catch (e) {
      debugPrint('❌ Error searching courses: $e');
      return [];
    }
  }

  // Get course by ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      // Check if course is already in memory
      try {
        final existingCourse = _courses.firstWhere(
          (course) => course.id == courseId,
        );
        return existingCourse;
      } catch (e) {
        // Course not found in memory, load from API
      }

      // Load from API
      return await _courseService.getCourseById(courseId);
    } catch (e) {
      debugPrint('❌ Error getting course by ID: $e');
      return null;
    }
  }

  // Enroll in course
  Future<bool> enrollInCourse(String courseId) async {
    try {
      final enrollment = await _courseService.enrollInCourse(courseId);
      _enrollments.add(enrollment);
      notifyListeners();

      // Cache updated - simplified for now

      return true;
    } catch (e) {
      debugPrint('❌ Error enrolling in course: $e');
      return false;
    }
  }

  // Check if user is enrolled in course
  bool isEnrolledInCourse(String courseId) {
    return _enrollments.any(
      (enrollment) => enrollment.courseId == courseId && enrollment.isActive,
    );
  }

  // Get enrollment for course
  Enrollment? getEnrollmentForCourse(String courseId) {
    try {
      return _enrollments.firstWhere(
        (enrollment) => enrollment.courseId == courseId,
      );
    } catch (e) {
      return null;
    }
  }

  // Private methods
  void _setLoadingState(CourseLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_coursesKey);
      if (cached != null) {
        final cacheData = json.decode(cached) as Map<String, dynamic>;
        final timestamp = DateTime.parse(cacheData['timestamp'].toString());
        if (DateTime.now().difference(timestamp) < _cacheExpiry) {
          _courses =
              (cacheData['data'] as List)
                  .map((json) => Course.fromJson(json as Map<String, dynamic>))
                  .toList();
          debugPrint('✅ Loaded ${_courses.length} courses from cache');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading from cache: $e');
    }
  }

  Future<void> _loadFromApi() async {
    _courses = await _courseService.getAllCourses();
    debugPrint('✅ Loaded ${_courses.length} courses from API');
  }

  Future<void> _cacheData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': _courses.map((course) => course.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_coursesKey, json.encode(cacheData));
    } catch (e) {
      debugPrint('❌ Error caching data: $e');
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_coursesKey);
      await prefs.remove(_featuredCoursesKey);
      await prefs.remove(_enrollmentsKey);
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  // Refresh all data
  Future<void> refresh() async {
    await loadCourses(forceRefresh: true);
    await loadFeaturedCourses(forceRefresh: true);
    await loadEnrollments(forceRefresh: true);
  }
}
