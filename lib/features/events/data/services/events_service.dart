import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/event_model.dart';
import '../../../../core/utils/logger.dart';

class EventsService {
  final FirebaseFirestore _firestore;

  EventsService(this._firestore);

  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection(EventModel.collectionPath)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
      AppLogger.d('Fetched ${snapshot.docs.length} events from Firebase');
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      AppLogger.e('Error fetching events from Firebase', error);
      throw error;
    });
  }

  Future<List<EventModel>> getEvents() async {
    try {
      final snapshot = await _firestore
          .collection(EventModel.collectionPath)
          .orderBy('startTime', descending: true)
          .get();
      
      AppLogger.d('Fetched ${snapshot.docs.length} events from Firebase');
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching events from Firebase', e);
      rethrow;
    }
  }

  Future<EventModel?> getEvent(String eventId) async {
    try {
      final doc = await _firestore.collection(EventModel.collectionPath).doc(eventId).get();
      
      if (!doc.exists) {
        AppLogger.w('Event $eventId not found in Firebase');
        return null;
      }
      
      AppLogger.d('Fetched event $eventId from Firebase');
      return EventModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.e('Error fetching event $eventId from Firebase', e);
      rethrow;
    }
  }

  Future<EventModel?> getActiveEvent({List<String>? categories}) async {
    try {
      final now = Timestamp.now();
      Query query = _firestore
          .collection(EventModel.collectionPath)
          .where('startTime', isLessThanOrEqualTo: now)
          .where('endTime', isGreaterThan: now);

      // Add category filter if specified
      if (categories != null && categories.isNotEmpty) {
        query = query.where('category', whereIn: categories);
      }

      final snapshot = await query
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        AppLogger.d('No active events found in Firebase');
        return null;
      }

      AppLogger.d('Found active event in Firebase');
      return EventModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      AppLogger.e('Error fetching active event from Firebase', e);
      rethrow;
    }
  }

  Future<List<EventModel>> getPastEvents({EventModel? activeEvent}) async {
    try {
      final now = Timestamp.now();
      activeEvent ??= await getActiveEvent();

      Query query = _firestore
          .collection(EventModel.collectionPath);

      if (activeEvent != null) {
        // Include all events with start time older than active event's start time
        query = query.where('startTime', isLessThan: Timestamp.fromDate(activeEvent.startTime));
      } else {
        // If no active event, show only ended events
        query = query.where('endTime', isLessThan: now);
      }

      final snapshot = await query
          .orderBy('startTime', descending: true)
          .get();

      AppLogger.d('Fetched ${snapshot.docs.length} past events from Firebase');
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching past events from Firebase', e);
      rethrow;
    }
  }

  Future<List<EventModel>> getAllPastEvents({EventModel? activeEvent}) async {
    try {
      final now = Timestamp.now();
      activeEvent ??= await getActiveEvent();

      Query query = _firestore
          .collection(EventModel.collectionPath);

      if (activeEvent != null) {
        // Include all events with start time older than active event's start time
        query = query.where('startTime', isLessThan: Timestamp.fromDate(activeEvent.startTime));
      } else {
        // If no active event, show only ended events
        query = query.where('endTime', isLessThan: now);
      }

      final snapshot = await query
          .orderBy('startTime', descending: true)
          .get();

      AppLogger.d('Fetched ${snapshot.docs.length} all past events from Firebase');
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching all past events from Firebase', e);
      rethrow;
    }
  }

  Future<List<EventModel>> getPaginatedPastEvents({
    int limit = 5,
    DocumentSnapshot? lastDocument,
    EventModel? activeEvent,
    List<String>? categories,
  }) async {
    try {
      final now = Timestamp.now();
      activeEvent ??= await getActiveEvent(categories: categories);

      Query query = _firestore
          .collection(EventModel.collectionPath);

      if (activeEvent != null) {
        // Include all events with start time older than active event's start time
        query = query.where('startTime', isLessThan: Timestamp.fromDate(activeEvent.startTime));
      } else {
        // If no active event, show only ended events
        query = query.where('endTime', isLessThan: now);
      }

      // Add category filter if specified
      if (categories != null && categories.isNotEmpty) {
        query = query.where('category', whereIn: categories);
      }

      query = query
          .orderBy('startTime', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      AppLogger.d('Fetched ${snapshot.docs.length} paginated past events from Firebase');
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching paginated past events from Firebase', e);
      rethrow;
    }
  }

  Future<void> createEvent(EventModel event) async {
    try {
      await _firestore.collection(EventModel.collectionPath).add(event.toFirestore());
      AppLogger.i('Created event: ${event.title}');
    } catch (e) {
      AppLogger.e('Error creating event', e);
      rethrow;
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(EventModel.collectionPath).doc(eventId).update(updates);
      AppLogger.i('Updated event: $eventId');
    } catch (e) {
      AppLogger.e('Error updating event $eventId', e);
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(EventModel.collectionPath).doc(eventId).delete();
      AppLogger.i('Deleted event: $eventId');
    } catch (e) {
      AppLogger.e('Error deleting event $eventId', e);
      rethrow;
    }
  }
}

final eventsServiceProvider = Provider<EventsService>((ref) {
  return EventsService(FirebaseFirestore.instance);
});