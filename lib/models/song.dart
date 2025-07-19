import 'package:flutter/foundation.dart';
import 'karaoke.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String key;
  final String? lyrics;
  final String? chords;
  final String? imageUrl; // Cover image URL from Supabase Storage
  final String? officialVideoUrl; // URL to the official music video
  final String?
  tutorialVideoUrl; // URL to a tutorial video showing how to play the song
  final List<String>? tags;
  final String? artistId;
  final int? capo; // Capo position
  final int? tempo; // Tempo in BPM
  final String? timeSignature; // Time signature (e.g., "4/4")
  final String? difficulty; // Difficulty level (e.g., "Easy", "Medium", "Hard")
  final String? languageId; // ID of the language
  final Map<String, dynamic>? language; // Language details
  final String? strummingPattern; // Strumming pattern notation
  bool isLiked; // Changed from isFavorite to isLiked and made non-final
  int commentCount; // Number of comments on the song
  double averageRating; // Average rating (1-5 stars)
  int ratingCount; // Number of ratings
  int? userRating; // Current user's rating (1-5 stars), null if not rated
  final Karaoke? karaoke; // Karaoke track for this song

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.key,
    this.lyrics,
    this.chords,
    this.imageUrl,
    this.officialVideoUrl,
    this.tutorialVideoUrl,
    this.tags,
    this.artistId,
    this.capo,
    this.tempo,
    this.timeSignature,
    this.difficulty,
    this.languageId,
    this.language,
    this.strummingPattern,
    this.isLiked = false,
    this.commentCount = 0,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.userRating,
    this.karaoke,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    // Handle artist which can be a string, an object, or null
    String artistName = '';
    try {
      if (json['artist'] == null) {
        // If artist is null, try to use a default value or leave empty
        artistName = '';
      } else if (json['artist'] is String) {
        // If artist is a string, use it directly
        artistName = json['artist'] as String;
      } else if (json['artist'] is Map) {
        // If artist is an object, extract the name
        artistName = (json['artist'] as Map)['name']?.toString() ?? '';
      } else {
        // Fallback: convert to string
        artistName = json['artist']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Error parsing artist field: $e');
      artistName = '';
    }

    // Get chord sheet from either chordSheet or chords field
    String? chordSheet =
        json['chordSheet']?.toString() ?? json['chords']?.toString();

    // If we have lyrics but no chord sheet, create a basic chord sheet
    if ((chordSheet == null || chordSheet.isEmpty) && json['lyrics'] != null) {
      chordSheet = json['lyrics']?.toString();
    }

    // Ensure spaces are preserved in chord sheets
    // This is critical for proper chord positioning
    if (chordSheet != null) {
      // Preserve the original spacing exactly as it was entered in the admin panel
      // No trimming or space normalization should be done here
      debugPrint('Preserving original chord sheet spacing');
    }

    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      artist: artistName,
      key: json['key']?.toString() ?? '',
      lyrics: json['lyrics']?.toString(),
      chords: chordSheet, // Use the processed chord sheet
      imageUrl: json['imageUrl']?.toString(),
      officialVideoUrl: json['officialVideoUrl']?.toString(),
      tutorialVideoUrl: json['tutorialVideoUrl']?.toString(),
      tags:
          json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      artistId: json['artistId']?.toString(),
      capo: json['capo'] != null ? int.tryParse(json['capo'].toString()) : null,
      tempo:
          json['tempo'] != null ? int.tryParse(json['tempo'].toString()) : null,
      timeSignature: json['timeSignature']?.toString(),
      difficulty: json['difficulty']?.toString(),
      languageId: json['languageId']?.toString(),
      language:
          json['language'] != null
              ? Map<String, dynamic>.from(json['language'] as Map)
              : null,
      strummingPattern: json['strummingPattern']?.toString(),
      isLiked:
          (json['isLiked'] as bool?) ?? (json['isFavorite'] as bool?) ?? false,
      commentCount: (json['commentCount'] as int?) ?? 0,
      averageRating:
          json['averageRating'] != null
              ? double.tryParse(json['averageRating'].toString()) ?? 0.0
              : 0.0,
      ratingCount:
          json['ratingCount'] != null
              ? int.tryParse(json['ratingCount'].toString()) ?? 0
              : 0,
      userRating:
          json['userRating'] != null
              ? int.tryParse(json['userRating'].toString())
              : null,
      karaoke:
          json['karaoke'] != null
              ? Karaoke.fromJson(json['karaoke'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'key': key,
      'lyrics': lyrics,
      'chords': chords,
      'imageUrl': imageUrl,
      'officialVideoUrl': officialVideoUrl,
      'tutorialVideoUrl': tutorialVideoUrl,
      'tags': tags,
      'artistId': artistId,
      'capo': capo,
      'tempo': tempo,
      'timeSignature': timeSignature,
      'difficulty': difficulty,
      'languageId': languageId,
      'language': language,
      'strummingPattern': strummingPattern,
      'isLiked': isLiked,
      'commentCount': commentCount,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'userRating': userRating,
      if (karaoke != null) 'karaoke': karaoke!.toJson(),
    };
  }
}
