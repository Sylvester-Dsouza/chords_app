import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/vocal.dart';
import '../services/cache_service.dart';
import '../services/auth_service.dart';
import '../services/vocal_download_manager.dart';
import '../utils/performance_utils.dart';

/// Service for managing vocal warmups and exercises
class VocalService extends ChangeNotifier {
  static final VocalService _instance = VocalService._internal();
  factory VocalService() => _instance;
  VocalService._internal();

  final CacheService _cacheService = CacheService();
  final AuthService _authService = AuthService();
  final VocalDownloadManager _downloadManager = VocalDownloadManager();
  final Dio _dio = Dio();

  // Cache keys
  static const String _categoriesCacheKey = 'vocal_categories';
  static const String _itemsCacheKey = 'vocal_items';
  static const String _downloadedItemsKey = 'downloaded_vocal_items';

  // Memory management constants
  static const int _maxCategoryItems = 20; // Limit cached categories
  static const int _maxItemsPerCategory = 100; // Limit items per category
  // NOTE: Downloaded items should NEVER be limited - they are permanent until manually deleted

  // Local state
  List<VocalCategory> _categories = [];
  final Map<String, List<VocalItem>> _categoryItems = {};
  final Map<String, VocalItem> _downloadedItems = {}; // This should never be auto-cleaned
  bool _isLoading = false;
  String? _error;

  // Memory usage tracking


  // Getters
  List<VocalCategory> get categories => _categories;
  Map<String, List<VocalItem>> get categoryItems => _categoryItems;
  Map<String, VocalItem> get downloadedItems => _downloadManager.downloadedItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Memory management - cleanup old entries (NEVER touch downloaded items)
  void _cleanupMemory() {
    // Cleanup category items if exceeding limit
    if (_categoryItems.length > _maxCategoryItems) {
      final keys = _categoryItems.keys.toList();
      final keysToRemove = keys.take(_categoryItems.length - _maxCategoryItems);
      for (final key in keysToRemove) {
        _categoryItems.remove(key);
      }
      debugPrint('Cleaned up ${keysToRemove.length} category items from memory');
    }

    // IMPORTANT: Downloaded items are NEVER auto-cleaned from memory
    // They represent actual downloaded files and should persist until manually deleted
    // Removing them from memory would make the app lose track of downloaded files

    // Cleanup items per category if exceeding limit
    for (final categoryId in _categoryItems.keys.toList()) {
      final items = _categoryItems[categoryId]!;
      if (items.length > _maxItemsPerCategory) {
        _categoryItems[categoryId] = items.take(_maxItemsPerCategory).toList();
        debugPrint('Cleaned up ${items.length - _maxItemsPerCategory} items from category $categoryId');
      }
    }
  }

  /// Clear all cached data and reset state (but preserve downloaded items)
  void clearCache() {
    _categories.clear();
    _categoryItems.clear();
    // IMPORTANT: Do NOT clear downloaded items - they represent actual downloaded files
    // _downloadedItems.clear(); // This line is commented out to preserve downloads
    _error = null;

    debugPrint('Vocal service cache cleared (downloaded items preserved)');
    notifyListeners();
  }

  /// Clear ALL data including downloaded items (use with caution)
  void clearAllData() {
    _categories.clear();
    _categoryItems.clear();
    _downloadedItems.clear();
    _error = null;

    debugPrint('Vocal service ALL data cleared (including downloads)');
    notifyListeners();
  }

  /// Dispose resources properly (preserve downloaded items)
  @override
  void dispose() {
    // Use clearCache() which preserves downloaded items
    clearCache();
    super.dispose();
  }

  /// Get categories by type
  List<VocalCategory> getCategoriesByType(VocalType type) {
    return _categories.where((category) => category.type == type).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  /// Get items for a specific category
  List<VocalItem> getItemsForCategory(String categoryId) {
    return _categoryItems[categoryId] ?? [];
  }

  /// Initialize the service
  Future<void> initialize() async {
    try {
      // Initialize the dedicated download manager first
      await _downloadManager.initialize();

      // Load downloaded items from the old system for migration
      await _loadDownloadedItems();
      await _migrateToDownloadManager();

      await fetchCategories();
    } catch (e) {
      debugPrint('Error initializing VocalService: $e');
      _error = 'Failed to initialize vocal service';
      notifyListeners();
    }
  }

  /// Migrate existing downloads to the new download manager
  Future<void> _migrateToDownloadManager() async {
    try {
      for (final item in _downloadedItems.values) {
        if (item.isDownloaded && item.localPath != null) {
          await _downloadManager.addDownloadedItem(item);
        }
      }

      // Clear the old downloaded items map since we're now using the download manager
      _downloadedItems.clear();

      debugPrint('Migrated ${_downloadManager.totalDownloads} downloads to new download manager');
    } catch (e) {
      debugPrint('Error migrating downloads: $e');
    }
  }



  /// Fetch all vocal categories from API with improved caching and memory management
  Future<void> fetchCategories({bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _error = null;

      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedData = await _cacheService.get(_categoriesCacheKey);
        if (cachedData != null) {
          try {
            final List<dynamic> categoriesJson = json.decode(cachedData) as List<dynamic>;
            _categories = categoriesJson
                .map((json) => VocalCategory.fromJson(json as Map<String, dynamic>))
                .where((category) => category.isActive)
                .toList();
            _categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

            // Cleanup memory after loading from cache
            _cleanupMemory();
            notifyListeners();

            // Return early if cache is fresh (less than 5 minutes old)
            final cacheTime = await _cacheService.get('${_categoriesCacheKey}_timestamp');
            if (cacheTime != null) {
              final timestamp = int.tryParse(cacheTime) ?? 0;
              final now = DateTime.now().millisecondsSinceEpoch;
              if (now - timestamp < 300000) { // 5 minutes
                _setLoading(false);
                return;
              }
            }
          } catch (e) {
            debugPrint('Error parsing cached categories: $e');
            // Continue to fetch from API if cache is corrupted
          }
        }
      }

      // Fetch from API with timeout
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vocal/categories?onlyActive=true'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> categoriesJson = json.decode(response.body) as List<dynamic>;
        _categories = categoriesJson
            .map((json) => VocalCategory.fromJson(json as Map<String, dynamic>))
            .toList();
        _categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        // Cache the response with timestamp
        await _cacheService.set(_categoriesCacheKey, response.body);
        await _cacheService.set('${_categoriesCacheKey}_timestamp',
            DateTime.now().millisecondsSinceEpoch.toString());

        // Cleanup memory after successful fetch
        _cleanupMemory();
        notifyListeners();
      } else {
        throw Exception('Failed to fetch categories: ${response.statusCode}');
      }

      // Track performance (non-blocking)
      PerformanceUtils.trackDataLoad(
        'vocal_categories',
        () async {},
        itemCount: _categories.length,
        attributes: {
          'force_refresh': forceRefresh.toString(),
        },
      ).catchError((e) {
        debugPrint('⚠️ Performance tracking error: $e');
      });

    } catch (e) {
      debugPrint('Error fetching vocal categories: $e');
      _error = e.toString().contains('TimeoutException')
          ? 'Connection timeout. Please check your internet connection.'
          : 'Failed to load vocal categories';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch items for a specific category
  Future<void> fetchCategoryItems(String categoryId, {bool forceRefresh = false}) async {
    try {
      final cacheKey = '${_itemsCacheKey}_$categoryId';

      // Check cache first
      if (!forceRefresh) {
        final cachedData = await _cacheService.get(cacheKey);
        if (cachedData != null) {
          final List<dynamic> itemsJson = json.decode(cachedData) as List<dynamic>;
          final items = itemsJson
              .map((json) => VocalItem.fromJson(json as Map<String, dynamic>))
              .where((item) => item.isActive)
              .toList();
          
          // Merge with download status
          _categoryItems[categoryId] = _mergeWithDownloadStatus(items);
          notifyListeners();
        }
      }

      // Fetch from API
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vocal/items?categoryId=$categoryId&onlyActive=true'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> itemsJson = json.decode(response.body) as List<dynamic>;
        final items = itemsJson
            .map((json) => VocalItem.fromJson(json as Map<String, dynamic>))
            .toList();
        items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        // Merge with download status and cache
        _categoryItems[categoryId] = _mergeWithDownloadStatus(items);
        await _cacheService.set(cacheKey, response.body);
        
        notifyListeners();
      } else {
        throw Exception('Failed to fetch items: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching vocal items for category $categoryId: $e');
      _error = 'Failed to load vocal items';
      notifyListeners();
    }
  }

  /// Fetch category with its items
  Future<VocalCategory?> fetchCategoryWithItems(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vocal/categories/$categoryId/with-items'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final categoryJson = json.decode(response.body) as Map<String, dynamic>;
        final category = VocalCategory.fromJson(categoryJson);
        
        // Update local state
        final categoryIndex = _categories.indexWhere((c) => c.id == categoryId);
        if (categoryIndex != -1) {
          _categories[categoryIndex] = category;
        }
        
        if (category.items != null) {
          _categoryItems[categoryId] = _mergeWithDownloadStatus(category.items!);
        }
        
        notifyListeners();
        return category;
      } else {
        throw Exception('Failed to fetch category: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching category with items $categoryId: $e');
      return null;
    }
  }

  /// Download an audio file for offline use
  Future<bool> downloadItem(VocalItem item) async {
    try {
      // Update download status
      final updatedItem = item.copyWith(isDownloading: true, downloadProgress: 0.0);
      _updateItemInCategory(updatedItem);

      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final vocalsDir = Directory('${appDir.path}/vocals');
      if (!await vocalsDir.exists()) {
        await vocalsDir.create(recursive: true);
      }

      // Create local file path
      final fileName = '${item.id}.${_getFileExtension(item.audioFileUrl)}';
      final localPath = '${vocalsDir.path}/$fileName';

      // Download with progress tracking
      await _dio.download(
        item.audioFileUrl,
        localPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final updatedItem = item.copyWith(
              isDownloading: true,
              downloadProgress: progress,
            );
            _updateItemInCategory(updatedItem);
          }
        },
      );

      // Update download status
      final downloadedItem = item.copyWith(
        localPath: localPath,
        isDownloaded: true,
        isDownloading: false,
        downloadProgress: 1.0,
      );

      // Add to the dedicated download manager
      await _downloadManager.addDownloadedItem(downloadedItem);
      _updateItemInCategory(downloadedItem);

      // Track performance (non-blocking)
      PerformanceUtils.trackFileOperation(
        'download',
        'vocal_audio',
        () async => true,
        attributes: {
          'vocal_item_id': item.id,
          'vocal_item_name': item.name,
          'file_url': item.audioFileUrl,
        },
      ).catchError((e) {
        debugPrint('⚠️ Performance tracking error: $e');
        return true; // Return a value for the error handler
      });

      return true;
    } catch (e) {
      debugPrint('Error downloading vocal item ${item.id}: $e');

      // Reset download status on error
      final resetItem = item.copyWith(
        isDownloading: false,
        downloadProgress: 0.0,
      );
      _updateItemInCategory(resetItem);

      return false;
    }
  }

  /// Delete downloaded audio file
  Future<bool> deleteDownloadedItem(String itemId) async {
    try {
      // Use the download manager to remove the item
      final success = await _downloadManager.removeDownloadedItem(itemId);

      if (success) {
        // Update item status in categories
        for (final categoryId in _categoryItems.keys) {
          final items = _categoryItems[categoryId]!;
          final itemIndex = items.indexWhere((item) => item.id == itemId);
          if (itemIndex != -1) {
            _categoryItems[categoryId]![itemIndex] = items[itemIndex].copyWith(
              localPath: null,
              isDownloaded: false,
              downloadProgress: 0.0,
            );
          }
        }
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('Error deleting downloaded item $itemId: $e');
      return false;
    }
  }

  /// Get total downloaded size in bytes
  int getTotalDownloadedSize() {
    return _downloadManager.totalSizeBytes;
  }

  /// Get formatted total downloaded size
  String getFormattedDownloadedSize() {
    return _downloadManager.formattedTotalSize;
  }

  /// Get download statistics
  Map<String, dynamic> getDownloadStats() {
    return _downloadManager.getDownloadStats();
  }

  /// Check if an item is downloaded
  bool isItemDownloaded(String itemId) {
    return _downloadManager.isItemDownloaded(itemId);
  }

  /// Get downloaded item by ID
  VocalItem? getDownloadedItem(String itemId) {
    return _downloadManager.getDownloadedItem(itemId);
  }

  /// Get all downloaded items
  List<VocalItem> getAllDownloadedItems() {
    return _downloadManager.getAllDownloadedItems();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  List<VocalItem> _mergeWithDownloadStatus(List<VocalItem> items) {
    return items.map((item) {
      final downloadedItem = _downloadManager.getDownloadedItem(item.id);
      if (downloadedItem != null) {
        return item.copyWith(
          localPath: downloadedItem.localPath,
          isDownloaded: downloadedItem.isDownloaded,
          isDownloading: downloadedItem.isDownloading,
          downloadProgress: downloadedItem.downloadProgress,
        );
      }
      return item;
    }).toList();
  }

  void _updateItemInCategory(VocalItem updatedItem) {
    for (final categoryId in _categoryItems.keys) {
      final items = _categoryItems[categoryId]!;
      final itemIndex = items.indexWhere((item) => item.id == updatedItem.id);
      if (itemIndex != -1) {
        _categoryItems[categoryId]![itemIndex] = updatedItem;
        notifyListeners();
        break;
      }
    }
  }

  Future<void> _loadDownloadedItems() async {
    try {
      final data = await _cacheService.get(_downloadedItemsKey);
      if (data != null) {
        final Map<String, dynamic> itemsJson = json.decode(data);
        _downloadedItems.clear();
        _downloadedItems.addAll(itemsJson.map(
          (key, value) => MapEntry(key, VocalItem.fromJson(value)),
        ));
      }
    } catch (e) {
      debugPrint('Error loading downloaded items: $e');
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
}
