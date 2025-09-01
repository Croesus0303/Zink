import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../events/providers/events_providers.dart';
import '../../data/models/comment_model.dart';
import '../../data/services/social_service.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/clickable_user_avatar.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class CommentSheet extends ConsumerStatefulWidget {
  final String eventId;
  final String submissionId;

  const CommentSheet({
    super.key,
    required this.eventId,
    required this.submissionId,
  });

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      CustomSnackBar.showError(context, 'Please sign in to comment');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final socialService = ref.read(socialServiceProvider);

      await socialService.addComment(
        eventId: widget.eventId,
        submissionId: widget.submissionId,
        userId: currentUser.uid,
        text: text,
      );

      _commentController.clear();
      AppLogger.d('Comment added to submission ${widget.submissionId}');

      // Refresh comments by invalidating the provider
      ref.invalidate(commentsStreamProvider(
          (eventId: widget.eventId, submissionId: widget.submissionId)));
    } catch (e) {
      AppLogger.e(
          'Error adding comment to submission ${widget.submissionId}', e);
      if (!mounted) return;
      CustomSnackBar.showError(context, 'Failed to add comment');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsStreamProvider(
        (eventId: widget.eventId, submissionId: widget.submissionId)));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.midnightGreen.withValues(alpha: 0.95),
                AppColors.midnightGreen.withValues(alpha: 0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.01, 
                      bottom: MediaQuery.of(context).size.height * 0.015
                    ),
                    width: MediaQuery.of(context).size.width * 0.1,
                    height: MediaQuery.of(context).size.height * 0.005,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
                    child: Row(
                      children: [
                        commentsAsync.when(
                          data: (comments) => Text(
                            'Comments (${comments.length})',
                            style: TextStyle(
                              color: AppColors.textPrimary,
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
                          loading: () => Text(
                            'Comments',
                            style: TextStyle(
                              color: AppColors.textPrimary,
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
                          error: (_, __) => Text(
                            'Comments',
                            style: TextStyle(
                              color: AppColors.textPrimary,
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
                        ),
                        const Spacer(),
                        Container(
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
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.iceBorder,
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width * 0.045,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.04,
                      vertical: MediaQuery.of(context).size.height * 0.008,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Comments list - flexible
                  Flexible(
                    child: commentsAsync.when(
                  data: (comments) => comments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: MediaQuery.of(context).size.width * 0.12,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                              Text(
                                'No comments yet',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                              Text(
                                'Be the first to comment!',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: MediaQuery.of(context).size.width * 0.035,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return _CommentItem(
                              comment: comment,
                            );
                          },
                        ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.pineGreen),
                  ),
                  error: (error, stack) {
                    AppLogger.e('Error loading comments', error, stack);
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error loading comments: $error',
                            style: TextStyle(
                              color: AppColors.textPrimary,
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
                                onTap: () => ref.refresh(
                                    commentsStreamProvider((
                                  eventId: widget.eventId,
                                  submissionId: widget.submissionId
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
                  Container(
                    height: 1,
                    margin: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.04,
                      vertical: MediaQuery.of(context).size.height * 0.008,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Comment input - fixed at bottom
                  Container(
                    padding: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width * 0.04,
                      right: MediaQuery.of(context).size.width * 0.04,
                      top: MediaQuery.of(context).size.height * 0.01,
                      bottom: MediaQuery.of(context).size.height * 0.015,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.08),
                                  AppColors.pineGreen.withValues(alpha: 0.05),
                                  Colors.white.withValues(alpha: 0.03),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.addComment,
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: MediaQuery.of(context).size.width * 0.035,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: MediaQuery.of(context).size.width * 0.04,
                                  vertical: MediaQuery.of(context).size.height * 0.01,
                                ),
                              ),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: MediaQuery.of(context).size.width * 0.035,
                              ),
                              maxLines: 3,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.send,
                              enabled: !_isSubmitting,
                              onSubmitted: _isSubmitting ? null : (_) => _addComment(),
                            ),
                          ),
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.rosyBrown.withValues(alpha: 0.8),
                                AppColors.rosyBrown.withValues(alpha: 0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: _isSubmitting ? null : _addComment,
                            icon: _isSubmitting
                                ? SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.04,
                                    height: MediaQuery.of(context).size.width * 0.04,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: MediaQuery.of(context).size.width * 0.04,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          ),
        );
      },
    );
  }
}

class _CommentItem extends ConsumerWidget {
  final CommentModel comment;

  const _CommentItem({
    required this.comment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider(comment.uid));

    return userDataAsync.when(
      data: (user) => _buildCommentItem(context, user),
      loading: () => _buildCommentItem(context, null),
      error: (error, stack) => _buildCommentItem(context, null),
    );
  }

  Widget _buildCommentItem(BuildContext context, UserModel? user) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.008),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            AppColors.pineGreen.withValues(alpha: 0.03),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClickableUserAvatar(
            user: user,
            userId: comment.uid,
            radius: MediaQuery.of(context).size.width * 0.04,
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClickableUserName(
                      user: user,
                      userId: comment.uid,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        color: AppColors.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: MediaQuery.of(context).size.width * 0.03,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                Text(
                  comment.text,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
