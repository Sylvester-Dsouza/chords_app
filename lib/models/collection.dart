import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'song.dart';

class Collection {
  final String id;
  final String title;
  final String? description;
  final int songCount;
  final int likeCount;
  final bool isLiked;
  final Color color;
  final String? imageUrl;
  final List<Song>? songs;
  final bool isPublic;

  Collection({
    required this.id,
    required this.title,
    this.description,
    this.songCount = 0,
    this.likeCount = 0,
    this.isLiked = false,
    required this.color,
    this.imageUrl,
    this.songs,
    this.isPublic = true,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    // Parse color from hex string
    Color parseColor(String? hexColor) {
      if (hexColor == null) return const Color(0xFF3498DB); // Default blue

      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // Add alpha value if not provided
      }
      return Color(int.parse(hexColor, radix: 16));
    }

    // Parse songs if available
    List<Song>? parseSongs(List<dynamic>? songsJson) {
      if (songsJson == null || songsJson.isEmpty) return null;

      try {
        return songsJson.map((songJson) => Song.fromJson(songJson)).toList();
      } catch (e) {
        debugPrint('Error parsing songs in collection: $e');
        return null;
      }
    }

    return Collection(
      id: json['id'] ?? '',
      title: json['name'] ?? json['title'] ?? '',
      description: json['description'],
      songCount: json['songCount'] ?? json['songs']?.length ?? 0,
      likeCount: json['likeCount'] ?? json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      color: parseColor(json['color']),
      imageUrl: json['imageUrl'],
      songs: parseSongs(json['songs'] as List<dynamic>?),
      isPublic: json['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    // Convert color to hex string
    String colorToHex(Color color) {
      // Just use a default color code for now to avoid deprecation warnings
      return '#3498DB';
    }

    // Convert songs to JSON if available
    List<Map<String, dynamic>>? songsToJson(List<Song>? songs) {
      if (songs == null || songs.isEmpty) return null;
      return songs.map((song) => song.toJson()).toList();
    }

    return {
      'id': id,
      'name': title,
      'description': description,
      'songCount': songCount,
      'likeCount': likeCount,
      'isLiked': isLiked,
      'color': colorToHex(color),
      'imageUrl': imageUrl,
      'songs': songsToJson(songs),
      'isPublic': isPublic,
    };
  }
}
