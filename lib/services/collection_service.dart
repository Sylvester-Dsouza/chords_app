import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/collection.dart';
import 'api_service.dart';
import 'cache_service.dart';

class CollectionService {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // Toggle like status for a collection
  Future<Map<String, dynamic>> toggleLike(String collectionId) async {
    try {
      // Check if user is logged in using Firebase directly
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return {
          'success': false,
          'message': 'You need to be logged in to like collections',
          'requiresLogin': true,
        };
      }

      // Get auth token directly from Firebase
      final token = await firebaseUser.getIdToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
          'requiresLogin': true,
        };
      }

      // Set auth header
      final options = _apiService.getAuthOptions(token);

      // Call API to toggle like
      final response = await _apiService.post(
        '/collections/$collectionId/like',
        options: options,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
        };
      }

      return {
        'success': false,
        'message': 'Failed to toggle like status',
      };
    } catch (e) {
      debugPrint('Error toggling like: $e');
      return {
        'success': false,
        'message': 'An error occurred while toggling like status',
      };
    }
  }

  // Get like status for a collection
  Future<Map<String, dynamic>> getLikeStatus(String collectionId) async {
    try {
      // Check if user is logged in using Firebase directly
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return {
          'success': false,
          'message': 'You need to be logged in to see like status',
          'requiresLogin': true,
        };
      }

      // Get auth token directly from Firebase
      final token = await firebaseUser.getIdToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
          'requiresLogin': true,
        };
      }

      // Set auth header
      final options = _apiService.getAuthOptions(token);

      // Call API to get like status
      final response = await _apiService.get(
        '/collections/$collectionId/like',
        options: options,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
        };
      }

      return {
        'success': false,
        'message': 'Failed to get like status',
      };
    } catch (e) {
      debugPrint('Error getting like status: $e');
      return {
        'success': false,
        'message': 'An error occurred while getting like status',
      };
    }
  }

  // Get all liked collections
  Future<List<Collection>> getLikedCollections() async {
    try {
      // Check if user is logged in using Firebase directly
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return [];
      }

      // Get auth token directly from Firebase
      final token = await firebaseUser.getIdToken();
      if (token == null) {
        return [];
      }

      // Set auth header
      final options = _apiService.getAuthOptions(token);

      // Call API to get liked collections
      final response = await _apiService.get(
        '/collections/liked',
        options: options,
      );

      if (response.statusCode == 200 && response.data is List) {
        // Parse the response data
        final List<dynamic> collectionsData = response.data;

        // Get the full collection details for each liked collection
        final List<Collection> likedCollections = [];
        for (final likeData in collectionsData) {
          if (likeData['collectionId'] != null) {
            try {
              // Get the full collection details
              final collectionResponse = await _apiService.get(
                '/collections/${likeData['collectionId']}',
              );

              if (collectionResponse.statusCode == 200) {
                final collection = Collection.fromJson(collectionResponse.data);
                likedCollections.add(collection);
              }
            } catch (e) {
              debugPrint('Error fetching collection details: $e');
            }
          }
        }

        return likedCollections;
      }

      return [];
    } catch (e) {
      debugPrint('Error getting liked collections: $e');
      return [];
    }
  }

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

      debugPrint('Collection API response: ${response.toString()}');
      debugPrint('Collection API response data type: ${response.data.runtimeType}');
      debugPrint('Collection API response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] as List<dynamic>;
          debugPrint('Received ${data.length} collections from API (nested data field)');
        } else if (response.data is List) {
          data = response.data as List<dynamic>;
          debugPrint('Received ${data.length} collections from API (direct list)');
        } else {
          debugPrint('Unexpected response format: ${response.data.runtimeType}');
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }
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

      debugPrint('Collection by ID API response: ${response.toString()}');
      debugPrint('Collection by ID API response data type: ${response.data.runtimeType}');
      debugPrint('Collection by ID API response data: ${response.data}');

      if (response.statusCode == 200) {
        dynamic data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'];
          debugPrint('Received collection data (nested data field)');
        } else {
          data = response.data;
          debugPrint('Received collection data (direct object)');
        }

        try {
          // Create the collection object
          final collection = Collection.fromJson(data);
          debugPrint('Successfully parsed collection: ${collection.title}');

          // Check if user is logged in to get like status
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            // Get the like status for this collection
            try {
              final likeStatusResult = await getLikeStatus(collection.id);
              if (likeStatusResult['success'] == true) {
                // Create a new collection with updated like status
                final updatedCollection = Collection(
                  id: collection.id,
                  title: collection.title,
                  description: collection.description,
                  songCount: collection.songCount,
                  likeCount: collection.likeCount,
                  isLiked: likeStatusResult['data']['isLiked'] ?? false,
                  color: collection.color,
                  imageUrl: collection.imageUrl,
                  songs: collection.songs,
                  isPublic: collection.isPublic,
                );
                return updatedCollection;
              }
            } catch (e) {
              debugPrint('Error getting like status: $e');
              // Continue with the original collection if there's an error
            }
          }

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

      debugPrint('Featured collections API response: ${response.toString()}');
      debugPrint('Featured collections API response data type: ${response.data.runtimeType}');
      debugPrint('Featured collections API response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] as List<dynamic>;
          debugPrint('Received ${data.length} featured collections from API (nested data field)');
        } else if (response.data is List) {
          data = response.data as List<dynamic>;
          debugPrint('Received ${data.length} featured collections from API (direct list)');
        } else {
          debugPrint('Unexpected response format: ${response.data.runtimeType}');
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }

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
  Future<List<Collection>> getSeasonalCollections({int limit = 10, bool forceRefresh = false}) async {
    try {
      // First check if we have cached seasonal collections and not forcing refresh
      if (!forceRefresh) {
        final cachedCollections = await _cacheService.getCachedSeasonalCollections();
        if (cachedCollections != null) {
          debugPrint('Using cached seasonal collections (${cachedCollections.length} collections)');
          // Apply limit if needed
          return cachedCollections.length > limit ? cachedCollections.sublist(0, limit) : cachedCollections;
        }
      }

      // If no cache, fetch from API
      debugPrint('No cached seasonal collections found, fetching from API...');
      final response = await _apiService.get('/collections', queryParameters: {
        'limit': limit.toString(),
        'seasonal': 'true'
      });

      debugPrint('Seasonal collections API response: ${response.toString()}');
      debugPrint('Seasonal collections API response data type: ${response.data.runtimeType}');
      debugPrint('Seasonal collections API response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] as List<dynamic>;
          debugPrint('Received ${data.length} seasonal collections from API (nested data field)');
        } else if (response.data is List) {
          data = response.data as List<dynamic>;
          debugPrint('Received ${data.length} seasonal collections from API (direct list)');
        } else {
          debugPrint('Unexpected response format: ${response.data.runtimeType}');
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }

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
  Future<List<Collection>> getBeginnerFriendlyCollections({int limit = 10, bool forceRefresh = false}) async {
    try {
      // First check if we have cached beginner collections and not forcing refresh
      if (!forceRefresh) {
        final cachedCollections = await _cacheService.getCachedBeginnerCollections();
        if (cachedCollections != null) {
          debugPrint('Using cached beginner collections (${cachedCollections.length} collections)');
          // Apply limit if needed
          return cachedCollections.length > limit ? cachedCollections.sublist(0, limit) : cachedCollections;
        }
      }

      // If no cache, fetch from API
      debugPrint('No cached beginner collections found, fetching from API...');
      final response = await _apiService.get('/collections', queryParameters: {
        'limit': limit.toString(),
        'beginner': 'true'
      });

      debugPrint('Beginner collections API response: ${response.toString()}');
      debugPrint('Beginner collections API response data type: ${response.data.runtimeType}');
      debugPrint('Beginner collections API response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] as List<dynamic>;
          debugPrint('Received ${data.length} beginner friendly collections from API (nested data field)');
        } else if (response.data is List) {
          data = response.data as List<dynamic>;
          debugPrint('Received ${data.length} beginner friendly collections from API (direct list)');
        } else {
          debugPrint('Unexpected response format: ${response.data.runtimeType}');
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }

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

      debugPrint('Collection by name API response: ${response.toString()}');
      debugPrint('Collection by name API response data type: ${response.data.runtimeType}');
      debugPrint('Collection by name API response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] as List<dynamic>;
          debugPrint('Received ${data.length} collections from name search (nested data field)');
        } else if (response.data is List) {
          data = response.data as List<dynamic>;
          debugPrint('Received ${data.length} collections from name search (direct list)');
        } else {
          debugPrint('Unexpected response format: ${response.data.runtimeType}');
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }

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

      debugPrint('Songs in collection API response: ${response.toString()}');
      debugPrint('Songs in collection API response data type: ${response.data.runtimeType}');
      debugPrint('Songs in collection API response data: ${response.data}');

      if (response.statusCode == 200) {
        dynamic data;

        // Check if the response data is a Map with a 'data' field (common API pattern)
        if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'];
          debugPrint('Received collection data (nested data field)');
        } else {
          data = response.data;
          debugPrint('Received collection data (direct object)');
        }

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
