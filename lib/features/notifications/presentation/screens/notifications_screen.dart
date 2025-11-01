import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notifications_providers.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notifications_service.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/notification_item.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<NotificationModel> _unreadNotificationsOnEntry = [];
  String? _currentUserId;
  NotificationsService? _notificationsService;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Store references we'll need in dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentUserId = ref.read(currentUserProvider)?.uid;
      _notificationsService = ref.read(notificationsServiceProvider);
      
      // Track unread notifications when entering the page
      final notificationsAsync = ref.read(userNotificationsStreamProvider);
      notificationsAsync.whenData((notifications) {
        _unreadNotificationsOnEntry = notifications.where((n) => !n.seen).toList();
      });
    });
  }

  void _onScroll() {
    // Simple approach - shows all notifications without pagination for now
  }

  @override
  void dispose() {
    // Mark notifications as read using stored references (safe to use after disposal)
    _markAllNotificationsAsReadOnExit();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _markAllNotificationsAsReadOnExit() {
    if (_unreadNotificationsOnEntry.isNotEmpty && 
        _currentUserId != null && 
        _notificationsService != null) {
      
      // Use stored service reference (safe after disposal)
      _notificationsService!.markAllNotificationsAsRead(_currentUserId!).then((_) {
        AppLogger.i('Marked ${_unreadNotificationsOnEntry.length} notifications as read on page exit');
      }).catchError((e) {
        AppLogger.e('Error marking notifications as read on exit', e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightGreen,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: MediaQuery.of(context).size.width * 0.07,
          ),
          padding: EdgeInsets.zero,
        ),
        title: Text(
          AppLocalizations.of(context)!.notifications,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildNotificationsList(),
    );
  }

  Widget _buildNotificationsList() {
    // Use the simple real-time stream for all notifications
    final notificationsAsync = ref.watch(userNotificationsStreamProvider);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: MediaQuery.of(context).size.width * 0.2,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  AppLocalizations.of(context)!.noNotificationsYet,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Text(
                  AppLocalizations.of(context)!.notificationsWillAppearHere,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.01,
            bottom: MediaQuery.of(context).size.height * 0.02,
          ),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final isUnread = ref.watch(isNotificationUnreadProvider(notification));

            return NotificationItem(
              notification: notification,
              isUnread: isUnread,
              onTap: () => _handleNotificationTap(notification),
              onDismiss: () => _handleNotificationDismiss(notification),
            );
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: AppColors.rosyBrown,
          strokeWidth: MediaQuery.of(context).size.width * 0.01,
        ),
      ),
      error: (error, stack) {
        AppLogger.e('Error loading notifications', error, stack);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: MediaQuery.of(context).size.width * 0.2,
                color: AppColors.rosyBrown,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Text(
                AppLocalizations.of(context)!.errorLoadingNotifications,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(userNotificationsStreamProvider),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pineGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.06,
                    vertical: MediaQuery.of(context).size.height * 0.015,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Navigate based on notification type without marking as read
    // Read state will be updated when user leaves the notifications page
    if (notification.eventId != null && notification.submissionId != null) {
      // Navigate to single submission screen
      context.push('/submission/${notification.eventId}/${notification.submissionId}');
    }
  }

  Future<void> _handleNotificationDismiss(NotificationModel notification) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final service = ref.read(notificationsServiceProvider);
        await service.deleteNotification(currentUser.uid, notification.id);
      }
    } catch (e) {
      AppLogger.e('Error dismissing notification', e);
      if (mounted) {
        CustomSnackBar.showError(
          context, 
          '${AppLocalizations.of(context)!.failedToDeleteNotification}: $e',
        );
      }
    }
  }
}