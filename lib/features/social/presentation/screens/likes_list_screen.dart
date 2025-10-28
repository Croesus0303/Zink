import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../events/providers/events_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../shared/widgets/clickable_user_avatar.dart';
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

    return Scaffold(
      backgroundColor: AppColors.midnightGreen,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header with back button and title
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
                vertical: MediaQuery.of(context).size.height * 0.015,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width * 0.07,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  Expanded(
                    child: Text(
                      'Likes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.07),
                ],
              ),
            ),
            Expanded(
              child: likesAsync.when(
              data: (likes) => likes.isNotEmpty
                  ? ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.04,
                        vertical: MediaQuery.of(context).size.height * 0.01,
                      ),
                      itemCount: likes.length,
                      itemBuilder: (context, index) {
                        final like = likes[index];
                        return _LikeListItem(
                          userId: like.uid,
                          likedAt: like.likedAt,
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: MediaQuery.of(context).size.width * 0.16,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.02),
                          Text(
                            'No likes yet',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          Text(
                            'Be the first to like this post!',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.035,
                            ),
                          ),
                        ],
                      ),
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.rosyBrown,
                  strokeWidth: 4,
                ),
              ),
              error: (error, stack) {
                AppLogger.e(
                    'Error loading likes for submission $submissionId', error);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: MediaQuery.of(context).size.width * 0.16,
                        color: AppColors.rosyBrown,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Text(
                        'Error loading likes',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(likesStreamProvider((
                          eventId: eventId,
                          submissionId: submissionId,
                        ))),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
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
            ),
          ),
        ],
      ),
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
      loading: () => _buildLoadingItem(context),
      error: (error, stack) => _buildErrorItem(context),
    );
  }

  Widget _buildListItem(BuildContext context, UserModel? user) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.midnightGreenLight,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.015),
      child: Row(
        children: [
          // User avatar
          ClickableUserAvatar(
            user: user,
            userId: userId,
            radius: MediaQuery.of(context).size.width * 0.04,
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
          // User info - only display name
          Expanded(
            child: ClickableUserName(
              user: user,
              userId: userId,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.035,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingItem(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.midnightGreenLight,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.015),
      child: Row(
        children: [
          // Loading avatar
          Container(
            width: MediaQuery.of(context).size.width * 0.08,
            height: MediaQuery.of(context).size.width * 0.08,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: AppColors.textSecondary,
              size: MediaQuery.of(context).size.width * 0.04,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
          // Loading info - only name placeholder
          Expanded(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.25,
              height: MediaQuery.of(context).size.height * 0.02,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorItem(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.midnightGreenLight,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.015),
      child: Row(
        children: [
          // Error avatar
          Container(
            width: MediaQuery.of(context).size.width * 0.08,
            height: MediaQuery.of(context).size.width * 0.08,
            decoration: BoxDecoration(
              color: AppColors.rosyBrown.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error,
              color: AppColors.rosyBrown,
              size: MediaQuery.of(context).size.width * 0.04,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
          // Error info - only "User not found"
          Expanded(
            child: Text(
              'User not found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.035,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
