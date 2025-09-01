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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen.withValues(alpha: 0.9),
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.065,
        title: Text(
          'Likes',
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: AppColors.rosyBrown.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: EdgeInsets.only(
            left: MediaQuery.of(context).size.width * 0.03, 
            top: 3, 
            bottom: 3
          ),
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
            onPressed: () => Navigator.of(context).pop(),
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
          image: const DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.auroraRadialGradient,
          ),
          child: SafeArea(
            child: likesAsync.when(
              data: (likes) => likes.isNotEmpty
                  ? ListView.builder(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
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
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                          Text(
                            'No likes yet',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: MediaQuery.of(context).size.width * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                          Text(
                            'Be the first to like this post!',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: MediaQuery.of(context).size.width * 0.035,
                            ),
                          ),
                        ],
                      ),
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.pineGreen),
              ),
              error: (error, stack) {
                AppLogger.e('Error loading likes for submission $submissionId', error);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: MediaQuery.of(context).size.width * 0.16,
                        color: AppColors.rosyBrown,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      Text(
                        'Error loading likes',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                        ),
                        textAlign: TextAlign.center,
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
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => ref.refresh(likesStreamProvider((
                              eventId: eventId,
                              submissionId: submissionId,
                            ))),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.width * 0.06,
                                vertical: MediaQuery.of(context).size.height * 0.015,
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.008),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
      decoration: BoxDecoration(
        gradient: AppColors.iceGlassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.iceBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(-1, -1),
          ),
          BoxShadow(
            color: AppColors.rosyBrown.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(1, 1),
          ),
        ],
      ),
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
                color: AppColors.textPrimary,
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
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.008),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
      decoration: BoxDecoration(
        gradient: AppColors.iceGlassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.iceBorder,
          width: 1,
        ),
      ),
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
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.008),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
      decoration: BoxDecoration(
        gradient: AppColors.iceGlassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.rosyBrown.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
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
                color: AppColors.textPrimary,
                fontSize: MediaQuery.of(context).size.width * 0.035,
              ),
            ),
          ),
        ],
      ),
    );
  }

}