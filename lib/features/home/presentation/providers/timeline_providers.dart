import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../events/data/models/event_model.dart';
import '../../../submissions/data/models/submission_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../core/utils/logger.dart';
import 'category_filter_provider.dart';

// Timeline post model - combines submission with event info
class TimelinePost {
  final SubmissionModel submission;
  final EventModel event;

  TimelinePost({
    required this.submission,
    required this.event,
  });
}

// Timeline posts state notifier
class TimelinePostsNotifier extends StateNotifier<AsyncValue<List<TimelinePost>>> {
  final Ref _ref;
  final int _pageSize = 5;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  List<String>? _currentCategories;

  TimelinePostsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadInitialPosts();
  }
  
  Future<void> loadInitialPosts({bool keepCache = false}) async {
    try {
      // Only show loading state if we don't have cached data
      if (!keepCache) {
        state = const AsyncValue.loading();
      }

      // Get current category filter
      final selectedCategories = _ref.read(categoryFilterProvider);
      _currentCategories = selectedCategories.isEmpty ? null : selectedCategories.toList();

      final posts = await _fetchTimelinePosts(limit: _pageSize);
      // Set hasMoreData based on whether we got a full page
      _hasMoreData = posts.length == _pageSize;

      state = AsyncValue.data(posts);
    } catch (error, stackTrace) {
      AppLogger.e('Error loading initial timeline posts', error, stackTrace);
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<void> loadMorePosts() async {
    if (_isLoadingMore || !_hasMoreData || state.value == null) return;
    
    try {
      _isLoadingMore = true;
      // Trigger UI update to show loading indicator
      state = AsyncValue.data(state.value!);
      final currentPosts = state.value!;
      
      final newPosts = await _fetchTimelinePosts(
        limit: _pageSize, 
        startAfter: _lastDocument
      );
      
      if (newPosts.isNotEmpty) {
        final updatedPosts = [...currentPosts, ...newPosts];
        state = AsyncValue.data(updatedPosts);
        _hasMoreData = newPosts.length == _pageSize;
      } else {
        _hasMoreData = false;
      }
    } catch (error, stackTrace) {
      AppLogger.e('Error loading more timeline posts', error, stackTrace);
    } finally {
      _isLoadingMore = false;
    }
  }
  
  Future<void> refresh() async {
    _lastDocument = null;
    _hasMoreData = true;
    _isLoadingMore = false;
    // Keep cache while refreshing to avoid blank screen
    await loadInitialPosts(keepCache: true);
  }

  Future<List<TimelinePost>> _fetchTimelinePosts({
    int limit = 5,
    DocumentSnapshot? startAfter,
  }) async {
    final timelinePosts = <TimelinePost>[];
    DocumentSnapshot? currentLastDoc = startAfter;

    // Keep fetching until we have enough valid timeline posts OR run out of data
    while (timelinePosts.length < limit) {
      try {
        Query query = FirebaseFirestore.instance
            .collectionGroup('submissions');

        // Add category filter if specified
        if (_currentCategories != null && _currentCategories!.isNotEmpty) {
          query = query.where('category', whereIn: _currentCategories);
        }

        query = query
            .orderBy('createdAt', descending: true)
            .limit(limit * 2); // Fetch more docs to account for filtering

        if (currentLastDoc != null) {
          query = query.startAfterDocument(currentLastDoc);
        }

        final querySnapshot = await query.get();
        if (querySnapshot.docs.isEmpty) {
          break; // No more data available
        }
        
        // Update _lastDocument for pagination
        _lastDocument = querySnapshot.docs.last;
        currentLastDoc = _lastDocument;
        
        // Convert to TimelinePost objects
        for (final doc in querySnapshot.docs) {
          if (timelinePosts.length >= limit) break; // Stop when we have enough
          
          try {
            final eventId = doc.reference.parent.parent!.id;
            
            // Fetch event directly for each submission
            final eventDoc = await FirebaseFirestore.instance
                .collection('events')
                .doc(eventId)
                .get();
            
            if (eventDoc.exists) {
              final event = EventModel.fromFirestore(eventDoc);
              final submission = SubmissionModel.fromFirestore(doc, eventId);
              timelinePosts.add(TimelinePost(
                submission: submission,
                event: event,
              ));
            }
          } catch (e) {
            // Skip invalid submissions
            continue;
          }
        }
        
        // If we got fewer documents than requested, we've reached the end
        if (querySnapshot.docs.length < limit * 2) {
          break;
        }
      } catch (e) {
        AppLogger.e('Error fetching timeline posts', e);
        break;
      }
    }
    
    return timelinePosts;
  }
  
  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => _isLoadingMore;
}

// Timeline posts provider
final timelinePostsProvider = StateNotifierProvider<TimelinePostsNotifier, AsyncValue<List<TimelinePost>>>((ref) {
  final notifier = TimelinePostsNotifier(ref);

  // Listen to auth state changes and refresh when user signs in/out
  ref.listen<AsyncValue<dynamic>>(authStateProvider, (previous, next) {
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

