import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../events/providers/events_providers.dart';
import '../../../submissions/data/models/submission_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../social/presentation/widgets/like_button.dart';
import '../../../social/presentation/widgets/comment_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/logger.dart';
import '../../../submissions/data/services/submissions_service.dart';

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
  ConsumerState<SingleSubmissionScreen> createState() => _SingleSubmissionScreenState();
}

class _SingleSubmissionScreenState extends ConsumerState<SingleSubmissionScreen> {
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
      ref.invalidate(likesStreamProvider((eventId: widget.eventId, submissionId: widget.submissionId)));
      ref.invalidate(commentsStreamProvider((eventId: widget.eventId, submissionId: widget.submissionId)));
      ref.invalidate(likeStatusProvider((eventId: widget.eventId, submissionId: widget.submissionId, userId: currentUser.uid)));
      ref.invalidate(likeCountProvider((eventId: widget.eventId, submissionId: widget.submissionId)));
      ref.invalidate(commentCountProvider((eventId: widget.eventId, submissionId: widget.submissionId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionAsync = ref.watch(submissionProvider((eventId: widget.eventId, submissionId: widget.submissionId)));
    
    return submissionAsync.when(
      data: (submission) => submission != null 
          ? _buildSubmissionDetail(submission)
          : _buildNotFound(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading submission: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(submissionProvider((eventId: widget.eventId, submissionId: widget.submissionId))),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Scaffold(
      appBar: AppBar(title: const Text('Submission Not Found')),
      body: const Center(
        child: Text('Submission not found'),
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
            onPressed: () => _showFullScreen(submission.imageURL),
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
                onTap: () => _showFullScreen(submission.imageURL),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  child: CachedNetworkImage(
                    imageUrl: submission.imageURL,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 64),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // User info and actions
            Container(
              color: Colors.black,
              child: _SubmissionInfo(submission: submission),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreen(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _FullScreenImageViewer(imageUrl: imageUrl),
      ),
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
    final likesStreamAsync = ref.watch(likesStreamProvider((eventId: submission.eventId, submissionId: submission.id)));
    
    bool isLikedByCurrentUser = false;
    int currentLikeCount = submission.likeCount;
    
    likesStreamAsync.whenData((likes) {
      currentLikeCount = likes.length;
      if (currentUser != null) {
        isLikedByCurrentUser = likes.any((like) => like.uid == currentUser.uid);
      }
    });
    
    return userDataAsync.when(
      data: (user) => _buildInfo(context, ref, user, currentUser, isLikedByCurrentUser, currentLikeCount),
      loading: () => _buildInfo(context, ref, null, currentUser, isLikedByCurrentUser, currentLikeCount),
      error: (error, stack) => _buildInfo(context, ref, null, currentUser, isLikedByCurrentUser, currentLikeCount),
    );
  }
  
  Widget _buildInfo(BuildContext context, WidgetRef ref, UserModel? user, dynamic currentUser, bool isLikedByCurrentUser, int currentLikeCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: user?.photoURL != null
                    ? CachedNetworkImageProvider(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(
                        user?.displayName.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(fontSize: 16),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Unknown User',
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
              if (currentUser != null && currentUser.uid == submission.uid)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      await _showDeleteConfirmationDialog(context, ref, submission);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, color: Colors.white),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          final commentsAsync = ref.watch(commentsStreamProvider((eventId: submission.eventId, submissionId: submission.id)));
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

  Future<void> _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, SubmissionModel submission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
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
        await submissionsService.deleteSubmission(submission.eventId, submission.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
          // Go back to profile or previous screen
          Navigator.of(context).pop();
        }
      } catch (e) {
        AppLogger.e('Error deleting submission ${submission.id}', e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete post')),
          );
        }
      }
    }
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

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
      body: Center(
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
    );
  }
}