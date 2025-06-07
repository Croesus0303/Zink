import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/models/event_model.dart';
import '../data/services/events_service.dart';
import '../../submissions/data/models/submission_model.dart';
import '../../submissions/data/services/submissions_service.dart';
import '../../social/data/models/comment_model.dart';
import '../../social/data/services/social_service.dart';
import '../../auth/data/models/user_model.dart';
import '../../../core/utils/logger.dart';

// Mock data providers for UI testing
final mockEventsProvider = Provider<List<EventModel>>((ref) {
  return [
    EventModel(
      id: '1',
      title: 'Morning Coffee Challenge',
      description: 'Capture the perfect morning coffee moment. Show us your favorite coffee setup, whether it\'s a cozy home brew or a cafe visit.',
      referenceImageURL: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400',
      startTime: DateTime.now().subtract(const Duration(hours: 2)),
      endTime: DateTime.now().add(const Duration(minutes: 30)),
    ),
    EventModel(
      id: '2',
      title: 'Urban Architecture',
      description: 'Find beauty in the city! Photograph interesting architectural details, patterns, or unique building features.',
      referenceImageURL: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=400',
      startTime: DateTime.now().subtract(const Duration(hours: 8)),
      endTime: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    EventModel(
      id: '3',
      title: 'Golden Hour Nature',
      description: 'Capture the magic of golden hour in nature. Trees, landscapes, or any natural scene bathed in warm light.',
      referenceImageURL: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
      startTime: DateTime.now().subtract(const Duration(days: 1)),
      endTime: DateTime.now().subtract(const Duration(hours: 18)),
    ),
  ];
});

final mockSubmissionsProvider = Provider.family<List<SubmissionModel>, String>((ref, eventId) {
  return [
    SubmissionModel(
      id: '1',
      eventId: eventId,
      uid: 'user1',
      imageURL: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      likeCount: 15,
    ),
    SubmissionModel(
      id: '2',
      eventId: eventId,
      uid: 'user2',
      imageURL: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      likeCount: 8,
    ),
    SubmissionModel(
      id: '3',
      eventId: eventId,
      uid: 'user3',
      imageURL: 'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=400',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likeCount: 23,
    ),
  ];
});

final mockCommentsProvider = Provider.family<List<CommentModel>, String>((ref, submissionId) {
  return [
    CommentModel(
      id: '1',
      submissionId: submissionId,
      uid: 'user1',
      text: 'Love the composition! ☕',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    CommentModel(
      id: '2',
      submissionId: submissionId,
      uid: 'user2',
      text: 'Perfect lighting 📸',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];
});

final mockUsersProvider = Provider<Map<String, UserModel>>((ref) {
  return {
    'user1': UserModel(
      uid: 'user1',
      displayName: 'Alex Chen',
      photoURL: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
      socialLinks: {'instagram': '@alexchen'},
    ),
    'user2': UserModel(
      uid: 'user2',
      displayName: 'Maria Rodriguez',
      photoURL: 'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=100',
      socialLinks: {'twitter': '@mariarodriguez'},
    ),
    'user3': UserModel(
      uid: 'user3',
      displayName: 'John Smith',
      photoURL: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      socialLinks: {},
    ),
  };
});

// Filter for submission feed
enum SubmissionFilter { mostPopular, newest, oldest }

final submissionFilterProvider = StateProvider<SubmissionFilter>((ref) {
  return SubmissionFilter.mostPopular;
});

final filteredSubmissionsProvider = Provider.family<List<SubmissionModel>, String>((ref, eventId) {
  final submissions = ref.watch(mockSubmissionsProvider(eventId));
  final filter = ref.watch(submissionFilterProvider);

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

  return sortedSubmissions;
});

// Active event provider (latest active or most recent)
final activeEventProvider = Provider<EventModel?>((ref) {
  final events = ref.watch(mockEventsProvider);
  
  // First try to find an active event
  final activeEvents = events.where((event) => event.isActive).toList();
  if (activeEvents.isNotEmpty) {
    return activeEvents.first;
  }
  
  // If no active events, return the most recent one
  final sortedEvents = List<EventModel>.from(events);
  sortedEvents.sort((a, b) => b.startTime.compareTo(a.startTime));
  return sortedEvents.isNotEmpty ? sortedEvents.first : null;
});

// Past events provider
final pastEventsProvider = Provider<List<EventModel>>((ref) {
  final events = ref.watch(mockEventsProvider);
  final pastEvents = events.where((event) => event.isExpired).toList();
  pastEvents.sort((a, b) => b.endTime.compareTo(a.endTime));
  return pastEvents;
});

// FIREBASE PROVIDERS WITH MOCK FALLBACK

// Events stream provider with Firebase fallback to mock data
final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final eventsService = ref.watch(eventsServiceProvider);
  
  return eventsService.getEventsStream().handleError((error) {
    AppLogger.e('Firebase events stream error, falling back to mock data', error);
    // Return mock data stream on error
    return Stream.value(ref.read(mockEventsProvider));
  });
});

// Events provider with Firebase fallback to mock data
final eventsProvider = FutureProvider<List<EventModel>>((ref) async {
  try {
    final eventsService = ref.watch(eventsServiceProvider);
    final events = await eventsService.getEvents();
    
    if (events.isEmpty) {
      AppLogger.d('No events found in Firebase, using mock data');
      return ref.read(mockEventsProvider);
    }
    
    return events;
  } catch (e) {
    AppLogger.e('Error fetching events from Firebase, falling back to mock data', e);
    return ref.read(mockEventsProvider);
  }
});

// Active event provider with Firebase fallback
final firebaseActiveEventProvider = FutureProvider<EventModel?>((ref) async {
  try {
    final eventsService = ref.watch(eventsServiceProvider);
    final activeEvent = await eventsService.getActiveEvent();
    
    if (activeEvent == null) {
      AppLogger.d('No active event found in Firebase, using mock data');
      return ref.read(activeEventProvider);
    }
    
    return activeEvent;
  } catch (e) {
    AppLogger.e('Error fetching active event from Firebase, falling back to mock data', e);
    return ref.read(activeEventProvider);
  }
});

// Past events provider with Firebase fallback
final firebasePastEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  try {
    final eventsService = ref.watch(eventsServiceProvider);
    final pastEvents = await eventsService.getPastEvents();
    
    if (pastEvents.isEmpty) {
      AppLogger.d('No past events found in Firebase, using mock data');
      return ref.read(pastEventsProvider);
    }
    
    return pastEvents;
  } catch (e) {
    AppLogger.e('Error fetching past events from Firebase, falling back to mock data', e);
    return ref.read(pastEventsProvider);
  }
});

// Submissions providers with Firebase fallback
final submissionsStreamProvider = StreamProvider.family<List<SubmissionModel>, String>((ref, eventId) {
  final submissionsService = ref.watch(submissionsServiceProvider);
  
  return submissionsService.getSubmissionsStream(eventId).handleError((error) {
    AppLogger.e('Firebase submissions stream error for event $eventId, falling back to mock data', error);
    return Stream.value(ref.read(mockSubmissionsProvider(eventId)));
  });
});

final submissionsProvider = FutureProvider.family<List<SubmissionModel>, String>((ref, eventId) async {
  try {
    final submissionsService = ref.watch(submissionsServiceProvider);
    final submissions = await submissionsService.getSubmissions(eventId);
    
    if (submissions.isEmpty) {
      AppLogger.d('No submissions found in Firebase for event $eventId, using mock data');
      return ref.read(mockSubmissionsProvider(eventId));
    }
    
    return submissions;
  } catch (e) {
    AppLogger.e('Error fetching submissions from Firebase for event $eventId, falling back to mock data', e);
    return ref.read(mockSubmissionsProvider(eventId));
  }
});

// Comments providers with Firebase fallback
final commentsStreamProvider = StreamProvider.family<List<CommentModel>, String>((ref, submissionId) {
  final socialService = ref.watch(socialServiceProvider);
  
  return socialService.getCommentsStream(submissionId).handleError((error) {
    AppLogger.e('Firebase comments stream error for submission $submissionId, falling back to mock data', error);
    return Stream.value(ref.read(mockCommentsProvider(submissionId)));
  });
});

final commentsProvider = FutureProvider.family<List<CommentModel>, String>((ref, submissionId) async {
  try {
    final socialService = ref.watch(socialServiceProvider);
    final comments = await socialService.getComments(submissionId);
    
    if (comments.isEmpty) {
      AppLogger.d('No comments found in Firebase for submission $submissionId, using mock data');
      return ref.read(mockCommentsProvider(submissionId));
    }
    
    return comments;
  } catch (e) {
    AppLogger.e('Error fetching comments from Firebase for submission $submissionId, falling back to mock data', e);
    return ref.read(mockCommentsProvider(submissionId));
  }
});

// User submissions provider
final userSubmissionsProvider = FutureProvider.family<List<SubmissionModel>, String>((ref, userId) async {
  try {
    final submissionsService = ref.watch(submissionsServiceProvider);
    final submissions = await submissionsService.getUserSubmissions(userId);
    
    if (submissions.isEmpty) {
      AppLogger.d('No submissions found in Firebase for user $userId, using mock data');
      return ref.read(mockSubmissionsProvider('1')); // Use mock data for user
    }
    
    return submissions;
  } catch (e) {
    AppLogger.e('Error fetching user submissions from Firebase for user $userId, falling back to mock data', e);
    return ref.read(mockSubmissionsProvider('1'));
  }
});

// Like status provider
final likeStatusProvider = FutureProvider.family<bool, ({String submissionId, String userId})>((ref, params) async {
  try {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.isLikedByUser(params.submissionId, params.userId);
  } catch (e) {
    AppLogger.e('Error checking like status for submission ${params.submissionId}, defaulting to false', e);
    return false;
  }
});

// Filtered submissions provider with Firebase data
final firebaseFilteredSubmissionsProvider = Provider.family<AsyncValue<List<SubmissionModel>>, String>((ref, eventId) {
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