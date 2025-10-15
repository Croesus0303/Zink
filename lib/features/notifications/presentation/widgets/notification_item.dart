import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../../../shared/widgets/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.01,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.rosyBrown.withValues(alpha: 0.3),
              AppColors.rosyBrown.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
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
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.01,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnread
                ? [
                    Colors.white.withValues(alpha: 0.18),
                    AppColors.primaryOrange.withValues(alpha: 0.12),
                    AppColors.rosyBrown.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.06),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.12),
                    AppColors.rosyBrown.withValues(alpha: 0.06),
                    AppColors.pineGreen.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0.03),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? AppColors.primaryOrange.withValues(alpha: 0.3)
                : AppColors.iceBorder,
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnread
                  ? AppColors.primaryOrange.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
              blurRadius: isUnread ? 12 : 8,
              offset: const Offset(-1, -1),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isUnread ? 0.08 : 0.04),
              blurRadius: 8,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Row(
                children: [
                  // Notification icon
                  Container(
                    width: MediaQuery.of(context).size.width * 0.12,
                    height: MediaQuery.of(context).size.width * 0.12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: notification.type == NotificationType.like
                            ? [
                                AppColors.rosyBrown.withValues(alpha: 0.8),
                                AppColors.rosyBrown.withValues(alpha: 0.9),
                              ]
                            : [
                                AppColors.pineGreen.withValues(alpha: 0.8),
                                AppColors.pineGreen.withValues(alpha: 0.9),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (notification.type == NotificationType.like
                                  ? AppColors.rosyBrown
                                  : AppColors.pineGreen)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      notification.type == NotificationType.like
                          ? Icons.favorite
                          : Icons.comment,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width * 0.06,
                    ),
                  ),
                  
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  
                  // Notification content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          notification.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            shadows: isUnread
                                ? [
                                    Shadow(
                                      color: AppColors.primaryOrange.withValues(alpha: 0.5),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                        
                        // Message
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: isUnread
                                ? AppColors.textPrimary.withValues(alpha: 0.9)
                                : AppColors.textSecondary,
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                        
                        // Time
                        Text(
                          _formatTime(context, notification.createdAt),
                          style: TextStyle(
                            color: isUnread
                                ? AppColors.primaryOrange.withValues(alpha: 0.8)
                                : AppColors.rosyBrown.withValues(alpha: 0.6),
                            fontSize: MediaQuery.of(context).size.width * 0.03,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Unread indicator
                  if (isUnread)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.025,
                      height: MediaQuery.of(context).size.width * 0.025,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 0),
                          ),
                        ],
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
    } else if (difference.inDays < 1) {
      return AppLocalizations.of(context)!.hoursAgoShort(difference.inHours);
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      return AppLocalizations.of(context)!.daysAgoShort(difference.inDays);
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return AppLocalizations.of(context)!.weeksAgoShort(weeks);
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}