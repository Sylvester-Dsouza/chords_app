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

  factory SongRequest.fromJson(Map<String, dynamic> json) {
    return SongRequest(
      id: json['id'] ?? '',
      songName: json['songName'] ?? '',
      artistName: json['artistName'],
      youtubeLink: json['youtubeLink'],
      spotifyLink: json['spotifyLink'],
      notes: json['notes'],
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
}
