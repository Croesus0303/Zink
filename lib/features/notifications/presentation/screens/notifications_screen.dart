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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen.withValues(alpha: 0.9),
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.065,
        title: Text(
          AppLocalizations.of(context)!.notifications,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: AppColors.rosyBrown.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 12, top: 3, bottom: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                AppColors.pineGreen.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.iceBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(-1, -1),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.04,
            ),
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width * 0.08,
              minHeight: MediaQuery.of(context).size.width * 0.08,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              ),
              Expanded(child: _buildNotificationsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    // Use the simple real-time stream for all notifications
    final notificationsAsync = ref.watch(userNotificationsStreamProvider);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return Center(
            child: Container(
              margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
              decoration: BoxDecoration(
                gradient: AppColors.iceGlassGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.iceBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(-2, -2),
                  ),
                  BoxShadow(
                    color: AppColors.rosyBrown.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.width * 0.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.pineGreen.withValues(alpha: 0.8),
                          AppColors.rosyBrown.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pineGreen.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_none,
                      size: MediaQuery.of(context).size.width * 0.1,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                  Text(
                    AppLocalizations.of(context)!.noNotificationsYet,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.045,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      shadows: [
                        Shadow(
                          color: AppColors.rosyBrown.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Text(
                    AppLocalizations.of(context)!.notificationsWillAppearHere,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.pineGreen),
      ),
      error: (error, stack) {
        AppLogger.e('Error loading notifications', error, stack);
        return Center(
          child: Container(
            margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
            decoration: BoxDecoration(
              gradient: AppColors.iceGlassGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.iceBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(-2, -2),
                ),
                BoxShadow(
                  color: AppColors.rosyBrown.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: MediaQuery.of(context).size.width * 0.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.rosyBrown.withValues(alpha: 0.8),
                        AppColors.rosyBrown.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.rosyBrown.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.error,
                    size: MediaQuery.of(context).size.width * 0.1,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                Text(
                  AppLocalizations.of(context)!.errorLoadingNotifications,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    shadows: [
                      Shadow(
                        color: AppColors.rosyBrown.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.pineGreen.withValues(alpha: 0.8),
                        AppColors.pineGreen.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pineGreen.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => ref.refresh(userNotificationsStreamProvider),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.06,
                          vertical: MediaQuery.of(context).size.height * 0.015,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width * 0.05,
                            ),
                            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                            Text(
                              AppLocalizations.of(context)!.retry,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: MediaQuery.of(context).size.width * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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