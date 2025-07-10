import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/karaoke.dart';

class MultiTrackDownloadManager extends ChangeNotifier {
  static const String _prefsKey = 'multi_track_downloads';
  static const String _statsKey = 'multi_track_stats';

  final Dio _dio = Dio();
  final Map<String, Map<TrackType, MultiTrackDownload>> _downloadedTracks = {};
  final Map<String, Map<TrackType, double>> _downloadProgress = {};
  int _totalDownloads = 0;
  int _totalSizeBytes = 0;

  // Getters
  Map<String, Map<TrackType, MultiTrackDownload>> get downloadedTracks => 
      Map.unmodifiable(_downloadedTracks);
  Map<String, Map<TrackType, double>> get downloadProgress => 
      Map.unmodifiable(_downloadProgress);
  int get totalDownloads => _totalDownloads;
  String get totalSizeFormatted => _formatFileSize(_totalSizeBytes);

  /// Initialize the download manager
  Future<void> initialize() async {
    await _loadDownloadedTracks();
    await _loadStats();
    await _cleanupInvalidFiles();
  }

  /// Check if all tracks for a song are downloaded
  bool areAllTracksDownloaded(String songId, List<TrackType> requiredTracks) {
    final songTracks = _downloadedTracks[songId];
    if (songTracks == null) return false;
    
    for (final trackType in requiredTracks) {
      if (!songTracks.containsKey(trackType)) return false;
    }
    return true;
  }

  /// Check if a specific track is downloaded
  bool isTrackDownloaded(String songId, TrackType trackType) {
    return _downloadedTracks[songId]?.containsKey(trackType) ?? false;
  }

  /// Get local path for a downloaded track
  String? getLocalPath(String songId, TrackType trackType) {
    return _downloadedTracks[songId]?[trackType]?.localPath;
  }

  /// Get all local paths for a song
  Map<TrackType, String> getLocalPaths(String songId) {
    final songTracks = _downloadedTracks[songId];
    if (songTracks == null) return {};
    
    final paths = <TrackType, String>{};
    for (final entry in songTracks.entries) {
      paths[entry.key] = entry.value.localPath;
    }
    return paths;
  }

  /// Download a single track
  Future<bool> downloadTrack(
    String songId,
    TrackType trackType,
    String downloadUrl, {
    required int fileSize,
    required int duration,
    String? fileName,
  }) async {
    try {
      // Check if already downloaded
      if (isTrackDownloaded(songId, trackType)) {
        debugPrint('🎤 Track already downloaded: $songId - ${trackType.displayName}');
        return true;
      }

      // Create karaoke directory
      final appDir = await getApplicationDocumentsDirectory();
      final karaokeDir = Directory('${appDir.path}/karaoke/multi_track');
      if (!await karaokeDir.exists()) {
        await karaokeDir.create(recursive: true);
      }

      // Generate file name
      final extension = _getFileExtension(downloadUrl);
      final localFileName = fileName ?? '${songId}_${trackType.apiValue}.$extension';
      final localPath = '${karaokeDir.path}/$localFileName';

      // Initialize progress tracking
      if (_downloadProgress[songId] == null) {
        _downloadProgress[songId] = {};
      }
      _downloadProgress[songId]![trackType] = 0.0;
      notifyListeners();

      // Download with progress tracking
      await _dio.download(
        downloadUrl,
        localPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[songId]![trackType] = progress;
            notifyListeners();
          }
        },
      );

      // Verify file exists and has correct size
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Downloaded file not found');
      }

      final actualSize = await file.length();
      if (fileSize > 0 && (actualSize - fileSize).abs() > 1024) {
        debugPrint('Warning: File size mismatch. Expected: $fileSize, Actual: $actualSize');
      }

      // Create download record
      final download = MultiTrackDownload(
        songId: songId,
        trackType: trackType,
        localPath: localPath,
        downloadedAt: DateTime.now(),
        fileSize: actualSize,
        duration: duration,
      );

      // Save to memory and storage
      if (_downloadedTracks[songId] == null) {
        _downloadedTracks[songId] = {};
      }
      _downloadedTracks[songId]![trackType] = download;
      _downloadProgress[songId]?.remove(trackType);
      
      await _saveDownloadedTracks();
      await _updateStats();
      notifyListeners();

      debugPrint('🎤 Track downloaded successfully: $songId - ${trackType.displayName}');
      return true;

    } catch (e) {
      debugPrint('🎤 Error downloading track $songId - ${trackType.displayName}: $e');
      _downloadProgress[songId]?.remove(trackType);
      notifyListeners();
      return false;
    }
  }

  /// Download all tracks for a song
  Future<Map<TrackType, bool>> downloadAllTracks(
    String songId,
    Map<TrackType, String> trackUrls, {
    Map<TrackType, int>? fileSizes,
    Map<TrackType, int>? durations,
  }) async {
    final results = <TrackType, bool>{};
    
    for (final entry in trackUrls.entries) {
      final trackType = entry.key;
      final downloadUrl = entry.value;
      
      final success = await downloadTrack(
        songId,
        trackType,
        downloadUrl,
        fileSize: fileSizes?[trackType] ?? 0,
        duration: durations?[trackType] ?? 0,
      );
      
      results[trackType] = success;
    }
    
    return results;
  }

  /// Delete a specific track
  Future<bool> deleteTrack(String songId, TrackType trackType) async {
    try {
      final download = _downloadedTracks[songId]?[trackType];
      if (download == null) return true;

      // Delete file
      final file = File(download.localPath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from memory
      _downloadedTracks[songId]?.remove(trackType);
      if (_downloadedTracks[songId]?.isEmpty ?? false) {
        _downloadedTracks.remove(songId);
      }

      await _saveDownloadedTracks();
      await _updateStats();
      notifyListeners();

      debugPrint('🎤 Track deleted: $songId - ${trackType.displayName}');
      return true;
    } catch (e) {
      debugPrint('🎤 Error deleting track: $e');
      return false;
    }
  }

  /// Delete all tracks for a song
  Future<bool> deleteAllTracks(String songId) async {
    try {
      final songTracks = _downloadedTracks[songId];
      if (songTracks == null) return true;

      for (final download in songTracks.values) {
        final file = File(download.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _downloadedTracks.remove(songId);
      await _saveDownloadedTracks();
      await _updateStats();
      notifyListeners();

      debugPrint('🎤 All tracks deleted for song: $songId');
      return true;
    } catch (e) {
      debugPrint('🎤 Error deleting all tracks: $e');
      return false;
    }
  }

  /// Get download progress for a specific track
  double getTrackProgress(String songId, TrackType trackType) {
    return _downloadProgress[songId]?[trackType] ?? 0.0;
  }

  /// Get overall download progress for a song
  double getSongProgress(String songId, List<TrackType> requiredTracks) {
    final songProgress = _downloadProgress[songId];
    if (songProgress == null || songProgress.isEmpty) return 0.0;
    
    double totalProgress = 0.0;
    int trackCount = 0;
    
    for (final trackType in requiredTracks) {
      if (songProgress.containsKey(trackType)) {
        totalProgress += songProgress[trackType]!;
        trackCount++;
      } else if (isTrackDownloaded(songId, trackType)) {
        totalProgress += 1.0;
        trackCount++;
      }
    }
    
    return trackCount > 0 ? totalProgress / trackCount : 0.0;
  }

  // Private methods
  Future<void> _loadDownloadedTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_prefsKey);
      if (data != null) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        for (final entry in json.entries) {
          final songId = entry.key;
          final tracksJson = entry.value as Map<String, dynamic>;
          
          _downloadedTracks[songId] = {};
          for (final trackEntry in tracksJson.entries) {
            final trackType = TrackTypeExtension.fromApiValue(trackEntry.key);
            final download = MultiTrackDownload.fromJson(trackEntry.value);
            _downloadedTracks[songId]![trackType] = download;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading downloaded tracks: $e');
    }
  }

  Future<void> _saveDownloadedTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = <String, dynamic>{};
      
      for (final entry in _downloadedTracks.entries) {
        final songId = entry.key;
        final tracks = entry.value;
        
        json[songId] = {};
        for (final trackEntry in tracks.entries) {
          json[songId][trackEntry.key.apiValue] = trackEntry.value.toJson();
        }
      }
      
      await prefs.setString(_prefsKey, jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving downloaded tracks: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalDownloads = prefs.getInt('${_statsKey}_count') ?? 0;
      _totalSizeBytes = prefs.getInt('${_statsKey}_size') ?? 0;
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _updateStats() async {
    try {
      int totalTracks = 0;
      int totalSize = 0;
      
      for (final songTracks in _downloadedTracks.values) {
        for (final download in songTracks.values) {
          totalTracks++;
          totalSize += download.fileSize;
        }
      }
      
      _totalDownloads = totalTracks;
      _totalSizeBytes = totalSize;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_statsKey}_count', _totalDownloads);
      await prefs.setInt('${_statsKey}_size', _totalSizeBytes);
    } catch (e) {
      debugPrint('Error updating stats: $e');
    }
  }

  Future<void> _cleanupInvalidFiles() async {
    try {
      final toRemove = <String, List<TrackType>>{};
      
      for (final songEntry in _downloadedTracks.entries) {
        final songId = songEntry.key;
        for (final trackEntry in songEntry.value.entries) {
          final trackType = trackEntry.key;
          final download = trackEntry.value;
          
          final file = File(download.localPath);
          if (!await file.exists()) {
            if (toRemove[songId] == null) toRemove[songId] = [];
            toRemove[songId]!.add(trackType);
          }
        }
      }
      
      for (final entry in toRemove.entries) {
        for (final trackType in entry.value) {
          _downloadedTracks[entry.key]?.remove(trackType);
        }
        if (_downloadedTracks[entry.key]?.isEmpty ?? false) {
          _downloadedTracks.remove(entry.key);
        }
      }
      
      if (toRemove.isNotEmpty) {
        await _saveDownloadedTracks();
        await _updateStats();
      }
    } catch (e) {
      debugPrint('Error cleaning up invalid files: $e');
    }
  }

  String _getFileExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot != -1 && lastDot < path.length - 1) {
      return path.substring(lastDot + 1);
    }
    return 'mp3'; // Default extension
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

/// Data class for multi-track download information
class MultiTrackDownload {
  final String songId;
  final TrackType trackType;
  final String localPath;
  final DateTime downloadedAt;
  final int fileSize;
  final int duration;

  const MultiTrackDownload({
    required this.songId,
    required this.trackType,
    required this.localPath,
    required this.downloadedAt,
    required this.fileSize,
    required this.duration,
  });

  factory MultiTrackDownload.fromJson(Map<String, dynamic> json) {
    return MultiTrackDownload(
      songId: json['songId'] as String,
      trackType: TrackTypeExtension.fromApiValue(json['trackType'] as String),
      localPath: json['localPath'] as String,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      fileSize: json['fileSize'] as int,
      duration: json['duration'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songId': songId,
      'trackType': trackType.apiValue,
      'localPath': localPath,
      'downloadedAt': downloadedAt.toIso8601String(),
      'fileSize': fileSize,
      'duration': duration,
    };
  }
}
