import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feature_request.dart';
import 'api_service.dart';

class FeatureRequestService {
  final ApiService _apiService = ApiService();

  // Get current user ID from UserProvider
  Future<String?> _getCurrentUserId() async {
    try {
      // Get user data from shared preferences (stored by UserProvider)
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      if (userData != null) {
        final userJson = json.decode(userData);
        return userJson['id'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }

  // Get all feature requests
  Future<List<FeatureRequest>> getAllFeatureRequests() async {
    try {
      debugPrint('📋 Fetching all feature requests...');
      
      // Get current user ID for upvote status
      final currentUserId = await _getCurrentUserId();
      debugPrint('📋 Current user ID: $currentUserId');

      final response = await _apiService.get('/feature-requests');

      if (response.statusCode == 200) {
        final data = response.data as List;
        debugPrint('📋 Received ${data.length} feature requests from API');

        try {
          // Parse feature requests from API - use the hasUpvoted status directly from the backend
          final List<FeatureRequest> featureRequests = data.map((item) {
            final featureRequest = FeatureRequest.fromJson(item);
            debugPrint('Feature request ${featureRequest.id} - ${featureRequest.title} - hasUpvoted: ${featureRequest.hasUpvoted}');
            return featureRequest;
          }).toList();

          debugPrint('Successfully parsed ${featureRequests.length} feature requests');
          return featureRequests;
        } catch (parseError) {
          debugPrint('Error parsing feature request data: $parseError');
          throw Exception('Failed to parse feature request data: $parseError');
        }
      } else {
        debugPrint('Failed to load feature requests: ${response.statusCode}');
        throw Exception('Failed to load feature requests: Status ${response.statusCode}');
      }
    } on DioException catch (dioError) {
      debugPrint('DioException in getAllFeatureRequests: ${dioError.message}');
      debugPrint('DioException response: ${dioError.response?.data}');
      debugPrint('DioException status code: ${dioError.response?.statusCode}');
      
      if (dioError.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (dioError.response?.statusCode == 403) {
        throw Exception('Access denied. You do not have permission to view feature requests.');
      } else if (dioError.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Network error: ${dioError.message}');
      }
    } catch (e) {
      debugPrint('Error getting feature requests: $e');
      return [];
    }
  }

  // Create a new feature request
  Future<FeatureRequest?> createFeatureRequest({
    required String title,
    required String description,
    String? category,
  }) async {
    try {
      debugPrint('Creating new feature request: $title');

      final Map<String, dynamic> requestData = {
        'title': title,
        'description': description,
      };

      if (category != null && category.isNotEmpty) {
        requestData['category'] = category;
      }

      final response = await _apiService.post('/feature-requests', data: requestData);

      if (response.statusCode == 201) {
        debugPrint('Feature request created successfully');
        final createdRequest = FeatureRequest.fromJson(response.data);

        // Since the user created this request, they should have it "upvoted" by default
        // Return a modified version with hasUpvoted set to true
        return FeatureRequest(
          id: createdRequest.id,
          title: createdRequest.title,
          description: createdRequest.description,
          category: createdRequest.category,
          priority: createdRequest.priority,
          status: createdRequest.status,
          upvotes: createdRequest.upvotes,
          customerId: createdRequest.customerId,
          createdAt: createdRequest.createdAt,
          updatedAt: createdRequest.updatedAt,
          hasUpvoted: true, // Creator should have this as upvoted
        );
      } else {
        debugPrint('Failed to create feature request: ${response.statusCode}');
        throw Exception('Failed to create feature request: Status ${response.statusCode}');
      }
    } on DioException catch (dioError) {
      debugPrint('DioException in createFeatureRequest: ${dioError.message}');
      debugPrint('DioException response: ${dioError.response?.data}');
      
      if (dioError.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (dioError.response?.statusCode == 400) {
        throw Exception('Invalid request data. Please check your input.');
      } else {
        throw Exception('Failed to create feature request: ${dioError.message}');
      }
    } catch (e) {
      debugPrint('Error creating feature request: $e');
      return null;
    }
  }

  // Upvote a feature request
  Future<bool> upvoteFeatureRequest(String featureRequestId) async {
    try {
      debugPrint('Upvoting feature request: $featureRequestId');
      
      final response = await _apiService.post('/feature-requests/$featureRequestId/upvote', data: {});
      
      if (response.statusCode == 201) {
        debugPrint('Feature request upvoted successfully');
        return true;
      } else {
        debugPrint('Failed to upvote feature request: ${response.statusCode}');
        return false;
      }
    } on DioException catch (dioError) {
      debugPrint('DioException in upvoteFeatureRequest: ${dioError.message}');
      debugPrint('DioException response: ${dioError.response?.data}');
      
      if (dioError.response?.statusCode == 400) {
        // User has already upvoted
        debugPrint('User has already upvoted this feature request');
        return false;
      } else if (dioError.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error upvoting feature request: $e');
      return false;
    }
  }
  
  // Check if a user has already upvoted a feature request
  // This is used to handle the case where the upvote API returns a 400 error
  Future<bool> checkIfAlreadyUpvoted(String featureRequestId) async {
    try {
      // Try to get the feature request details to check if it's already upvoted
      final response = await _apiService.get('/feature-requests/$featureRequestId');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final featureRequest = FeatureRequest.fromJson(data);
        return featureRequest.hasUpvoted;
      } else {
        return false;
      }
    } on DioException catch (dioError) {
      if (dioError.response?.statusCode == 400 && 
          dioError.response?.data != null && 
          dioError.response!.data['message'] != null && 
          dioError.response!.data['message'].toString().contains('already upvoted')) {
        // If the error message contains 'already upvoted', then the user has already upvoted
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking if already upvoted: $e');
      return false;
    }
  }

  // Remove upvote from a feature request
  Future<bool> removeUpvote(String featureRequestId) async {
    try {
      debugPrint('Removing upvote from feature request: $featureRequestId');
      
      final response = await _apiService.delete('/feature-requests/$featureRequestId/upvote');
      
      if (response.statusCode == 200) {
        debugPrint('Upvote removed successfully');
        return true;
      } else {
        debugPrint('Failed to remove upvote: ${response.statusCode}');
        return false;
      }
    } on DioException catch (dioError) {
      debugPrint('DioException in removeUpvote: ${dioError.message}');
      debugPrint('DioException response: ${dioError.response?.data}');
      
      if (dioError.response?.statusCode == 404) {
        // Upvote not found
        debugPrint('Upvote not found for this feature request');
        return false;
      } else if (dioError.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error removing upvote: $e');
      return false;
    }
  }
}
