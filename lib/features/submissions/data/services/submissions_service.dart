import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/submission_model.dart';
import '../../../../core/utils/logger.dart';

class SubmissionsService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  SubmissionsService(this._firestore, this._storage);

  Stream<List<SubmissionModel>> getSubmissionsStream(String eventId) {
    return _firestore
        .collection(SubmissionModel.getCollectionPath(eventId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      AppLogger.d(
          'Fetched ${snapshot.docs.length} submissions for event $eventId from Firebase');
      return snapshot.docs
          .map((doc) => SubmissionModel.fromFirestore(doc, eventId))
          .toList();
    }).handleError((error) {
      AppLogger.e(
          'Error fetching submissions for event $eventId from Firebase', error);
      throw error;
    });
  }

  Future<List<SubmissionModel>> getSubmissions(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection(SubmissionModel.getCollectionPath(eventId))
          .orderBy('createdAt', descending: true)
          .get();

      AppLogger.d(
          'Fetched ${snapshot.docs.length} submissions for event $eventId from Firebase');
      return snapshot.docs
          .map((doc) => SubmissionModel.fromFirestore(doc, eventId))
          .toList();
    } catch (e) {
      AppLogger.e(
          'Error fetching submissions for event $eventId from Firebase', e);
      rethrow;
    }
  }

  Future<List<SubmissionModel>> getUserSubmissions(String userId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('submissions')
          .where('uid', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      AppLogger.d(
          'Fetched ${snapshot.docs.length} submissions for user $userId from Firebase');
      final submissions = <SubmissionModel>[];
      for (final doc in snapshot.docs) {
        final eventId = doc.reference.parent.parent!.id;
        submissions.add(SubmissionModel.fromFirestore(doc, eventId));
      }
      return submissions;
    } catch (e) {
      AppLogger.e(
          'Error fetching submissions for user $userId from Firebase', e);
      rethrow;
    }
  }

  Future<SubmissionModel?> getSubmission(
      String eventId, String submissionId) async {
    try {
      final doc = await _firestore
          .collection(SubmissionModel.getCollectionPath(eventId))
          .doc(submissionId)
          .get();

      if (!doc.exists) {
        AppLogger.w('Submission $submissionId not found in Firebase');
        return null;
      }

      AppLogger.d('Fetched submission $submissionId from Firebase');
      return SubmissionModel.fromFirestore(doc, eventId);
    } catch (e) {
      AppLogger.e('Error fetching submission $submissionId from Firebase', e);
      rethrow;
    }
  }

  Future<String> uploadImage(
      File imageFile, String eventId, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final ref = _storage.ref().child('submissions/$eventId/$fileName');

      AppLogger.d('Starting image upload: $fileName');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'eventId': eventId,
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.i('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      AppLogger.e('Error uploading image', e);
      rethrow;
    }
  }

  Future<SubmissionModel> createSubmission({
    required String eventId,
    required String userId,
    required File imageFile,
  }) async {
    try {
      AppLogger.d('Creating submission for event $eventId by user $userId');

      // Upload image first
      final imageUrl = await uploadImage(imageFile, eventId, userId);

      // Get event data to retrieve badgeURL and category
      final eventDoc = await _firestore
          .collection('events')
          .doc(eventId)
          .get();

      String? badgeURL;
      String? category;
      if (eventDoc.exists) {
        final eventData = eventDoc.data() as Map<String, dynamic>;
        badgeURL = eventData['badgeURL'];
        category = eventData['category'];
      }

      // Use batch to create both submission and user reference
      final batch = _firestore.batch();

      // Create submission document
      final submissionRef = _firestore
          .collection(SubmissionModel.getCollectionPath(eventId))
          .doc();
      final submissionData = {
        'eventId': eventId,
        'uid': userId,
        'imageURL': imageUrl,
        if (badgeURL != null) 'badgeURL': badgeURL,
        if (category != null) 'category': category,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
      };
      batch.set(submissionRef, submissionData);

      // Create user submission reference
      final userSubmissionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('submissions')
          .doc(submissionRef.id);
      final userSubmissionData = {
        'eventId': eventId,
        'submissionId': submissionRef.id,
        'imageURL': imageUrl,
        if (badgeURL != null) 'badgeURL': badgeURL,
        if (category != null) 'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      };
      batch.set(userSubmissionRef, userSubmissionData);

      // Commit batch
      await batch.commit();

      // Return the created submission
      final doc = await submissionRef.get();
      final submission = SubmissionModel.fromFirestore(doc, eventId);

      AppLogger.i(
          'Created submission ${submission.id} for event $eventId with user reference');
      return submission;
    } catch (e) {
      AppLogger.e('Error creating submission', e);
      rethrow;
    }
  }

  Future<void> updateSubmission(
      String eventId, String submissionId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(SubmissionModel.getCollectionPath(eventId))
          .doc(submissionId)
          .update(updates);
      AppLogger.i('Updated submission: $submissionId');
    } catch (e) {
      AppLogger.e('Error updating submission $submissionId', e);
      rethrow;
    }
  }

  Future<void> deleteSubmission(String eventId, String submissionId) async {
    try {
      // Get submission to get image URL and user ID for deletion
      final doc = await _firestore
          .collection(SubmissionModel.getCollectionPath(eventId))
          .doc(submissionId)
          .get();
      if (doc.exists) {
        final submission = SubmissionModel.fromFirestore(doc, eventId);

        // Use batch to delete both submission and user reference
        final batch = _firestore.batch();

        // Delete submission document
        batch.delete(doc.reference);

        // Delete user submission reference
        final userSubmissionRef = _firestore
            .collection('users')
            .doc(submission.uid)
            .collection('submissions')
            .doc(submissionId);
        batch.delete(userSubmissionRef);

        // Delete all likes for this submission
        final likesQuery = await _firestore
            .collection('events')
            .doc(eventId)
            .collection('submissions')
            .doc(submissionId)
            .collection('likes')
            .get();

        for (final likeDoc in likesQuery.docs) {
          batch.delete(likeDoc.reference);
          // Also delete from user's likes collection
          final userLikeRef = _firestore
              .collection('users')
              .doc(likeDoc.id)
              .collection('likes')
              .doc(submissionId);
          batch.delete(userLikeRef);
        }

        // Delete all comments for this submission
        final commentsQuery = await _firestore
            .collection('events')
            .doc(eventId)
            .collection('submissions')
            .doc(submissionId)
            .collection('comments')
            .get();

        for (final commentDoc in commentsQuery.docs) {
          batch.delete(commentDoc.reference);
        }

        // Commit batch
        await batch.commit();

        // Delete image from storage
        try {
          final ref = _storage.refFromURL(submission.imageURL);
          await ref.delete();
          AppLogger.d('Deleted image for submission $submissionId');
        } catch (e) {
          AppLogger.w(
              'Could not delete image for submission $submissionId: $e');
        }
      }

      AppLogger.i('Deleted submission: $submissionId with all references');
    } catch (e) {
      AppLogger.e('Error deleting submission $submissionId', e);
      rethrow;
    }
  }

  Future<int> getSubmissionCount(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection(SubmissionModel.getCollectionPath(eventId))
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.e('Error getting submission count for event $eventId', e);
      return 0;
    }
  }

  Future<int> getUserSubmissionCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('submissions')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.e('Error getting submission count for user $userId', e);
      return 0;
    }
  }

  Future<List<SubmissionModel>> getUserSubmissionsFromUserCollection(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('submissions')
          .orderBy('createdAt', descending: true)
          .get();

      AppLogger.d(
          'Fetched ${snapshot.docs.length} submissions from user collection for user $userId');
      final submissions = <SubmissionModel>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final eventId = data['eventId'] as String;
        final submissionId = data['submissionId'] as String;

        // Fetch the actual submission data
        try {
          final submissionDoc = await _firestore
              .collection('events')
              .doc(eventId)
              .collection('submissions')
              .doc(submissionId)
              .get();

          if (submissionDoc.exists) {
            submissions
                .add(SubmissionModel.fromFirestore(submissionDoc, eventId));
          }
        } catch (e) {
          AppLogger.w('Could not fetch submission $submissionId: $e');
        }
      }

      return submissions;
    } catch (e) {
      AppLogger.e(
          'Error fetching user submissions from user collection for $userId',
          e);
      rethrow;
    }
  }

  Future<List<Map<String, String>>> getUserBadges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('submissions')
          .get();

      AppLogger.d(
          'Fetched ${snapshot.docs.length} submissions for badge extraction for user $userId');

      final badgeMap = <String, String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final badgeURL = data['badgeURL'] as String?;
        final eventId = data['eventId'] as String?;

        if (badgeURL != null && badgeURL.isNotEmpty && eventId != null) {
          badgeMap[badgeURL] = eventId;
        }
      }

      final badgesWithEvents = badgeMap.entries
          .map((entry) => {'badgeURL': entry.key, 'eventId': entry.value})
          .toList();
      AppLogger.d('Found ${badgesWithEvents.length} unique badges with event IDs for user $userId');
      return badgesWithEvents;
    } catch (e) {
      AppLogger.e('Error fetching user badges with event IDs for $userId', e);
      return [];
    }
  }

  Future<int> getUserSubmissionCountForEvent(String userId, String eventId) async {
    try {
      // Use main submissions collection for more reliable count
      final mainSnapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('submissions')
          .where('uid', isEqualTo: userId)
          .get();

      return mainSnapshot.docs.length;
    } catch (e) {
      AppLogger.e('Error getting user submission count for event $eventId', e);
      return 0;
    }
  }
}

final submissionsServiceProvider = Provider<SubmissionsService>((ref) {
  return SubmissionsService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
});
