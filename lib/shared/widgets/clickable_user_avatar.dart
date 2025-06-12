import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/auth/data/models/user_model.dart';

class ClickableUserAvatar extends StatelessWidget {
  final UserModel? user;
  final String? userId;
  final double radius;
  final bool showNavigateIcon;

  const ClickableUserAvatar({
    super.key,
    this.user,
    this.userId,
    this.radius = 20,
    this.showNavigateIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final targetUserId = userId ?? user?.uid;
    
    if (targetUserId == null) {
      return CircleAvatar(
        radius: radius,
        child: Text(
          '?',
          style: TextStyle(fontSize: radius * 0.8),
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/profile/$targetUserId'),
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundImage: user?.photoURL != null
                ? CachedNetworkImageProvider(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? Text(
                    user?.displayName?.substring(0, 1).toUpperCase() ?? '?',
                    style: TextStyle(fontSize: radius * 0.8),
                  )
                : null,
          ),
          if (showNavigateIcon)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
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
    final displayName = user?.displayName ?? 'Unknown User';
    
    if (targetUserId == null) {
      return Text(displayName, style: style);
    }

    return GestureDetector(
      onTap: () => context.push('/profile/$targetUserId'),
      child: Text(
        displayName,
        style: (style ?? const TextStyle()).copyWith(
          decoration: TextDecoration.underline,
          decorationColor: style?.color ?? Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}