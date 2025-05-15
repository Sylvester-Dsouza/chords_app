import 'package:flutter/foundation.dart';
import 'package:chords_app/models/collection.dart';
import 'package:chords_app/models/song.dart';
import 'package:chords_app/models/artist.dart';
import 'package:chords_app/services/api_service.dart';
import 'package:chords_app/services/cache_service.dart';

enum SectionType {
  COLLECTIONS,
  SONGS,
  ARTISTS,
  BANNER
}

class HomeSection {
  final String id;
  final String title;
  final SectionType type;
  final List<dynamic> items;
  final bool isActive;

  HomeSection({
    required this.id,
    required this.title,
    required this.type,
    required this.items,
    this.isActive = true,
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
      default:
        type = SectionType.COLLECTIONS;
    }

    // Parse the items based on the section type
    List<dynamic> items = [];
    if (json['items'] != null) {
      if (type == SectionType.COLLECTIONS) {
        items = (json['items'] as List).map((item) => Collection.fromJson(item)).toList();
      } else if (type == SectionType.SONGS) {
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
    );
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

        // If not forcing refresh, check if cache is stale (older than 30 minutes)
        if (!forceRefresh) {
          final isCacheStale = await _cacheService.isCacheStale('cache_home_sections', 30);
          shouldRefreshInBackground = isCacheStale;
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
        _refreshHomeSectionsInBackground();
      }

      return sections;
    } catch (e) {
      debugPrint('Error getting home sections: $e');
      // Return empty list instead of throwing
      return [];
    }
  }

  // Refresh home sections in background without blocking UI
  Future<void> _refreshHomeSectionsInBackground() async {
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
        } else if (type == SectionType.SONGS) {
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
