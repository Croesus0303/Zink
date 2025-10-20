import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import '../providers/locale_provider.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final SharedPreferences _prefs;

  static const String _notificationPromptDismissedKey =
      'notification_prompt_dismissed';

  NotificationService(this._messaging, this._prefs);

  Future<void> initialize() async {
    try {
      await _requestNotificationPermission();

      // Check if we have permission and subscribe to all_users topic
      final hasPermission = await hasNotificationPermission();
      if (hasPermission) {
        await subscribeToTopic('all_users');
        AppLogger.i('Subscribed to all_users topic during initialization');
      }

      // Get FCM token
      final token = await _messaging.getToken();
      AppLogger.i('FCM Token: $token');

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

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
        AppLogger.d(
            'App opened from terminated state via notification: ${initialMessage.messageId}');
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
      // Ensure we have a valid FCM token before subscribing
      String? token;
      try {
        token = await _messaging.getToken();
      } catch (tokenError) {
        AppLogger.e('Failed to get FCM token for topic subscription: $tokenError');
        return; // Don't subscribe if we can't get token
      }

      if (token == null) {
        AppLogger.e('Cannot subscribe to topic: No FCM token available');
        return;
      }

      await _messaging.subscribeToTopic(topic);
      AppLogger.i(
          'Successfully subscribed to topic: $topic with token: ${token.substring(0, 20)}...');
    } catch (e) {
      AppLogger.e('Failed to subscribe to topic $topic', e);
      // Don't rethrow - topic subscription failure shouldn't block other operations
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

    // Log notification details
    if (message.notification != null) {
      AppLogger.d(
          'Foreground notification title: ${message.notification!.title}');
      AppLogger.d(
          'Foreground notification body: ${message.notification!.body}');
    }

    // Log data payload
    if (message.data.isNotEmpty) {
      AppLogger.d('Foreground message data: ${message.data}');
    }

    // Handle different message types when app is in foreground
    final data = message.data;

    if (data.containsKey('type')) {
      final messageType = data['type'];

      switch (messageType) {
        case 'new_event':
          _handleForegroundNewEvent(data);
          break;
        case 'event_reminder':
          _handleForegroundEventReminder(data);
          break;
        case 'submission_update':
          _handleForegroundSubmissionUpdate(data);
          break;
        case 'general':
        default:
          _handleForegroundGeneral(data);
          break;
      }
    }
  }

  void _handleForegroundNewEvent(Map<String, dynamic> data) {
    AppLogger.d('Handling foreground new event notification');
  }

  void _handleForegroundEventReminder(Map<String, dynamic> data) {
    AppLogger.d('Handling foreground event reminder notification');
  }

  void _handleForegroundSubmissionUpdate(Map<String, dynamic> data) {
    AppLogger.d('Handling foreground submission update notification');
  }

  void _handleForegroundGeneral(Map<String, dynamic> data) {
    AppLogger.d('Handling foreground general notification');
  }

  void _handleNotificationTap(RemoteMessage message) {
    AppLogger.d('Handling notification tap: ${message.data}');

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
    });
  }

  Future<bool> hasNotificationPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final settings = await _messaging.getNotificationSettings();
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.status;
        return status.isGranted;
      }
      return false;
    } catch (e) {
      AppLogger.e('Failed to check notification permission', e);
      return false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final granted = await _requestNotificationPermission();

      if (granted) {
        // Subscribe to all_users topic when permission is granted
        await subscribeToTopic('all_users');
        AppLogger.i('Subscribed to all_users topic after permission granted');
      }

      return granted;
    } catch (e) {
      AppLogger.e('Failed to request notification permission', e);
      return false;
    }
  }

  Future<bool> _requestNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.i(
          'iOS notification permission: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      AppLogger.i('Android notification permission: $status');
      return status.isGranted;
    }

    return false;
  }

  bool isNotificationPromptDismissed() {
    return _prefs.getBool(_notificationPromptDismissedKey) ?? false;
  }

  Future<void> dismissNotificationPrompt() async {
    await _prefs.setBool(_notificationPromptDismissedKey, true);
  }

  Future<bool> shouldShowNotificationPrompt() async {
    // Don't show if user has dismissed it
    if (isNotificationPromptDismissed()) {
      return false;
    }

    // Don't show if permission is already granted
    final hasPermission = await hasNotificationPermission();
    return !hasPermission;
  }

  Future<void> unsubscribeFromAllTopics() async {
    try {
      await unsubscribeFromTopic('all_users');
      AppLogger.i('Unsubscribed from all topics');
    } catch (e) {
      AppLogger.e('Failed to unsubscribe from topics', e);
    }
  }

  Future<void> checkAndManageTopicSubscription() async {
    try {
      final hasPermission = await hasNotificationPermission();

      if (hasPermission) {
        // Subscribe to all_users topic if we have permission
        await subscribeToTopic('all_users');
        AppLogger.d('Ensured subscription to all_users topic');
      } else {
        // Unsubscribe if we don't have permission
        await unsubscribeFromAllTopics();
        AppLogger.d('Unsubscribed from topics due to no permission');
      }
    } catch (e) {
      AppLogger.e('Failed to manage topic subscription', e);
    }
  }

  // Debug method to verify FCM setup
  Future<void> debugFCMSetup() async {
    try {
      AppLogger.i('=== FCM Debug Information ===');
      AppLogger.i('Platform: ${defaultTargetPlatform.toString()}');

      // Check if running on simulator/emulator
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        AppLogger.w(
            '⚠️  iOS Simulator detected - FCM notifications will NOT work!');
        AppLogger.w('⚠️  Use a physical iOS device for notification testing');
      }

      // Check permission status
      final hasPermission = await hasNotificationPermission();
      AppLogger.i('Notification permission: $hasPermission');

      // Get FCM token
      final token = await getToken();
      if (token != null) {
        AppLogger.i('FCM Token: ${token.substring(0, 50)}...');
      } else {
        AppLogger.w('FCM Token: null (expected on iOS Simulator)');
      }

      // Check notification settings (iOS)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final settings = await _messaging.getNotificationSettings();
        AppLogger.i('iOS Notification Settings:');
        AppLogger.i(
            '  - Authorization Status: ${settings.authorizationStatus}');
        AppLogger.i('  - Alert Setting: ${settings.alert}');
        AppLogger.i('  - Badge Setting: ${settings.badge}');
        AppLogger.i('  - Sound Setting: ${settings.sound}');
      }

      AppLogger.i('=== End FCM Debug ===');
    } catch (e) {
      AppLogger.e('FCM Debug failed', e);
    }
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp();

  AppLogger.d('Handling background message: ${message.messageId}');

  // Log notification details
  if (message.notification != null) {
    AppLogger.d(
        'Background notification title: ${message.notification!.title}');
    AppLogger.d('Background notification body: ${message.notification!.body}');
  }

  // Log data payload
  if (message.data.isNotEmpty) {
    AppLogger.d('Background message data: ${message.data}');
  }

  // Handle different message types based on data
  final data = message.data;

  if (data.containsKey('type')) {
    final messageType = data['type'];

    switch (messageType) {
      case 'new_event':
        await _handleNewEventNotification(data);
        break;
      case 'event_reminder':
        await _handleEventReminderNotification(data);
        break;
      case 'submission_update':
        await _handleSubmissionUpdateNotification(data);
        break;
      case 'general':
      default:
        await _handleGeneralNotification(data);
        break;
    }
  } else {
    // Handle notifications without specific type
    await _handleGeneralNotification(data);
  }
}

// Handle new event notifications
Future<void> _handleNewEventNotification(Map<String, dynamic> data) async {
  AppLogger.d('Handling new event notification');

  if (data.containsKey('eventId')) {
    final eventId = data['eventId'];
    AppLogger.d('New event ID: $eventId');
  }
}

// Handle event reminder notifications
Future<void> _handleEventReminderNotification(Map<String, dynamic> data) async {
  AppLogger.d('Handling event reminder notification');

  if (data.containsKey('eventId')) {
    final eventId = data['eventId'];
    AppLogger.d('Event reminder for ID: $eventId');
  }
}

// Handle submission update notifications
Future<void> _handleSubmissionUpdateNotification(
    Map<String, dynamic> data) async {
  AppLogger.d('Handling submission update notification');

  if (data.containsKey('submissionId')) {
    final submissionId = data['submissionId'];
    AppLogger.d('Submission update for ID: $submissionId');
  }
}

// Handle general notifications
Future<void> _handleGeneralNotification(Map<String, dynamic> data) async {
  AppLogger.d('Handling general notification');
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationService(FirebaseMessaging.instance, prefs);
});

// Provider for FCM token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return await notificationService.getToken();
});

// Provider for notification permission status
final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return await notificationService.hasNotificationPermission();
});

// Provider for whether to show notification prompt
final shouldShowNotificationPromptProvider = FutureProvider<bool>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return await notificationService.shouldShowNotificationPrompt();
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
