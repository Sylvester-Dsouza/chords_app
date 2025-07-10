enum TrackType {
  vocals,
  bass,
  drums,
  other,
}

extension TrackTypeExtension on TrackType {
  String get displayName {
    switch (this) {
      case TrackType.vocals:
        return 'Vocals';
      case TrackType.bass:
        return 'Bass';
      case TrackType.drums:
        return 'Drums';
      case TrackType.other:
        return 'Other';
    }
  }

  String get apiValue {
    switch (this) {
      case TrackType.vocals:
        return 'VOCALS';
      case TrackType.bass:
        return 'BASS';
      case TrackType.drums:
        return 'DRUMS';
      case TrackType.other:
        return 'OTHER';
    }
  }

  static TrackType fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'VOCALS':
        return TrackType.vocals;
      case 'BASS':
        return TrackType.bass;
      case 'DRUMS':
        return TrackType.drums;
      case 'OTHER':
        return TrackType.other;
      default:
        return TrackType.other;
    }
  }
}

class KaraokeTrack {
  final String id;
  final String karaokeId;
  final TrackType trackType;
  final String fileUrl;
  final int? fileSize;
  final int? duration;
  final double volume;
  final bool isMuted;
  final DateTime uploadedAt;
  final DateTime updatedAt;
  final String? quality;
  final String? notes;
  final String status;

  const KaraokeTrack({
    required this.id,
    required this.karaokeId,
    required this.trackType,
    required this.fileUrl,
    this.fileSize,
    this.duration,
    required this.volume,
    required this.isMuted,
    required this.uploadedAt,
    required this.updatedAt,
    this.quality,
    this.notes,
    required this.status,
  });

  factory KaraokeTrack.fromJson(Map<String, dynamic> json) {
    return KaraokeTrack(
      id: json['id'] as String,
      karaokeId: json['karaokeId'] as String,
      trackType: TrackTypeExtension.fromApiValue(json['trackType'] as String),
      fileUrl: json['fileUrl'] as String,
      fileSize: json['fileSize'] as int?,
      duration: json['duration'] as int?,
      volume: (json['volume'] as num).toDouble(),
      isMuted: json['isMuted'] as bool,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      quality: json['quality'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'karaokeId': karaokeId,
      'trackType': trackType.apiValue,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'duration': duration,
      'volume': volume,
      'isMuted': isMuted,
      'uploadedAt': uploadedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'quality': quality,
      'notes': notes,
      'status': status,
    };
  }

  KaraokeTrack copyWith({
    String? id,
    String? karaokeId,
    TrackType? trackType,
    String? fileUrl,
    int? fileSize,
    int? duration,
    double? volume,
    bool? isMuted,
    DateTime? uploadedAt,
    DateTime? updatedAt,
    String? quality,
    String? notes,
    String? status,
  }) {
    return KaraokeTrack(
      id: id ?? this.id,
      karaokeId: karaokeId ?? this.karaokeId,
      trackType: trackType ?? this.trackType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  bool get isActive => status == 'ACTIVE';
}

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
  final List<KaraokeTrack> tracks;

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
    this.tracks = const [],
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
      tracks: json['tracks'] != null
          ? (json['tracks'] as List)
              .map((trackJson) => KaraokeTrack.fromJson(trackJson as Map<String, dynamic>))
              .toList()
          : [],
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
      'tracks': tracks.map((track) => track.toJson()).toList(),
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
