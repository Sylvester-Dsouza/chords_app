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

  factory FeatureRequest.fromJson(Map<String, dynamic> json) {
    return FeatureRequest(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'],
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'PENDING',
      upvotes: json['upvotes'] ?? 0,
      customerId: json['customerId'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      hasUpvoted: json['hasUpvoted'] ?? false,
    );
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
}
