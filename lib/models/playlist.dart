import 'package:flutter/foundation.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String customerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<dynamic>? songs;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.customerId,
    required this.createdAt,
    required this.updatedAt,
    this.songs,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    debugPrint('Creating Playlist from JSON: ${json['id']} - ${json['name']}');

    // Handle songs data
    List<dynamic>? songsData;
    if (json['songs'] != null) {
      songsData = json['songs'] as List<dynamic>;
      debugPrint('Songs data found: ${songsData.length} songs');
    } else {
      debugPrint('No songs data found in playlist JSON');
    }

    return Playlist(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      customerId: json['customerId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      songs: songsData,
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
    };
  }
}
