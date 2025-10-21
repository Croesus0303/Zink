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
import '../providers/timeline_providers.dart';

class TimelineTab extends ConsumerStatefulWidget {
  const TimelineTab({super.key});

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
    // Load more posts when near bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(timelinePostsProvider.notifier).loadMorePosts();
    }

    // Show/hide scroll to top button
    final shouldShow = _scrollController.position.pixels > 300;
    if (shouldShow != _showScrollToTop) {
      setState(() {
        _showScrollToTop = shouldShow;
      });
    }
  }

  void scrollToTop() {
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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: RefreshIndicator(
              color: AppColors.rosyBrown,
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: const [
                  _TimelineContent(),
                  SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
          ),
          // Scroll to top button
          if (_showScrollToTop)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.02,
              right: MediaQuery.of(context).size.width * 0.05,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showScrollToTop ? 1.0 : 0.0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryOrange.withValues(alpha: 0.95),
                          AppColors.rosyBrown.withValues(alpha: 0.95),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: scrollToTop,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: MediaQuery.of(context).size.width * 0.06,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

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
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: AppColors.iceGlassGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.iceBorder,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.rosyBrown,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 12),
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
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TimelinePostCard(post: post),
          );
        },
        childCount: posts.length + (notifier.hasMoreData ? 1 : 0),
      ),
    );
  }

  Widget _buildEmptyTimeline(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          gradient: AppColors.iceGlassGradient,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.iceBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(-2, -2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(2, 2),
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
                    AppColors.rosyBrown.withValues(alpha: 0.4),
                    AppColors.pineGreen.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
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
                    color: AppColors.rosyBrown.withValues(alpha: 0.5),
                    blurRadius: 10,
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
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          gradient: AppColors.iceGlassGradient,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.iceBorder,
            width: 1.5,
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
                    AppColors.rosyBrown.withValues(alpha: 0.8),
                    AppColors.pineGreen.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.rosyBrown.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => ref.read(timelinePostsProvider.notifier).refresh(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.retry,
                          style: const TextStyle(
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
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.rosyBrown,
            strokeWidth: 4,
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

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: AppColors.iceGlassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.iceBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: AppColors.rosyBrown.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and event
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile photo on far left
              ClickableUserAvatar(
                user: userDataAsync.value!,
                userId: widget.post.submission.uid,
                radius: MediaQuery.of(context).size.width * 0.045,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
              // Username centered with profile photo
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.025),
                  child: ClickableUserName(
                    user: userDataAsync.value!,
                    userId: widget.post.submission.uid,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              // Date and event name in right column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Date in top right
                  Text(
                    _formatSubmissionTime(context, widget.post.submission.createdAt),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: MediaQuery.of(context).size.width * 0.032,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.003),
                  // Event name in bottom right
                  eventDataAsync.when(
                    data: (event) => event != null
                        ? InkWell(
                            onTap: () => context.push('/event/${event.id}'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryOrange.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event,
                                    color: AppColors.primaryOrange,
                                    size: MediaQuery.of(context).size.width * 0.03,
                                  ),
                                  SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                                  Text(
                                    event.title,
                                    style: TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontSize: MediaQuery.of(context).size.width * 0.028,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                    loading: () => Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),

          // Post image
          AspectRatio(
            aspectRatio: 0.85, // Make it taller than square (1.0)
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.rosyBrown.withValues(alpha: 0.6),
                    AppColors.pineGreen.withValues(alpha: 0.5),
                    AppColors.midnightGreen.withValues(alpha: 0.4),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(context, widget.post.submission.imageURL),
                    onDoubleTap: () async {
                      if (_toggleLike != null) {
                        await _toggleLike!();
                      }
                    },
                    child: CachedNetworkImage(
                      imageUrl: widget.post.submission.imageURL,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.midnightGreen.withValues(alpha: 0.4),
                              AppColors.rosyBrown.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 4,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.midnightGreen.withValues(alpha: 0.4),
                              AppColors.rosyBrown.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: MediaQuery.of(context).size.width * 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * 0.015),

          // Actions (like and comment)
          Row(
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
        ],
      ),
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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
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
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.03,
          vertical: MediaQuery.of(context).size.height * 0.01,
        ),
        decoration: BoxDecoration(
          color: AppColors.pineGreen.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.pineGreen.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.comment_outlined,
              size: MediaQuery.of(context).size.width * 0.04,
              color: Colors.white,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Text(
              '$currentCommentCount',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: MediaQuery.of(context).size.width * 0.032,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.pineGreen,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
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
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.iceBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(-1, -1),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.pineGreen),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  alignment: Alignment.center,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: AppColors.pineGreen),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.error, color: AppColors.pineGreen, size: 64),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}