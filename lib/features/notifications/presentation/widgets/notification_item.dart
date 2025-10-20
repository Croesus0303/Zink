import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/clickable_user_avatar.dart';
import '../../../../l10n/app_localizations.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final bool isUnread;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.isUnread,
    required this.onTap,
    required this.onDismiss,
  });

  String _getUsername() {
    if (notification.type == NotificationType.like) {
      return notification.likerUsername ?? 'Someone';
    } else {
      return notification.commenterUsername ?? 'Someone';
    }
  }

  String _getUserId() {
    if (notification.type == NotificationType.like) {
      return notification.likerUserId ?? '';
    } else {
      return notification.commenterUserId ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = _getUsername();
    final userId = _getUserId();

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: MediaQuery.of(context).size.height * 0.005,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.rosyBrown.withValues(alpha: 0.3),
              AppColors.rosyBrown.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.06,
        ),
        child: Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: MediaQuery.of(context).size.width * 0.06,
        ),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: MediaQuery.of(context).size.height * 0.006,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnread
                ? [
                    Colors.white.withValues(alpha: 0.16),
                    AppColors.pineGreen.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.04),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.08),
                    AppColors.pineGreen.withValues(alpha: 0.03),
                    Colors.white.withValues(alpha: 0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.iceBorder.withValues(alpha: 0.2),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
                vertical: MediaQuery.of(context).size.height * 0.015,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User avatar with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Main avatar
                      ClickableUserAvatar(
                        userId: userId,
                        username: username,
                        radius: MediaQuery.of(context).size.width * 0.065,
                      ),
                      // Badge icon (like/comment indicator)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: notification.type == NotificationType.like
                                ? AppColors.rosyBrown
                                : AppColors.pineGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            notification.type == NotificationType.like
                                ? Icons.favorite
                                : Icons.chat_bubble,
                            color: Colors.white,
                            size: MediaQuery.of(context).size.width * 0.03,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(width: MediaQuery.of(context).size.width * 0.035),

                  // Notification content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username and action message
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: username,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: MediaQuery.of(context).size.width * 0.038,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              TextSpan(
                                text: ' ',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.038,
                                ),
                              ),
                              TextSpan(
                                text: notification.type == NotificationType.like
                                    ? 'liked your post'
                                    : 'commented on your post',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: MediaQuery.of(context).size.width * 0.038,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: MediaQuery.of(context).size.height * 0.006),

                        // Timestamp
                        Text(
                          _formatTime(context, notification.createdAt),
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            fontSize: MediaQuery.of(context).size.width * 0.033,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),

                  // Unread indicator dot
                  if (isUnread)
                    Container(
                      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
                      width: MediaQuery.of(context).size.width * 0.022,
                      height: MediaQuery.of(context).size.width * 0.022,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrangeDark,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrangeDark.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(width: MediaQuery.of(context).size.width * 0.022),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return AppLocalizations.of(context)!.justNow;
    } else if (difference.inHours < 1) {
      return AppLocalizations.of(context)!.minutesAgoShort(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return AppLocalizations.of(context)!.hoursAgoShort(difference.inHours);
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      // Show day name (e.g., "Monday", "Tuesday")
      final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      return weekdays[dateTime.weekday % 7];
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return AppLocalizations.of(context)!.weeksAgoShort(weeks);
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}