import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/karaoke.dart';

/// Dedicated download manager for karaoke tracks
class KaraokeDownloadManager extends ChangeNotifier {
  static final KaraokeDownloadManager _instance = KaraokeDownloadManager._internal();
  factory KaraokeDownloadManager() => _instance;
  KaraokeDownloadManager._internal();

  static const String _downloadedTracksKey = 'karaoke_downloads_permanent';
  static const String _downloadStatsKey = 'karaoke_download_stats';

  final Map<String, KaraokeDownload> _downloadedTracks = {};
  final Map<String, double> _downloadProgress = {};
  final Dio _dio = Dio();

  int _totalDownloads = 0;
  int _totalSizeBytes = 0;

  // Getters
  Map<String, KaraokeDownload> get downloadedTracks => Map.unmodifiable(_downloadedTracks);
  Map<String, double> get downloadProgress => Map.unmodifiable(_downloadProgress);
  int get totalDownloads => _totalDownloads;
  String get totalSizeFormatted => _formatFileSize(_totalSizeBytes);

  /// Initialize the download manager
  Future<void> initialize() async {
    await _loadDownloadedTracks();
    await _loadStats();
    await _cleanupInvalidFiles();
  }

  /// Check if a karaoke track is downloaded
  bool isDownloaded(String songId) {
    return _downloadedTracks.containsKey(songId);
  }

  /// Get local path for a downloaded track
  String? getLocalPath(String songId) {
    return _downloadedTracks[songId]?.localPath;
  }

  /// Download a karaoke track
  Future<bool> downloadTrack(String songId, String downloadUrl, {
    required int fileSize,
    required int duration,
    String? fileName,
  }) async {
    try {
      // Check if already downloaded
      if (isDownloaded(songId)) {
        debugPrint('Karaoke track already downloaded: $songId');
        return true;
      }

      // Create karaoke directory
      final appDir = await getApplicationDocumentsDirectory();
      final karaokeDir = Directory('${appDir.path}/karaoke');
      if (!await karaokeDir.exists()) {
        await karaokeDir.create(recursive: true);
      }

      // Generate file name
      final extension = _getFileExtension(downloadUrl);
      final localFileName = fileName ?? '${songId}_karaoke.$extension';
      final localPath = '${karaokeDir.path}/$localFileName';

      // Initialize progress
      _downloadProgress[songId] = 0.0;
      notifyListeners();

      // Download with progress tracking
      await _dio.download(
        downloadUrl,
        localPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[songId] = progress;
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
      final download = KaraokeDownload(
        songId: songId,
        localPath: localPath,
        downloadedAt: DateTime.now(),
        fileSize: actualSize,
        duration: duration,
      );

      // Save to memory and storage
      _downloadedTracks[songId] = download;
      _downloadProgress.remove(songId);
      await _saveDownloadedTracks();
      await _updateStats();
      notifyListeners();

      debugPrint('Karaoke track downloaded successfully: $songId');
      return true;

    } catch (e) {
      debugPrint('Error downloading karaoke track $songId: $e');
      _downloadProgress.remove(songId);
      notifyListeners();
      return false;
    }
  }

  /// Remove a downloaded track
  Future<bool> removeTrack(String songId) async {
    try {
      final download = _downloadedTracks[songId];
      if (download == null) {
        return true; // Already removed
      }

      // Delete local file
      final file = File(download.localPath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from memory and storage
      _downloadedTracks.remove(songId);
      await _saveDownloadedTracks();
      await _updateStats();
      notifyListeners();

      debugPrint('Karaoke track removed: $songId');
      return true;

    } catch (e) {
      debugPrint('Error removing karaoke track $songId: $e');
      return false;
    }
  }

  /// Get download progress for a track
  double getDownloadProgress(String songId) {
    return _downloadProgress[songId] ?? 0.0;
  }

  /// Check if a track is currently downloading
  bool isDownloading(String songId) {
    return _downloadProgress.containsKey(songId);
  }

  /// Clear all downloads
  Future<void> clearAllDownloads() async {
    try {
      // Delete all local files
      for (final download in _downloadedTracks.values) {
        final file = File(download.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Clear memory and storage
      _downloadedTracks.clear();
      _downloadProgress.clear();
      await _saveDownloadedTracks();
      await _updateStats();
      notifyListeners();

      debugPrint('All karaoke downloads cleared');
    } catch (e) {
      debugPrint('Error clearing karaoke downloads: $e');
    }
  }

  /// Load downloaded tracks from storage
  Future<void> _loadDownloadedTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_downloadedTracksKey);
      
      if (data != null) {
        final Map<String, dynamic> json = jsonDecode(data);
        _downloadedTracks.clear();
        
        for (final entry in json.entries) {
          try {
            _downloadedTracks[entry.key] = KaraokeDownload.fromJson(entry.value);
          } catch (e) {
            debugPrint('Error loading download record ${entry.key}: $e');
          }
        }
        
        debugPrint('Loaded ${_downloadedTracks.length} karaoke downloads');
      }
    } catch (e) {
      debugPrint('Error loading karaoke downloads: $e');
    }
  }

  /// Save downloaded tracks to storage
  Future<void> _saveDownloadedTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> json = {};
      
      for (final entry in _downloadedTracks.entries) {
        json[entry.key] = entry.value.toJson();
      }
      
      await prefs.setString(_downloadedTracksKey, jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving karaoke downloads: $e');
    }
  }

  /// Load download statistics
  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalDownloads = prefs.getInt('${_downloadStatsKey}_count') ?? 0;
      _totalSizeBytes = prefs.getInt('${_downloadStatsKey}_size') ?? 0;
    } catch (e) {
      debugPrint('Error loading karaoke download stats: $e');
    }
  }

  /// Update download statistics
  Future<void> _updateStats() async {
    try {
      _totalDownloads = _downloadedTracks.length;
      _totalSizeBytes = _downloadedTracks.values
          .fold(0, (sum, download) => sum + download.fileSize);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_downloadStatsKey}_count', _totalDownloads);
      await prefs.setInt('${_downloadStatsKey}_size', _totalSizeBytes);
    } catch (e) {
      debugPrint('Error updating karaoke download stats: $e');
    }
  }

  /// Clean up invalid files
  Future<void> _cleanupInvalidFiles() async {
    try {
      final toRemove = <String>[];
      
      for (final entry in _downloadedTracks.entries) {
        final file = File(entry.value.localPath);
        if (!await file.exists()) {
          toRemove.add(entry.key);
        }
      }
      
      for (final songId in toRemove) {
        _downloadedTracks.remove(songId);
      }
      
      if (toRemove.isNotEmpty) {
        await _saveDownloadedTracks();
        await _updateStats();
        debugPrint('Cleaned up ${toRemove.length} invalid karaoke files');
      }
    } catch (e) {
      debugPrint('Error cleaning up karaoke files: $e');
    }
  }

  /// Get file extension from URL
  String _getFileExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();
    
    if (path.endsWith('.mp3')) return 'mp3';
    if (path.endsWith('.wav')) return 'wav';
    if (path.endsWith('.m4a')) return 'm4a';
    if (path.endsWith('.aac')) return 'aac';
    
    return 'mp3'; // Default
  }

  /// Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
