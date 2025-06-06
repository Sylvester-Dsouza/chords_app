import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocal.dart';

/// Dedicated download manager for vocal items that ensures downloads are never lost
class VocalDownloadManager extends ChangeNotifier {
  static final VocalDownloadManager _instance = VocalDownloadManager._internal();
  factory VocalDownloadManager() => _instance;
  VocalDownloadManager._internal();

  // Storage key for downloaded items - separate from cache to prevent accidental deletion
  static const String _downloadedItemsStorageKey = 'vocal_downloads_permanent';
  static const String _downloadStatsStorageKey = 'vocal_download_stats';

  // Downloaded items map - this should NEVER be auto-cleared
  final Map<String, VocalItem> _downloadedItems = {};

  // Download statistics
  int _totalDownloads = 0;
  int _totalSizeBytes = 0;

  // Getters
  Map<String, VocalItem> get downloadedItems => Map.unmodifiable(_downloadedItems);
  int get totalDownloads => _totalDownloads;
  int get totalSizeBytes => _totalSizeBytes;
  
  String get formattedTotalSize {
    if (_totalSizeBytes < 1024 * 1024) {
      return '${(_totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(_totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Initialize the download manager
  Future<void> initialize() async {
    await _loadDownloadedItems();
    await _verifyDownloadedFiles();
    await _updateStats();
    debugPrint('VocalDownloadManager initialized with ${_downloadedItems.length} downloads');
  }

  /// Add a downloaded item to permanent storage
  Future<void> addDownloadedItem(VocalItem item) async {
    if (item.localPath == null || !item.isDownloaded) {
      debugPrint('Cannot add item to downloads: missing local path or not downloaded');
      return;
    }

    _downloadedItems[item.id] = item;
    await _saveDownloadedItems();
    await _updateStats();
    notifyListeners();
    
    debugPrint('Added downloaded item: ${item.name} (${_downloadedItems.length} total downloads)');
  }

  /// Remove a downloaded item and delete the file
  Future<bool> removeDownloadedItem(String itemId) async {
    final item = _downloadedItems[itemId];
    if (item == null) {
      debugPrint('Item $itemId not found in downloads');
      return false;
    }

    try {
      // Delete the physical file
      if (item.localPath != null) {
        final file = File(item.localPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted file: ${item.localPath}');
        }
      }

      // Remove from downloads
      _downloadedItems.remove(itemId);
      await _saveDownloadedItems();
      await _updateStats();
      notifyListeners();

      debugPrint('Removed downloaded item: ${item.name} (${_downloadedItems.length} total downloads)');
      return true;
    } catch (e) {
      debugPrint('Error removing downloaded item $itemId: $e');
      return false;
    }
  }

  /// Check if an item is downloaded and file exists
  bool isItemDownloaded(String itemId) {
    final item = _downloadedItems[itemId];
    if (item?.localPath != null) {
      final file = File(item!.localPath!);
      return file.existsSync();
    }
    return false;
  }

  /// Get downloaded item by ID
  VocalItem? getDownloadedItem(String itemId) {
    return _downloadedItems[itemId];
  }

  /// Get all downloaded items as a list
  List<VocalItem> getAllDownloadedItems() {
    return _downloadedItems.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
  }

  /// Get download statistics
  Map<String, dynamic> getDownloadStats() {
    return {
      'totalDownloads': _totalDownloads,
      'totalSizeBytes': _totalSizeBytes,
      'formattedSize': formattedTotalSize,
      'downloadedItemIds': _downloadedItems.keys.toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Verify all downloaded files exist and clean up orphaned entries
  Future<void> _verifyDownloadedFiles() async {
    final itemsToRemove = <String>[];
    
    for (final entry in _downloadedItems.entries) {
      final itemId = entry.key;
      final item = entry.value;
      
      if (item.localPath != null) {
        final file = File(item.localPath!);
        if (!await file.exists()) {
          itemsToRemove.add(itemId);
          debugPrint('Downloaded file not found, removing from tracking: ${item.name}');
        }
      } else {
        itemsToRemove.add(itemId);
        debugPrint('Downloaded item has no local path, removing: ${item.name}');
      }
    }
    
    // Remove orphaned entries
    for (final itemId in itemsToRemove) {
      _downloadedItems.remove(itemId);
    }
    
    if (itemsToRemove.isNotEmpty) {
      await _saveDownloadedItems();
      debugPrint('Cleaned up ${itemsToRemove.length} orphaned download entries');
    }
  }

  /// Load downloaded items from permanent storage
  Future<void> _loadDownloadedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_downloadedItemsStorageKey);
      
      if (data != null) {
        final Map<String, dynamic> itemsJson = json.decode(data);
        _downloadedItems.clear();
        _downloadedItems.addAll(itemsJson.map(
          (key, value) => MapEntry(key, VocalItem.fromJson(value)),
        ));
        debugPrint('Loaded ${_downloadedItems.length} downloaded items from storage');
      }
    } catch (e) {
      debugPrint('Error loading downloaded items: $e');
    }
  }

  /// Save downloaded items to permanent storage
  Future<void> _saveDownloadedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = _downloadedItems.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await prefs.setString(_downloadedItemsStorageKey, json.encode(itemsJson));
      debugPrint('Saved ${_downloadedItems.length} downloaded items to storage');
    } catch (e) {
      debugPrint('Error saving downloaded items: $e');
    }
  }

  /// Update download statistics
  Future<void> _updateStats() async {
    _totalDownloads = _downloadedItems.length;
    _totalSizeBytes = _downloadedItems.values
        .fold(0, (total, item) => total + item.fileSizeBytes);
    
    // Save stats to storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = {
        'totalDownloads': _totalDownloads,
        'totalSizeBytes': _totalSizeBytes,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_downloadStatsStorageKey, json.encode(stats));
    } catch (e) {
      debugPrint('Error saving download stats: $e');
    }
  }

  /// Get the downloads directory path
  Future<String> getDownloadsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vocalsDir = Directory('${appDir.path}/vocals');
    if (!await vocalsDir.exists()) {
      await vocalsDir.create(recursive: true);
    }
    return vocalsDir.path;
  }

  /// Clear all downloads (use with extreme caution)
  Future<void> clearAllDownloads() async {
    try {
      // Delete all files
      for (final item in _downloadedItems.values) {
        if (item.localPath != null) {
          final file = File(item.localPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      // Clear the downloads map
      _downloadedItems.clear();
      await _saveDownloadedItems();
      await _updateStats();
      notifyListeners();

      debugPrint('Cleared all downloads');
    } catch (e) {
      debugPrint('Error clearing all downloads: $e');
    }
  }

  /// Export download list for backup
  Map<String, dynamic> exportDownloadList() {
    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'totalDownloads': _totalDownloads,
      'downloads': _downloadedItems.map((key, value) => MapEntry(key, {
        'id': value.id,
        'name': value.name,
        'categoryId': value.categoryId,
        'audioFileUrl': value.audioFileUrl,
        'durationSeconds': value.durationSeconds,
        'fileSizeBytes': value.fileSizeBytes,
        'localPath': value.localPath,
        'downloadedAt': value.createdAt.toIso8601String(),
      })),
    };
  }
}
