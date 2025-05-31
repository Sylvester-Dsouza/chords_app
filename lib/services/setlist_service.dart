import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/setlist.dart';
import 'api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SetlistService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      // First check for access token
      final token = await _secureStorage.read(key: 'access_token');
      if (token != null) {
        debugPrint('Access token found, user is authenticated');
        return true;
      }

      // If no access token, check Firebase auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          // Get a fresh token
          final idToken = await firebaseUser.getIdToken(true);
          debugPrint('Firebase user is authenticated, got fresh token');

          // Store the token for future use
          await _secureStorage.write(key: 'firebase_token', value: idToken);

          return true;
        } catch (e) {
          debugPrint('Error getting Firebase token: $e');
          return false;
        }
      }

      debugPrint('No authentication found (no token, no Firebase user)');
      return false;
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  // Get all setlists for the current user (both owned and shared)
  Future<List<Setlist>> getSetlists() async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        debugPrint('User is not authenticated when fetching setlists');
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('🔍 Fetching both owned and shared setlists from API');

      // Fetch both owned setlists and shared setlists in parallel
      final results = await Future.wait([
        _getOwnedSetlists(),
        _getSharedSetlists(),
      ]);

      final ownedSetlists = results[0];
      final sharedSetlists = results[1];

      debugPrint('🔍 Received ${ownedSetlists.length} owned setlists and ${sharedSetlists.length} shared setlists');

      // Log details of each list
      debugPrint('🔍 Owned setlists:');
      for (var setlist in ownedSetlists) {
        debugPrint('🔍   - ${setlist.name} (${setlist.id}) - isSharedWithMe: ${setlist.isSharedWithMe}');
      }

      debugPrint('🔍 Shared setlists:');
      for (var setlist in sharedSetlists) {
        debugPrint('🔍   - ${setlist.name} (${setlist.id}) - isSharedWithMe: ${setlist.isSharedWithMe}');
      }

      // Combine both lists
      final allSetlists = <Setlist>[];
      allSetlists.addAll(ownedSetlists);
      allSetlists.addAll(sharedSetlists);

      // Sort by updated date (most recent first)
      allSetlists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      debugPrint('🔍 Total combined setlists: ${allSetlists.length}');
      debugPrint('🔍 Final combined list:');
      for (var setlist in allSetlists) {
        debugPrint('🔍   - ${setlist.name} (${setlist.id}) - isSharedWithMe: ${setlist.isSharedWithMe}');
      }

      return allSetlists;
    } catch (e) {
      debugPrint('Error fetching setlists: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to load setlists: $e');
    }
  }

  // Get owned setlists (private method)
  Future<List<Setlist>> _getOwnedSetlists() async {
    try {
      final response = await _apiService.get('/setlists');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Received ${data.length} owned setlists from API');

        if (data.isEmpty) {
          return [];
        }

        final setlists = data.map((json) => Setlist.fromJson(json)).toList();
        debugPrint('Parsed ${setlists.length} owned setlists');
        return setlists;
      } else {
        throw Exception('Failed to load owned setlists');
      }
    } catch (e) {
      debugPrint('Error fetching owned setlists: $e');
      rethrow;
    }
  }

  // Get shared setlists (private method)
  Future<List<Setlist>> _getSharedSetlists() async {
    try {
      debugPrint('🔍 Fetching shared setlists from /setlists/shared');
      final response = await _apiService.get('/setlists/shared');

      debugPrint('🔍 Shared setlists response status: ${response.statusCode}');
      debugPrint('🔍 Shared setlists response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('🔍 Received ${data.length} shared setlists from API');

        if (data.isEmpty) {
          debugPrint('🔍 No shared setlists found');
          return [];
        }

        final setlists = data.map((json) {
          debugPrint('🔍 Processing shared setlist: ${json['name']} (${json['id']})');
          // Mark shared setlists with a flag for UI distinction
          final setlistJson = Map<String, dynamic>.from(json);
          setlistJson['isSharedWithMe'] = true;
          return Setlist.fromJson(setlistJson);
        }).toList();

        debugPrint('🔍 Parsed ${setlists.length} shared setlists successfully');
        for (var setlist in setlists) {
          debugPrint('🔍 Shared setlist: ${setlist.name} (${setlist.id}) - isSharedWithMe: ${setlist.isSharedWithMe}');
        }
        return setlists;
      } else {
        debugPrint('🔍 Failed to load shared setlists: ${response.statusCode}');
        throw Exception('Failed to load shared setlists');
      }
    } catch (e) {
      debugPrint('🔍 Error fetching shared setlists: $e');
      if (e is DioException) {
        debugPrint('🔍 DioException status code: ${e.response?.statusCode}');
        debugPrint('🔍 DioException response data: ${e.response?.data}');
      }
      // Don't throw error for shared setlists - just return empty list
      // This ensures owned setlists still work if shared setlists fail
      debugPrint('🔍 Continuing without shared setlists');
      return [];
    }
  }

  // Create a new setlist
  Future<Setlist> createSetlist(String name, {String? description}) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      // The API service will automatically use the token from secure storage
      // or get a fresh Firebase token if needed
      debugPrint('Creating setlist: $name');

      // Make the API request
      final response = await _apiService.post('/setlists', data: {
        'name': name,
        'description': description,
      });

      if (response.statusCode == 201) {
        debugPrint('Setlist created successfully: ${response.data}');
        try {
          final setlist = Setlist.fromJson(response.data);
          debugPrint('Parsed setlist: ${setlist.id} - ${setlist.name}');
          return setlist;
        } catch (parseError) {
          debugPrint('Error parsing created setlist: $parseError');
          throw Exception('Failed to parse created setlist: $parseError');
        }
      } else {
        debugPrint('Failed to create setlist: ${response.statusCode}');
        throw Exception('Failed to create setlist: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating setlist: $e');
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');

        if (e.response?.statusCode == 401) {
          // Clear tokens on authentication error
          await _secureStorage.delete(key: 'access_token');
          await _secureStorage.delete(key: 'refresh_token');
          throw Exception('Authentication required. Please log in.');
        }
      }
      throw Exception('Failed to create setlist: $e');
    }
  }

  // Get a specific setlist by ID
  Future<Setlist> getSetlist(String id) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        debugPrint('User not authenticated when fetching setlist $id');
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Sending API request to get setlist $id');
      final response = await _apiService.get('/setlists/$id');

      if (response.statusCode == 200) {
        debugPrint('Setlist $id fetched successfully');
        debugPrint('Response data: ${response.data}');

        // Check if response data is valid
        if (response.data == null) {
          debugPrint('Response data is null');
          throw Exception('Invalid setlist data received');
        }

        // Log songs data if available
        if (response.data['songs'] != null) {
          debugPrint('Songs in response: ${response.data['songs'].length}');
          for (var song in response.data['songs']) {
            debugPrint('Song: ${song['title'] ?? 'Unknown'} by ${song['artist']?['name'] ?? 'Unknown Artist'}');
          }
        } else {
          debugPrint('No songs in response');
        }

        return Setlist.fromJson(response.data);
      } else {
        debugPrint('Failed to load setlist: ${response.statusCode}');
        throw Exception('Failed to load setlist: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting setlist: $e');
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');

        if (e.response?.statusCode == 401) {
          // Clear tokens on authentication error
          await _secureStorage.delete(key: 'access_token');
          await _secureStorage.delete(key: 'refresh_token');
          throw Exception('Authentication required. Please log in.');
        }
      }
      throw Exception('Failed to load setlist: $e');
    }
  }

  // Update a setlist
  Future<Setlist> updateSetlist(String id, String name, {String? description}) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Updating setlist with ID: $id, name: $name, description: $description');
      final response = await _apiService.patch('/setlists/$id', data: {
        'name': name,
        'description': description,
      });

      if (response.statusCode == 200) {
        return Setlist.fromJson(response.data);
      } else {
        throw Exception('Failed to update setlist');
      }
    } catch (e) {
      debugPrint('Error updating setlist: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to update setlist: $e');
    }
  }

  // Delete a setlist
  Future<void> deleteSetlist(String id) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      final response = await _apiService.delete('/setlists/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete setlist');
      }
    } catch (e) {
      debugPrint('Error deleting setlist: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to delete setlist: $e');
    }
  }

  // ==================== COLLABORATIVE FEATURES ====================

  // Share a setlist with another user
  Future<Map<String, dynamic>> shareSetlist(String setlistId, String email, String permission) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Sharing setlist $setlistId with $email, permission: $permission');

      final response = await _apiService.post('/setlists/$setlistId/share', data: {
        'email': email,
        'permission': permission,
      });

      if (response.statusCode == 201) {
        debugPrint('Setlist shared successfully');
        return response.data;
      } else {
        throw Exception('Failed to share setlist');
      }
    } catch (e) {
      debugPrint('Error sharing setlist: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw Exception('Authentication required. Please log in.');
        } else if (e.response?.statusCode == 404) {
          throw Exception('User with this email not found.');
        } else if (e.response?.statusCode == 409) {
          throw Exception('Setlist is already shared with this user.');
        }
      }
      throw Exception('Failed to share setlist: $e');
    }
  }

  // Accept a setlist invitation using share code
  Future<Setlist> acceptInvitation(String shareCode) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Accepting invitation with share code: $shareCode');

      final response = await _apiService.post('/setlists/join/$shareCode', data: {});

      if (response.statusCode == 200) {
        debugPrint('Invitation accepted successfully');
        return Setlist.fromJson(response.data);
      } else {
        throw Exception('Failed to accept invitation');
      }
    } catch (e) {
      debugPrint('Error accepting invitation: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw Exception('Authentication required. Please log in.');
        } else if (e.response?.statusCode == 404) {
          throw Exception('Invalid share code or no pending invitation.');
        }
      }
      throw Exception('Failed to accept invitation: $e');
    }
  }

  // Get all collaborators for a setlist
  Future<List<Map<String, dynamic>>> getCollaborators(String setlistId) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Getting collaborators for setlist $setlistId');

      final response = await _apiService.get('/setlists/$setlistId/collaborators');

      if (response.statusCode == 200) {
        debugPrint('Got ${response.data.length} collaborators');
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get collaborators');
      }
    } catch (e) {
      debugPrint('Error getting collaborators: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to get collaborators: $e');
    }
  }

  // Update collaborator permissions
  Future<Map<String, dynamic>> updateCollaborator(String setlistId, String collaboratorId, String permission) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Updating collaborator $collaboratorId permission to $permission');

      final response = await _apiService.patch('/setlists/$setlistId/collaborators/$collaboratorId', data: {
        'permission': permission,
      });

      if (response.statusCode == 200) {
        debugPrint('Collaborator updated successfully');
        return response.data;
      } else {
        throw Exception('Failed to update collaborator');
      }
    } catch (e) {
      debugPrint('Error updating collaborator: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to update collaborator: $e');
    }
  }

  // Remove a collaborator from a setlist
  Future<void> removeCollaborator(String setlistId, String collaboratorId) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Removing collaborator $collaboratorId from setlist $setlistId');

      final response = await _apiService.delete('/setlists/$setlistId/collaborators/$collaboratorId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove collaborator');
      }

      debugPrint('Collaborator removed successfully');
    } catch (e) {
      debugPrint('Error removing collaborator: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to remove collaborator: $e');
    }
  }

  // Get activity log for a setlist
  Future<List<Map<String, dynamic>>> getActivities(String setlistId, {int limit = 20}) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Getting activities for setlist $setlistId, limit: $limit');

      final response = await _apiService.get('/setlists/$setlistId/activities?limit=$limit');

      if (response.statusCode == 200) {
        debugPrint('Got ${response.data.length} activities');
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get activities');
      }
    } catch (e) {
      debugPrint('Error getting activities: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to get activities: $e');
    }
  }

  // Add a comment to a setlist
  Future<Map<String, dynamic>> addComment(String setlistId, String text, {String? parentId}) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Adding comment to setlist $setlistId: $text');

      final response = await _apiService.post('/setlists/$setlistId/comments', data: {
        'text': text,
        'parentId': parentId,
      });

      if (response.statusCode == 201) {
        debugPrint('Comment added successfully');
        return response.data;
      } else {
        throw Exception('Failed to add comment');
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to add comment: $e');
    }
  }

  // Get comments for a setlist
  Future<List<Map<String, dynamic>>> getComments(String setlistId) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Getting comments for setlist $setlistId');

      final response = await _apiService.get('/setlists/$setlistId/comments');

      if (response.statusCode == 200) {
        debugPrint('Got ${response.data.length} comments');
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get comments');
      }
    } catch (e) {
      debugPrint('Error getting comments: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to get comments: $e');
    }
  }

  // Sync setlist changes for real-time collaboration
  Future<Setlist> syncSetlist(String setlistId, Map<String, dynamic> changes, int currentVersion) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Syncing setlist $setlistId, version: $currentVersion');

      final response = await _apiService.post('/setlists/$setlistId/sync', data: {
        'changes': changes,
        'version': currentVersion,
      });

      if (response.statusCode == 200) {
        debugPrint('Setlist synced successfully');
        return Setlist.fromJson(response.data);
      } else {
        throw Exception('Failed to sync setlist');
      }
    } catch (e) {
      debugPrint('Error syncing setlist: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw Exception('Authentication required. Please log in.');
        } else if (e.response?.statusCode == 409) {
          throw Exception('Conflict - setlist has been modified by another user.');
        }
      }
      throw Exception('Failed to sync setlist: $e');
    }
  }

  // Update setlist collaboration settings
  Future<Setlist> updateSettings(String setlistId, Map<String, dynamic> settings) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Updating setlist $setlistId settings: $settings');

      final response = await _apiService.patch('/setlists/$setlistId/settings', data: settings);

      if (response.statusCode == 200) {
        debugPrint('Settings updated successfully');
        return Setlist.fromJson(response.data);
      } else {
        throw Exception('Failed to update settings');
      }
    } catch (e) {
      debugPrint('Error updating settings: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to update settings: $e');
    }
  }

  // Get all setlists shared with the current user
  Future<List<Setlist>> getSharedSetlists() async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Getting shared setlists');

      final response = await _apiService.get('/setlists/shared');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('Got ${data.length} shared setlists');

        if (data.isEmpty) {
          return [];
        }

        try {
          final setlists = data.map((json) => Setlist.fromJson(json)).toList();
          return setlists;
        } catch (parseError) {
          debugPrint('Error parsing shared setlists: $parseError');
          throw Exception('Failed to parse shared setlists: $parseError');
        }
      } else {
        throw Exception('Failed to get shared setlists');
      }
    } catch (e) {
      debugPrint('Error getting shared setlists: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to get shared setlists: $e');
    }
  }

  // Save setlist for offline use
  Future<void> saveSetlistOffline(Setlist setlist) async {
    try {
      debugPrint('Saving setlist ${setlist.id} for offline use');

      // Convert setlist to JSON
      final setlistJson = setlist.toJson();

      // Store in secure storage with timestamp
      await _secureStorage.write(
        key: 'offline_setlist_${setlist.id}',
        value: jsonEncode({
          'data': setlistJson,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      debugPrint('Setlist saved for offline use');
    } catch (e) {
      debugPrint('Error saving setlist offline: $e');
      throw Exception('Failed to save setlist offline: $e');
    }
  }

  // Get offline setlist
  Future<Setlist?> getOfflineSetlist(String id) async {
    try {
      debugPrint('Getting offline setlist $id');

      final data = await _secureStorage.read(key: 'offline_setlist_$id');

      if (data == null) {
        debugPrint('No offline data found for setlist $id');
        return null;
      }

      final json = jsonDecode(data);
      final setlistData = json['data'];

      debugPrint('Found offline data for setlist $id, saved at ${json['timestamp']}');

      return Setlist.fromJson(setlistData);
    } catch (e) {
      debugPrint('Error getting offline setlist: $e');
      return null;
    }
  }

  // Get all offline setlists
  Future<List<Setlist>> getAllOfflineSetlists() async {
    try {
      debugPrint('Getting all offline setlists');

      // Get all keys from secure storage
      final allKeys = await _secureStorage.readAll();

      // Filter keys for offline setlists
      final setlistKeys = allKeys.keys.where((key) => key.startsWith('offline_setlist_')).toList();

      if (setlistKeys.isEmpty) {
        debugPrint('No offline setlists found');
        return [];
      }

      // Get all setlists
      final List<Setlist> setlists = [];

      for (final key in setlistKeys) {
        try {
          final data = allKeys[key];
          if (data != null) {
            final json = jsonDecode(data);
            final setlistData = json['data'];
            final setlist = Setlist.fromJson(setlistData);
            setlists.add(setlist);
          }
        } catch (e) {
          debugPrint('Error parsing offline setlist for key $key: $e');
          // Continue with other setlists
        }
      }

      debugPrint('Found ${setlists.length} offline setlists');
      return setlists;
    } catch (e) {
      debugPrint('Error getting all offline setlists: $e');
      return [];
    }
  }

  // Delete a setlist from offline storage
  Future<void> deleteOfflineSetlist(String id) async {
    try {
      debugPrint('Deleting offline setlist $id');
      await _secureStorage.delete(key: 'offline_setlist_$id');
      debugPrint('Offline setlist deleted successfully');
    } catch (e) {
      debugPrint('Error deleting offline setlist: $e');
      throw Exception('Failed to delete offline setlist: $e');
    }
  }

  // Add a song to a setlist
  Future<void> addSongToSetlist(String setlistId, String songId) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      final response = await _apiService.post('/setlists/$setlistId/songs', data: {
        'songId': songId,
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add song to setlist');
      }
    } catch (e) {
      debugPrint('Error adding song to setlist: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to add song to setlist: $e');
    }
  }

  // Add multiple songs to a setlist in a single API call
  Future<void> addMultipleSongsToSetlist(String setlistId, List<String> songIds) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      if (songIds.isEmpty) {
        throw Exception('No songs provided to add to setlist');
      }

      debugPrint('Adding ${songIds.length} songs to setlist $setlistId');

      // Add timeout to prevent hanging
      final response = await _apiService.post('/setlists/$setlistId/songs/bulk', data: {
        'songIds': songIds,
      }).timeout(
        const Duration(seconds: 30), // 30 second timeout
        onTimeout: () {
          throw Exception('Request timed out. Please try again.');
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add songs to setlist');
      }

      debugPrint('Successfully added ${songIds.length} songs to setlist');
    } catch (e) {
      debugPrint('Error adding multiple songs to setlist: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to add songs to setlist: $e');
    }
  }

  // Remove a song from a setlist
  Future<void> removeSongFromSetlist(String setlistId, String songId) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      final response = await _apiService.delete('/setlists/$setlistId/songs/$songId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove song from setlist');
      }
    } catch (e) {
      debugPrint('Error removing song from setlist: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to remove song from setlist: $e');
    }
  }

  // Check if a song is in a setlist
  Future<bool> isSongInSetlist(String setlistId, String songId) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      // Get the setlist with songs
      final setlist = await getSetlist(setlistId);

      // Check if the song is in the setlist
      if (setlist.songs == null || setlist.songs!.isEmpty) {
        return false;
      }

      // Check each song in the setlist
      for (final song in setlist.songs!) {
        if (song is Map<String, dynamic> && song['id'] == songId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking if song is in setlist: $e');
      return false;
    }
  }

  // Get setlist by ID
  Future<Setlist> getSetlistById(String setlistId) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Getting setlist by ID: $setlistId');

      final response = await _apiService.get('/setlists/$setlistId');

      if (response.statusCode == 200) {
        debugPrint('Setlist retrieved successfully');
        return Setlist.fromJson(response.data);
      } else {
        throw Exception('Failed to get setlist');
      }
    } catch (e) {
      debugPrint('Error getting setlist: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to get setlist: $e');
    }
  }

  // Update setlist settings
  Future<Setlist> updateSetlistSettings(
    String setlistId, {
    bool? isPublic,
    bool? allowEditing,
    bool? allowComments,
  }) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Updating setlist settings for: $setlistId');

      final Map<String, dynamic> data = {};
      if (isPublic != null) data['isPublic'] = isPublic;
      if (allowEditing != null) data['allowEditing'] = allowEditing;
      if (allowComments != null) data['allowComments'] = allowComments;

      final response = await _apiService.patch('/setlists/$setlistId/settings', data: data);

      if (response.statusCode == 200) {
        debugPrint('Setlist settings updated successfully');
        try {
          debugPrint('Attempting to parse setlist response...');
          final setlist = Setlist.fromJson(response.data);
          debugPrint('Setlist parsed successfully');
          return setlist;
        } catch (parseError) {
          debugPrint('Error parsing setlist response: $parseError');
          debugPrint('Response data type: ${response.data.runtimeType}');
          debugPrint('Response data keys: ${response.data is Map ? (response.data as Map).keys.toList() : 'Not a Map'}');

          // Try to extract just the basic info we need for settings update
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            debugPrint('Attempting to create minimal setlist object...');

            // Create a minimal setlist object with just the essential fields
            final minimalSetlist = Setlist(
              id: data['id']?.toString() ?? '',
              name: data['name']?.toString() ?? '',
              description: data['description']?.toString(),
              customerId: data['customerId']?.toString() ?? '',
              createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
              updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : DateTime.now(),
              isPublic: data['isPublic'] ?? false,
              isShared: data['isShared'] ?? false,
              shareCode: data['shareCode']?.toString(),
              allowEditing: data['allowEditing'] ?? false,
              allowComments: data['allowComments'] ?? true,
              version: data['version'] ?? 1,
              songs: [], // Empty songs list for settings update
            );

            debugPrint('Minimal setlist created successfully');
            return minimalSetlist;
          }

          rethrow;
        }
      } else {
        throw Exception('Failed to update setlist settings');
      }
    } catch (e) {
      debugPrint('Error updating setlist settings: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please log in.');
      }
      throw Exception('Failed to update setlist settings: $e');
    }
  }

  // Get setlist by share code (public endpoint - no authentication required)
  Future<Setlist> getSetlistByShareCode(String shareCode) async {
    try {
      debugPrint('Getting setlist by share code: $shareCode');

      // Create a separate Dio instance for unauthenticated requests
      final Dio unauthenticatedDio = Dio();
      unauthenticatedDio.options.baseUrl = ApiService.baseUrl;
      unauthenticatedDio.options.connectTimeout = const Duration(seconds: 15);
      unauthenticatedDio.options.receiveTimeout = const Duration(seconds: 15);
      unauthenticatedDio.options.sendTimeout = const Duration(seconds: 15);

      // Add logging interceptor for debugging
      unauthenticatedDio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));

      // Make the request without authentication headers
      final String endpoint = '/api/setlists/share/$shareCode';
      debugPrint('Making unauthenticated request to: $endpoint');

      final response = await unauthenticatedDio.get(endpoint);

      if (response.statusCode == 200) {
        debugPrint('Setlist retrieved successfully by share code');
        return Setlist.fromJson(response.data);
      } else {
        throw Exception('Setlist not found or invalid share code');
      }
    } catch (e) {
      debugPrint('Error getting setlist by share code: $e');
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');

        if (e.response?.statusCode == 404) {
          throw Exception('Setlist not found. Please check the share code.');
        } else if (e.response?.statusCode == 403) {
          throw Exception('This setlist is not available for sharing.');
        }
      }
      throw Exception('Failed to get setlist: $e');
    }
  }

  // Join setlist by share code
  Future<void> joinSetlist(String shareCode) async {
    try {
      // Check if user is authenticated
      if (!await isAuthenticated()) {
        throw Exception('Authentication required. Please log in.');
      }

      debugPrint('Joining setlist with share code: $shareCode');

      final response = await _apiService.post('/setlists/join/$shareCode');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Successfully joined setlist');
      } else {
        throw Exception('Failed to join setlist');
      }
    } catch (e) {
      debugPrint('Error joining setlist: $e');
      if (e is DioException) {
        switch (e.response?.statusCode) {
          case 401:
            throw Exception('Authentication required. Please log in.');
          case 404:
            throw Exception('Setlist not found. Please check the share code.');
          case 409:
            throw Exception('You are already a member of this setlist.');
          default:
            throw Exception('Failed to join setlist: ${e.response?.data?['message'] ?? e.message}');
        }
      }
      throw Exception('Failed to join setlist: $e');
    }
  }
}
