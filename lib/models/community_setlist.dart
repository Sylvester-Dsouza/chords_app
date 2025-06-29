class CommunitySetlistCreator {
  final String id;
  final String name;
  final String? profilePicture;

  CommunitySetlistCreator({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  factory CommunitySetlistCreator.fromJson(Map<String, dynamic> json) {
    return CommunitySetlistCreator(
      id: json['id'] as String,
      name: json['name'] as String,
      profilePicture: json['profilePicture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profilePicture': profilePicture,
    };
  }
}

class CommunitySetlistSong {
  final String id;
  final String title;
  final String artist;
  final String? key;

  CommunitySetlistSong({
    required this.id,
    required this.title,
    required this.artist,
    this.key,
  });

  factory CommunitySetlistSong.fromJson(Map<String, dynamic> json) {
    return CommunitySetlistSong(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      key: json['key'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'key': key,
    };
  }
}

class CommunitySetlist {
  final String id;
  final String name;
  final String? description;
  final CommunitySetlistCreator creator;
  final int songCount;
  final int viewCount;
  final int likeCount;
  final bool isLikedByUser;
  final DateTime sharedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CommunitySetlistSong> songPreview;

  CommunitySetlist({
    required this.id,
    required this.name,
    this.description,
    required this.creator,
    required this.songCount,
    required this.viewCount,
    required this.likeCount,
    required this.isLikedByUser,
    required this.sharedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.songPreview,
  });

  factory CommunitySetlist.fromJson(Map<String, dynamic> json) {
    return CommunitySetlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      creator: CommunitySetlistCreator.fromJson(json['creator'] as Map<String, dynamic>),
      songCount: json['songCount'] as int,
      viewCount: json['viewCount'] as int,
      likeCount: json['likeCount'] as int,
      isLikedByUser: json['isLikedByUser'] as bool,
      sharedAt: DateTime.parse(json['sharedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      songPreview: (json['songPreview'] as List<dynamic>)
          .map((song) => CommunitySetlistSong.fromJson(song as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creator': creator.toJson(),
      'songCount': songCount,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'isLikedByUser': isLikedByUser,
      'sharedAt': sharedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'songPreview': songPreview.map((song) => song.toJson()).toList(),
    };
  }

  // Create a copy with updated like status
  CommunitySetlist copyWith({
    String? id,
    String? name,
    String? description,
    CommunitySetlistCreator? creator,
    int? songCount,
    int? viewCount,
    int? likeCount,
    bool? isLikedByUser,
    DateTime? sharedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CommunitySetlistSong>? songPreview,
  }) {
    return CommunitySetlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creator: creator ?? this.creator,
      songCount: songCount ?? this.songCount,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      sharedAt: sharedAt ?? this.sharedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songPreview: songPreview ?? this.songPreview,
    );
  }
}

class CommunitySetlistsResponse {
  final List<CommunitySetlist> setlists;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasMore;

  CommunitySetlistsResponse({
    required this.setlists,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasMore,
  });

  factory CommunitySetlistsResponse.fromJson(Map<String, dynamic> json) {
    return CommunitySetlistsResponse(
      setlists: (json['setlists'] as List<dynamic>)
          .map((setlist) => CommunitySetlist.fromJson(setlist as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
      hasMore: json['hasMore'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setlists': setlists.map((setlist) => setlist.toJson()).toList(),
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
      'hasMore': hasMore,
    };
  }
}
