import 'package:flutter/foundation.dart';

class Setlist {
  final String id;
  final String name;
  final String? description;
  final String customerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<dynamic>? songs;

  // Collaborative features
  final bool isPublic;
  final bool isShared;
  final String? shareCode;
  final bool allowEditing;
  final bool allowComments;
  final bool
  isSharedWithMe; // Flag to indicate if this setlist is shared with the current user

  // Offline support
  final int version;
  final DateTime? lastSyncAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  // Relations
  final List<SetlistCollaborator>? collaborators;
  final List<SetlistActivity>? activities;
  final List<SetlistComment>? comments;

  Setlist({
    required this.id,
    required this.name,
    this.description,
    required this.customerId,
    required this.createdAt,
    required this.updatedAt,
    this.songs,
    this.isPublic = false,
    this.isShared = false,
    this.shareCode,
    this.allowEditing = false,
    this.allowComments = true,
    this.isSharedWithMe = false,
    this.version = 1,
    this.lastSyncAt,
    this.isDeleted = false,
    this.deletedAt,
    this.collaborators,
    this.activities,
    this.comments,
  });

  factory Setlist.fromJson(Map<String, dynamic> json) {
    debugPrint('Creating Setlist from JSON: ${json['id']} - ${json['name']}');

    // Handle songs data with error handling
    List<dynamic>? songsData;
    try {
      if (json['songs'] != null) {
        songsData = json['songs'] as List<dynamic>;
        debugPrint('Songs data found: ${songsData.length} songs');
      } else {
        debugPrint('No songs data found in setlist JSON');
      }
    } catch (e) {
      debugPrint('Error parsing songs data: $e');
      songsData = []; // Fallback to empty list
    }

    // Handle collaborators data with error handling
    List<SetlistCollaborator>? collaboratorsData;
    try {
      if (json['collaborators'] != null) {
        collaboratorsData =
            (json['collaborators'] as List)
                .map(
                  (item) => SetlistCollaborator.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
      }
    } catch (e) {
      debugPrint('Error parsing collaborators data: $e');
      collaboratorsData = [];
    }

    // Handle activities data with error handling
    List<SetlistActivity>? activitiesData;
    try {
      if (json['activities'] != null) {
        activitiesData =
            (json['activities'] as List)
                .map(
                  (item) =>
                      SetlistActivity.fromJson(item as Map<String, dynamic>),
                )
                .toList();
      }
    } catch (e) {
      debugPrint('Error parsing activities data: $e');
      activitiesData = [];
    }

    // Handle comments data with error handling
    List<SetlistComment>? commentsData;
    try {
      if (json['comments'] != null) {
        commentsData =
            (json['comments'] as List)
                .map(
                  (item) =>
                      SetlistComment.fromJson(item as Map<String, dynamic>),
                )
                .toList();
      }
    } catch (e) {
      debugPrint('Error parsing comments data: $e');
      commentsData = [];
    }

    return Setlist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      customerId: json['customerId']?.toString() ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      songs: songsData,
      isPublic: (json['isPublic'] as bool?) ?? false,
      isShared: (json['isShared'] as bool?) ?? false,
      shareCode: json['shareCode']?.toString(),
      allowEditing: (json['allowEditing'] as bool?) ?? false,
      allowComments: (json['allowComments'] as bool?) ?? true,
      isSharedWithMe: json['isSharedWithMe'] == true,
      version: (json['version'] as int?) ?? 1,
      lastSyncAt:
          json['lastSyncAt'] != null
              ? DateTime.tryParse(json['lastSyncAt'].toString())
              : null,
      isDeleted: (json['isDeleted'] as bool?) ?? false,
      deletedAt:
          json['deletedAt'] != null
              ? DateTime.tryParse(json['deletedAt'].toString())
              : null,
      collaborators: collaboratorsData,
      activities: activitiesData,
      comments: commentsData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'customerId': customerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'songs': songs,
      'isPublic': isPublic,
      'isShared': isShared,
      'shareCode': shareCode,
      'allowEditing': allowEditing,
      'allowComments': allowComments,
      'version': version,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}

// Setlist collaborator model
class SetlistCollaborator {
  final String id;
  final String customerId;
  final String permission; // "VIEW", "EDIT", "ADMIN"
  final String status; // "PENDING", "ACCEPTED", "DECLINED", "REMOVED"
  final DateTime invitedAt;
  final DateTime? acceptedAt;
  final DateTime? lastActiveAt;
  final Map<String, dynamic>? customer; // Customer data

  SetlistCollaborator({
    required this.id,
    required this.customerId,
    required this.permission,
    required this.status,
    required this.invitedAt,
    this.acceptedAt,
    this.lastActiveAt,
    this.customer,
  });

  factory SetlistCollaborator.fromJson(Map<String, dynamic> json) {
    return SetlistCollaborator(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      permission: json['permission']?.toString() ?? 'VIEW',
      status: json['status']?.toString() ?? 'PENDING',
      invitedAt:
          json['invitedAt'] != null
              ? DateTime.tryParse(json['invitedAt'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      acceptedAt:
          json['acceptedAt'] != null
              ? DateTime.tryParse(json['acceptedAt'].toString())
              : null,
      lastActiveAt:
          json['lastActiveAt'] != null
              ? DateTime.tryParse(json['lastActiveAt'].toString())
              : null,
      customer: json['customer'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'permission': permission,
      'status': status,
      'invitedAt': invitedAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }
}

// Setlist activity model
class SetlistActivity {
  final String id;
  final String customerId;
  final String action; // "CREATED", "UPDATED", "SONG_ADDED", etc.
  final Map<String, dynamic>? details;
  final DateTime timestamp;
  final int version;
  final Map<String, dynamic>? customer; // Customer data

  SetlistActivity({
    required this.id,
    required this.customerId,
    required this.action,
    this.details,
    required this.timestamp,
    required this.version,
    this.customer,
  });

  factory SetlistActivity.fromJson(Map<String, dynamic> json) {
    return SetlistActivity(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      details: json['details'] as Map<String, dynamic>?,
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      version: (json['version'] as int?) ?? 1,
      customer: json['customer'] as Map<String, dynamic>?,
    );
  }
}

// Setlist comment model
class SetlistComment {
  final String id;
  final String customerId;
  final String text;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final Map<String, dynamic>? customer; // Customer data
  final List<SetlistComment>? replies;

  SetlistComment({
    required this.id,
    required this.customerId,
    required this.text,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.customer,
    this.replies,
  });

  factory SetlistComment.fromJson(Map<String, dynamic> json) {
    List<SetlistComment>? repliesData;
    try {
      if (json['replies'] != null) {
        repliesData =
            (json['replies'] as List)
                .map(
                  (item) =>
                      SetlistComment.fromJson(item as Map<String, dynamic>),
                )
                .toList();
      }
    } catch (e) {
      debugPrint('Error parsing comment replies: $e');
      repliesData = [];
    }

    return SetlistComment(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      parentId: json['parentId']?.toString(),
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      isDeleted: (json['isDeleted'] as bool?) ?? false,
      deletedAt:
          json['deletedAt'] != null
              ? DateTime.tryParse(json['deletedAt'].toString())
              : null,
      customer: json['customer'] as Map<String, dynamic>?,
      replies: repliesData,
    );
  }
}
