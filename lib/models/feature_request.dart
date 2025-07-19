/// Represents a feature request in the Worship Paradise application.
/// 
/// This model contains information about user-requested features including
/// details, priority, status, and voting information.
class FeatureRequest {
  final String id;
  final String title;
  final String description;
  final String? category;
  final String priority;
  final String status;
  final int upvotes;
  final String customerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasUpvoted;

  /// Creates a new [FeatureRequest] instance.
  /// 
  /// All required fields must be provided. Optional fields can be null.
  FeatureRequest({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    required this.priority,
    required this.status,
    required this.upvotes,
    required this.customerId,
    required this.createdAt,
    required this.updatedAt,
    this.hasUpvoted = false,
  });

  /// Creates a [FeatureRequest] instance from a JSON map.
  /// 
  /// Validates all required fields and throws [ArgumentError] if any required
  /// field is missing or has an invalid type. Throws [FormatException] if
  /// date strings cannot be parsed.
  /// 
  /// Required fields: id, title, description, priority, status, upvotes, 
  /// customerId, createdAt, updatedAt
  factory FeatureRequest.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null || json['id'] is! String || (json['id'] as String).isEmpty) {
      throw ArgumentError('FeatureRequest.fromJson: id is required and must be a non-empty string');
    }
    if (json['title'] == null || json['title'] is! String || (json['title'] as String).isEmpty) {
      throw ArgumentError('FeatureRequest.fromJson: title is required and must be a non-empty string');
    }
    if (json['description'] == null || json['description'] is! String || (json['description'] as String).isEmpty) {
      throw ArgumentError('FeatureRequest.fromJson: description is required and must be a non-empty string');
    }
    if (json['priority'] == null || json['priority'] is! String) {
      throw ArgumentError('FeatureRequest.fromJson: priority is required and must be a string');
    }
    if (json['status'] == null || json['status'] is! String) {
      throw ArgumentError('FeatureRequest.fromJson: status is required and must be a string');
    }
    if (json['customerId'] == null || json['customerId'] is! String || (json['customerId'] as String).isEmpty) {
      throw ArgumentError('FeatureRequest.fromJson: customerId is required and must be a non-empty string');
    }
    if (json['createdAt'] == null || json['createdAt'] is! String) {
      throw ArgumentError('FeatureRequest.fromJson: createdAt is required and must be a string');
    }
    if (json['updatedAt'] == null || json['updatedAt'] is! String) {
      throw ArgumentError('FeatureRequest.fromJson: updatedAt is required and must be a string');
    }

    return FeatureRequest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String?,
      priority: json['priority'] as String,
      status: json['status'] as String,
      upvotes: json['upvotes'] as int? ?? 0,
      customerId: json['customerId'] as String,
      createdAt: _parseDateTime(json['createdAt'] as String),
      updatedAt: _parseDateTime(json['updatedAt'] as String),
      hasUpvoted: json['hasUpvoted'] as bool? ?? false,
    );
  }

  // Helper method to safely parse DateTime strings
  static DateTime _parseDateTime(String dateTimeString) {
    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      throw FormatException('FeatureRequest._parseDateTime: Invalid date format: $dateTimeString');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'upvotes': upvotes,
      'customerId': customerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'hasUpvoted': hasUpvoted,
    };
  }

  // Helper methods for display
  String get categoryDisplayName {
    switch (category) {
      case 'UI_UX':
        return 'UI/UX';
      case 'NEW_FEATURE':
        return 'New Feature';
      case 'BUG_FIX':
        return 'Bug Fix';
      case 'PERFORMANCE':
        return 'Performance';
      case 'INTEGRATION':
        return 'Integration';
      case 'SECURITY':
        return 'Security';
      case 'OTHER':
        return 'Other';
      default:
        return category ?? 'General';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'UNDER_REVIEW':
        return 'Under Review';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'LOW':
        return 'Low';
      case 'MEDIUM':
        return 'Medium';
      case 'HIGH':
        return 'High';
      case 'CRITICAL':
        return 'Critical';
      default:
        return priority;
    }
  }

  /// Creates a copy of this [FeatureRequest] with the given fields replaced with new values.
  FeatureRequest copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? priority,
    String? status,
    int? upvotes,
    String? customerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasUpvoted,
  }) {
    return FeatureRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      upvotes: upvotes ?? this.upvotes,
      customerId: customerId ?? this.customerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasUpvoted: hasUpvoted ?? this.hasUpvoted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FeatureRequest) return false;
    
    return other.id == id &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.priority == priority &&
        other.status == status &&
        other.upvotes == upvotes &&
        other.customerId == customerId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.hasUpvoted == hasUpvoted;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      category,
      priority,
      status,
      upvotes,
      customerId,
      createdAt,
      updatedAt,
      hasUpvoted,
    );
  }

  @override
  String toString() {
    return 'FeatureRequest(id: $id, title: $title, description: $description, '
        'category: $category, priority: $priority, status: $status, '
        'upvotes: $upvotes, customerId: $customerId, createdAt: $createdAt, '
        'updatedAt: $updatedAt, hasUpvoted: $hasUpvoted)';
  }
}
