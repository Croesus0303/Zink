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
      _refreshSocialData();
    });
  }

  void _refreshSocialData() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final submissionsAsync = ref.read(submissionsProvider(widget.eventId));
      submissionsAsync.whenData((submissions) {
        for (final submission in submissions) {
          ref.invalidate(likesStreamProvider((eventId: submission.eventId, submissionId: submission.id)));
          ref.invalidate(commentsStreamProvider((eventId: submission.eventId, submissionId: submission.id)));
          ref.invalidate(likeStatusProvider((eventId: submission.eventId, submissionId: submission.id, userId: currentUser.uid)));
          ref.invalidate(likeCountProvider((eventId: submission.eventId, submissionId: submission.id)));
          ref.invalidate(commentCountProvider((eventId: submission.eventId, submissionId: submission.id)));
        }
      });
    }
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
            appBar: AppBar(title: const Text('Event Not Found')),
            body: const Center(
              child: Text('Event not found'),
            ),
          );
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        AppLogger.e('Error loading event details', error, stack);
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error loading event: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(eventsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEventDetail(EventModel event) {

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _EventDetailAppBar(event: event),
          SliverToBoxAdapter(
            child: _EventInfoSection(event: event),
          ),
          SliverToBoxAdapter(
            child: _FilterSection(),
          ),
          _SubmissionsList(eventId: widget.eventId),
        ],
      ),
    );
  }
}

class _EventDetailAppBar extends StatelessWidget {
  final EventModel event;

  const _EventDetailAppBar({required this.event});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: event.referenceImageURL,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (event.isActive)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/submit/${event.id}');
              },
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _EventInfoSection extends StatelessWidget {
  final EventModel event;

  const _EventInfoSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                  color: event.isActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(16),
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
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeRemaining(event.endTime),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            event.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          // Submit button (if active)
          if (event.isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/submit/${event.id}');
                },
                icon: const Icon(Icons.camera_alt),
                label: Text(AppLocalizations.of(context)!.submitPhoto),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.submissions,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
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
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
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
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) {
        AppLogger.e('Error loading submissions', error, stack);
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Text('Error loading submissions: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(submissionsProvider(eventId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmissionsList(BuildContext context, List<SubmissionModel> submissions) {
    if (submissions.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No submissions yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to submit a photo!',
                style: TextStyle(color: Colors.grey[600]),
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
      data: (user) => _buildCard(context, ref, user, currentUser, isLikedByCurrentUser, currentLikeCount),
      loading: () => _buildCard(context, ref, null, currentUser, isLikedByCurrentUser, currentLikeCount),
      error: (error, stack) => _buildCard(context, ref, null, currentUser, isLikedByCurrentUser, currentLikeCount),
    );
  }
  
  Widget _buildCard(BuildContext context, WidgetRef ref, UserModel? user, dynamic currentUser, bool isLikedByCurrentUser, int currentLikeCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info header
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: user?.photoURL != null
                        ? CachedNetworkImageProvider(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Text(
                            user?.displayName.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(fontSize: 14),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _formatSubmissionTime(submission.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Submission image
            AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                imageUrl: submission.imageURL,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
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
                        builder: (context) => CommentSheet(
                          eventId: submission.eventId,
                          submissionId: submission.id,
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
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Comments',
                            style: TextStyle(color: Colors.grey[600]),
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
}