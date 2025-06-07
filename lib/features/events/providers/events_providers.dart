import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/models/event_model.dart';
import '../../submissions/data/models/submission_model.dart';
import '../../social/data/models/comment_model.dart';
import '../../auth/data/models/user_model.dart';

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