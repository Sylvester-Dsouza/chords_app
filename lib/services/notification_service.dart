import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import '../services/api_service.dart';


// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to ensure Firebase is initialized
  await Firebase.initializeApp();
  debugPrint('🔔 Handling a background message: ${message.messageId}');
  debugPrint('📱 Message data: ${message.data}');
  debugPrint('📢 Message notification: ${message.notification}');

  // Initialize local notifications for background handling
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize if not already done
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await localNotifications.initialize(initializationSettings);

  // Show notification manually for background/killed app state
  if (message.notification != null || message.data.isNotEmpty) {
    final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
    final body = message.notification?.body ?? message.data['body'] ?? 'You have a new notification';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications from Stuthi app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF9500),
      ledOnMs: 1000,
      ledOffMs: 500,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await localNotifications.show(
      message.hashCode,
      title as String?,
      body as String?,
      platformChannelSpecifics,
      payload: message.data['notificationId'] as String? ?? message.messageId,
    );

    debugPrint('✅ Background notification displayed: $title');
  }
}



class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Stream controller for notification clicks
  final ValueNotifier<RemoteMessage?> onNotificationClick = ValueNotifier(null);

  // Factory constructor
  factory NotificationService() {
    return _instance;
  }

  // Private constructor
  NotificationService._internal();

  // Initialize the notification service (basic setup only)
  Future<void> initialize() async {
    debugPrint('🚀 Initializing NotificationService (basic setup)...');

    // Only initialize local notifications without permissions
    debugPrint('📱 Initializing local notifications...');
    await _initializeLocalNotifications();

    // Configure FCM listeners (but don't request permissions yet)
    debugPrint('🔧 Configuring FCM listeners...');
    await _configureFCM();

    // Handle notification click when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('📬 Initial message found: ${message.messageId}');
        onNotificationClick.value = message;
      }
    });

    debugPrint('✅ NotificationService basic initialization complete!');
    debugPrint('⏳ Permissions and token registration will happen after login');
  }

  // Complete notification setup after user login
  Future<void> completeSetupAfterLogin() async {
    debugPrint('🔐 Completing notification setup after login...');

    try {
      // Request local notification permissions first
      debugPrint('📱 Requesting local notification permissions...');
      await _requestLocalNotificationPermissions();

      // Request FCM permissions
      debugPrint('🔐 Requesting FCM notification permissions...');
      await _requestPermission();

      // Generate and register FCM token
      debugPrint('🎯 Generating and registering FCM token...');
      await registerDeviceToken();

      debugPrint('✅ Notification setup completed after login!');
    } catch (e) {
      debugPrint('❌ Error completing notification setup after login: $e');
    }
  }

  // Initialize local notifications (without requesting permissions)
  Future<void> _initializeLocalNotifications() async {
    try {
      debugPrint('📱 Starting local notifications initialization (no permissions)...');

      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization - DON'T request permissions during initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,  // Don't request during initialization
        requestBadgePermission: false,  // Don't request during initialization
        requestSoundPermission: false,  // Don't request during initialization
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      debugPrint('📱 Initializing flutter_local_notifications (no permissions)...');
      final result = await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Local notification clicked: ${response.payload}');
          // Handle notification click
          if (response.payload != null) {
            // You can parse the payload and navigate accordingly
          }
        },
      );

      debugPrint('📱 Local notifications initialized: $result');
      debugPrint('✅ Local notifications initialization complete (permissions will be requested after login)');
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow; // Re-throw to stop initialization
    }
  }

  // Initialize local notifications with permissions (call after login)
  Future<void> _requestLocalNotificationPermissions() async {
    try {
      debugPrint('📱 Requesting local notification permissions...');

      // Request permissions for Android 13+
      if (Platform.isAndroid) {
        debugPrint('📱 Requesting Android notification permissions...');
        final androidImpl = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImpl != null) {
          final permissionResult = await androidImpl.requestNotificationsPermission();
          debugPrint('📱 Android notification permission result: $permissionResult');
        } else {
          debugPrint('⚠️ Could not get Android notification implementation');
        }
      }

      // For iOS, we'll handle permissions through FCM
      debugPrint('✅ Local notification permissions requested');
    } catch (e) {
      debugPrint('❌ Error requesting local notification permissions: $e');
    }
  }

  // Request permission for iOS
  Future<void> _requestPermission() async {
    try {
      debugPrint('🔐 Requesting FCM permissions...');
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔐 User granted permission: ${settings.authorizationStatus}');
      debugPrint('🔐 Alert setting: ${settings.alert}');
      debugPrint('🔐 Badge setting: ${settings.badge}');
      debugPrint('🔐 Sound setting: ${settings.sound}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⚠️ User denied notification permissions');
      } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        debugPrint('⚠️ User has not yet granted notification permissions');
      } else {
        debugPrint('✅ Notification permissions granted');
      }
    } catch (e) {
      debugPrint('❌ Error requesting FCM permissions: $e');
      rethrow;
    }
  }

  // Configure FCM
  Future<void> _configureFCM() async {
    try {
      debugPrint('🔧 Starting FCM configuration...');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 Got a message whilst in the foreground!');
        debugPrint('📱 Message data: ${message.data}');
        debugPrint('📢 Message notification: ${message.notification}');
        debugPrint('🔍 Message from: ${message.from}');
        debugPrint('🔍 Message ID: ${message.messageId}');
        debugPrint('🔍 Message category: ${message.category}');
        debugPrint('🔍 Message senderId: ${message.senderId}');
        debugPrint('🔍 Message contentAvailable: ${message.contentAvailable}');

        // Always show notification regardless of type
        _showLocalNotification(message);
      });

      // Handle background messages
      debugPrint('🔧 Setting up background message handler...');
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification click when app is in background
      debugPrint('🔧 Setting up message opened app handler...');
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        onNotificationClick.value = message;
      });

      debugPrint('✅ FCM configuration complete');
    } catch (e) {
      debugPrint('❌ Error configuring FCM: $e');
      rethrow;
    }
  }

  // Show local notification (system notification)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      RemoteNotification? notification = message.notification;

      debugPrint('🔔 _showLocalNotification called');
      debugPrint('📱 Message: ${message.toMap()}');
      debugPrint('📢 Notification: $notification');

      // Extract title and body from either notification or data
      String title;
      String body;

      if (notification != null) {
        // Standard notification message
        title = notification.title ?? 'New Notification';
        body = notification.body ?? 'You have a new notification';
        debugPrint('✅ Using notification payload: $title - $body');
      } else if (message.data.isNotEmpty) {
        // Data-only message - extract from data payload
        title = message.data['title'] as String? ?? 'New Notification';
        body = message.data['body'] as String? ?? 'You have a new notification';
        debugPrint('✅ Using data payload: $title - $body');
      } else {
        debugPrint('❌ No notification or data payload found');
        return;
      }

      debugPrint('🎯 Final notification: $title - $body');

        // Android notification details
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications from Stuthi app',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFF9500),
          ledOnMs: 1000,
          ledOffMs: 500,
          icon: '@mipmap/ic_launcher',
        );

        // iOS notification details
        const DarwinNotificationDetails iOSPlatformChannelSpecifics =
            DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        );

      // Show the notification
      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        platformChannelSpecifics,
        payload: message.data['notificationId'] as String? ?? message.messageId,
      );

      debugPrint('✅ Local notification displayed successfully');
      debugPrint('🎯 Notification ID: ${message.hashCode}');
      debugPrint('📝 Title: $title');
      debugPrint('📝 Body: $body');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  // Test method to verify local notifications work
  Future<void> testLocalNotification() async {
    try {
      debugPrint('🧪 Testing local notification...');

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications from Stuthi app',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF9500),
        ledOnMs: 1000,
        ledOffMs: 500,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        999,
        'Test Notification',
        'This is a test notification to verify local notifications work',
        platformChannelSpecifics,
        payload: 'test_notification',
      );

      debugPrint('✅ Test notification sent successfully');
    } catch (e) {
      debugPrint('❌ Test notification failed: $e');
    }
  }

  // Generate and store FCM token locally (without backend registration)
  Future<void> _generateAndStoreFCMToken() async {
    try {
      debugPrint('🎯 Starting FCM token generation...');

      // Get the token
      String? token = await _firebaseMessaging.getToken();

      if (token == null) {
        debugPrint('❌ Failed to get FCM token - token is null');
        return;
      }

      debugPrint('✅ FCM Token generated: ${token.substring(0, 20)}...');

      // Save token to shared preferences for later registration
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      debugPrint('💾 FCM token saved locally for later registration');
    } catch (e) {
      debugPrint('❌ Error generating FCM token: $e');
    }
  }

  // Register device token with the backend (call this after user login)
  Future<void> registerDeviceToken() async {
    try {
      debugPrint('🎯 Starting device token registration with backend...');

      // Get the stored token
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('fcm_token');

      if (token == null) {
        debugPrint('❌ No FCM token found in storage - generating new one...');
        await _generateAndStoreFCMToken();
        final String? newToken = prefs.getString('fcm_token');
        if (newToken == null) {
          debugPrint('❌ Failed to generate FCM token');
          return;
        }
        // Use the newly generated token
        await _registerTokenWithBackend(newToken);
        return;
      }

      await _registerTokenWithBackend(token);
    } catch (e) {
      debugPrint('❌ Error in registerDeviceToken: $e');
    }
  }

  // Helper method to register token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      debugPrint('🎯 Registering token with backend: ${token.substring(0, 20)}...');

      // Check if token was already registered
      final prefs = await SharedPreferences.getInstance();
      final String? registeredToken = prefs.getString('registered_fcm_token');

      // If token hasn't changed, no need to register again
      if (registeredToken == token) {
        debugPrint('💾 Token already registered, skipping registration');
        return;
      }

      // Ensure we have a valid Firebase token for authentication
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          // Get a fresh token
          final idToken = await firebaseUser.getIdToken(true);
          // Store it for API service to use
          await _secureStorage.write(key: 'firebase_token', value: idToken);
          debugPrint('✅ Refreshed Firebase auth token before registering device token');
          debugPrint('🔐 User logged in: ${firebaseUser.email}');
        } catch (e) {
          debugPrint('❌ Error refreshing Firebase auth token: $e');
          // Continue anyway, the API service will handle token issues
        }
      } else {
        debugPrint('❌ No Firebase user found when registering device token');
        debugPrint('⚠️ Device token registration will fail - user must be logged in');
        return; // Don't attempt registration without authentication
      }

      // Register with backend (notifications routes now use /api prefix)
      debugPrint('🎯 Attempting to register device token with backend...');
      debugPrint('🔍 Request URL: /notifications/device-token (will become /api/notifications/device-token)');
      debugPrint('🔍 Request data: token=${token.substring(0, 20)}..., deviceType=${defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'}, deviceName=${defaultTargetPlatform.toString()}');

      final response = await _apiService.post(
        '/notifications/device-token',
        data: {
          'token': token,
          'deviceType': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          'deviceName': defaultTargetPlatform.toString(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Device token registered successfully: ${response.statusCode}');
        debugPrint('📱 Response data: ${response.data}');
      } else {
        debugPrint('⚠️ Unexpected response status: ${response.statusCode}');
        debugPrint('📱 Response data: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ Error registering device token: $e');
      if (e.toString().contains('401')) {
        debugPrint('🔐 Authentication error - user may not be logged in properly');
      } else if (e.toString().contains('404')) {
        debugPrint('🔍 Endpoint not found - check API route configuration');
      } else if (e.toString().contains('500')) {
        debugPrint('🔥 Server error - check backend logs');
      }
    }
  }

  // Unregister device token
  Future<void> unregisterDeviceToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('fcm_token');

      if (token == null) {
        debugPrint('No token to unregister');
        return;
      }

      // Ensure we have a valid Firebase token for authentication
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          // Get a fresh token
          final idToken = await firebaseUser.getIdToken(true);
          // Store it for API service to use
          await _secureStorage.write(key: 'firebase_token', value: idToken);
          debugPrint('Refreshed Firebase auth token before unregistering device token');
        } catch (e) {
          debugPrint('Error refreshing Firebase auth token: $e');
          // Continue anyway, the API service will handle token issues
        }
      } else {
        debugPrint('No Firebase user found when unregistering device token');
        // We might not be able to unregister the token without authentication
      }

      // Unregister with backend
      await _apiService.delete('/notifications/device-token/$token');

      // Remove token from shared preferences
      await prefs.remove('fcm_token');

      debugPrint('Device token unregistered');
    } catch (e) {
      debugPrint('Error unregistering device token: $e');
    }
  }

  // Get notification history
  Future<List<dynamic>> getNotificationHistory() async {
    try {
      // Ensure we have a valid Firebase token
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          // Get a fresh token
          final idToken = await firebaseUser.getIdToken(true);
          // Store it for API service to use
          await _secureStorage.write(key: 'firebase_token', value: idToken);
          debugPrint('Refreshed Firebase token before getting notification history');
        } catch (e) {
          debugPrint('Error refreshing Firebase token: $e');
          // Continue anyway, the API service will handle token issues
        }
      } else {
        debugPrint('No Firebase user found when getting notification history');
      }

      final response = await _apiService.get('/notifications/customer/history');

      if (response.data is List) {
        return response.data as List<dynamic>;
      } else if (response.data is Map && response.data['data'] is List) {
        return response.data['data'] as List<dynamic>;
      } else {
        debugPrint('Unexpected notification history response format: ${response.data.runtimeType}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting notification history: $e');
      return [];
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final notifications = await getNotificationHistory();
      // Filter notifications where status is 'DELIVERED' (not read or clicked)
      final unreadNotifications = notifications.where((notification) =>
        notification['status'] == 'DELIVERED'
      ).toList();
      return unreadNotifications.length;
    } catch (e) {
      debugPrint('Error getting unread notification count: $e');
      return 0;
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      // Ensure we have a valid Firebase token
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          // Get a fresh token
          final idToken = await firebaseUser.getIdToken(true);
          // Store it for API service to use
          await _secureStorage.write(key: 'firebase_token', value: idToken);
        } catch (e) {
          debugPrint('Error refreshing Firebase token: $e');
          // Continue anyway, the API service will handle token issues
        }
      }

      await _apiService.patch(
        '/notifications/customer/history/$notificationId',
        data: {
          'status': 'READ',
        },
      );
      debugPrint('Notification marked as read');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark notification as clicked
  Future<void> markNotificationAsClicked(String notificationId) async {
    try {
      // Ensure we have a valid Firebase token
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          // Get a fresh token
          final idToken = await firebaseUser.getIdToken(true);
          // Store it for API service to use
          await _secureStorage.write(key: 'firebase_token', value: idToken);
        } catch (e) {
          debugPrint('Error refreshing Firebase token: $e');
          // Continue anyway, the API service will handle token issues
        }
      }

      await _apiService.patch(
        '/notifications/customer/history/$notificationId',
        data: {
          'status': 'CLICKED',
        },
      );
      debugPrint('Notification marked as clicked');
    } catch (e) {
      debugPrint('Error marking notification as clicked: $e');
    }
  }
}


