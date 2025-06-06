

/// Enum for vocal types
enum VocalType {
  warmup('WARMUP'),
  exercise('EXERCISE');

  const VocalType(this.value);
  final String value;

  static VocalType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'WARMUP':
        return VocalType.warmup;
      case 'EXERCISE':
        return VocalType.exercise;
      default:
        throw ArgumentError('Unknown VocalType: $value');
    }
  }

  String get displayName {
    switch (this) {
      case VocalType.warmup:
        return 'Warmup';
      case VocalType.exercise:
        return 'Exercise';
    }
  }
}

/// Model for vocal categories (warmups and exercises)
class VocalCategory {
  final String id;
  final String name;
  final VocalType type;
  final String? description;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? itemCount;
  final List<VocalItem>? items;

  VocalCategory({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.itemCount,
    this.items,
  });

  factory VocalCategory.fromJson(Map<String, dynamic> json) {
    return VocalCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      type: VocalType.fromString(json['type'] as String),
      description: json['description'] as String?,
      displayOrder: json['displayOrder'] as int,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      itemCount: json['itemCount'] as int?,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => VocalItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'description': description,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'itemCount': itemCount,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  VocalCategory copyWith({
    String? id,
    String? name,
    VocalType? type,
    String? description,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? itemCount,
    List<VocalItem>? items,
  }) {
    return VocalCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VocalCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VocalCategory(id: $id, name: $name, type: $type, itemCount: $itemCount)';
  }
}

/// Model for individual vocal items (warmups/exercises)
class VocalItem {
  final String id;
  final String categoryId;
  final String name;
  final String audioFileUrl;
  final int durationSeconds;
  final int fileSizeBytes;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Local storage properties
  final String? localPath;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;

  VocalItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.audioFileUrl,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.localPath,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
  });

  factory VocalItem.fromJson(Map<String, dynamic> json) {
    return VocalItem(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
      audioFileUrl: json['audioFileUrl'] as String,
      durationSeconds: json['durationSeconds'] as int,
      fileSizeBytes: json['fileSizeBytes'] as int,
      displayOrder: json['displayOrder'] as int,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      localPath: json['localPath'] as String?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      isDownloading: json['isDownloading'] as bool? ?? false,
      downloadProgress: (json['downloadProgress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'audioFileUrl': audioFileUrl,
      'durationSeconds': durationSeconds,
      'fileSizeBytes': fileSizeBytes,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'localPath': localPath,
      'isDownloaded': isDownloaded,
      'isDownloading': isDownloading,
      'downloadProgress': downloadProgress,
    };
  }

  VocalItem copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? audioFileUrl,
    int? durationSeconds,
    int? fileSizeBytes,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? localPath,
    bool? isDownloaded,
    bool? isDownloading,
    double? downloadProgress,
  }) {
    return VocalItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      audioFileUrl: audioFileUrl ?? this.audioFileUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  /// Get formatted duration as MM:SS
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get file size in MB
  double get fileSizeMB {
    return fileSizeBytes / (1024 * 1024);
  }

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '${fileSizeBytes}B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VocalItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VocalItem(id: $id, name: $name, duration: $formattedDuration, downloaded: $isDownloaded)';
  }
}
