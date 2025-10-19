import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/models/notification_model.dart';
import '../data/services/notifications_service.dart';
import '../../../core/utils/logger.dart';

// Singleton provider for NotificationsService
final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});

// Provider for the current user's notifications stream
final userNotificationsStreamProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null || currentUser.uid.isEmpty) {
    AppLogger.w('No current user for notifications stream');
    return Stream.value([]);
  }
  
  final service = ref.watch(notificationsServiceProvider);
  return service.getUserNotificationsStream(currentUser.uid).handleError((error) {
    AppLogger.e('Error in notifications stream', error);
    return [];
  });
});

// Provider for unread notifications count (considering local read states)
final enhancedUnreadNotificationsCountProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  final notificationsAsync = ref.watch(userNotificationsStreamProvider);
  final locallyReadIds = ref.watch(notificationReadStateProvider);
  
  return notificationsAsync.when(
    data: (notifications) {
      // Count notifications that are not read in Firebase AND not locally read
      final unreadCount = notifications.where((notification) {
        // If already seen in Firebase, it's read
        if (notification.seen) return false;
        
        // If locally marked as read, it's considered read
        if (locallyReadIds.contains(notification.id)) return false;
        
        // Otherwise it's unread
        return true;
      }).length;
      
      return AsyncValue.data(unreadCount);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Legacy provider - kept for backwards compatibility during migration
@Deprecated('Use enhancedUnreadNotificationsCountProvider instead')
final unreadNotificationsCountProvider = enhancedUnreadNotificationsCountProvider;

// Provider for marking a notification as read
final markNotificationAsReadProvider = FutureProvider.family<void, String>((ref, notificationId) async {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null || currentUser.uid.isEmpty) {
    throw Exception('No authenticated user');
  }
  
  final service = ref.watch(notificationsServiceProvider);
  await service.markNotificationAsRead(currentUser.uid, notificationId);
});


// Provider for deleting a notification
final deleteNotificationProvider = FutureProvider.family<void, String>((ref, notificationId) async {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null || currentUser.uid.isEmpty) {
    throw Exception('No authenticated user');
  }
  
  final service = ref.watch(notificationsServiceProvider);
  await service.deleteNotification(currentUser.uid, notificationId);
});

// State notifier for managing notification read states locally
class NotificationReadStateNotifier extends StateNotifier<Set<String>> {
  NotificationReadStateNotifier() : super(<String>{});
  
  void markAsReadLocally(String notificationId) {
    state = {...state, notificationId};
  }
  
  void markAllAsReadLocally(List<String> notificationIds) {
    state = {...state, ...notificationIds};
  }
  
  void clearLocalReadStates() {
    state = <String>{};
  }
  
  bool isReadLocally(String notificationId) {
    return state.contains(notificationId);
  }
}

final notificationReadStateProvider = StateNotifierProvider<NotificationReadStateNotifier, Set<String>>((ref) {
  return NotificationReadStateNotifier();
});

// Provider for enhanced notifications that include local read state
final enhancedNotificationsProvider = Provider.autoDispose<AsyncValue<List<NotificationModel>>>((ref) {
  final notificationsAsync = ref.watch(userNotificationsStreamProvider);
  final locallyReadIds = ref.watch(notificationReadStateProvider);
  
  return notificationsAsync.when(
    data: (notifications) {
      // Apply local read states to notifications
      final enhancedNotifications = notifications.map((notification) {
        if (locallyReadIds.contains(notification.id) && !notification.seen) {
          // Keep the original notification but mark it as locally read for UI purposes
          return notification;
        }
        return notification;
      }).toList();
      
      return AsyncValue.data(enhancedNotifications);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Provider for checking if a notification is unread (including local state)
final isNotificationUnreadProvider = Provider.family<bool, NotificationModel>((ref, notification) {
  final locallyReadIds = ref.watch(notificationReadStateProvider);
  
  // If it's already marked as seen in Firebase, it's read
  if (notification.seen) return false;
  
  // If it's marked as locally read, it's considered read for UI purposes
  if (locallyReadIds.contains(notification.id)) return false;
  
  // Otherwise it's unread
  return true;
});

// Provider for getting notification by ID
final notificationByIdProvider = FutureProvider.family<NotificationModel?, String>((ref, notificationId) async {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null || currentUser.uid.isEmpty) {
    throw Exception('No authenticated user');
  }
  
  final service = ref.watch(notificationsServiceProvider);
  return service.getNotificationById(currentUser.uid, notificationId);
});

// Provider for clearing old notifications
final clearOldNotificationsProvider = FutureProvider<void>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null || currentUser.uid.isEmpty) {
    throw Exception('No authenticated user');
  }
  
  final service = ref.watch(notificationsServiceProvider);
  await service.clearOldNotifications(currentUser.uid);
});

// Clean, simple approach - no complex pagination provider needed