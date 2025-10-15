import 'package:firebase_database/firebase_database.dart';
import '../../../../core/utils/logger.dart';
import '../models/notification_model.dart';

class NotificationsService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Get notifications stream for a specific user
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    try {
      AppLogger.i('Setting up notifications stream for user: $userId');
      
      return _database
          .ref('notifications/$userId')
          .orderByChild('createdAt')
          .limitToLast(100) // Get latest 100 notifications (increased from 50)
          .onValue
          .map((event) {
        final data = event.snapshot.value;
        
        if (data == null) {
          AppLogger.i('No notifications found for user');
          return <NotificationModel>[];
        }
        
        final Map<String, dynamic> notificationsMap = Map<String, dynamic>.from(data as Map);
        final List<NotificationModel> notifications = [];
        
        notificationsMap.forEach((key, value) {
          try {
            final notification = NotificationModel.fromRealtimeDatabase(
              key, 
              Map<String, dynamic>.from(value as Map)
            );
            notifications.add(notification);
          } catch (e, stackTrace) {
            AppLogger.e('Error parsing notification: $key', e, stackTrace);
          }
        });
        
        // Sort by createdAt descending (most recent first)
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        AppLogger.i('Received ${notifications.length} notifications');
        return notifications;
      });
    } catch (e, stackTrace) {
      AppLogger.e('Error setting up notifications stream', e, stackTrace);
      return Stream.value([]);
    }
  }

  // Get unread notifications count
  Stream<int> getUnreadNotificationsCountStream(String userId) {
    try {
      AppLogger.i('Setting up unread count stream for user: $userId');
      
      return _database
          .ref('notifications/$userId')
          .orderByChild('seen')
          .equalTo(false)
          .onValue
          .map((event) {
        final data = event.snapshot.value;
        
        if (data == null) {
          AppLogger.i('No unread notifications found');
          return 0;
        }
        
        final Map<String, dynamic> unreadNotifications = Map<String, dynamic>.from(data as Map);
        final count = unreadNotifications.length;
        
        AppLogger.i('Unread notifications count: $count');
        return count;
      });
    } catch (e, stackTrace) {
      AppLogger.e('Error setting up unread count stream', e, stackTrace);
      return Stream.value(0);
    }
  }

  // Mark a specific notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      AppLogger.i('Marking notification as read: $notificationId');
      
      await _database.ref('notifications/$userId/$notificationId').update({
        'seen': true,
        'seenAt': ServerValue.timestamp,
      });
      
      AppLogger.i('Notification marked as read successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Error marking notification as read', e, stackTrace);
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      AppLogger.i('Marking all notifications as read for user: $userId');
      
      final snapshot = await _database
          .ref('notifications/$userId')
          .orderByChild('seen')
          .equalTo(false)
          .get();
      
      if (!snapshot.exists) {
        AppLogger.i('No unread notifications to mark as read');
        return;
      }
      
      final Map<String, dynamic> unreadNotifications = Map<String, dynamic>.from(snapshot.value as Map);
      final Map<String, dynamic> updates = {};
      
      unreadNotifications.forEach((key, value) {
        updates['notifications/$userId/$key/seen'] = true;
        updates['notifications/$userId/$key/seenAt'] = ServerValue.timestamp;
      });
      
      await _database.ref().update(updates);
      AppLogger.i('${unreadNotifications.length} notifications marked as read');
    } catch (e, stackTrace) {
      AppLogger.e('Error marking all notifications as read', e, stackTrace);
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete a specific notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      AppLogger.i('Deleting notification: $notificationId');
      
      await _database.ref('notifications/$userId/$notificationId').remove();
      
      AppLogger.i('Notification deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Error deleting notification', e, stackTrace);
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Get a single notification by ID
  Future<NotificationModel?> getNotificationById(
    String userId, 
    String notificationId,
  ) async {
    try {
      AppLogger.i('Getting notification by ID: $notificationId');
      
      final snapshot = await _database.ref('notifications/$userId/$notificationId').get();
      
      if (!snapshot.exists) {
        AppLogger.w('Notification not found: $notificationId');
        return null;
      }
      
      return NotificationModel.fromRealtimeDatabase(
        notificationId,
        Map<String, dynamic>.from(snapshot.value as Map)
      );
    } catch (e, stackTrace) {
      AppLogger.e('Error getting notification by ID', e, stackTrace);
      throw Exception('Failed to get notification: $e');
    }
  }

  // Clear old notifications (older than 30 days)
  Future<void> clearOldNotifications(String userId) async {
    try {
      AppLogger.i('Clearing old notifications for user: $userId');
      
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      final snapshot = await _database.ref('notifications/$userId').get();
      
      if (!snapshot.exists) {
        AppLogger.i('No notifications to clear');
        return;
      }
      
      final Map<String, dynamic> allNotifications = Map<String, dynamic>.from(snapshot.value as Map);
      final List<String> oldNotificationIds = [];
      
      allNotifications.forEach((key, value) {
        final notificationData = Map<String, dynamic>.from(value as Map);
        final createdAt = notificationData['createdAt'] as int;
        
        if (createdAt < thirtyDaysAgo) {
          oldNotificationIds.add(key);
        }
      });
      
      if (oldNotificationIds.isNotEmpty) {
        final Map<String, dynamic> updates = {};
        for (final id in oldNotificationIds) {
          updates['notifications/$userId/$id'] = null; // null removes the data
        }
        
        await _database.ref().update(updates);
        AppLogger.i('${oldNotificationIds.length} old notifications deleted');
      } else {
        AppLogger.i('No old notifications to delete');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error clearing old notifications', e, stackTrace);
      throw Exception('Failed to clear old notifications: $e');
    }
  }
}