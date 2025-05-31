import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class CustomerService {
  // Singleton pattern
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Check if the customer has an active subscription
  Future<bool> hasActiveSubscription() async {
    try {
      // Check if user is authenticated
      if (!await _isAuthenticated()) {
        debugPrint('User is not authenticated when checking subscription');
        return false;
      }

      // Get the customer ID
      final customerId = await _getCustomerId();
      if (customerId == null) {
        debugPrint('No customer ID found when checking subscription');
        return false;
      }

      // Make the API request to check for active subscription
      final response = await _apiService.get('/subscriptions/customer/$customerId/active');

      // If we get a 200 response, the customer has an active subscription
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error checking active subscription: $e');
      return false;
    }
  }

  // Get subscription details
  Future<Map<String, dynamic>?> getActiveSubscription() async {
    try {
      // Check if user is authenticated
      if (!await _isAuthenticated()) {
        debugPrint('User is not authenticated when getting subscription details');
        return null;
      }

      // Get the customer ID
      final customerId = await _getCustomerId();
      if (customerId == null) {
        debugPrint('No customer ID found when getting subscription details');
        return null;
      }

      // Make the API request to get active subscription
      final response = await _apiService.get('/subscriptions/customer/$customerId/active');

      // If we get a 200 response, return the subscription details
      if (response.statusCode == 200) {
        return response.data;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting subscription details: $e');
      return null;
    }
  }



  // Get subscription plans
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      // Make the API request to get subscription plans
      final response = await _apiService.get('/subscription-plans');

      // If we get a 200 response, return the subscription plans
      if (response.statusCode == 200) {
        final List<dynamic> plans = response.data;

        // Filter to only include active plans
        final activePlans = plans
            .where((plan) => plan['isActive'] == true)
            .toList()
            .cast<Map<String, dynamic>>();

        // Sort plans by price (lowest to highest)
        activePlans.sort((a, b) {
          final priceA = a['price'] is num ? (a['price'] as num).toDouble() : 0.0;
          final priceB = b['price'] is num ? (b['price'] as num).toDouble() : 0.0;
          return priceA.compareTo(priceB);
        });

        debugPrint('Fetched ${activePlans.length} active subscription plans');
        return activePlans;
      }

      debugPrint('Failed to fetch subscription plans: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error getting subscription plans: $e');
      return [];
    }
  }

  // Subscribe to a plan
  Future<bool> subscribeToPlan(String planId) async {
    try {
      // Check if user is authenticated
      if (!await _isAuthenticated()) {
        debugPrint('User is not authenticated when subscribing to plan');
        return false;
      }

      // Get the customer ID
      final customerId = await _getCustomerId();
      if (customerId == null) {
        debugPrint('No customer ID found when subscribing to plan');
        return false;
      }

      // Calculate start and renewal dates
      final now = DateTime.now();
      final startDate = now.toIso8601String();

      // Default to monthly renewal (30 days)
      final renewalDate = now.add(const Duration(days: 30)).toIso8601String();

      // Make the API request to create a subscription
      final response = await _apiService.post('/subscriptions', data: {
        'customerId': customerId,
        'planId': planId,
        'startDate': startDate,
        'renewalDate': renewalDate,
        'status': 'ACTIVE',
        'isAutoRenew': true,
      });

      // If we get a 201 response, subscription was successfully created
      if (response.statusCode == 201) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error subscribing to plan: $e');
      return false;
    }
  }

  // Helper method to check if user is authenticated
  Future<bool> _isAuthenticated() async {
    try {
      // First check for access token
      final token = await _secureStorage.read(key: 'access_token');
      if (token != null) {
        return true;
      }

      // If no access token, check Firebase auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          // Get a fresh token
          final idToken = await firebaseUser.getIdToken(true);

          // Store the token for future use
          await _secureStorage.write(key: 'firebase_token', value: idToken);

          return true;
        } catch (e) {
          debugPrint('Error getting Firebase token: $e');
          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  // Helper method to get the customer ID
  Future<String?> _getCustomerId() async {
    try {
      // Try to get the customer ID from secure storage
      final userData = await _secureStorage.read(key: 'user_data');
      if (userData != null) {
        final Map<String, dynamic> user = Map<String, dynamic>.from(
          await jsonDecode(userData) as Map,
        );
        return user['id'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting customer ID: $e');
      return null;
    }
  }
}
