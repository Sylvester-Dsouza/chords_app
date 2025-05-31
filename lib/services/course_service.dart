import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import 'api_service.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  final ApiService _apiService = ApiService();

  // Get all published courses
  Future<List<Course>> getAllCourses({
    String? search,
    String? level,
    String? courseType,
    bool? isFeatured,
  }) async {
    try {
      debugPrint('🎓 Fetching courses...');

      final Map<String, dynamic> queryParams = {
        'limit': '1000',
        'page': '1',
        'isPublished': 'true', // Only get published courses for mobile app
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (level != null && level.isNotEmpty && level != 'All') {
        queryParams['level'] = level;
      }
      if (courseType != null && courseType.isNotEmpty) {
        queryParams['courseType'] = courseType;
      }
      if (isFeatured != null) {
        queryParams['isFeatured'] = isFeatured.toString();
      }

      final response = await _apiService.get('/courses', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('📦 Courses response data type: ${data.runtimeType}');
        debugPrint('📦 Courses response: $data');

        List<Course> courses = [];

        if (data is Map<String, dynamic> && data['courses'] is List) {
          // Response format: { courses: [...], total: x, page: y, limit: z }
          courses = (data['courses'] as List)
              .map((courseJson) {
                try {
                  return Course.fromJson(courseJson);
                } catch (e) {
                  debugPrint('❌ Error parsing course: $e');
                  debugPrint('📦 Course JSON: $courseJson');
                  rethrow;
                }
              })
              .toList();
        } else if (data is List) {
          // Direct array response
          courses = data.map((courseJson) {
            try {
              return Course.fromJson(courseJson);
            } catch (e) {
              debugPrint('❌ Error parsing course: $e');
              debugPrint('📦 Course JSON: $courseJson');
              rethrow;
            }
          }).toList();
        }

        debugPrint('✅ Successfully fetched ${courses.length} courses');
        return courses;
      } else {
        debugPrint('❌ Failed to fetch courses: ${response.statusCode}');
        throw Exception('Failed to fetch courses: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching courses: $e');
      rethrow;
    }
  }

  // Get course by ID with lessons
  Future<Course> getCourseById(String courseId, {bool includeLessons = true}) async {
    try {
      debugPrint('🎓 Fetching course: $courseId');

      final Map<String, dynamic> queryParams = {};
      if (includeLessons) {
        queryParams['includeLessons'] = 'true';
      }

      final response = await _apiService.get('/courses/$courseId', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final course = Course.fromJson(response.data);
        debugPrint('✅ Successfully fetched course: ${course.title}');
        return course;
      } else {
        debugPrint('❌ Failed to fetch course: ${response.statusCode}');
        throw Exception('Failed to fetch course: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching course: $e');
      rethrow;
    }
  }

  // Get featured courses
  Future<List<Course>> getFeaturedCourses() async {
    try {
      debugPrint('🌟 Fetching featured courses...');
      return await getAllCourses(isFeatured: true);
    } catch (e) {
      debugPrint('❌ Error fetching featured courses: $e');
      rethrow;
    }
  }

  // Get courses by level
  Future<List<Course>> getCoursesByLevel(String level) async {
    try {
      debugPrint('📚 Fetching courses for level: $level');
      return await getAllCourses(level: level);
    } catch (e) {
      debugPrint('❌ Error fetching courses by level: $e');
      rethrow;
    }
  }

  // Get courses by type
  Future<List<Course>> getCoursesByType(String courseType) async {
    try {
      debugPrint('🎵 Fetching courses for type: $courseType');
      return await getAllCourses(courseType: courseType);
    } catch (e) {
      debugPrint('❌ Error fetching courses by type: $e');
      rethrow;
    }
  }

  // Search courses
  Future<List<Course>> searchCourses(String query) async {
    try {
      debugPrint('🔍 Searching courses: $query');
      return await getAllCourses(search: query);
    } catch (e) {
      debugPrint('❌ Error searching courses: $e');
      rethrow;
    }
  }

  // Enroll in a course
  Future<Enrollment> enrollInCourse(String courseId) async {
    try {
      debugPrint('📝 Enrolling in course: $courseId');

      final response = await _apiService.post('/courses/enrollments', data: {
        'courseId': courseId,
      });

      if (response.statusCode == 201) {
        final enrollment = Enrollment.fromJson(response.data);
        debugPrint('✅ Successfully enrolled in course');
        return enrollment;
      } else {
        debugPrint('❌ Failed to enroll in course: ${response.statusCode}');
        throw Exception('Failed to enroll in course: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error enrolling in course: $e');
      rethrow;
    }
  }

  // Get user enrollments
  Future<List<Enrollment>> getUserEnrollments() async {
    try {
      debugPrint('📚 Fetching user enrollments...');

      final response = await _apiService.get('/courses/enrollments/my');

      if (response.statusCode == 200) {
        final data = response.data;
        List<Enrollment> enrollments = [];

        if (data is List) {
          enrollments = data.map((enrollmentJson) => Enrollment.fromJson(enrollmentJson)).toList();
        }

        debugPrint('✅ Successfully fetched ${enrollments.length} enrollments');
        return enrollments;
      } else {
        debugPrint('❌ Failed to fetch enrollments: ${response.statusCode}');
        throw Exception('Failed to fetch enrollments: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching enrollments: $e');
      rethrow;
    }
  }

  // Get enrollment for specific course
  Future<Enrollment?> getCourseEnrollment(String courseId) async {
    try {
      debugPrint('📖 Fetching enrollment for course: $courseId');

      final response = await _apiService.get('/courses/enrollments/course/$courseId');

      if (response.statusCode == 200) {
        final enrollment = Enrollment.fromJson(response.data);
        debugPrint('✅ Found enrollment for course');
        return enrollment;
      } else if (response.statusCode == 404) {
        debugPrint('ℹ️ No enrollment found for course');
        return null;
      } else {
        debugPrint('❌ Failed to fetch course enrollment: ${response.statusCode}');
        throw Exception('Failed to fetch course enrollment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching course enrollment: $e');
      return null; // Return null instead of throwing for enrollment checks
    }
  }

  // Update enrollment progress
  Future<Enrollment> updateEnrollmentProgress(String enrollmentId, {
    int? currentDay,
    double? progress,
    String? status,
  }) async {
    try {
      debugPrint('📈 Updating enrollment progress: $enrollmentId');

      final Map<String, dynamic> updateData = {};
      if (currentDay != null) updateData['currentDay'] = currentDay;
      if (progress != null) updateData['progress'] = progress;
      if (status != null) updateData['status'] = status;

      final response = await _apiService.put('/courses/enrollments/$enrollmentId', data: updateData);

      if (response.statusCode == 200) {
        final enrollment = Enrollment.fromJson(response.data);
        debugPrint('✅ Successfully updated enrollment progress');
        return enrollment;
      } else {
        debugPrint('❌ Failed to update enrollment progress: ${response.statusCode}');
        throw Exception('Failed to update enrollment progress: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error updating enrollment progress: $e');
      rethrow;
    }
  }

  // Mark lesson as completed
  Future<LessonProgress> markLessonCompleted(String enrollmentId, String lessonId, {
    int? timeSpent,
    String? notes,
  }) async {
    try {
      debugPrint('✅ Marking lesson completed: $lessonId');

      final response = await _apiService.post('/courses/enrollments/$enrollmentId/lessons/$lessonId/complete', data: {
        'timeSpent': timeSpent,
        'notes': notes,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final lessonProgress = LessonProgress.fromJson(response.data);
        debugPrint('✅ Successfully marked lesson as completed');
        return lessonProgress;
      } else {
        debugPrint('❌ Failed to mark lesson as completed: ${response.statusCode}');
        throw Exception('Failed to mark lesson as completed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error marking lesson as completed: $e');
      rethrow;
    }
  }

  // Rate course
  Future<Enrollment> rateCourse(String enrollmentId, double rating, {String? review}) async {
    try {
      debugPrint('⭐ Rating course: $rating stars');

      final response = await _apiService.put('/courses/enrollments/$enrollmentId', data: {
        'rating': rating,
        'review': review,
      });

      if (response.statusCode == 200) {
        final enrollment = Enrollment.fromJson(response.data);
        debugPrint('✅ Successfully rated course');
        return enrollment;
      } else {
        debugPrint('❌ Failed to rate course: ${response.statusCode}');
        throw Exception('Failed to rate course: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error rating course: $e');
      rethrow;
    }
  }
}
