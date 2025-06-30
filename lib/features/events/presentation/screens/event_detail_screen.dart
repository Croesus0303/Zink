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
              title: const Text('Event Not Found', style: TextStyle(color: AppColors.textPrimary)),
              centerTitle: true,
            ),
            body: Container(
              decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
              child: Container(
                decoration: BoxDecoration(gradient: AppColors.radialBackgroundGradient),
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
          title: const Text('Loading...', style: TextStyle(color: AppColors.textPrimary)),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.radialBackgroundGradient),
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
            title: const Text('Error', style: TextStyle(color: AppColors.textPrimary)),
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: Container(
              decoration: BoxDecoration(gradient: AppColors.radialBackgroundGradient),
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
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => ref.refresh(eventsProvider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
        title: Text(event.title, style: const TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryCyan.withOpacity(0.2),
                AppColors.primaryCyan.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryCyan.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryCyan),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.radialBackgroundGradient),
          child: RefreshIndicator(
            color: AppColors.primaryCyan,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100), // Space for app bar
                ),
                _EventHeaderSection(event: event),
                SliverToBoxAdapter(
                  child: _EventInfoSection(event: event),
                ),
                SliverToBoxAdapter(
                  child: _FilterSection(),
                ),
                _SubmissionsList(eventId: widget.eventId),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventHeaderSection extends StatelessWidget {
  final EventModel event;

  const _EventHeaderSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: GlassContainer(
        margin: const EdgeInsets.all(16),
        borderRadius: 32.0,
        useCyanAccent: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image with glassmorphism styling
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: event.referenceImageURL,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryCyan.withOpacity(0.2),
                              AppColors.primaryOrange.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primaryCyan),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryOrange.withOpacity(0.2),
                              AppColors.primaryCyan.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: const Icon(Icons.error, color: AppColors.primaryOrange, size: 48),
                      ),
                    ),
                    // Glassmorphism gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.primaryCyan.withOpacity(0.3),
                            AppColors.backgroundPrimary.withOpacity(0.8),
                          ],
                          stops: [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),
                    // Submit button overlay
                    if (event.isActive)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryOrange.withOpacity(0.9),
                                AppColors.primaryOrangeDark.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryOrange.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryOrange.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => context.push('/submit/${event.id}'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Submit Photo',
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
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventInfoSection extends StatelessWidget {
  final EventModel event;

  const _EventInfoSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 32.0,
      useOrangeAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and time info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: event.isActive ? [
                      AppColors.primaryCyan.withOpacity(0.8),
                      AppColors.primaryCyanDark.withOpacity(0.9),
                    ] : [
                      AppColors.textSecondary.withOpacity(0.8),
                      AppColors.textSecondary.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: event.isActive ? AppColors.primaryCyan.withOpacity(0.3) : AppColors.textSecondary.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (event.isActive ? AppColors.primaryCyan : AppColors.textSecondary).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryOrange.withOpacity(0.2),
                        AppColors.primaryOrange.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryOrange.withOpacity(0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeRemaining(event.endTime),
                        style: const TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            event.title,
            style: TextStyle(
              color: AppColors.primaryOrange,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            event.description,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Submit button (if active)
          if (event.isActive)
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.8),
                    AppColors.primaryOrangeDark.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/submit/${event.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.submitPhoto,
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
}

class _FilterSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(submissionFilterProvider);

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 32.0,
      useCyanAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.submissions,
            style: TextStyle(
              color: AppColors.primaryCyan,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                const SizedBox(width: 8),
                _FilterChip(
                  label: AppLocalizations.of(context)!.newest,
                  isSelected: currentFilter == SubmissionFilter.newest,
                  onSelected: () {
                    ref.read(submissionFilterProvider.notifier).state =
                        SubmissionFilter.newest;
                  },
                ),
                const SizedBox(width: 8),
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
          gradient: isSelected ? LinearGradient(
            colors: [
              AppColors.primaryCyan.withOpacity(0.8),
              AppColors.primaryCyanDark.withOpacity(0.9),
            ],
          ) : LinearGradient(
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryCyan.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.primaryCyan.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primaryCyan,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
            shadows: isSelected ? [
              Shadow(
                color: AppColors.primaryCyan.withOpacity(0.5),
                blurRadius: 4,
              ),
            ] : null,
          ),
        ),
      ),
    );
  }
}

class _SubmissionsList extends ConsumerWidget {
  final String eventId;

  const _SubmissionsList({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(filteredSubmissionsProvider(eventId));

    return submissionsAsync.when(
      data: (submissions) => _buildSubmissionsList(context, submissions),
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryCyan),
          ),
        ),
      ),
      error: (error, stack) {
        AppLogger.e('Error loading submissions', error, stack);
        return SliverToBoxAdapter(
          child: GlassContainer(
            margin: const EdgeInsets.all(16),
            borderRadius: 32.0,
            useCyanAccent: true,
            child: Column(
              children: [
                Text(
                  'Error loading submissions: $error',
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
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => ref.refresh(submissionsProvider(eventId)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          ),
        );
      },
    );
  }

  Widget _buildSubmissionsList(
      BuildContext context, List<SubmissionModel> submissions) {
    if (submissions.isEmpty) {
      return SliverToBoxAdapter(
        child: GlassContainer(
          margin: const EdgeInsets.all(16),
          borderRadius: 32.0,
          useCyanAccent: true,
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryCyan.withOpacity(0.8),
                      AppColors.primaryCyanDark.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No submissions yet',
                style: TextStyle(
                  color: AppColors.primaryCyan,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: AppColors.primaryCyan.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Be the first to submit a photo!',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final submission = submissions[index];

          return _SubmissionCard(
            submission: submission,
          );
        },
        childCount: submissions.length,
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
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 32.0,
      useOrangeAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClickableUserAvatar(
                  user: user,
                  userId: submission.uid,
                  radius: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClickableUserName(
                        user: user,
                        userId: submission.uid,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      Text(
                        _formatSubmissionTime(submission.createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Show delete option if current user owns the submission
                if (currentUser != null && currentUser.uid == submission.uid)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange.withOpacity(0.2),
                          AppColors.primaryOrange.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryOrange.withOpacity(0.4), width: 1),
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
                      child: const Icon(Icons.more_vert, color: AppColors.primaryOrange),
                    ),
                  ),
              ],
            ),
          ),
          // Submission image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context, submission.imageURL),
                child: CachedNetworkImage(
                  imageUrl: submission.imageURL,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange.withOpacity(0.2),
                          AppColors.primaryCyan.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryOrange),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange.withOpacity(0.2),
                          AppColors.primaryCyan.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.error, color: AppColors.primaryOrange, size: 48),
                  ),
                ),
              ),
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange.withOpacity(0.2),
                          AppColors.primaryOrange.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryOrange.withOpacity(0.4), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 20,
                          color: AppColors.primaryOrange,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Comments',
                          style: TextStyle(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3), width: 1),
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
              child: Icon(Icons.error, color: AppColors.primaryOrange, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
