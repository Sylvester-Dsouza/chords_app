import 'course.dart';

enum EnrollmentStatus { active, paused, completed, cancelled }

class Enrollment {
  final String id;
  final String customerId;
  final String courseId;
  final EnrollmentStatus status;
  final int currentDay;
  final double progress; // 0-100
  final DateTime enrolledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastAccessedAt;
  final double? rating; // 1-5 stars
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Course? course; // Course details if included

  const Enrollment({
    required this.id,
    required this.customerId,
    required this.courseId,
    required this.status,
    required this.currentDay,
    required this.progress,
    required this.enrolledAt,
    this.startedAt,
    this.completedAt,
    this.lastAccessedAt,
    this.rating,
    this.review,
    required this.createdAt,
    required this.updatedAt,
    this.course,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      courseId: json['courseId'] as String,
      status: _parseStatus(json['status'] as String),
      currentDay: json['currentDay'] as int? ?? 1,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      enrolledAt: DateTime.parse(json['enrolledAt'] as String),
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      lastAccessedAt: json['lastAccessedAt'] != null ? DateTime.parse(json['lastAccessedAt'] as String) : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      review: json['review'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      course: json['course'] != null ? Course.fromJson(json['course']) : null,
    );
  }

  static EnrollmentStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return EnrollmentStatus.active;
      case 'PAUSED':
        return EnrollmentStatus.paused;
      case 'COMPLETED':
        return EnrollmentStatus.completed;
      case 'CANCELLED':
        return EnrollmentStatus.cancelled;
      default:
        return EnrollmentStatus.active;
    }
  }

  static String _statusToString(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.active:
        return 'ACTIVE';
      case EnrollmentStatus.paused:
        return 'PAUSED';
      case EnrollmentStatus.completed:
        return 'COMPLETED';
      case EnrollmentStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'courseId': courseId,
      'status': _statusToString(status),
      'currentDay': currentDay,
      'progress': progress,
      'enrolledAt': enrolledAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'rating': rating,
      'review': review,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'course': course?.toJson(),
    };
  }

  Enrollment copyWith({
    String? id,
    String? customerId,
    String? courseId,
    EnrollmentStatus? status,
    int? currentDay,
    double? progress,
    DateTime? enrolledAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastAccessedAt,
    double? rating,
    String? review,
    DateTime? createdAt,
    DateTime? updatedAt,
    Course? course,
  }) {
    return Enrollment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      courseId: courseId ?? this.courseId,
      status: status ?? this.status,
      currentDay: currentDay ?? this.currentDay,
      progress: progress ?? this.progress,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      course: course ?? this.course,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Enrollment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Enrollment(id: $id, courseId: $courseId, status: $status, progress: $progress%)';
  }

  // Helper getters
  bool get isActive => status == EnrollmentStatus.active;
  bool get isPaused => status == EnrollmentStatus.paused;
  bool get isCompleted => status == EnrollmentStatus.completed;
  bool get isCancelled => status == EnrollmentStatus.cancelled;

  String get statusDisplayName {
    switch (status) {
      case EnrollmentStatus.active:
        return 'Active';
      case EnrollmentStatus.paused:
        return 'Paused';
      case EnrollmentStatus.completed:
        return 'Completed';
      case EnrollmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get progressText => '${progress.toStringAsFixed(0)}%';

  int get daysRemaining {
    if (course == null) return 0;
    return (course!.totalDays - currentDay).clamp(0, course!.totalDays);
  }

  Duration? get timeSpent {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }

  bool get hasRating => rating != null && rating! > 0;
}

class LessonProgress {
  final String id;
  final String enrollmentId;
  final String lessonId;
  final bool isCompleted;
  final DateTime? completedAt;
  final int? timeSpent; // in minutes
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LessonProgress({
    required this.id,
    required this.enrollmentId,
    required this.lessonId,
    required this.isCompleted,
    this.completedAt,
    this.timeSpent,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      id: json['id'] as String,
      enrollmentId: json['enrollmentId'] as String,
      lessonId: json['lessonId'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      timeSpent: json['timeSpent'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enrollmentId': enrollmentId,
      'lessonId': lessonId,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'timeSpent': timeSpent,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LessonProgress && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LessonProgress(id: $id, lessonId: $lessonId, isCompleted: $isCompleted)';
  }
}
