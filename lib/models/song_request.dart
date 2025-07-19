/// Represents a song request in the Worship Paradise application.
/// 
/// This model contains information about user-requested songs including
/// metadata, links, status, and voting information.
class SongRequest {
  final String id;
  final String songName;
  final String? artistName;
  final String? youtubeLink;
  final String? spotifyLink;
  final String? notes;
  final String status;
  final int upvotes;
  final String customerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasUpvoted;

  /// Creates a new [SongRequest] instance.
  /// 
  /// All required fields must be provided. Optional fields can be null.
  SongRequest({
    required this.id,
    required this.songName,
    this.artistName,
    this.youtubeLink,
    this.spotifyLink,
    this.notes,
    required this.status,
    required this.upvotes,
    required this.customerId,
    required this.createdAt,
    required this.updatedAt,
    this.hasUpvoted = false,
  });

  /// Creates a [SongRequest] instance from a JSON map.
  /// 
  /// Validates all required fields and throws [ArgumentError] if any required
  /// field is missing or has an invalid type. Throws [FormatException] if
  /// date strings cannot be parsed.
  /// 
  /// Required fields: id, songName, status, upvotes, customerId, 
  /// createdAt, updatedAt
  factory SongRequest.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null || json['id'] is! String || (json['id'] as String).isEmpty) {
      throw ArgumentError('SongRequest.fromJson: id is required and must be a non-empty string');
    }
    if (json['songName'] == null || json['songName'] is! String || (json['songName'] as String).isEmpty) {
      throw ArgumentError('SongRequest.fromJson: songName is required and must be a non-empty string');
    }
    if (json['status'] == null || json['status'] is! String) {
      throw ArgumentError('SongRequest.fromJson: status is required and must be a string');
    }
    if (json['customerId'] == null || json['customerId'] is! String || (json['customerId'] as String).isEmpty) {
      throw ArgumentError('SongRequest.fromJson: customerId is required and must be a non-empty string');
    }
    if (json['createdAt'] == null || json['createdAt'] is! String) {
      throw ArgumentError('SongRequest.fromJson: createdAt is required and must be a string');
    }
    if (json['updatedAt'] == null || json['updatedAt'] is! String) {
      throw ArgumentError('SongRequest.fromJson: updatedAt is required and must be a string');
    }

    return SongRequest(
      id: json['id'] as String,
      songName: json['songName'] as String,
      artistName: json['artistName'] as String?,
      youtubeLink: json['youtubeLink'] as String?,
      spotifyLink: json['spotifyLink'] as String?,
      notes: json['notes'] as String?,
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
      throw FormatException('SongRequest._parseDateTime: Invalid date format: $dateTimeString');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'songName': songName,
      'artistName': artistName,
      'youtubeLink': youtubeLink,
      'spotifyLink': spotifyLink,
      'notes': notes,
      'status': status,
      'upvotes': upvotes,
      'customerId': customerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'hasUpvoted': hasUpvoted,
    };
  }

  /// Creates a copy of this [SongRequest] with the given fields replaced with new values.
  SongRequest copyWith({
    String? id,
    String? songName,
    String? artistName,
    String? youtubeLink,
    String? spotifyLink,
    String? notes,
    String? status,
    int? upvotes,
    String? customerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasUpvoted,
  }) {
    return SongRequest(
      id: id ?? this.id,
      songName: songName ?? this.songName,
      artistName: artistName ?? this.artistName,
      youtubeLink: youtubeLink ?? this.youtubeLink,
      spotifyLink: spotifyLink ?? this.spotifyLink,
      notes: notes ?? this.notes,
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
    if (other is! SongRequest) return false;
    
    return other.id == id &&
        other.songName == songName &&
        other.artistName == artistName &&
        other.youtubeLink == youtubeLink &&
        other.spotifyLink == spotifyLink &&
        other.notes == notes &&
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
      songName,
      artistName,
      youtubeLink,
      spotifyLink,
      notes,
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
    return 'SongRequest(id: $id, songName: $songName, artistName: $artistName, '
        'youtubeLink: $youtubeLink, spotifyLink: $spotifyLink, notes: $notes, '
        'status: $status, upvotes: $upvotes, customerId: $customerId, '
        'createdAt: $createdAt, updatedAt: $updatedAt, hasUpvoted: $hasUpvoted)';
  }
}
