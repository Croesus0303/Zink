import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../events/providers/events_providers.dart';
import '../../../submissions/data/models/submission_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../social/presentation/widgets/like_button.dart';
import '../../../social/presentation/widgets/comment_sheet.dart';
import '../../../../core/utils/logger.dart';
import '../../../submissions/data/services/submissions_service.dart';
import '../../../../shared/widgets/clickable_user_avatar.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../l10n/app_localizations.dart';

class SingleSubmissionScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String submissionId;
  final bool fromProfile;

  const SingleSubmissionScreen({
    super.key,
    required this.eventId,
    required this.submissionId,
    this.fromProfile = false,
  });

  @override
  ConsumerState<SingleSubmissionScreen> createState() =>
      _SingleSubmissionScreenState();
}

class _SingleSubmissionScreenState
    extends ConsumerState<SingleSubmissionScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSocialData();
    });
  }

  void _refreshSocialData() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      ref.invalidate(likesStreamProvider(
          (eventId: widget.eventId, submissionId: widget.submissionId)));
      ref.invalidate(commentsStreamProvider(
          (eventId: widget.eventId, submissionId: widget.submissionId)));
      ref.invalidate(likeStatusProvider((
        eventId: widget.eventId,
        submissionId: widget.submissionId,
        userId: currentUser.uid
      )));
      ref.invalidate(likeCountProvider(
          (eventId: widget.eventId, submissionId: widget.submissionId)));
      ref.invalidate(commentCountProvider(
          (eventId: widget.eventId, submissionId: widget.submissionId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionAsync = ref.watch(submissionProvider(
        (eventId: widget.eventId, submissionId: widget.submissionId)));

    return submissionAsync.when(
      data: (submission) => submission != null
          ? _buildSubmissionDetail(submission)
          : _buildNotFound(),
      loading: () => Scaffold(
        backgroundColor: AppColors.midnightGreen,
        appBar: AppBar(
          backgroundColor: AppColors.midnightGreen,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.07,
            ),
            padding: EdgeInsets.zero,
          ),
          title: Text(
            AppLocalizations.of(context)!.photo,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.rosyBrown,
            strokeWidth: 4,
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.midnightGreen,
        appBar: AppBar(
          backgroundColor: AppColors.midnightGreen,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.07,
            ),
            padding: EdgeInsets.zero,
          ),
          title: Text(
            AppLocalizations.of(context)!.photo,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
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
                AppLocalizations.of(context)!.errorLoadingSubmission,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(submissionProvider((
                  eventId: widget.eventId,
                  submissionId: widget.submissionId
                ))),
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
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Scaffold(
      backgroundColor: AppColors.midnightGreen,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: MediaQuery.of(context).size.width * 0.07,
          ),
          padding: EdgeInsets.zero,
        ),
        title: Text(
          AppLocalizations.of(context)!.photo,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: MediaQuery.of(context).size.width * 0.2,
              color: AppColors.rosyBrown,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              AppLocalizations.of(context)!.submissionNotFound,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionDetail(SubmissionModel submission) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: MediaQuery.of(context).size.width * 0.07,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
      backgroundColor: AppColors.midnightGreen,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User info at top - username and event name only
            _SubmissionInfoTop(submission: submission),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            // Main image with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: submission.imageURL,
                fit: BoxFit.cover,
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.7,
                placeholder: (context, url) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.rosyBrown,
                      strokeWidth: 4,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const Center(
                    child:
                        Icon(Icons.error, color: AppColors.rosyBrown, size: 64),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015),
            // Action buttons - like, comment, delete
            _SubmissionInfoBottom(submission: submission),
          ],
        ),
      ),
    );
  }
}

class _SubmissionInfoTop extends ConsumerWidget {
  final SubmissionModel submission;

  const _SubmissionInfoTop({required this.submission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider(submission.uid));
    final eventAsync = ref.watch(eventProvider(submission.eventId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Profile picture and username
          userDataAsync.when(
            data: (user) => Row(
              children: [
                ClickableUserAvatar(
                  user: user,
                  userId: submission.uid,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                ClickableUserName(
                  user: user,
                  userId: submission.uid,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            loading: () => Row(
              children: [
                ClickableUserAvatar(
                  user: null,
                  userId: submission.uid,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                ClickableUserName(
                  user: null,
                  userId: submission.uid,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            error: (_, __) => Row(
              children: [
                ClickableUserAvatar(
                  user: null,
                  userId: submission.uid,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                ClickableUserName(
                  user: null,
                  userId: submission.uid,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Right side: Event name
          eventAsync.when(
            data: (event) => event != null
                ? InkWell(
                    onTap: () => context.push('/event/${event.id}'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.rosyBrown,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SubmissionInfoBottom extends ConsumerWidget {
  final SubmissionModel submission;

  const _SubmissionInfoBottom({required this.submission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final likesStreamAsync = ref.watch(likesStreamProvider(
        (eventId: submission.eventId, submissionId: submission.id)));

    bool isLikedByCurrentUser = false;
    int currentLikeCount = submission.likeCount;

    likesStreamAsync.whenData((likes) {
      currentLikeCount = likes.length;
      if (currentUser != null) {
        isLikedByCurrentUser = likes.any((like) => like.uid == currentUser.uid);
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Like and comment buttons
          LikeButton(
            eventId: submission.eventId,
            submissionId: submission.id,
            initialLikeCount: currentLikeCount,
            initialIsLiked: isLikedByCurrentUser,
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useSafeArea: true,
                enableDrag: true,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: CommentSheet(
                    eventId: submission.eventId,
                    submissionId: submission.id,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: MediaQuery.of(context).size.width * 0.06,
                    color: Colors.white,
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                  Consumer(
                    builder: (context, ref, child) {
                      final commentsAsync = ref.watch(commentsStreamProvider((
                        eventId: submission.eventId,
                        submissionId: submission.id
                      )));
                      return commentsAsync.when(
                        data: (comments) => Text(
                          comments.length.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                          ),
                        ),
                        loading: () => Text(
                          '0',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                          ),
                        ),
                        error: (_, __) => Text(
                          '0',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Delete button on the right
          if (currentUser != null && currentUser.uid == submission.uid)
            InkWell(
              onTap: () async {
                await _showDeleteConfirmationDialog(context, ref, submission);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.06,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, SubmissionModel submission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: AppColors.midnightGreen,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete Post',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Are you sure you want to delete this post? This action cannot be undone.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rosyBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final submissionsService = ref.read(submissionsServiceProvider);
        await submissionsService.deleteSubmission(
            submission.eventId, submission.id);

        if (context.mounted) {
          // Refresh the submission count provider
          ref.invalidate(userSubmissionCountForEventProvider(
              (userId: submission.uid, eventId: submission.eventId)));

          CustomSnackBar.showSuccess(context, 'Post deleted successfully');
          // Go back to profile or previous screen
          Navigator.of(context).pop();
        }
      } catch (e) {
        AppLogger.e('Error deleting submission ${submission.id}', e);
        if (context.mounted) {
          CustomSnackBar.showError(context, 'Failed to delete post');
        }
      }
    }
  }
}
