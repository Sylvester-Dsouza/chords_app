import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// Persistent cache manager that survives app restarts
/// Uses file system for permanent storage with smart update checking
class PersistentCacheManager {
  static final PersistentCacheManager _instance = PersistentCacheManager._internal();
  factory PersistentCacheManager() => _instance;
  PersistentCacheManager._internal();

  Directory? _cacheDir;
  final Map<String, dynamic> _memoryCache = {};
  
  // Cache metadata for smart updates
  final Map<String, CacheMetadata> _cacheMetadata = {};

  /// Initialize the cache manager
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/persistent_cache');
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      
      // Load cache metadata
      await _loadCacheMetadata();
      
      debugPrint('📦 Persistent cache initialized at: ${_cacheDir!.path}');
    } catch (e) {
      debugPrint('❌ Error initializing persistent cache: $e');
    }
  }

  /// Check if data exists in cache and is still valid
  Future<bool> hasValidCache(String key, {Duration maxAge = const Duration(days: 7)}) async {
    try {
      final metadata = _cacheMetadata[key];
      if (metadata == null) return false;
      
      final age = DateTime.now().difference(metadata.lastUpdated);
      return age < maxAge;
    } catch (e) {
      debugPrint('Error checking cache validity for $key: $e');
      return false;
    }
  }

  /// Get data from cache (memory first, then disk)
  Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        debugPrint('📦 Cache HIT (memory): $key');
        return fromJson(_memoryCache[key]);
      }

      // Check disk cache
      final file = File('${_cacheDir!.path}/$key.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        
        // Store in memory for faster access
        _memoryCache[key] = data;
        
        debugPrint('📦 Cache HIT (disk): $key');
        return fromJson(data);
      }

      debugPrint('📦 Cache MISS: $key');
      return null;
    } catch (e) {
      debugPrint('❌ Error reading cache for $key: $e');
      return null;
    }
  }

  /// Get list data from cache
  Future<List<T>?> getList<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        final List<dynamic> data = _memoryCache[key];
        debugPrint('📦 Cache HIT (memory): $key - ${data.length} items');
        return data.map((item) => fromJson(item)).toList();
      }

      // Check disk cache
      final file = File('${_cacheDir!.path}/$key.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> data = json.decode(content);
        
        // Store in memory for faster access
        _memoryCache[key] = data;
        
        debugPrint('📦 Cache HIT (disk): $key - ${data.length} items');
        return data.map((item) => fromJson(item)).toList();
      }

      debugPrint('📦 Cache MISS: $key');
      return null;
    } catch (e) {
      debugPrint('❌ Error reading list cache for $key: $e');
      return null;
    }
  }

  /// Store data in cache (both memory and disk)
  Future<void> set<T>(String key, T data, Map<String, dynamic> Function(T) toJson) async {
    try {
      final jsonData = toJson(data);
      
      // Store in memory
      _memoryCache[key] = jsonData;
      
      // Store on disk
      final file = File('${_cacheDir!.path}/$key.json');
      await file.writeAsString(json.encode(jsonData));
      
      // Update metadata
      _cacheMetadata[key] = CacheMetadata(
        key: key,
        lastUpdated: DateTime.now(),
        dataHash: _generateHash(jsonData),
        size: jsonData.toString().length,
      );
      
      await _saveCacheMetadata();
      
      debugPrint('📦 Cache STORED: $key');
    } catch (e) {
      debugPrint('❌ Error storing cache for $key: $e');
    }
  }

  /// Store list data in cache
  Future<void> setList<T>(String key, List<T> data, Map<String, dynamic> Function(T) toJson) async {
    try {
      final jsonData = data.map((item) => toJson(item)).toList();
      
      // Store in memory
      _memoryCache[key] = jsonData;
      
      // Store on disk
      final file = File('${_cacheDir!.path}/$key.json');
      await file.writeAsString(json.encode(jsonData));
      
      // Update metadata
      _cacheMetadata[key] = CacheMetadata(
        key: key,
        lastUpdated: DateTime.now(),
        dataHash: _generateHash(jsonData),
        size: jsonData.toString().length,
      );
      
      await _saveCacheMetadata();
      
      debugPrint('📦 Cache STORED: $key - ${data.length} items');
    } catch (e) {
      debugPrint('❌ Error storing list cache for $key: $e');
    }
  }

  /// Get cache metadata for smart updates
  CacheMetadata? getMetadata(String key) {
    return _cacheMetadata[key];
  }

  /// Check if data has changed (for delta sync)
  bool hasDataChanged(String key, dynamic newData) {
    final metadata = _cacheMetadata[key];
    if (metadata == null) return true;
    
    final newHash = _generateHash(newData);
    return metadata.dataHash != newHash;
  }

  /// Clear specific cache entry
  Future<void> remove(String key) async {
    try {
      _memoryCache.remove(key);
      _cacheMetadata.remove(key);
      
      final file = File('${_cacheDir!.path}/$key.json');
      if (await file.exists()) {
        await file.delete();
      }
      
      await _saveCacheMetadata();
      debugPrint('📦 Cache REMOVED: $key');
    } catch (e) {
      debugPrint('❌ Error removing cache for $key: $e');
    }
  }

  /// Get cache size and statistics
  Future<CacheStats> getStats() async {
    try {
      int totalFiles = 0;
      int totalSize = 0;
      
      if (_cacheDir != null && await _cacheDir!.exists()) {
        final files = _cacheDir!.listSync();
        totalFiles = files.length;
        
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            totalSize += stat.size;
          }
        }
      }
      
      return CacheStats(
        totalFiles: totalFiles,
        totalSizeBytes: totalSize,
        memoryEntries: _memoryCache.length,
        oldestEntry: _getOldestCacheDate(),
      );
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return CacheStats(totalFiles: 0, totalSizeBytes: 0, memoryEntries: 0);
    }
  }

  /// Load cache metadata from disk
  Future<void> _loadCacheMetadata() async {
    try {
      final file = File('${_cacheDir!.path}/metadata.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = json.decode(content);
        
        for (final entry in data.entries) {
          _cacheMetadata[entry.key] = CacheMetadata.fromJson(entry.value);
        }
        
        debugPrint('📦 Loaded metadata for ${_cacheMetadata.length} cache entries');
      }
    } catch (e) {
      debugPrint('Error loading cache metadata: $e');
    }
  }

  /// Save cache metadata to disk
  Future<void> _saveCacheMetadata() async {
    try {
      final file = File('${_cacheDir!.path}/metadata.json');
      final data = <String, dynamic>{};
      
      for (final entry in _cacheMetadata.entries) {
        data[entry.key] = entry.value.toJson();
      }
      
      await file.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('Error saving cache metadata: $e');
    }
  }

  /// Generate hash for data comparison
  String _generateHash(dynamic data) {
    final content = json.encode(data);
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get oldest cache entry date
  DateTime? _getOldestCacheDate() {
    if (_cacheMetadata.isEmpty) return null;
    
    return _cacheMetadata.values
        .map((m) => m.lastUpdated)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }
}

/// Cache metadata for tracking updates
class CacheMetadata {
  final String key;
  final DateTime lastUpdated;
  final String dataHash;
  final int size;

  CacheMetadata({
    required this.key,
    required this.lastUpdated,
    required this.dataHash,
    required this.size,
  });

  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      key: json['key'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      dataHash: json['dataHash'],
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'lastUpdated': lastUpdated.toIso8601String(),
      'dataHash': dataHash,
      'size': size,
    };
  }
}

/// Cache statistics
class CacheStats {
  final int totalFiles;
  final int totalSizeBytes;
  final int memoryEntries;
  final DateTime? oldestEntry;

  CacheStats({
    required this.totalFiles,
    required this.totalSizeBytes,
    required this.memoryEntries,
    this.oldestEntry,
  });

  double get totalSizeMB => totalSizeBytes / (1024 * 1024);
}
