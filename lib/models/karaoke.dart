class Karaoke {
  final String id;
  final String songId;
  final String fileUrl;
  final int? fileSize;
  final int? duration;
  final String? key;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final DateTime updatedAt;
  final int version;
  final String status;
  final String? quality;
  final String? notes;

  const Karaoke({
    required this.id,
    required this.songId,
    required this.fileUrl,
    this.fileSize,
    this.duration,
    this.key,
    this.uploadedBy,
    required this.uploadedAt,
    required this.updatedAt,
    required this.version,
    required this.status,
    this.quality,
    this.notes,
  });

  factory Karaoke.fromJson(Map<String, dynamic> json) {
    return Karaoke(
      id: json['id'] as String,
      songId: json['songId'] as String,
      fileUrl: json['fileUrl'] as String,
      fileSize: json['fileSize'] as int?,
      duration: json['duration'] as int?,
      key: json['key'] as String?,
      uploadedBy: json['uploadedBy'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: json['version'] as int,
      status: json['status'] as String,
      quality: json['quality'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'songId': songId,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'duration': duration,
      'key': key,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
      'status': status,
      'quality': quality,
      'notes': notes,
    };
  }

  String get formattedDuration {
    if (duration == null) return 'Unknown';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  bool get isActive => status == 'ACTIVE';
  bool get isHighQuality => quality == 'HIGH';
  bool get isMediumQuality => quality == 'MEDIUM';
  bool get isLowQuality => quality == 'LOW';
}

class KaraokeSong {
  final String id;
  final String title;
  final String artistName;
  final String? imageUrl;
  final String? songKey;
  final int? tempo;
  final String? difficulty;
  final int viewCount;
  final double averageRating;
  final int ratingCount;
  final DateTime createdAt;
  final Karaoke karaoke;

  const KaraokeSong({
    required this.id,
    required this.title,
    required this.artistName,
    this.imageUrl,
    this.songKey,
    this.tempo,
    this.difficulty,
    required this.viewCount,
    required this.averageRating,
    required this.ratingCount,
    required this.createdAt,
    required this.karaoke,
  });

  factory KaraokeSong.fromJson(Map<String, dynamic> json) {
    return KaraokeSong(
      id: json['id'] as String,
      title: json['title'] as String,
      artistName: json['artistName'] as String,
      imageUrl: json['imageUrl'] as String?,
      songKey: json['songKey'] as String?,
      tempo: json['tempo'] as int?,
      difficulty: json['difficulty'] as String?,
      viewCount: json['viewCount'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      karaoke: Karaoke.fromJson(json['karaoke'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artistName': artistName,
      'imageUrl': imageUrl,
      'songKey': songKey,
      'tempo': tempo,
      'difficulty': difficulty,
      'viewCount': viewCount,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'createdAt': createdAt.toIso8601String(),
      'karaoke': karaoke.toJson(),
    };
  }
}

class KaraokeDownload {
  final String songId;
  final String localPath;
  final DateTime downloadedAt;
  final int fileSize;
  final int duration;

  const KaraokeDownload({
    required this.songId,
    required this.localPath,
    required this.downloadedAt,
    required this.fileSize,
    required this.duration,
  });

  factory KaraokeDownload.fromJson(Map<String, dynamic> json) {
    return KaraokeDownload(
      songId: json['songId'] as String,
      localPath: json['localPath'] as String,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      fileSize: json['fileSize'] as int,
      duration: json['duration'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songId': songId,
      'localPath': localPath,
      'downloadedAt': downloadedAt.toIso8601String(),
      'fileSize': fileSize,
      'duration': duration,
    };
  }
}

enum KaraokeQuality { high, medium, low }

enum KaraokeSortOption {
  popular,
  recent,
  title,
  artist,
}

extension KaraokeSortOptionExtension on KaraokeSortOption {
  String get displayName {
    switch (this) {
      case KaraokeSortOption.popular:
        return 'Popular';
      case KaraokeSortOption.recent:
        return 'Recent';
      case KaraokeSortOption.title:
        return 'Title A-Z';
      case KaraokeSortOption.artist:
        return 'Artist A-Z';
    }
  }

  String get apiValue {
    switch (this) {
      case KaraokeSortOption.popular:
        return 'popular';
      case KaraokeSortOption.recent:
        return 'recent';
      case KaraokeSortOption.title:
        return 'title';
      case KaraokeSortOption.artist:
        return 'artist';
    }
  }
}
