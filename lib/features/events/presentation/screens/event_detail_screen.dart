import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/events_providers.dart';
import '../../data/models/event_model.dart';
import '../../../submissions/data/models/submission_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../social/presentation/widgets/like_button.dart';
import '../../../social/presentation/widgets/comment_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/logger.dart';
import '../../../submissions/data/services/submissions_service.dart';
import '../../../../shared/widgets/clickable_user_avatar.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_colors.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshEventData();
    });
  }

  void _refreshEventData() {
    // Refresh event data
    ref.refresh(eventsProvider);
    ref.refresh(submissionsProvider(widget.eventId));

    // Refresh social data
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final submissionsAsync = ref.read(submissionsProvider(widget.eventId));
      submissionsAsync.whenData((submissions) {
        for (final submission in submissions) {
          ref.invalidate(likesStreamProvider(
              (eventId: submission.eventId, submissionId: submission.id)));
          ref.invalidate(commentsStreamProvider(
              (eventId: submission.eventId, submissionId: submission.id)));
          ref.invalidate(likeStatusProvider((
            eventId: submission.eventId,
            submissionId: submission.id,
            userId: currentUser.uid
          )));
          ref.invalidate(likeCountProvider(
              (eventId: submission.eventId, submissionId: submission.id)));
          ref.invalidate(commentCountProvider(
              (eventId: submission.eventId, submissionId: submission.id)));
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    _refreshEventData();
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return eventsAsync.when(
      data: (events) {
        try {
          final event = events.firstWhere(
            (e) => e.id == widget.eventId,
            orElse: () => throw Exception('Event not found'),
          );
          return _buildEventDetail(event);
        } catch (e) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Event Not Found',
                  style: TextStyle(color: AppColors.textPrimary)),
              centerTitle: true,
            ),
            body: Container(
              decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
              child: Container(
                decoration:
                    BoxDecoration(gradient: AppColors.radialBackgroundGradient),
                child: const Center(
                  child: Text(
                    'Event not found',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          );
        }
      },
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Loading...',
              style: TextStyle(color: AppColors.textPrimary)),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          child: Container(
            decoration:
                BoxDecoration(gradient: AppColors.radialBackgroundGradient),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan),
            ),
          ),
        ),
      ),
      error: (error, stack) {
        AppLogger.e('Error loading event details', error, stack);
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Error',
                style: TextStyle(color: AppColors.textPrimary)),
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: Container(
              decoration:
                  BoxDecoration(gradient: AppColors.radialBackgroundGradient),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error loading event: $error',
                      style: const TextStyle(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 140,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryCyan.withOpacity(0.8),
                            AppColors.primaryCyanDark.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryCyan.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => ref.refresh(eventsProvider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
        );
      },
    );
  }

  Widget _buildEventDetail(EventModel event) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.11,
        title: null,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.055,
            ),
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width * 0.12,
              minHeight: MediaQuery.of(context).size.width * 0.12,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundDark,
              AppColors.backgroundDark,
              AppColors.backgroundDark,
              AppColors.backgroundDark,
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: RefreshIndicator(
          color: Color(0xFF87ceeb),
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child:
                    SizedBox(height: MediaQuery.of(context).size.height * 0.12),
              ),
              SliverToBoxAdapter(
                child: _UnifiedEventContainer(
                    event: event, eventId: widget.eventId),
              ),
              SliverToBoxAdapter(
                child:
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnifiedEventContainer extends ConsumerWidget {
  final EventModel event;
  final String eventId;

  const _UnifiedEventContainer({required this.event, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(submissionFilterProvider);
    final submissionsAsync = ref.watch(filteredSubmissionsProvider(eventId));

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      padding: const EdgeInsets.all(20.0),
      useCyanAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Header with Image, Title, Description
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: Column(
              children: [
                // Reference photo (main space)
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xFF87ceeb).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: event.referenceImageURL.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: event.referenceImageURL,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primaryCyan,
                                        AppColors.primaryOrange,
                                        AppColors.warmBeige,
                                      ],
                                    ),
                                  ),
                                  child: Center(
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
                                        AppColors.primaryCyan,
                                        AppColors.primaryOrange,
                                        AppColors.warmBeige,
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.photo_camera_outlined,
                                    color: Colors.white,
                                    size:
                                        MediaQuery.of(context).size.width * 0.2,
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryCyan,
                                      AppColors.primaryOrange,
                                      AppColors.warmBeige,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.photo_camera_outlined,
                                  color: Colors.white,
                                  size: MediaQuery.of(context).size.width * 0.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                // Title and description below photo
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: MediaQuery.of(context).size.width * 0.048,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: AppColors.primaryCyan.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.012),
                      Text(
                        event.description,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dynamic Status and Submit Button Section
          AnimatedContainer(
            padding: const EdgeInsets.only(top: 16),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              children: [
                // Status Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: event.isActive
                            ? Color(0xFF87ceeb).withOpacity(0.8)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: event.isActive
                              ? Color(0xFF87ceeb).withOpacity(0.3)
                              : Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        event.isActive ? 'Active' : 'Ended',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (event.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: MediaQuery.of(context).size.width * 0.04,
                              color: Colors.white,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.01),
                            Text(
                              _formatTimeRemaining(event.endTime),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.035,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Dynamic Submit Button Section
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: event.isActive
                      ? MediaQuery.of(context).size.height * 0.1
                      : 0,
                  child: event.isActive
                      ? Column(
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02),
                            Container(
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height * 0.08,
                              decoration: BoxDecoration(
                                color: Color(0xFF87ceeb).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(0xFF87ceeb).withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () =>
                                      context.push('/submit/${event.id}'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.045,
                                        ),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.02),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .submitPhoto,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.035,
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
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Dynamic Divider
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(
              vertical: event.isActive ? 20 : 10,
            ),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Submissions Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.submissions,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: AppColors.primaryCyan.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: AppLocalizations.of(context)!.mostPopular,
                      isSelected: currentFilter == SubmissionFilter.mostPopular,
                      onSelected: () {
                        ref.read(submissionFilterProvider.notifier).state =
                            SubmissionFilter.mostPopular;
                      },
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.025),
                    _FilterChip(
                      label: AppLocalizations.of(context)!.newest,
                      isSelected: currentFilter == SubmissionFilter.newest,
                      onSelected: () {
                        ref.read(submissionFilterProvider.notifier).state =
                            SubmissionFilter.newest;
                      },
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.025),
                    _FilterChip(
                      label: AppLocalizations.of(context)!.oldest,
                      isSelected: currentFilter == SubmissionFilter.oldest,
                      onSelected: () {
                        ref.read(submissionFilterProvider.notifier).state =
                            SubmissionFilter.oldest;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // Submissions List
              submissionsAsync.when(
                data: (submissions) =>
                    _buildSubmissionsList(context, submissions),
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child:
                        CircularProgressIndicator(color: AppColors.primaryCyan),
                  ),
                ),
                error: (error, stack) => _buildErrorWidget(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeRemaining(DateTime endTime) {
    final duration = endTime.difference(DateTime.now());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else if (minutes > 0) {
      return '${minutes}m left';
    } else {
      return 'Ending soon';
    }
  }

  Widget _buildSubmissionsList(
      BuildContext context, List<SubmissionModel> submissions) {
    if (submissions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.25,
              height: MediaQuery.of(context).size.width * 0.25,
              decoration: BoxDecoration(
                color: Color(0xFF87ceeb).withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
                size: MediaQuery.of(context).size.width * 0.12,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              'No submissions yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: MediaQuery.of(context).size.width * 0.04,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: AppColors.primaryCyan.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              'Be the first to submit a photo!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: MediaQuery.of(context).size.width * 0.032,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: submissions
          .map(
            (submission) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _SubmissionCard(submission: submission),
            ),
          )
          .toList(),
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Error loading submissions',
            style: const TextStyle(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryCyan.withOpacity(0.8),
                  AppColors.primaryCyanDark.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryCyan.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => ref.refresh(submissionsProvider(eventId)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 20),
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.8),
                    AppColors.primaryCyanDark.withOpacity(0.9),
                  ],
                )
              : LinearGradient(
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.2),
                    AppColors.primaryCyan.withOpacity(0.1),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryCyan.withOpacity(isSelected ? 0.6 : 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primaryCyan,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
            shadows: isSelected
                ? [
                    Shadow(
                      color: AppColors.primaryCyan.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _SubmissionCard extends ConsumerWidget {
  final SubmissionModel submission;

  const _SubmissionCard({
    required this.submission,
  });

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
      data: (user) => _buildCard(context, ref, user, currentUser,
          isLikedByCurrentUser, currentLikeCount),
      loading: () => _buildCard(context, ref, null, currentUser,
          isLikedByCurrentUser, currentLikeCount),
      error: (error, stack) => _buildCard(context, ref, null, currentUser,
          isLikedByCurrentUser, currentLikeCount),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, UserModel? user,
      dynamic currentUser, bool isLikedByCurrentUser, int currentLikeCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // User info header
          Row(
            children: [
              ClickableUserAvatar(
                user: user,
                userId: submission.uid,
                radius: MediaQuery.of(context).size.width * 0.035,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClickableUserName(
                      user: user,
                      userId: submission.uid,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                      ),
                    ),
                    Text(
                      _formatSubmissionTime(submission.createdAt),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: MediaQuery.of(context).size.width * 0.028,
                      ),
                    ),
                  ],
                ),
              ),
              // Show delete option if current user owns the submission
              if (currentUser != null && currentUser.uid == submission.uid)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
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
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width * 0.045,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          // Submission image
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryCyan,
                    AppColors.primaryOrange,
                    AppColors.warmBeige,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: GestureDetector(
                    onTap: () =>
                        _showFullScreenImage(context, submission.imageURL),
                    child: CachedNetworkImage(
                      imageUrl: submission.imageURL,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF87ceeb).withOpacity(0.3),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 4,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF87ceeb).withOpacity(0.3),
                        ),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          color: Colors.white,
                          size: MediaQuery.of(context).size.width * 0.08,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          // Actions
          Row(
            children: [
              LikeButton(
                eventId: submission.eventId,
                submissionId: submission.id,
                initialLikeCount: currentLikeCount,
                initialIsLiked: isLikedByCurrentUser,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.035),
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
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.03,
                    vertical: MediaQuery.of(context).size.height * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
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
                        'Comments',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: MediaQuery.of(context).size.width * 0.032,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ]),
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
        backgroundColor: AppColors.backgroundSecondary,
        title: const Text(
          'Delete Post',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.primaryCyan),
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }

        // Refresh the submissions list
        ref.invalidate(submissionsProvider(submission.eventId));
        ref.invalidate(submissionsStreamProvider(submission.eventId));
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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _FullScreenImageViewer(imageUrl: imageUrl),
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
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryCyan.withOpacity(0.2),
                AppColors.primaryCyan.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.primaryCyan.withOpacity(0.3), width: 1),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.primaryCyan),
          ),
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
              child: CircularProgressIndicator(color: AppColors.primaryCyan),
            ),
            errorWidget: (context, url, error) => const Center(
              child:
                  Icon(Icons.error, color: AppColors.primaryOrange, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
