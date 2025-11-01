import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/events/providers/events_providers.dart';
import '../widgets/app_colors.dart';

class ClickableUserAvatar extends ConsumerWidget {
  final UserModel? user;
  final String? userId;
  final String? username;
  final double radius;
  final bool showNavigateIcon;

  ClickableUserAvatar({
    super.key,
    this.user,
    this.userId,
    this.username,
    double? radius,
    this.showNavigateIcon = false,
  }) : radius = radius ?? 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetUserId = userId ?? user?.uid;

    if (targetUserId == null) {
      return Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.rosyBrown,
              AppColors.pineGreen,
              AppColors.midnightGreen,
            ],
          ),
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: Colors.transparent,
          child: Text(
            username?.isNotEmpty == true
                ? username!.substring(0, 1).toUpperCase()
                : '?',
            style: TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // If we have a user object, use it directly
    if (user != null) {
      return _buildAvatar(context, user, targetUserId);
    }

    // If we only have userId, fetch the user data
    final userAsync = ref.watch(userDataProvider(targetUserId));

    return userAsync.when(
      data: (fetchedUser) => _buildAvatar(context, fetchedUser, targetUserId),
      loading: () => Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.rosyBrown,
              AppColors.pineGreen,
              AppColors.midnightGreen,
            ],
          ),
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: Colors.transparent,
          child: Text(
            username?.isNotEmpty == true
                ? username!.substring(0, 1).toUpperCase()
                : '?',
            style: TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      error: (_, __) => Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.rosyBrown,
              AppColors.pineGreen,
              AppColors.midnightGreen,
            ],
          ),
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: Colors.transparent,
          child: Text(
            username?.isNotEmpty == true
                ? username!.substring(0, 1).toUpperCase()
                : '?',
            style: TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, UserModel? userData, String targetUserId) {
    return GestureDetector(
      onTap: () => context.push('/profile/$targetUserId'),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.rosyBrown,
                  AppColors.pineGreen,
                  AppColors.midnightGreen,
                ],
              ),
            ),
            child: CircleAvatar(
              radius: radius,
              backgroundColor: Colors.transparent,
              backgroundImage: userData?.photoURL != null
                  ? CachedNetworkImageProvider(userData!.photoURL!)
                  : null,
              child: userData?.photoURL == null
                  ? Text(
                      _getDisplayText(userData),
                      style: TextStyle(
                        fontSize: radius * 0.8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          if (showNavigateIcon)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.005),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  size: radius * 0.4,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getDisplayText(UserModel? userData) {
    // Priority: userData username > passed username parameter > '?'
    if (userData?.username != null && userData!.username.isNotEmpty) {
      return userData.username.substring(0, 1).toUpperCase();
    }
    if (username != null && username!.isNotEmpty) {
      return username!.substring(0, 1).toUpperCase();
    }
    return '?';
  }
}

class ClickableUserName extends StatelessWidget {
  final UserModel? user;
  final String? userId;
  final TextStyle? style;
  
  const ClickableUserName({
    super.key,
    this.user,
    this.userId,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final targetUserId = userId ?? user?.uid;
    final username = user?.username ?? 'Unknown User';

    if (targetUserId == null) {
      return Text(username, style: style);
    }

    return GestureDetector(
      onTap: () => context.push('/profile/$targetUserId'),
      child: Text(
        username,
        style: (style ?? const TextStyle()).copyWith(
          decoration: style?.decoration ?? TextDecoration.underline,
          decorationColor: style?.color ?? Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}