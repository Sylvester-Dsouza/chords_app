import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to manage search history and suggestions
class SearchHistoryService extends ChangeNotifier {
  static const String _searchHistoryKey = 'search_history';
  static const String _searchSuggestionsKey = 'search_suggestions';
  static const int _maxHistoryItems = 20;
  static const int _maxSuggestions = 10;

  List<SearchHistoryItem> _searchHistory = [];
  List<String> _searchSuggestions = [];
  bool _isLoaded = false;

  List<SearchHistoryItem> get searchHistory => List.unmodifiable(_searchHistory);
  List<String> get searchSuggestions => List.unmodifiable(_searchSuggestions);
  bool get isLoaded => _isLoaded;

  /// Initialize the service and load data
  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      await _loadSearchHistory();
      await _loadSearchSuggestions();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing search history service: $e');
    }
  }

  /// Add a search query to history
  Future<void> addToHistory(String query, SearchType type) async {
    if (query.trim().isEmpty) return;

    try {
      final trimmedQuery = query.trim();

      // Remove existing entry if it exists
      _searchHistory.removeWhere((item) =>
        item.query.toLowerCase() == trimmedQuery.toLowerCase() &&
        item.type == type
      );

      // Add new entry at the beginning
      _searchHistory.insert(0, SearchHistoryItem(
        query: trimmedQuery,
        type: type,
        timestamp: DateTime.now(),
      ));

      // Keep only the most recent items
      if (_searchHistory.length > _maxHistoryItems) {
        _searchHistory = _searchHistory.take(_maxHistoryItems).toList();
      }

      await _saveSearchHistory();
      await _updateSuggestions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to search history: $e');
    }
  }

  /// Get search history filtered by type
  List<SearchHistoryItem> getHistoryByType(SearchType type) {
    return _searchHistory.where((item) => item.type == type).toList();
  }

  /// Get recent search queries (last 5)
  List<String> getRecentQueries({SearchType? type, int limit = 5}) {
    var history = type != null
      ? getHistoryByType(type)
      : _searchHistory;

    return history
      .take(limit)
      .map((item) => item.query)
      .toList();
  }

  /// Get search suggestions based on query
  List<String> getSuggestions(String query, {SearchType? type}) {
    if (query.trim().isEmpty) {
      return getRecentQueries(type: type);
    }

    final lowercaseQuery = query.toLowerCase();
    final suggestions = <String>[];

    // Add matching history items
    final historyMatches = (type != null ? getHistoryByType(type) : _searchHistory)
      .where((item) => item.query.toLowerCase().contains(lowercaseQuery))
      .map((item) => item.query)
      .take(5)
      .toList();

    suggestions.addAll(historyMatches);

    // Add matching predefined suggestions
    final suggestionMatches = _searchSuggestions
      .where((suggestion) => suggestion.toLowerCase().contains(lowercaseQuery))
      .take(5)
      .toList();

    suggestions.addAll(suggestionMatches);

    // Remove duplicates and limit results
    return suggestions.toSet().take(_maxSuggestions).toList();
  }

  /// Clear search history
  Future<void> clearHistory({SearchType? type}) async {
    try {
      if (type != null) {
        _searchHistory.removeWhere((item) => item.type == type);
      } else {
        _searchHistory.clear();
      }

      await _saveSearchHistory();
      await _updateSuggestions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  /// Remove specific item from history
  Future<void> removeFromHistory(SearchHistoryItem item) async {
    try {
      _searchHistory.remove(item);
      await _saveSearchHistory();
      await _updateSuggestions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from search history: $e');
    }
  }

  /// Load search history from storage
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey);

      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _searchHistory = historyList
          .map((item) => SearchHistoryItem.fromJson(item))
          .toList();
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
      _searchHistory = [];
    }
  }

  /// Save search history to storage
  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(
        _searchHistory.map((item) => item.toJson()).toList()
      );
      await prefs.setString(_searchHistoryKey, historyJson);
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  /// Load search suggestions from storage
  Future<void> _loadSearchSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final suggestionsJson = prefs.getString(_searchSuggestionsKey);

      if (suggestionsJson != null) {
        final List<dynamic> suggestionsList = json.decode(suggestionsJson);
        _searchSuggestions = suggestionsList.cast<String>();
      } else {
        // Initialize with default suggestions
        _searchSuggestions = _getDefaultSuggestions();
        await _saveSuggestions();
      }
    } catch (e) {
      debugPrint('Error loading search suggestions: $e');
      _searchSuggestions = _getDefaultSuggestions();
    }
  }

  /// Save suggestions to storage
  Future<void> _saveSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final suggestionsJson = json.encode(_searchSuggestions);
      await prefs.setString(_searchSuggestionsKey, suggestionsJson);
    } catch (e) {
      debugPrint('Error saving search suggestions: $e');
    }
  }

  /// Update suggestions based on search history
  Future<void> _updateSuggestions() async {
    try {
      // Get most frequent search terms
      final frequencyMap = <String, int>{};

      for (final item in _searchHistory) {
        final words = item.query.toLowerCase().split(' ');
        for (final word in words) {
          if (word.length > 2) { // Only consider words longer than 2 characters
            frequencyMap[word] = (frequencyMap[word] ?? 0) + 1;
          }
        }
      }

      // Sort by frequency and take top suggestions
      final sortedSuggestions = frequencyMap.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final newSuggestions = sortedSuggestions
        .take(5)
        .map((entry) => entry.key)
        .toList();

      // Combine with default suggestions
      _searchSuggestions = {
        ...newSuggestions,
        ..._getDefaultSuggestions(),
      }.take(_maxSuggestions).toList();

      await _saveSuggestions();
    } catch (e) {
      debugPrint('Error updating suggestions: $e');
    }
  }

  /// Get default search suggestions
  List<String> _getDefaultSuggestions() {
    return [
      'Amazing Grace',
      'How Great Thou Art',
      'Blessed Be Your Name',
      'Hillsong',
      'Chris Tomlin',
      'Bethel Music',
      'Elevation Worship',
      'Jesus',
      'Worship',
      'Praise',
    ];
  }
}

/// Represents a search history item
class SearchHistoryItem {
  final String query;
  final SearchType type;
  final DateTime timestamp;

  SearchHistoryItem({
    required this.query,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'],
      type: SearchType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => SearchType.songs,
      ),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchHistoryItem &&
      other.query == query &&
      other.type == type;
  }

  @override
  int get hashCode => query.hashCode ^ type.hashCode;
}

/// Search types for categorizing history
enum SearchType {
  songs,
  artists,
  collections,
}
