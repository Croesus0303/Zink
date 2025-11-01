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
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.06,
        ),
        color: AppColors.rosyBrown,
        child: Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: MediaQuery.of(context).size.width * 0.06,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.midnightGreenLight.withValues(alpha: 0.5)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppColors.midnightGreenLight,
              width: MediaQuery.of(context).size.width * 0.0025,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
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
                        right: -MediaQuery.of(context).size.width * 0.005,
                        bottom: -MediaQuery.of(context).size.width * 0.005,
                        child: Container(
                          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01),
                          decoration: BoxDecoration(
                            color: notification.type == NotificationType.like
                                ? AppColors.rosyBrown
                                : AppColors.pineGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: MediaQuery.of(context).size.width * 0.005,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: MediaQuery.of(context).size.width * 0.01,
                                offset: Offset(0, MediaQuery.of(context).size.height * 0.00125),
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
                      width: MediaQuery.of(context).size.width * 0.025,
                      height: MediaQuery.of(context).size.width * 0.025,
                      decoration: const BoxDecoration(
                        color: AppColors.rosyBrown,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    SizedBox(width: MediaQuery.of(context).size.width * 0.025),
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