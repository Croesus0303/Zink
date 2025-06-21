import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../events/providers/events_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../shared/widgets/clickable_user_avatar.dart';
import '../../../../shared/widgets/crystal_scaffold.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../core/utils/logger.dart';

class LikesListScreen extends ConsumerWidget {
  final String eventId;
  final String submissionId;

  const LikesListScreen({
    super.key,
    required this.eventId,
    required this.submissionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likesAsync = ref.watch(likesStreamProvider((
      eventId: eventId,
      submissionId: submissionId,
    )));

    return CrystalScaffold(
      appBarTitle: 'Likes',
      body: likesAsync.when(
        data: (likes) => likes.isNotEmpty
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: likes.length,
                itemBuilder: (context, index) {
                  final like = likes[index];
                  return _LikeListItem(
                    userId: like.uid,
                    likedAt: like.likedAt,
                  );
                },
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No likes yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Be the first to like this post!',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
        error: (error, stack) {
          AppLogger.e('Error loading likes for submission $submissionId', error);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading likes',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(likesStreamProvider((
                    eventId: eventId,
                    submissionId: submissionId,
                  ))),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LikeListItem extends ConsumerWidget {
  final String userId;
  final DateTime likedAt;

  const _LikeListItem({
    required this.userId,
    required this.likedAt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider(userId));

    return userDataAsync.when(
      data: (user) => _buildListItem(context, user),
      loading: () => _buildLoadingItem(),
      error: (error, stack) => _buildErrorItem(context),
    );
  }

  Widget _buildListItem(BuildContext context, UserModel? user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryCyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // User avatar
          ClickableUserAvatar(
            user: user,
            userId: userId,
            radius: 24,
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClickableUserName(
                  user: user,
                  userId: userId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                if (user?.username != null && user!.username!.isNotEmpty) ...[
                  Text(
                    '@${user.username!}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  _formatLikeTime(likedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Like icon
          const Icon(
            Icons.favorite,
            color: AppColors.primaryOrange,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryCyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Loading avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Loading info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          // Loading icon
          Icon(
            Icons.favorite,
            color: AppColors.primaryOrange.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Error avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error,
              color: AppColors.primaryOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Error info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User not found',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatLikeTime(likedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Like icon
          const Icon(
            Icons.favorite,
            color: AppColors.primaryOrange,
            size: 20,
          ),
        ],
      ),
    );
  }

  String _formatLikeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      final months = difference.inDays ~/ 30;
      return '${months}mo ago';
    }
  }
}