import 'package:flutter/foundation.dart';

class Artist {
  final String id;
  final String name;
  final String? bio;
  final String? imageUrl;
  final int songCount;
  final bool isFeatured;

  Artist({
    required this.id,
    required this.name,
    this.bio,
    this.imageUrl,
    this.songCount = 0,
    this.isFeatured = false,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    // Debug the incoming JSON
    debugPrint('Artist JSON: $json');

    // Try to parse songCount from different possible fields
    int songCount = 0;
    if (json['songCount'] != null) {
      // Try to parse as int
      songCount = json['songCount'] is int
          ? json['songCount']
          : int.tryParse(json['songCount'].toString()) ?? 0;
    } else if (json['songs_count'] != null) {
      // Alternative field name
      songCount = json['songs_count'] is int
          ? json['songs_count']
          : int.tryParse(json['songs_count'].toString()) ?? 0;
    } else if (json['songs'] != null && json['songs'] is List) {
      // If songs array is provided, count its length
      songCount = (json['songs'] as List).length;
    }

    return Artist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'],
      imageUrl: json['imageUrl'],
      songCount: songCount,
      isFeatured: json['isFeatured'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'imageUrl': imageUrl,
      'songCount': songCount,
      'isFeatured': isFeatured,
    };
  }
}
