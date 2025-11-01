import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../events/providers/events_providers.dart';
import '../../../social/presentation/widgets/like_button.dart';
import '../../../social/presentation/widgets/comment_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/clickable_user_avatar.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/tiny_separator_line.dart';
import '../providers/timeline_providers.dart';

class TimelineTab extends ConsumerStatefulWidget {
  final Function(double)? onScrollUpdate;
  final VoidCallback? onScrollToTopTapped;

  const TimelineTab({
    super.key,
    this.onScrollUpdate,
    this.onScrollToTopTapped,
  });

  @override
  ConsumerState<TimelineTab> createState() => TimelineTabState();
}

class TimelineTabState extends ConsumerState<TimelineTab> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentPosition = _scrollController.position.pixels;

    // Notify parent about scroll position changes
    widget.onScrollUpdate?.call(currentPosition);

    // Load more posts when near bottom
    if (currentPosition >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(timelinePostsProvider.notifier).loadMorePosts();
    }

    // Show/hide scroll to top button
    final shouldShow = currentPosition > 300;
    if (shouldShow != _showScrollToTop) {
      setState(() {
        _showScrollToTop = shouldShow;
      });
    }
  }

  void scrollToTop() {
    // Notify parent that scroll-to-top was tapped
    widget.onScrollToTopTapped?.call();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onRefresh() async {
    ref.read(timelinePostsProvider.notifier).refresh();
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      right: false,
      top: false,
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.rosyBrown,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: const [
            _TimelineContent(),
          ],
        ),
      ),
    );
  }

  bool get showScrollToTop => _showScrollToTop;

  Widget _buildTimeline(BuildContext context, List<TimelinePost> posts, TimelinePostsNotifier notifier) {
    if (posts.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyTimeline(context));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= posts.length) {
            // Loading indicator for pagination - only show if actually loading
            if (!notifier.isLoadingMore) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.03),
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
              decoration: BoxDecoration(
                gradient: AppColors.iceGlassGradient,
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                border: Border.all(
                  color: AppColors.iceBorder,
                  width: MediaQuery.of(context).size.width * 0.004,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.rosyBrown,
                      strokeWidth: MediaQuery.of(context).size.width * 0.0075,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    Text(
                      'Loading more posts...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: MediaQuery.of(context).size.width * 0.032,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final post = posts[index];
          return TimelinePostCard(post: post);
        },
        childCount: posts.length + (notifier.hasMoreData ? 1 : 0),
      ),
    );
  }

  Widget _buildEmptyTimeline(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
        decoration: BoxDecoration(
          gradient: AppColors.iceGlassGradient,
          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.08),
          border: Border.all(
            color: AppColors.iceBorder,
            width: MediaQuery.of(context).size.width * 0.004,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.08),
              blurRadius: MediaQuery.of(context).size.width * 0.038,
              offset: Offset(-MediaQuery.of(context).size.width * 0.005, -MediaQuery.of(context).size.width * 0.005),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: MediaQuery.of(context).size.width * 0.038,
              offset: Offset(MediaQuery.of(context).size.width * 0.005, MediaQuery.of(context).size.width * 0.005),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.width * 0.3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.rosyBrown,
                    AppColors.pineGreen.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.075),
              ),
              child: Icon(
                Icons.timeline,
                color: Colors.white,
                size: MediaQuery.of(context).size.width * 0.14,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
            Text(
              AppLocalizations.of(context)!.noPostsYet,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: AppColors.rosyBrown,
                    blurRadius: MediaQuery.of(context).size.width * 0.025,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              AppLocalizations.of(context)!.checkBackLater,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: MediaQuery.of(context).size.width * 0.035,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
        decoration: BoxDecoration(
          gradient: AppColors.iceGlassGradient,
          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.08),
          border: Border.all(
            color: AppColors.iceBorder,
            width: MediaQuery.of(context).size.width * 0.004,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.rosyBrown,
              size: MediaQuery.of(context).size.width * 0.12,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              AppLocalizations.of(context)!.errorLoadingTimeline,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: MediaQuery.of(context).size.width * 0.045,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.rosyBrown,
                    AppColors.pineGreen.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                border: Border.all(
                  color: AppColors.rosyBrown,
                  width: MediaQuery.of(context).size.width * 0.0025,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => ref.read(timelinePostsProvider.notifier).refresh(),
                  borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.06,
                      vertical: MediaQuery.of(context).size.height * 0.015,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: MediaQuery.of(context).size.width * 0.05,
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        Text(
                          AppLocalizations.of(context)!.retry,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
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
    );
  }
}

class _TimelineContent extends ConsumerWidget {
  const _TimelineContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelinePostsAsync = ref.watch(timelinePostsProvider);
    final notifier = ref.read(timelinePostsProvider.notifier);

    return timelinePostsAsync.when(
      data: (posts) {
        final parentState = context.findAncestorStateOfType<TimelineTabState>();
        if (parentState == null) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return parentState._buildTimeline(context, posts, notifier);
      },
      loading: () => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.rosyBrown,
            strokeWidth: MediaQuery.of(context).size.width * 0.01,
          ),
        ),
      ),
      error: (error, stack) {
        final parentState = context.findAncestorStateOfType<TimelineTabState>();
        if (parentState == null) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: parentState._buildErrorWidget(context),
        );
      },
    );
  }
}

class TimelinePostCard extends ConsumerStatefulWidget {
  final TimelinePost post;

  const TimelinePostCard({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<TimelinePostCard> createState() => _TimelinePostCardState();
}

class _TimelinePostCardState extends ConsumerState<TimelinePostCard> {
  Future<void> Function()? _toggleLike;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userDataProvider(widget.post.submission.uid));
    final eventDataAsync = ref.watch(eventProvider(widget.post.submission.eventId));
    final likesStreamAsync = ref.watch(likesStreamProvider(
        (eventId: widget.post.submission.eventId, submissionId: widget.post.submission.id)));

    // Don't render if user data is not loaded yet
    if (userDataAsync.isLoading || !userDataAsync.hasValue || userDataAsync.value == null) {
      return const SizedBox.shrink();
    }

    bool isLikedByCurrentUser = false;
    int currentLikeCount = widget.post.submission.likeCount;

    likesStreamAsync.whenData((likes) {
      currentLikeCount = likes.length;
      if (currentUser != null) {
        isLikedByCurrentUser = likes.any((like) => like.uid == currentUser.uid);
      }
    });

    return Column(
      children: [
        // Main image with user info overlay on top
        AspectRatio(
          aspectRatio: 0.92,
          child: GestureDetector(
            onTap: () => context.push('/submission/${widget.post.submission.eventId}/${widget.post.submission.id}'),
            onDoubleTap: () async {
              if (_toggleLike != null) {
                await _toggleLike!();
              }
            },
            child: Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                  child: CachedNetworkImage(
                    imageUrl: widget.post.submission.imageURL,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        color: AppColors.rosyBrown,
                        strokeWidth: MediaQuery.of(context).size.width * 0.01,
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.error,
                        color: AppColors.rosyBrown,
                        size: MediaQuery.of(context).size.width * 0.16,
                      ),
                    ),
                  ),
                ),
                // User info overlay on top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(MediaQuery.of(context).size.width * 0.04),
                        topRight: Radius.circular(MediaQuery.of(context).size.width * 0.04),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.03,
                      vertical: MediaQuery.of(context).size.height * 0.015,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile photo
                        ClickableUserAvatar(
                          user: userDataAsync.value!,
                          userId: widget.post.submission.uid,
                          radius: MediaQuery.of(context).size.width * 0.05,
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        // Username and date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClickableUserName(
                                user: userDataAsync.value!,
                                userId: widget.post.submission.uid,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
                                  decoration: TextDecoration.none,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.8),
                                      blurRadius: MediaQuery.of(context).size.width * 0.01,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatSubmissionTime(context, widget.post.submission.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: MediaQuery.of(context).size.width * 0.032,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.8),
                                      blurRadius: MediaQuery.of(context).size.width * 0.01,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Event name
                        eventDataAsync.when(
                          data: (event) => event != null
                              ? InkWell(
                                  onTap: () => context.push('/event/${event.id}'),
                                  borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: MediaQuery.of(context).size.width * 0.025,
                                      vertical: MediaQuery.of(context).size.height * 0.0075,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.rosyBrown,
                                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                                    ),
                                    child: Text(
                                      event.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: MediaQuery.of(context).size.width * 0.032,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.015),
        // Action buttons below image
        Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03),
          child: Row(
            children: [
              LikeButton(
                eventId: widget.post.submission.eventId,
                submissionId: widget.post.submission.id,
                initialLikeCount: currentLikeCount,
                initialIsLiked: isLikedByCurrentUser,
                onLikeController: (toggleLike) {
                  _toggleLike = toggleLike;
                },
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.015),
              _CommentButton(
                eventId: widget.post.submission.eventId,
                submissionId: widget.post.submission.id,
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.015),
        // Separator line between objects
        const TinySeparatorLine(),
        SizedBox(height: MediaQuery.of(context).size.height * 0.015),
      ],
    );
  }

  String _formatSubmissionTime(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return AppLocalizations.of(context)!.minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return AppLocalizations.of(context)!.hoursAgo(difference.inHours);
    } else {
      return AppLocalizations.of(context)!.daysAgoShort(difference.inDays);
    }
  }

}

class _CommentButton extends ConsumerWidget {
  final String eventId;
  final String submissionId;

  const _CommentButton({
    required this.eventId,
    required this.submissionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentCountAsync = ref.watch(commentCountProvider(
        (eventId: eventId, submissionId: submissionId)));

    int currentCommentCount = 0;
    commentCountAsync.whenData((count) {
      currentCommentCount = count;
    });

    return InkWell(
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
              eventId: eventId,
              submissionId: submissionId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: MediaQuery.of(context).size.width * 0.06,
              color: Colors.white,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Text(
              '$currentCommentCount',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).size.width * 0.04,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

