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
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/separator_line.dart';

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
    ref.invalidate(eventProvider(widget.eventId));
    ref.invalidate(submissionsProvider(widget.eventId));

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
    final eventAsync = ref.watch(eventProvider(widget.eventId));

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(AppLocalizations.of(context)!.eventNotFound,
                  style: const TextStyle(color: AppColors.textPrimary)),
              centerTitle: true,
            ),
            body: Center(
              child: Text(
                AppLocalizations.of(context)!.eventNotFound,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
        }

        // For expired events, pre-load submissions to prevent Spotlight flicker
        if (event.isExpired) {
          return _buildExpiredEventWithPreloadedData(event);
        }

        return _buildEventDetail(event);
      },
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
            AppLocalizations.of(context)!.loading,
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
      error: (error, stack) {
        AppLogger.e('Error loading event details', error, stack);
        return Scaffold(
          backgroundColor: AppColors.midnightGreen,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(AppLocalizations.of(context)!.error,
                style: const TextStyle(color: AppColors.textPrimary)),
            centerTitle: true,
          ),
          body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.errorLoadingEvent}: $error',
                      style: const TextStyle(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 140,
                      height: 56,
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.pineGreen.withValues(alpha: 0.3),
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
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              ref.refresh(eventProvider(widget.eventId)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.refresh,
                                    color: Colors.white, size: 20),
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
      },
    );
  }

  Widget _buildExpiredEventWithPreloadedData(EventModel event) {
    final submissionsAsync = ref.watch(submissionsProvider(widget.eventId));

    return submissionsAsync.when(
      data: (submissions) {
        // All data is loaded, show the complete event detail
        return _buildEventDetail(event);
      },
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
            AppLocalizations.of(context)!.loading,
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
      error: (error, stack) {
        AppLogger.e(
            'Error loading submissions for expired event', error, stack);
        return _buildEventDetail(
            event); // Show event detail even if submissions fail
      },
    );
  }

  Widget _buildEventDetail(EventModel event) {
    return Scaffold(
      backgroundColor: AppColors.midnightGreen,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen,
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.065,
        title: Text(
          event.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      ),
      body: RefreshIndicator(
            color: AppColors.pineGreen,
            onRefresh: _onRefresh,
            edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        20,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: _EventDetailWidget(event: event),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.06),
                ),
                const SliverToBoxAdapter(
                  child: SeparatorLine(),
                ),
                SliverToBoxAdapter(
                  child:
                      _SubmissionsWidget(event: event, eventId: widget.eventId),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02),
                ),
              ],
            ),
          ),
    );
  }
}

class _EventDetailWidget extends ConsumerWidget {
  final EventModel event;

  const _EventDetailWidget({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Show reference photo and description unless event is expired AND has submissions
        _buildReferencePhotoSection(context, event, ref),
        // Status and Submit Section
        _buildStatusAndSubmitSection(context, event),
      ],
    );
  }

  Widget _buildReferencePhotoSection(
      BuildContext context, EventModel event, WidgetRef ref) {
    // If event is still active, always show reference photo
    if (!event.isExpired) {
      return _buildFullReferenceSection(context, event);
    }

    // If event has ended, check if there are submissions
    final submissionsAsync = ref.watch(submissionsProvider(event.id));

    return submissionsAsync.when(
      data: (submissions) {
        // If event has ended and has submissions, don't show anything here (winner widget will be shown below with description)
        if (submissions.isNotEmpty) {
          return const SizedBox.shrink();
        }

        // If event has ended but no submissions, show full reference section
        return _buildFullReferenceSection(context, event);
      },
      loading: () => _buildFullReferenceSection(context, event),
      error: (error, stack) => _buildFullReferenceSection(context, event),
    );
  }

  Widget _buildFullReferenceSection(BuildContext context, EventModel event) {
    return Column(
      children: [
        // Reference photo with rounded corners and overlays
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Photo filling entire widget
                event.referenceImageURL.isNotEmpty
                    ? CachedNetworkImage(
                          imageUrl: event.referenceImageURL,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: AppColors.midnightGreenLight,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.pineGreen,
                                strokeWidth: 4,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.midnightGreenLight,
                            child: Icon(
                              Icons.photo_camera_outlined,
                              color: AppColors.rosyBrown,
                              size: MediaQuery.of(context).size.width * 0.15,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.midnightGreenLight,
                          child: Icon(
                            Icons.photo_camera_outlined,
                            color: AppColors.rosyBrown,
                            size: MediaQuery.of(context).size.width * 0.15,
                          ),
                        ),
                // Badge overlay - positioned at top right of reference photo
                if (event.badgeURL != null && event.badgeURL!.isNotEmpty)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.12,
                      height: MediaQuery.of(context).size.width * 0.12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: event.badgeURL!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.rosyBrown.withValues(alpha: 0.7),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.rosyBrown,
                            child: Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width * 0.06,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Active/Ended status tag overlay at top left
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: event.isActive
                          ? AppColors.rosyBrown.withValues(alpha: 0.9)
                          : AppColors.midnightGreenLight.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.isActive
                              ? AppLocalizations.of(context)!.active
                              : AppLocalizations.of(context)!.ended,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (event.isActive) ...<Widget>[
                          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                          Icon(
                            Icons.access_time,
                            size: MediaQuery.of(context).size.width * 0.035,
                            color: Colors.white,
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                          Text(
                            _formatTimeRemaining(context, event.endTime),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: MediaQuery.of(context).size.width * 0.032,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Submit button overlay at center bottom (only for active events)
                if (event.isActive)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.height * 0.06,
                        decoration: BoxDecoration(
                          color: AppColors.pineGreen,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pineGreen.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push('/submit/${event.id}'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: MediaQuery.of(context).size.width * 0.04,
                                  vertical: MediaQuery.of(context).size.height * 0.015),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.submit,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.width * 0.035,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Description below photo
        if (event.description.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              event.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: MediaQuery.of(context).size.width * 0.037,
                fontWeight: FontWeight.w500,
                height: 1.5,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: AppColors.midnightGreen.withValues(alpha: 0.5),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusAndSubmitSection(BuildContext context, EventModel event) {
    // If event has ended, show winner widget
    if (event.isExpired) {
      return _WinnerAnnouncementWidget(eventId: event.id);
    }

    // For active events, return empty widget since status and submit are now overlaid on reference photo
    return const SizedBox.shrink();
  }

  String _formatTimeRemaining(BuildContext context, DateTime endTime) {
    final duration = endTime.difference(DateTime.now());
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      if (hours > 0) {
        // For now, fall back to showing days only since new localizations might not be available yet
        return "${days}d ${hours}h left";
      } else {
        return "${days}d left";
      }
    } else if (hours > 0) {
      return AppLocalizations.of(context)!.hoursLeft(hours, minutes);
    } else if (minutes > 0) {
      return AppLocalizations.of(context)!.minutesLeft(minutes);
    } else {
      return AppLocalizations.of(context)!.endingSoon;
    }
  }
}

class _SubmissionsWidget extends ConsumerWidget {
  final EventModel event;
  final String eventId;

  const _SubmissionsWidget({required this.event, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(submissionFilterProvider);
    final submissionsAsync = ref.watch(filteredSubmissionsProvider(eventId));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Submissions Section Header
          Text(
            AppLocalizations.of(context)!.submissions,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  color: AppColors.rosyBrown.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Filter Chips
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
            data: (submissions) => _buildSubmissionsList(context, submissions),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppColors.rosyBrown),
              ),
            ),
            error: (error, stack) => _buildErrorWidget(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsList(
      BuildContext context, List<SubmissionModel> submissions) {
    if (submissions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.25,
                height: MediaQuery.of(context).size.width * 0.25,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.rosyBrown.withValues(alpha: 0.4),
                      AppColors.pineGreen.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.12,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Text(
                AppLocalizations.of(context)!.noSubmissionsYet,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: AppColors.rosyBrown.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Text(
                AppLocalizations.of(context)!.beFirstToSubmit,
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
        ),
      );
    }

    return Column(
      children: submissions
          .map(
            (submission) => _SubmissionCard(submission: submission),
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
            AppLocalizations.of(context)!.errorLoadingSubmissions,
            style: const TextStyle(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
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
                onTap: () => ref.refresh(submissionsProvider(eventId)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          color: isSelected
              ? AppColors.rosyBrown
              : AppColors.pineGreen.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.rosyBrown
                : AppColors.pineGreen.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SubmissionCard extends ConsumerStatefulWidget {
  final SubmissionModel submission;

  const _SubmissionCard({
    required this.submission,
  });

  @override
  ConsumerState<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends ConsumerState<_SubmissionCard> {
  Future<void> Function()? _toggleLike;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userDataProvider(widget.submission.uid));
    final likesStreamAsync = ref.watch(likesStreamProvider((
      eventId: widget.submission.eventId,
      submissionId: widget.submission.id
    )));
    final commentCountAsync = ref.watch(commentCountProvider((
      eventId: widget.submission.eventId,
      submissionId: widget.submission.id
    )));

    bool isLikedByCurrentUser = false;
    int currentLikeCount = widget.submission.likeCount;
    int currentCommentCount = 0;

    likesStreamAsync.whenData((likes) {
      currentLikeCount = likes.length;
      if (currentUser != null) {
        isLikedByCurrentUser = likes.any((like) => like.uid == currentUser.uid);
      }
    });

    commentCountAsync.whenData((count) {
      currentCommentCount = count;
    });

    return userDataAsync.when(
      data: (user) => _buildCard(context, ref, user, currentUser,
          isLikedByCurrentUser, currentLikeCount, currentCommentCount),
      loading: () => _buildCard(context, ref, null, currentUser,
          isLikedByCurrentUser, currentLikeCount, currentCommentCount),
      error: (error, stack) => _buildCard(context, ref, null, currentUser,
          isLikedByCurrentUser, currentLikeCount, currentCommentCount),
    );
  }

  Widget _buildCard(
      BuildContext context,
      WidgetRef ref,
      UserModel? user,
      dynamic currentUser,
      bool isLikedByCurrentUser,
      int currentLikeCount,
      int currentCommentCount) {
    return Column(
      children: [
        Stack(
          children: [
            // Full width image
            AspectRatio(
              aspectRatio: 0.85,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(
                      context, widget.submission.imageURL),
                  onDoubleTap: () async {
                    if (_toggleLike != null) {
                      await _toggleLike!();
                    }
                  },
                  child: CachedNetworkImage(
                    imageUrl: widget.submission.imageURL,
                    fit: BoxFit.cover,
                    width: double.infinity,
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

            // Top overlay with user info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile photo
                      ClickableUserAvatar(
                        user: user,
                        userId: widget.submission.uid,
                        radius: MediaQuery.of(context).size.width * 0.05,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                      // Username and date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClickableUserName(
                              user: user,
                              userId: widget.submission.uid,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: MediaQuery.of(context).size.width * 0.04,
                                decoration: TextDecoration.none,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatSubmissionTime(
                                  context, widget.submission.createdAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: MediaQuery.of(context).size.width * 0.032,
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
                      // Delete button for own submissions
                      if (currentUser != null &&
                          currentUser.uid == widget.submission.uid)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              await _showDeleteConfirmationDialog(
                                  context, ref, widget.submission);
                            },
                            icon: Icon(
                              Icons.delete,
                              color: AppColors.rosyBrown,
                              size: MediaQuery.of(context).size.width * 0.05,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom overlay with action buttons
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      LikeButton(
                        eventId: widget.submission.eventId,
                        submissionId: widget.submission.id,
                        initialLikeCount: currentLikeCount,
                        initialIsLiked: isLikedByCurrentUser,
                        onLikeController: (toggleLike) {
                          _toggleLike = toggleLike;
                        },
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.015),
                      _CommentButton(
                        eventId: widget.submission.eventId,
                        submissionId: widget.submission.id,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Separator line with padding
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            height: 1,
            color: AppColors.midnightGreenLight,
          ),
        ),
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
            color: AppColors.midnightGreen.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.pineGreen.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.deletePost,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.sureDeletePost,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.rosyBrown.withValues(alpha: 0.8),
                            AppColors.rosyBrown,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).pop(true),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.delete,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
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
          CustomSnackBar.showSuccess(
              context, AppLocalizations.of(context)!.postDeletedSuccessfully);
        }

        // Refresh the submissions list and submission count
        ref.invalidate(submissionsProvider(submission.eventId));
        ref.invalidate(submissionsStreamProvider(submission.eventId));
        ref.invalidate(userSubmissionCountForEventProvider(
            (userId: submission.uid, eventId: submission.eventId)));
      } catch (e) {
        AppLogger.e('Error deleting submission ${submission.id}', e);
        if (context.mounted) {
          CustomSnackBar.showError(
              context, AppLocalizations.of(context)!.failedToDeletePost);
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

class _WinnerAnnouncementWidget extends ConsumerWidget {
  final String eventId;

  const _WinnerAnnouncementWidget({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(submissionsProvider(eventId));
    final eventAsync = ref.watch(eventProvider(eventId));

    return submissionsAsync.when(
      data: (submissions) {
        // If no submissions, show the regular status section
        if (submissions.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.midnightGreenLight.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ended',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Determine winner synchronously since submissions are already loaded
        try {
          final winnerSubmission = _determineWinnerSync(submissions, ref);
          return eventAsync.when(
            data: (event) => _buildWinnerWidget(context, ref, winnerSubmission, event),
            loading: () => _buildWinnerWidget(context, ref, winnerSubmission, null),
            error: (_, __) => _buildWinnerWidget(context, ref, winnerSubmission, null),
          );
        } catch (e) {
          // If there's an error determining the winner, show ended status
          return Container(
            margin: const EdgeInsets.only(top: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.midnightGreenLight.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.ended,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      loading: () => Container(
        margin: const EdgeInsets.only(top: 20),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.pineGreen),
        ),
      ),
      error: (error, stack) => Container(
        margin: const EdgeInsets.only(top: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.midnightGreen.withValues(alpha: 0.9),
                AppColors.midnightGreen.withValues(alpha: 0.7),
                AppColors.midnightGreen.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.ended,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SubmissionModel _determineWinnerSync(
      List<SubmissionModel> submissions, WidgetRef ref) {
    if (submissions.isEmpty) {
      throw Exception('No submissions available');
    }

    // Create a list of submissions with their like counts
    // For the synchronous version, we'll use the like count from the submission model
    // and sort primarily by likes, then by creation time
    final sortedSubmissions = List<SubmissionModel>.from(submissions);

    sortedSubmissions.sort((a, b) {
      // Rule 1: Most likes wins
      if (a.likeCount != b.likeCount) {
        return b.likeCount.compareTo(a.likeCount);
      }

      // Rule 2: If likes are tied, earliest upload wins (simplified rule)
      return a.createdAt.compareTo(b.createdAt);
    });

    return sortedSubmissions.first;
  }

  Widget _buildWinnerWidget(
      BuildContext context, WidgetRef ref, SubmissionModel winnerSubmission, EventModel? event) {
    final userDataAsync = ref.watch(userDataProvider(winnerSubmission.uid));

    return Column(
      children: [
        // Winner photo with overlays - matching reference photo dimensions
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Full photo
                GestureDetector(
                  onTap: () => _showFullScreenImage(
                      context, winnerSubmission.imageURL),
                  child: CachedNetworkImage(
                    imageUrl: winnerSubmission.imageURL,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: AppColors.midnightGreenLight,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.pineGreen,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.midnightGreenLight,
                      child: Icon(
                        Icons.broken_image,
                        color: AppColors.rosyBrown,
                        size: MediaQuery.of(context).size.width * 0.15,
                      ),
                    ),
                  ),
                ),
                // Dark overlay for text readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                // Spotlight label at top
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.rosyBrown.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.spotlight.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.032,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                // User info at bottom
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: userDataAsync.when(
              data: (user) => Row(
                children: [
                  ClickableUserAvatar(
                    user: user,
                    userId: winnerSubmission.uid,
                    radius: MediaQuery.of(context).size.width * 0.05,
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  Expanded(
                    child: ClickableUserName(
                      user: user,
                      userId: winnerSubmission.uid,
                      style: TextStyle(
                        color: const Color(0xFF80CBC4),
                        fontSize: MediaQuery.of(context).size.width * 0.042,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 3,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1E1E1E).withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: const Color(0xFFFF6F61),
                          size: MediaQuery.of(context).size.width * 0.035,
                          shadows: [
                            Shadow(
                              color: const Color(0xFFFF6F61)
                                  .withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.01),
                        Text(
                          '${winnerSubmission.likeCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width * 0.036,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 2,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              loading: () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.1,
                    height: MediaQuery.of(context).size.width * 0.1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.pineGreen.withValues(alpha: 0.3),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.pineGreen.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.25,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.rosyBrown.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              error: (error, stack) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.1,
                    height: MediaQuery.of(context).size.width * 0.1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.pineGreen.withValues(alpha: 0.6),
                          AppColors.rosyBrown.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width * 0.05,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.anonymousWinner,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 2,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          AppLocalizations.of(context)!.championOfEvent,
                          style: TextStyle(
                            color:
                                AppColors.rosyBrown.withValues(alpha: 0.9),
                            fontSize: MediaQuery.of(context).size.width * 0.03,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
        ),
        // Description below photo
        if (event != null && event.description.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              event.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: MediaQuery.of(context).size.width * 0.037,
                fontWeight: FontWeight.w500,
                height: 1.5,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: AppColors.midnightGreen.withValues(alpha: 0.5),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
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
            border: Border.all(color: AppColors.pineGreen.withValues(alpha: 0.3), width: 1),
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
