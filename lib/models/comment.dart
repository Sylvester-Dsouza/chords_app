class Comment {
  final String id;
  final String songId;
  final String customerId;
  final String customerName;
  final String? customerProfilePicture;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentId;
  final List<Comment> replies;
  final int likesCount;
  final bool isLiked;
  final bool isDeleted;
  final DateTime? deletedAt;

  Comment({
    required this.id,
    required this.songId,
    required this.customerId,
    required this.customerName,
    this.customerProfilePicture,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.replies = const [],
    this.likesCount = 0,
    this.isLiked = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      songId: json['songId'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customer'] != null ? json['customer']['name'] : 'Anonymous',
      customerProfilePicture: json['customer'] != null ? json['customer']['profilePicture'] : null,
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      parentId: json['parentId'],
      replies: json['replies'] != null
          ? List<Comment>.from(json['replies'].map((x) => Comment.fromJson(x)))
          : [],
      likesCount: json['likesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'songId': songId,
      'customerId': customerId,
      'text': text,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      // These fields are not sent to the server but used in the app
      'customerName': customerName,
      'customerProfilePicture': customerProfilePicture,
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'likesCount': likesCount,
      'isLiked': isLiked,
    };
  }
}
