import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/models/event_model.dart';
import '../data/services/events_service.dart';
import '../../submissions/data/models/submission_model.dart';
import '../../submissions/data/services/submissions_service.dart';
import '../../social/data/models/comment_model.dart';
import '../../social/data/models/like_model.dart';
import '../../social/data/services/social_service.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../../../core/utils/logger.dart';

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
  final eventsService = ref.watch(eventsServiceProvider);
  return await eventsService.getActiveEvent();
});

// Past events provider
final pastEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final eventsService = ref.watch(eventsServiceProvider);
  return await eventsService.getPastEvents();
});

// Submissions providers
final submissionsStreamProvider = StreamProvider.family<List<SubmissionModel>, String>((ref, eventId) {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return submissionsService.getSubmissionsStream(eventId);
});

final submissionsProvider = FutureProvider.family<List<SubmissionModel>, String>((ref, eventId) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getSubmissions(eventId);
});

// User submissions provider
final userSubmissionsProvider = FutureProvider.family<List<SubmissionModel>, String>((ref, userId) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getUserSubmissions(userId);
});

// Comments providers
final commentsStreamProvider = StreamProvider.family<List<CommentModel>, ({String eventId, String submissionId})>((ref, params) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getCommentsStream(params.eventId, params.submissionId);
});

final commentsProvider = FutureProvider.family<List<CommentModel>, ({String eventId, String submissionId})>((ref, params) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getComments(params.eventId, params.submissionId);
});

// Like status provider
final likeStatusProvider = FutureProvider.family<bool, ({String eventId, String submissionId, String userId})>((ref, params) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.isLikedByUser(params.eventId, params.submissionId, params.userId);
});

// Likes stream provider
final likesStreamProvider = StreamProvider.family<List<LikeModel>, ({String eventId, String submissionId})>((ref, params) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getLikesStream(params.eventId, params.submissionId);
});

// Like count provider
final likeCountProvider = FutureProvider.family<int, ({String eventId, String submissionId})>((ref, params) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getLikeCount(params.eventId, params.submissionId);
});

// Comment count provider
final commentCountProvider = FutureProvider.family<int, ({String eventId, String submissionId})>((ref, params) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getCommentCount(params.eventId, params.submissionId);
});

// Filtered submissions provider
final filteredSubmissionsProvider = Provider.family<AsyncValue<List<SubmissionModel>>, String>((ref, eventId) {
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
final submissionCountProvider = FutureProvider.family<int, String>((ref, eventId) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getSubmissionCount(eventId);
});

final userSubmissionCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getUserSubmissionCount(userId);
});

// User activity providers
final userLikeCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getUserLikeCount(userId);
});

final userCommentCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getUserCommentCount(userId);
});

// User data provider
final userDataProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getUserData(userId);
});

// User submissions from user collection provider
final userSubmissionsFromUserCollectionProvider = FutureProvider.family<List<SubmissionModel>, String>((ref, userId) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getUserSubmissionsFromUserCollection(userId);
});

// User liked submission IDs provider
final userLikedSubmissionIdsProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getUserLikedSubmissionIds(userId);
});

// User like count from user collection provider
final userLikeCountFromUserCollectionProvider = FutureProvider.family<int, String>((ref, userId) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getUserLikeCountFromUserCollection(userId);
});

// User liked submissions provider
final userLikedSubmissionsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final socialService = ref.watch(socialServiceProvider);
  return await socialService.getUserLikedSubmissions(userId);
});

// Single submission provider
final submissionProvider = FutureProvider.family<SubmissionModel?, ({String eventId, String submissionId})>((ref, params) async {
  final submissionsService = ref.watch(submissionsServiceProvider);
  return await submissionsService.getSubmission(params.eventId, params.submissionId);
});