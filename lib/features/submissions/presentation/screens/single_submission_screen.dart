import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../events/providers/events_providers.dart';
import '../../../submissions/data/models/submission_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../social/presentation/widgets/like_button.dart';
import '../../../social/presentation/widgets/comment_sheet.dart';
import '../../../../core/utils/logger.dart';
import '../../../submissions/data/services/submissions_service.dart';
import '../../../../shared/widgets/clickable_user_avatar.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

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
        backgroundColor: Colors.black,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.grey.shade900,
              ],
            ),
          ),
          child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan)),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Error', style: TextStyle(color: Colors.white)),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.grey.shade900,
              ],
            ),
          ),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withValues(alpha: 0.2),
                    AppColors.primaryOrangeDark.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange.withValues(alpha: 0.8),
                          AppColors.primaryOrangeDark.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Error loading submission',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange.withValues(alpha: 0.8),
                          AppColors.primaryOrangeDark.withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => ref.refresh(submissionProvider((
                          eventId: widget.eventId,
                          submissionId: widget.submissionId
                        ))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Retry',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Submission Not Found',
            style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey.shade900,
            ],
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryOrange.withValues(alpha: 0.2),
                  AppColors.primaryOrangeDark.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_not_supported, size: 64, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Submission not found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionDetail(SubmissionModel submission) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () =>
                _showFullScreen(submission.imageURL, submission.eventId),
            icon: const Icon(Icons.fullscreen),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          children: [
            // Main image
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    _showFullScreen(submission.imageURL, submission.eventId),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      // Main image
                      CachedNetworkImage(
                        imageUrl: submission.imageURL,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(Icons.error,
                                color: Colors.white, size: 64),
                          ),
                        ),
                      ),
                      // Event information overlay in bottom right
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: _EventInfoOverlay(eventId: submission.eventId),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // User info and actions
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black,
                  ],
                ),
              ),
              child: _SubmissionInfo(submission: submission),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreen(String imageUrl, String eventId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _FullScreenImageViewer(
          imageUrl: imageUrl,
          eventId: eventId,
        ),
      ),
    );
  }
}

class _EventInfoOverlay extends ConsumerWidget {
  final String eventId;

  const _EventInfoOverlay({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider(eventId));

    return eventAsync.when(
      data: (event) => event != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  // Navigate to event detail screen
                  context.push('/event/${event.id}');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryCyan.withValues(alpha: 0.3),
                        AppColors.primaryOrange.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryCyan.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundSecondary.withValues(alpha: 0.3),
              AppColors.backgroundSecondary.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryCyan.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _SubmissionInfo extends ConsumerWidget {
  final SubmissionModel submission;

  const _SubmissionInfo({required this.submission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userDataProvider(submission.uid));
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

    return userDataAsync.when(
      data: (user) => _buildInfo(context, ref, user, currentUser,
          isLikedByCurrentUser, currentLikeCount),
      loading: () => _buildInfo(context, ref, null, currentUser,
          isLikedByCurrentUser, currentLikeCount),
      error: (error, stack) => _buildInfo(context, ref, null, currentUser,
          isLikedByCurrentUser, currentLikeCount),
    );
  }

  Widget _buildInfo(BuildContext context, WidgetRef ref, UserModel? user,
      dynamic currentUser, bool isLikedByCurrentUser, int currentLikeCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryCyan.withValues(alpha: 0.2),
                  AppColors.primaryOrange.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryCyan.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    ClickableUserAvatar(
                      user: user,
                      userId: submission.uid,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClickableUserName(
                            user: user,
                            userId: submission.uid,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _formatSubmissionTime(submission.createdAt),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Show delete option if current user owns the submission
                    if (currentUser != null &&
                        currentUser.uid == submission.uid)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryOrange.withValues(alpha: 0.3),
                              AppColors.primaryOrange.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                AppColors.primaryOrange.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await _showDeleteConfirmationDialog(
                                  context, ref, submission);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.more_vert,
                                color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  children: [
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
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 20,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Consumer(
                              builder: (context, ref, child) {
                                final commentsAsync = ref.watch(
                                    commentsStreamProvider((
                                  eventId: submission.eventId,
                                  submissionId: submission.id
                                )));
                                return commentsAsync.when(
                                  data: (comments) => Text(
                                    comments.length.toString(),
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  loading: () => Text(
                                    '0',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  error: (_, __) => Text(
                                    '0',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSubmissionTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, SubmissionModel submission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String eventId;

  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 64),
                ),
              ),
            ),
          ),
          // Event information overlay in bottom right
          Positioned(
            bottom: 32,
            right: 16,
            child: _EventInfoOverlay(eventId: eventId),
          ),
        ],
      ),
    );
  }
}
