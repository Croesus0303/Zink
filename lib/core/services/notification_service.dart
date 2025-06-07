import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../utils/logger.dart';

class NotificationService {
  final FirebaseMessaging _messaging;

  NotificationService(this._messaging);

  Future<void> initialize() async {
    try {
      // Request permission for iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final settings = await _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        AppLogger.i('iOS notification permission: ${settings.authorizationStatus}');
      }

      // Get FCM token
      final token = await _messaging.getToken();
      AppLogger.i('FCM Token: $token');

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.d('Received foreground message: ${message.messageId}');
        _handleMessage(message);
      });

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.d('App opened from notification: ${message.messageId}');
        _handleNotificationTap(message);
      });

      // Check if app was opened from a notification when terminated
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.d('App opened from terminated state via notification: ${initialMessage.messageId}');
        _handleNotificationTap(initialMessage);
      }

      AppLogger.i('Notification service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to initialize notification service', e, stackTrace);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      AppLogger.e('Failed to get FCM token', e);
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.i('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.e('Failed to subscribe to topic $topic', e);
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.i('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.e('Failed to unsubscribe from topic $topic', e);
    }
  }

  void _handleMessage(RemoteMessage message) {
    AppLogger.d('Handling foreground message: ${message.notification?.title}');
    
    // TODO: Show in-app notification or update UI
    // You could use a local notification package here or update the UI directly
    
    if (message.notification != null) {
      AppLogger.d('Message notification: ${message.notification!.title} - ${message.notification!.body}');
    }
    
    if (message.data.isNotEmpty) {
      AppLogger.d('Message data: ${message.data}');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    AppLogger.d('Handling notification tap: ${message.data}');
    
    // TODO: Navigate to appropriate screen based on message data
    // Example: Navigate to event detail if it's a new challenge notification
    
    final data = message.data;
    if (data.containsKey('eventId')) {
      // Navigate to event detail
      AppLogger.d('Should navigate to event: ${data['eventId']}');
    } else if (data.containsKey('submissionId')) {
      // Navigate to submission detail
      AppLogger.d('Should navigate to submission: ${data['submissionId']}');
    }
  }

  Future<void> handleTokenRefresh() async {
    _messaging.onTokenRefresh.listen((newToken) {
      AppLogger.i('FCM token refreshed: $newToken');
      // TODO: Send new token to your backend if needed
    });
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.d('Handling background message: ${message.messageId}');
  
  // TODO: Handle background message
  // This could include updating local storage, showing notifications, etc.
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FirebaseMessaging.instance);
});

// Provider for FCM token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return await notificationService.getToken();
});

// Provider for notification settings
final notificationSettingsProvider = StateProvider<NotificationSettings>((ref) {
  return NotificationSettings();
});

class NotificationSettings {
  final bool newChallenges;
  final bool challengeReminders;
  final bool socialActivity;

  NotificationSettings({
    this.newChallenges = true,
    this.challengeReminders = true,
    this.socialActivity = true,
  });

  NotificationSettings copyWith({
    bool? newChallenges,
    bool? challengeReminders,
    bool? socialActivity,
  }) {
    return NotificationSettings(
      newChallenges: newChallenges ?? this.newChallenges,
      challengeReminders: challengeReminders ?? this.challengeReminders,
      socialActivity: socialActivity ?? this.socialActivity,
    );
  }
}