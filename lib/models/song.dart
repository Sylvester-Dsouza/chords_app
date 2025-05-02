class Song {
  final String id;
  final String title;
  final String artist;
  final String key;
  final String? lyrics;
  final String? chords;
  final String? imageUrl; // Cover image URL from Supabase Storage
  final List<String>? tags;
  final String? artistId;
  final int? capo; // Capo position
  bool isLiked; // Changed from isFavorite to isLiked and made non-final
  int commentCount; // Number of comments on the song

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.key,
    this.lyrics,
    this.chords,
    this.imageUrl,
    this.tags,
    this.artistId,
    this.capo,
    this.isLiked = false,
    this.commentCount = 0,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    // Handle artist which can be a string, an object, or null
    String artistName = '';
    if (json['artist'] == null) {
      // If artist is null, try to use a default value or leave empty
      artistName = '';
    } else if (json['artist'] is String) {
      // If artist is a string, use it directly
      artistName = json['artist'];
    } else if (json['artist'] is Map) {
      // If artist is an object, extract the name
      artistName = (json['artist'] as Map)['name'] ?? '';
    }

    // Get chord sheet from either chordSheet or chords field
    String? chordSheet = json['chordSheet'] ?? json['chords'];

    // If we have lyrics but no chord sheet, create a basic chord sheet
    if ((chordSheet == null || chordSheet.isEmpty) && json['lyrics'] != null) {
      chordSheet = json['lyrics'];
    }

    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artist: artistName,
      key: json['key'] ?? '',
      lyrics: json['lyrics'],
      chords: chordSheet, // Use the processed chord sheet
      imageUrl: json['imageUrl'],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : null,
      artistId: json['artistId'],
      capo: json['capo'] != null ? int.tryParse(json['capo'].toString()) : null,
      isLiked: json['isLiked'] ?? json['isFavorite'] ?? false,
      commentCount: json['commentCount'] ?? 0,
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
      'tags': tags,
      'artistId': artistId,
      'capo': capo,
      'isLiked': isLiked,
      'commentCount': commentCount,
    };
  }
}
