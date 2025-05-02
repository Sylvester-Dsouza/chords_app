class Artist {
  final String id;
  final String name;
  final String? bio;
  final String? imageUrl;
  final int songCount;

  Artist({
    required this.id,
    required this.name,
    this.bio,
    this.imageUrl,
    this.songCount = 0,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'],
      imageUrl: json['imageUrl'],
      songCount: json['songCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'imageUrl': imageUrl,
      'songCount': songCount,
    };
  }
}
