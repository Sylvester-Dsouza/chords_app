// Removed unused import
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to ensure Firebase is initialized
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification}');

  // Firebase will automatically display the notification in the system tray
  // when the app is in the background, so we don't need to do anything here
}



class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  // Stream controller for notification clicks
  final ValueNotifier<RemoteMessage?> onNotificationClick = ValueNotifier(null);

  // Factory constructor
  factory NotificationService() {
    return _instance;
  }

  // Private constructor
  NotificationService._internal();

  // Initialize the notification service
  Future<void> initialize() async {
    // Request permission for iOS
    await _requestPermission();

    // Configure FCM
    await _configureFCM();

    // Get the FCM token and register it with the backend
    await registerDeviceToken();

    // Handle notification click when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        onNotificationClick.value = message;
      }
    });
  }

  // Request permission for iOS
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  // Configure FCM
  Future<void> _configureFCM() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      debugPrint('Message notification: ${message.notification}');

      // Handle both notification messages and data-only messages
      if (message.notification != null) {
        debugPrint('Message contained a notification: ${message.notification}');
        _showInAppNotification(message);
      } else if (message.data.isNotEmpty) {
        debugPrint('Message is data-only');
        // Create a synthetic RemoteMessage with notification
        final syntheticMessage = RemoteMessage(
          data: message.data,
          notification: RemoteNotification(
            title: message.data['title'] ?? 'New Notification',
            body: message.data['body'] ?? 'You have a new notification',
          ),
          messageId: message.messageId,
          senderId: message.senderId,
          category: message.category,
          collapseKey: message.collapseKey,
          contentAvailable: message.contentAvailable,
          from: message.from,
          mutableContent: message.mutableContent,
          sentTime: message.sentTime,
          threadId: message.threadId,
          ttl: message.ttl,
        );
        _showInAppNotification(syntheticMessage);
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification click when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      onNotificationClick.value = message;
    });
  }

  // Show in-app notification
  void _showInAppNotification(RemoteMessage message) {
    try {
      RemoteNotification? notification = message.notification;

      if (notification != null) {
        // For in-app notifications, you can implement a custom UI
        // For example, show a snackbar, dialog, or custom overlay
        debugPrint('In-app notification: ${notification.title} - ${notification.body}');

        // The actual UI implementation would depend on your app's design
        // You could use a GlobalKey<ScaffoldMessengerState> to show a SnackBar
        // or create a custom overlay widget
      }
    } catch (e) {
      debugPrint('Error showing in-app notification: $e');
    }
  }

  // Register device token with the backend
  Future<void> registerDeviceToken() async {
    try {
      // Get the token
      String? token = await _firebaseMessaging.getToken();

      if (token == null) {
        debugPrint('Failed to get FCM token');
        return;
      }

      debugPrint('FCM Token: $token');

      // Save token to shared preferences
      final prefs = await SharedPreferences.getInstance();
      final String? oldToken = prefs.getString('fcm_token');

      // If token hasn't changed, no need to register again
      if (oldToken == token) {
        debugPrint('Token unchanged, skipping registration');
        return;
      }

      // Save the new token
      await prefs.setString('fcm_token', token);

      // Register with backend
      final response = await _apiService.post(
        '/notifications/device-token',
        data: {
          'token': token,
          'deviceType': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          'deviceName': defaultTargetPlatform.toString(),
        },
      );

      debugPrint('Device token registered: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error registering device token: $e');
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
      final response = await _apiService.get('/notifications/customer/history');
      return response.data;
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


