import 'package:flutter/material.dart';

class Course {
  final String id;
  final String title;
  final String? subtitle;
  final String description;
  final String level; // Beginner, Intermediate, Advanced
  final String courseType; // vocal, guitar, piano, etc.
  final String? imageUrl;
  final int totalDays;
  final int totalLessons;
  final int estimatedHours;
  final bool isPublished;
  final bool isFeatured;
  final bool isActive;
  final double? price;
  final int viewCount;
  final int enrollmentCount;
  final double completionRate;
  final double averageRating;
  final int ratingCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Lesson>? lessons;

  // Additional UI properties
  final String? emoji;
  final Color? color;

  const Course({
    required this.id,
    required this.title,
    this.subtitle,
    required this.description,
    required this.level,
    required this.courseType,
    this.imageUrl,
    required this.totalDays,
    required this.totalLessons,
    required this.estimatedHours,
    required this.isPublished,
    required this.isFeatured,
    required this.isActive,
    this.price,
    required this.viewCount,
    required this.enrollmentCount,
    required this.completionRate,
    required this.averageRating,
    required this.ratingCount,
    required this.createdAt,
    required this.updatedAt,
    this.lessons,
    this.emoji,
    this.color,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String,
      level: json['level'] as String,
      courseType: json['courseType'] as String? ?? 'vocal',
      imageUrl: json['imageUrl'] as String?,
      totalDays: json['totalDays'] as int? ?? 0,
      totalLessons: json['totalLessons'] as int? ?? 0,
      estimatedHours: json['estimatedHours'] as int? ?? 0,
      isPublished: json['isPublished'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      viewCount: json['viewCount'] as int? ?? 0,
      enrollmentCount: json['enrollmentCount'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lessons: json['lessons'] != null
          ? (json['lessons'] as List).map((lesson) => Lesson.fromJson(lesson)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'level': level,
      'courseType': courseType,
      'imageUrl': imageUrl,
      'totalDays': totalDays,
      'totalLessons': totalLessons,
      'estimatedHours': estimatedHours,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'price': price,
      'viewCount': viewCount,
      'enrollmentCount': enrollmentCount,
      'completionRate': completionRate,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lessons': lessons?.map((lesson) => lesson.toJson()).toList(),
    };
  }

  Course copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? level,
    String? courseType,
    String? imageUrl,
    int? totalDays,
    int? totalLessons,
    int? estimatedHours,
    bool? isPublished,
    bool? isFeatured,
    bool? isActive,
    double? price,
    int? viewCount,
    int? enrollmentCount,
    double? completionRate,
    double? averageRating,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Lesson>? lessons,
    String? emoji,
    Color? color,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      level: level ?? this.level,
      courseType: courseType ?? this.courseType,
      imageUrl: imageUrl ?? this.imageUrl,
      totalDays: totalDays ?? this.totalDays,
      totalLessons: totalLessons ?? this.totalLessons,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      price: price ?? this.price,
      viewCount: viewCount ?? this.viewCount,
      enrollmentCount: enrollmentCount ?? this.enrollmentCount,
      completionRate: completionRate ?? this.completionRate,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lessons: lessons ?? this.lessons,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Course(id: $id, title: $title, level: $level, courseType: $courseType)';
  }

  // Helper getters
  bool get isFree => price == null || price == 0;
  String get formattedPrice => isFree ? 'Free' : '₹${price!.toStringAsFixed(0)}';
  String get levelEmoji {
    switch (level.toLowerCase()) {
      case 'beginner':
        return '🌱';
      case 'intermediate':
        return '🌿';
      case 'advanced':
        return '🌳';
      default:
        return '📚';
    }
  }

  String get courseTypeEmoji {
    switch (courseType.toLowerCase()) {
      case 'vocal':
        return '🎤';
      case 'guitar':
        return '🎸';
      case 'piano':
        return '🎹';
      case 'music_production':
        return '🎛️';
      default:
        return '🎵';
    }
  }
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final int dayNumber;
  final int duration; // in minutes
  final String? practiceSongId;
  final String? practiceSongTitle;
  final String instructions;
  final String? videoUrl;
  final String? audioUrl;
  final bool isPublished;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.dayNumber,
    required this.duration,
    this.practiceSongId,
    this.practiceSongTitle,
    this.instructions = '',
    this.videoUrl,
    this.audioUrl,
    required this.isPublished,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dayNumber: json['dayNumber'] as int,
      duration: json['duration'] as int,
      practiceSongId: json['practiceSongId'] as String?,
      practiceSongTitle: json['practiceSongTitle'] as String?,
      instructions: json['instructions'] as String? ?? '',
      videoUrl: json['videoUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      isPublished: json['isPublished'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dayNumber': dayNumber,
      'duration': duration,
      'practiceSongId': practiceSongId,
      'practiceSongTitle': practiceSongTitle,
      'instructions': instructions,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'isPublished': isPublished,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lesson && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Lesson(id: $id, title: $title, dayNumber: $dayNumber)';
  }
}
