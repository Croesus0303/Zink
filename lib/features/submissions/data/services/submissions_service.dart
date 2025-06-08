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
      AppLogger.d('Fetched ${snapshot.docs.length} submissions for event $eventId from Firebase');
      return snapshot.docs
          .map((doc) => SubmissionModel.fromFirestore(doc, eventId))
          .toList();
    }).handleError((error) {
      AppLogger.e('Error fetching submissions for event $eventId from Firebase', error);
      throw error;
    });
  }

  Future<List<SubmissionModel>> getSubmissions(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection(SubmissionModel.getCollectionPath(eventId))
          .orderBy('createdAt', descending: true)
          .get();
      
      AppLogger.d('Fetched ${snapshot.docs.length} submissions for event $eventId from Firebase');
      return snapshot.docs
          .map((doc) => SubmissionModel.fromFirestore(doc, eventId))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching submissions for event $eventId from Firebase', e);
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
      
      AppLogger.d('Fetched ${snapshot.docs.length} submissions for user $userId from Firebase');
      final submissions = <SubmissionModel>[];
      for (final doc in snapshot.docs) {
        final eventId = doc.reference.parent.parent!.id;
        submissions.add(SubmissionModel.fromFirestore(doc, eventId));
      }
      return submissions;
    } catch (e) {
      AppLogger.e('Error fetching submissions for user $userId from Firebase', e);
      rethrow;
    }
  }

  Future<SubmissionModel?> getSubmission(String eventId, String submissionId) async {
    try {
      final doc = await _firestore.collection(SubmissionModel.getCollectionPath(eventId)).doc(submissionId).get();
      
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

  Future<String> uploadImage(File imageFile, String eventId, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${userId}.jpg';
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
      
      // Create submission document
      final submissionData = {
        'eventId': eventId,
        'uid': userId,
        'imageURL': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
      };

      final docRef = await _firestore.collection(SubmissionModel.getCollectionPath(eventId)).add(submissionData);
      
      // Return the created submission
      final doc = await docRef.get();
      final submission = SubmissionModel.fromFirestore(doc, eventId);
      
      AppLogger.i('Created submission ${submission.id} for event $eventId');
      return submission;
    } catch (e) {
      AppLogger.e('Error creating submission', e);
      rethrow;
    }
  }

  Future<void> updateSubmission(String eventId, String submissionId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(SubmissionModel.getCollectionPath(eventId)).doc(submissionId).update(updates);
      AppLogger.i('Updated submission: $submissionId');
    } catch (e) {
      AppLogger.e('Error updating submission $submissionId', e);
      rethrow;
    }
  }

  Future<void> deleteSubmission(String eventId, String submissionId) async {
    try {
      // Get submission to get image URL for deletion
      final doc = await _firestore.collection(SubmissionModel.getCollectionPath(eventId)).doc(submissionId).get();
      if (doc.exists) {
        final submission = SubmissionModel.fromFirestore(doc, eventId);
        
        // Delete image from storage
        try {
          final ref = _storage.refFromURL(submission.imageURL);
          await ref.delete();
          AppLogger.d('Deleted image for submission $submissionId');
        } catch (e) {
          AppLogger.w('Could not delete image for submission $submissionId: $e');
        }
      }
      
      // Delete submission document
      await _firestore.collection(SubmissionModel.getCollectionPath(eventId)).doc(submissionId).delete();
      AppLogger.i('Deleted submission: $submissionId');
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
          .collectionGroup('submissions')
          .where('uid', isEqualTo: userId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.e('Error getting submission count for user $userId', e);
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