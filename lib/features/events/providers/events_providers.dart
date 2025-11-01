import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/event_model.dart';
import '../data/services/events_service.dart';
import '../../submissions/data/models/submission_model.dart';
import '../../submissions/data/services/submissions_service.dart';
import '../../social/data/models/comment_model.dart';
import '../../social/data/models/like_model.dart';
import '../../social/data/services/social_service.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../home/presentation/providers/category_filter_provider.dart';
import '../../../../core/utils/logger.dart';

// Filter for submission feed
enum SubmissionFilter { mostPopular, newest, oldest }

final submissionFilterProvider = StateProvider<SubmissionFilter>((ref) {
  return SubmissionFilter.mostPopular;
});

// PURE FIREBASE PROVIDERS

// Events stream provider
final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final eventsService = ref.watch(eventsServiceProvider);
  return eventsService.getEventsStream();
});

// Events provider
final eventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final eventsService = ref.watch(eventsServiceProvider);
  return await eventsService.getEvents();
});

// Active event provider
final activeEventProvider = FutureProvider<EventModel?>((ref) async {
  // Watch auth state to ensure this provider refreshes when user signs in/out
  ref.watch(authStateProvider);
  // Watch category filter
  final selectedCategories = ref.watch(categoryFilterProvider);
  final eventsService = ref.watch(eventsServiceProvider);
  final categories = selectedCategories.isEmpty ? null : selectedCategories.toList();
  return await eventsService.getActiveEvent(categories: categories);
});

// Past events provider
final pastEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  // Watch auth state to ensure this provider refreshes when user signs in/out
  ref.watch(authStateProvider);
  final eventsService = ref.watch(eventsServiceProvider);
  return await eventsService.getAllPastEvents();
});

// Paginated past events state notifier
class PaginatedPastEventsNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final EventsService _eventsService;
  final Ref _ref;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  EventModel? _cachedActiveEvent;
  List<String>? _currentCategories;

  PaginatedPastEventsNotifier(this._eventsService, this._ref) : super(const AsyncValue.loading()) {
    loadInitialEvents();
  }

  Future<void> loadInitialEvents() async {
    try {
      state = const AsyncValue.loading();

      // Get current category filter
      final selectedCategories = _ref.read(categoryFilterProvider);
      _currentCategories = selectedCategories.isEmpty ? null : selectedCategories.toList();

      // Use the shared activeEventProvider to avoid duplicate queries
      // Wait for the future to complete to get the cached result
      final activeEventAsync = _ref.read(activeEventProvider);
      if (activeEventAsync is AsyncData<EventModel?>) {
        _cachedActiveEvent = activeEventAsync.value;
      } else {
        // If not loaded yet, wait for it
        _cachedActiveEvent = await _ref.read(activeEventProvider.future);
      }

      final events = await _eventsService.getPaginatedPastEvents(
        limit: 5,
        activeEvent: _cachedActiveEvent,
        categories: _currentCategories,
      );
      _hasMoreData = events.length == 5;
      if (events.isNotEmpty) {
        final snapshot = await FirebaseFirestore.instance
            .collection(EventModel.collectionPath)
            .doc(events.last.id)
            .get();
        _lastDocument = snapshot;
      }
      state = AsyncValue.data(events);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMoreEvents() async {
    if (_isLoadingMore || !_hasMoreData || state.value == null) return;

    try {
      _isLoadingMore = true;
      final currentEvents = state.value!;
      final newEvents = await _eventsService.getPaginatedPastEvents(
        limit: 5,
        lastDocument: _lastDocument,
        activeEvent: _cachedActiveEvent,
        categories: _currentCategories,
      );

      _hasMoreData = newEvents.length == 5;
      if (newEvents.isNotEmpty) {
        final snapshot = await FirebaseFirestore.instance
            .collection(EventModel.collectionPath)
            .doc(newEvents.last.id)
            .get();
        _lastDocument = snapshot;
        state = AsyncValue.data([...currentEvents, ...newEvents]);
      }
    } catch (error, stackTrace) {
      AppLogger.e('Error loading more events', error, stackTrace);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    _lastDocument = null;
    _hasMoreData = true;
    _isLoadingMore = false;
    _cachedActiveEvent = null; // Clear cache on refresh
    await loadInitialEvents();
  }

  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => _isLoadingMore;
}

// Paginated past events provider
final paginatedPastEventsProvider = StateNotifierProvider<PaginatedPastEventsNotifier, AsyncValue<List<EventModel>>>((ref) {
  final eventsService = ref.watch(eventsServiceProvider);
  final notifier = PaginatedPastEventsNotifier(eventsService, ref);

  // Listen to auth state changes and refresh when user signs in/out
  ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
    if (previous?.value != next.value) {
      notifier.refresh();
    }
  });

  // Listen to category filter changes and refresh
  ref.listen<Set<String>>(categoryFilterProvider, (previous, next) {
    if (previous != next) {
      notifier.refresh();
    }
  });

  return notifier;
});

final eventProvider =
    FutureProvider.family<EventModel?, String>((ref, eventId) async {
  final eventsService = ref.watch(eventsServiceProvider);
  return await eventsService.getEvent(eventId);
});

// Submissions providers
final submissionsStreamProvider =
    StreamProvider.family<List<SubmissionModel>, String>((ref, eventId) {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return submissionsService.getSubmissionsStream(eventId);
});

final submissionsProvider =
    FutureProvider.family<List<SubmissionModel>, String>((ref, eventId) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getSubmissions(eventId);
});

// User submissions provider
final userSubmissionsProvider =
    FutureProvider.family<List<SubmissionModel>, String>((ref, userId) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getUserSubmissions(userId);
});

// Comments providers
final commentsStreamProvider = StreamProvider.family<List<CommentModel>,
    ({String eventId, String submissionId})>((ref, params) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getCommentsStream(params.eventId, params.submissionId);
});

final commentsProvider = FutureProvider.family<List<CommentModel>,
    ({String eventId, String submissionId})>((ref, params) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getComments(params.eventId, params.submissionId);
});

// Like status provider
final likeStatusProvider = FutureProvider.family<
    bool,
    ({
      String eventId,
      String submissionId,
      String userId
    })>((ref, params) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.isLikedByUser(
      params.eventId, params.submissionId, params.userId);
});

// Likes stream provider
final likesStreamProvider = StreamProvider.family<List<LikeModel>,
    ({String eventId, String submissionId})>((ref, params) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getLikesStream(params.eventId, params.submissionId);
});

// Like count provider
final likeCountProvider =
    FutureProvider.family<int, ({String eventId, String submissionId})>(
        (ref, params) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getLikeCount(params.eventId, params.submissionId);
});

// Comment count provider
final commentCountProvider =
    FutureProvider.family<int, ({String eventId, String submissionId})>(
        (ref, params) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getCommentCount(
      params.eventId, params.submissionId);
});

// Filtered submissions provider
final filteredSubmissionsProvider =
    Provider.family<AsyncValue<List<SubmissionModel>>, String>((ref, eventId) {
  final submissionsAsync = ref.watch(submissionsProvider(eventId));
  final filter = ref.watch(submissionFilterProvider);

  return submissionsAsync.when(
    data: (submissions) {
      final sortedSubmissions = List<SubmissionModel>.from(submissions);

      switch (filter) {
        case SubmissionFilter.mostPopular:
          sortedSubmissions.sort((a, b) => b.likeCount.compareTo(a.likeCount));
          break;
        case SubmissionFilter.newest:
          sortedSubmissions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case SubmissionFilter.oldest:
          sortedSubmissions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
      }

      return AsyncValue.data(sortedSubmissions);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Submission count providers
final submissionCountProvider =
    FutureProvider.family<int, String>((ref, eventId) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getSubmissionCount(eventId);
});

final userSubmissionCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getUserSubmissionCount(userId);
});

// User activity providers
final userLikeCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getUserLikeCount(userId);
});

final userCommentCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getUserCommentCount(userId);
});

// User data provider
final userDataProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getUserData(userId);
});

// User submissions from user collection provider
final userSubmissionsFromUserCollectionProvider =
    FutureProvider.family<List<SubmissionModel>, String>((ref, userId) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getUserSubmissionsFromUserCollection(userId);
});

// User badges provider (derived from submissions - no extra query)
final userBadgesProvider = Provider.family<List<Map<String, String>>, String>((ref, userId) {
  final submissionsAsync = ref.watch(userSubmissionsFromUserCollectionProvider(userId));

  return submissionsAsync.maybeWhen(
    data: (submissions) {
      final badgeMap = <String, String>{};

      for (final submission in submissions) {
        final badgeURL = submission.badgeURL;
        final eventId = submission.eventId;

        if (badgeURL != null && badgeURL.isNotEmpty && eventId.isNotEmpty) {
          badgeMap[badgeURL] = eventId;
        }
      }

      return badgeMap.entries
          .map((entry) => {'badgeURL': entry.key, 'eventId': entry.value})
          .toList();
    },
    orElse: () => [],
  );
});

// User submission count for event provider
final userSubmissionCountForEventProvider = FutureProvider.family<int, ({String userId, String eventId})>((ref, params) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getUserSubmissionCountForEvent(params.userId, params.eventId);
});

// User liked submission IDs provider
final userLikedSubmissionIdsProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getUserLikedSubmissionIds(userId);
});

// User like count from user collection provider
final userLikeCountFromUserCollectionProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  try {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getUserLikeCountFromUserCollection(userId);
  } catch (e) {
    // Return 0 instead of throwing to prevent UI errors
    return 0;
  }
});

// User liked submissions provider
final userLikedSubmissionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, userId) async {
  try {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getUserLikedSubmissions(userId);
  } catch (e) {
    // Return empty list instead of throwing to prevent UI errors
    return <Map<String, dynamic>>[];
  }
});

// Single submission provider
final submissionProvider = FutureProvider.family<SubmissionModel?,
    ({String eventId, String submissionId})>((ref, params) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getSubmission(
      params.eventId, params.submissionId);
});
