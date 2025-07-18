import 'package:flutter/foundation.dart';
import 'package:chords_app/models/collection.dart';
import 'package:chords_app/models/song.dart';
import 'package:chords_app/models/artist.dart';
import 'package:chords_app/services/api_service.dart';
import 'package:chords_app/services/cache_service.dart';
import 'package:chords_app/services/session_manager.dart';


// ignore_for_file: constant_identifier_names
enum SectionType {
  COLLECTIONS,
  SONGS,
  ARTISTS,
  BANNER,
  SONG_LIST
}

class HomeSection {
  final String id;
  final String title;
  final SectionType type;
  final List<dynamic> items;
  final bool isActive;
  final int? itemCount; // Number of items to display (from admin panel)

  HomeSection({
    required this.id,
    required this.title,
    required this.type,
    required this.items,
    this.isActive = true,
    this.itemCount,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    // Parse the section type
    SectionType type;
    switch (json['type']) {
      case 'COLLECTIONS':
        type = SectionType.COLLECTIONS;
        break;
      case 'SONGS':
        type = SectionType.SONGS;
        break;
      case 'ARTISTS':
        type = SectionType.ARTISTS;
        break;
      case 'BANNER':
        type = SectionType.BANNER;
        break;
      case 'SONG_LIST':
        type = SectionType.SONG_LIST;
        break;
      default:
        type = SectionType.COLLECTIONS;
    }

    // Parse the items based on the section type
    List<dynamic> items = [];
    if (json['items'] != null) {
      if (type == SectionType.COLLECTIONS) {
        items = (json['items'] as List).map((item) => Collection.fromJson(item)).toList();
      } else if (type == SectionType.SONGS || type == SectionType.SONG_LIST) {
        // Both SONGS and SONG_LIST contain Song objects, just displayed differently
        items = (json['items'] as List).map((item) => Song.fromJson(item)).toList();
      } else if (type == SectionType.ARTISTS) {
        items = (json['items'] as List).map((item) => Artist.fromJson(item)).toList();
      } else if (type == SectionType.BANNER) {
        // For banner items, we'll just keep the raw JSON for now
        items = json['items'] as List;
      }
    }

    return HomeSection(
      id: json['id'],
      title: json['title'],
      type: type,
      items: items,
      isActive: json['isActive'] ?? true,
      itemCount: json['itemCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString().split('.').last,
      'items': items.map((item) {
        if (item is Collection) {
          return item.toJson();
        } else if (item is Song) {
          return item.toJson();
        } else if (item is Artist) {
          return item.toJson();
        } else {
          return item; // For banner items or other raw data
        }
      }).toList(),
      'isActive': isActive,
      'itemCount': itemCount,
    };
  }
}

class HomeSectionService {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // Get all home sections for the app with improved caching
  Future<List<HomeSection>> getHomeSections({bool forceRefresh = false}) async {
    try {
      List<HomeSection> sections = [];
      bool shouldRefreshInBackground = false;

      // First check if we have cached home sections
      final cachedSectionsJson = await _cacheService.getCachedHomeSections();
      if (cachedSectionsJson != null) {
        // Convert cached JSON to HomeSection objects
        sections = cachedSectionsJson.map((json) => HomeSection.fromJson(json)).toList();
        debugPrint('Using cached home sections (${sections.length} sections)');

        // Use session-based refresh logic instead of time-based
        if (!forceRefresh) {
          final sessionManager = SessionManager();
          shouldRefreshInBackground = sessionManager.shouldRefreshData();
          debugPrint('Session-based refresh decision: $shouldRefreshInBackground');
        } else {
          shouldRefreshInBackground = true;
        }
      } else {
        // No cache available, need to fetch from API immediately
        shouldRefreshInBackground = false;
        forceRefresh = true;
      }

      // If we need to refresh (either forced or cache is stale)
      if (forceRefresh) {
        try {
          debugPrint('Fetching home sections from API...');
          final response = await _apiService.get('/home-sections/app/content');

          if (response.statusCode == 200) {
            final List<dynamic> sectionsJson = response.data;
            sections = sectionsJson.map((json) => HomeSection.fromJson(json)).toList();

            // Cache the sections for future use
            await _cacheService.cacheHomeSections(sections);

            debugPrint('Fetched ${sections.length} home sections from API');
          } else {
            debugPrint('Failed to load home sections: ${response.statusCode}');
            // If we have cached sections, use them instead of throwing
            if (sections.isEmpty) {
              throw Exception('Failed to load home sections: Status ${response.statusCode}');
            }
          }
        } catch (apiError) {
          debugPrint('Error fetching home sections from API: $apiError');
          // If we have cached sections, continue using them
          if (sections.isEmpty) {
            rethrow; // Re-throw if we don't have cached sections
          }
        }
      } else if (shouldRefreshInBackground && sections.isNotEmpty) {
        // If we have cached sections but they're stale, refresh in background
        debugPrint('Refreshing home sections in background...');
        refreshHomeSectionsInBackground();
      }

      return sections;
    } catch (e) {
      debugPrint('Error getting home sections: $e');
      // Return empty list instead of throwing
      return [];
    }
  }

  // Public method to refresh home sections in background without blocking UI
  Future<void> refreshHomeSectionsInBackground() async {
    try {
      final response = await _apiService.get('/home-sections/app/content');

      if (response.statusCode == 200) {
        final List<dynamic> sectionsJson = response.data;
        final List<HomeSection> sections = sectionsJson.map((json) => HomeSection.fromJson(json)).toList();

        // Cache the sections for future use
        await _cacheService.cacheHomeSections(sections);

        debugPrint('Background refresh: Updated ${sections.length} home sections in cache');
      } else {
        debugPrint('Background refresh: Failed to load home sections: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Background refresh: Error refreshing home sections: $e');
    }
  }

  // Get cached home sections without forcing a refresh
  Future<List<HomeSection>?> getCachedHomeSections({bool checkOnly = false}) async {
    try {
      // Get cached sections from cache service
      final cachedSectionsJson = await _cacheService.getCachedHomeSections();
      if (cachedSectionsJson != null) {
        // Convert cached JSON to HomeSection objects
        final sections = cachedSectionsJson.map((json) => HomeSection.fromJson(json)).toList();
        debugPrint('Retrieved ${sections.length} home sections from cache');
        return sections;
      }

      // If checkOnly is true, don't try to fetch from API
      if (checkOnly) {
        return null;
      }

      // If no cache available and not checkOnly, try to fetch from API
      return await getHomeSections(forceRefresh: true);
    } catch (e) {
      debugPrint('Error getting cached home sections: $e');
      return null;
    }
  }

  // Get all items for a specific section by ID
  Future<List<dynamic>> getSectionItems(String sectionId, SectionType type) async {
    try {
      debugPrint('Fetching items for section $sectionId');
      final response = await _apiService.get('/home-sections/app/section/$sectionId/items');

      if (response.statusCode == 200) {
        final List<dynamic> itemsJson = response.data;
        List<dynamic> items = [];

        // Parse the items based on the section type
        if (type == SectionType.COLLECTIONS) {
          items = itemsJson.map((item) => Collection.fromJson(item)).toList();
        } else if (type == SectionType.SONGS || type == SectionType.SONG_LIST) {
          // Both SONGS and SONG_LIST contain Song objects, just displayed differently
          items = itemsJson.map((item) => Song.fromJson(item)).toList();
        } else if (type == SectionType.ARTISTS) {
          items = itemsJson.map((item) => Artist.fromJson(item)).toList();
        } else if (type == SectionType.BANNER) {
          // For banner items, we'll just keep the raw JSON for now
          items = itemsJson;
        }

        debugPrint('Fetched ${items.length} items for section $sectionId');
        return items;
      } else {
        debugPrint('Failed to load section items: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting section items: $e');
      return [];
    }
  }
}
