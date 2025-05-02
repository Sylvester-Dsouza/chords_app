import 'package:flutter/material.dart';
import '../models/collection.dart';
import 'api_service.dart';
import 'cache_service.dart';

class CollectionService {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // Get all collections with optional limit
  Future<List<Collection>> getAllCollections({int? limit}) async {
    try {
      debugPrint('Fetching all collections from API...');
      // Add limit parameter if provided
      final Map<String, dynamic> queryParams = {};
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final response = await _apiService.get('/collections', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} collections from API');
        debugPrint('Raw collection data: $data');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No collections found in API response');
          return [];
        }

        try {
          final collections = data.map((json) => Collection.fromJson(json)).toList();
          debugPrint('Successfully parsed ${collections.length} collections');
          return collections;
        } catch (parseError) {
          debugPrint('Error parsing collection data: $parseError');
          throw Exception('Failed to parse collection data: $parseError');
        }
      } else {
        debugPrint('Failed to load collections: ${response.statusCode}');
        throw Exception('Failed to load collections: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting collections: $e');
      throw Exception('Failed to load collections: $e');
    }
  }

  // Search collections by query with optional limit
  Future<List<Collection>> searchCollections(String query, {int? limit}) async {
    if (query.isEmpty) {
      return getAllCollections(limit: limit);
    }

    try {
      debugPrint('Searching collections with query: $query');
      // Use the correct endpoint and parameter based on the API
      // Add limit parameter if provided
      final Map<String, dynamic> queryParams = {'search': query};
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final response = await _apiService.get('/collections', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} collections from search');
        debugPrint('Raw search data: $data');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No collections found in search response');
          return [];
        }

        try {
          final collections = data.map((json) => Collection.fromJson(json)).toList();
          debugPrint('Successfully parsed ${collections.length} collections from search');
          return collections;
        } catch (parseError) {
          debugPrint('Error parsing search data: $parseError');
          throw Exception('Failed to parse search data: $parseError');
        }
      } else {
        debugPrint('Failed to search collections: ${response.statusCode}');
        throw Exception('Failed to search collections: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching collections: $e');
      throw Exception('Failed to search collections: $e');
    }
  }

  // Get collection by ID
  Future<Collection> getCollectionById(String id) async {
    try {
      debugPrint('Fetching collection with ID: $id');
      final response = await _apiService.get('/collections/$id');

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        debugPrint('Received collection data: $data');

        try {
          final collection = Collection.fromJson(data);
          debugPrint('Successfully parsed collection: ${collection.title}');
          return collection;
        } catch (parseError) {
          debugPrint('Error parsing collection data: $parseError');
          throw Exception('Failed to parse collection data: $parseError');
        }
      } else {
        debugPrint('Failed to load collection: ${response.statusCode}');
        throw Exception('Failed to load collection: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting collection: $e');
      throw Exception('Failed to load collection: $e');
    }
  }

  // Get featured collections (limit to specified number)
  Future<List<Collection>> getFeaturedCollections({int limit = 10}) async {
    try {
      debugPrint('Fetching featured collections from API...');
      final response = await _apiService.get('/collections', queryParameters: {
        'limit': limit.toString(),
        'featured': 'true'
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} featured collections from API');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No featured collections found in API response');
          return [];
        }

        try {
          final collections = data.map((json) => Collection.fromJson(json)).toList();
          debugPrint('Successfully parsed ${collections.length} featured collections');
          return collections;
        } catch (parseError) {
          debugPrint('Error parsing featured collection data: $parseError');
          throw Exception('Failed to parse featured collection data: $parseError');
        }
      } else {
        debugPrint('Failed to load featured collections: ${response.statusCode}');
        throw Exception('Failed to load featured collections: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting featured collections: $e');
      // For demo purposes, return empty list instead of throwing
      return [];
    }
  }

  // Get seasonal collections (limit to specified number)
  Future<List<Collection>> getSeasonalCollections({int limit = 10}) async {
    try {
      // First check if we have cached seasonal collections
      final cachedCollections = await _cacheService.getCachedSeasonalCollections();
      if (cachedCollections != null) {
        debugPrint('Using cached seasonal collections (${cachedCollections.length} collections)');
        // Apply limit if needed
        return cachedCollections.length > limit ? cachedCollections.sublist(0, limit) : cachedCollections;
      }

      // If no cache, fetch from API
      debugPrint('No cached seasonal collections found, fetching from API...');
      final response = await _apiService.get('/collections', queryParameters: {
        'limit': limit.toString(),
        'seasonal': 'true'
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} seasonal collections from API');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No seasonal collections found in API response');
          return [];
        }

        try {
          final collections = data.map((json) => Collection.fromJson(json)).toList();
          debugPrint('Successfully parsed ${collections.length} seasonal collections');

          // Cache the collections for future use
          await _cacheService.cacheSeasonalCollections(collections);

          return collections;
        } catch (parseError) {
          debugPrint('Error parsing seasonal collection data: $parseError');
          throw Exception('Failed to parse seasonal collection data: $parseError');
        }
      } else {
        debugPrint('Failed to load seasonal collections: ${response.statusCode}');
        throw Exception('Failed to load seasonal collections: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting seasonal collections: $e');
      // For demo purposes, return empty list instead of throwing
      return [];
    }
  }

  // Get beginner friendly collections (limit to specified number)
  Future<List<Collection>> getBeginnerFriendlyCollections({int limit = 10}) async {
    try {
      // First check if we have cached beginner collections
      final cachedCollections = await _cacheService.getCachedBeginnerCollections();
      if (cachedCollections != null) {
        debugPrint('Using cached beginner collections (${cachedCollections.length} collections)');
        // Apply limit if needed
        return cachedCollections.length > limit ? cachedCollections.sublist(0, limit) : cachedCollections;
      }

      // If no cache, fetch from API
      debugPrint('No cached beginner collections found, fetching from API...');
      final response = await _apiService.get('/collections', queryParameters: {
        'limit': limit.toString(),
        'beginner': 'true'
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} beginner friendly collections from API');

        // Check if data is empty
        if (data.isEmpty) {
          debugPrint('No beginner friendly collections found in API response');
          return [];
        }

        try {
          final collections = data.map((json) => Collection.fromJson(json)).toList();
          debugPrint('Successfully parsed ${collections.length} beginner friendly collections');

          // Cache the collections for future use
          await _cacheService.cacheBeginnerCollections(collections);

          return collections;
        } catch (parseError) {
          debugPrint('Error parsing beginner friendly collection data: $parseError');
          throw Exception('Failed to parse beginner friendly collection data: $parseError');
        }
      } else {
        debugPrint('Failed to load beginner friendly collections: ${response.statusCode}');
        throw Exception('Failed to load beginner friendly collections: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting beginner friendly collections: $e');
      // For demo purposes, return empty list instead of throwing
      return [];
    }
  }

  // Get collection by name
  Future<Collection?> getCollectionByName(String name) async {
    try {
      debugPrint('Searching for collection with name: $name');
      final response = await _apiService.get('/collections', queryParameters: {'search': name});

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} collections from name search');

        // Find the exact match by name
        final exactMatch = data.firstWhere(
          (collection) => collection['name'].toString().toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );

        if (exactMatch == null) {
          debugPrint('No exact match found for collection name: $name');
          return null;
        }

        try {
          final collection = Collection.fromJson(exactMatch);
          debugPrint('Successfully found collection: ${collection.title}');
          return collection;
        } catch (parseError) {
          debugPrint('Error parsing collection data: $parseError');
          throw Exception('Failed to parse collection data: $parseError');
        }
      } else {
        debugPrint('Failed to search collection by name: ${response.statusCode}');
        throw Exception('Failed to search collection by name: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching collection by name: $e');
      throw Exception('Failed to search collection by name: $e');
    }
  }

  // Get songs in a collection
  Future<List<dynamic>> getSongsInCollection(String collectionId) async {
    try {
      debugPrint('Fetching songs in collection with ID: $collectionId');
      final response = await _apiService.get('/collections/$collectionId');

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        final List<dynamic> songs = data['songs'] ?? [];
        debugPrint('Received ${songs.length} songs in collection');
        return songs;
      } else {
        debugPrint('Failed to load songs in collection: ${response.statusCode}');
        throw Exception('Failed to load songs in collection: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting songs in collection: $e');
      throw Exception('Failed to load songs in collection: $e');
    }
  }
}
