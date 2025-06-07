import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/like_model.dart';
import '../models/comment_model.dart';
import '../../../../core/utils/logger.dart';

class SocialService {
  final FirebaseFirestore _firestore;

  SocialService(this._firestore);

  // LIKES
  Stream<List<LikeModel>> getLikesStream(String submissionId) {
    return _firestore
        .collection('likes')
        .where('submissionId', isEqualTo: submissionId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      AppLogger.d('Fetched ${snapshot.docs.length} likes for submission $submissionId from Firebase');
      return snapshot.docs
          .map((doc) => LikeModel.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      AppLogger.e('Error fetching likes for submission $submissionId from Firebase', error);
      throw error;
    });
  }

  Future<bool> isLikedByUser(String submissionId, String userId) async {
    try {
      final likeId = '${submissionId}_$userId';
      final doc = await _firestore.collection('likes').doc(likeId).get();
      return doc.exists;
    } catch (e) {
      AppLogger.e('Error checking if submission $submissionId is liked by user $userId', e);
      return false;
    }
  }

  Future<void> likeSubmission(String submissionId, String userId) async {
    final batch = _firestore.batch();
    
    try {
      // Create like document
      final likeId = '${submissionId}_$userId';
      final likeRef = _firestore.collection('likes').doc(likeId);
      final like = LikeModel(
        submissionId: submissionId,
        uid: userId,
        createdAt: DateTime.now(),
      );
      
      batch.set(likeRef, like.toFirestore());
      
      // Increment like count on submission
      final submissionRef = _firestore.collection('submissions').doc(submissionId);
      batch.update(submissionRef, {
        'likeCount': FieldValue.increment(1),
      });
      
      await batch.commit();
      AppLogger.i('User $userId liked submission $submissionId');
    } catch (e) {
      AppLogger.e('Error liking submission $submissionId by user $userId', e);
      rethrow;
    }
  }

  Future<void> unlikeSubmission(String submissionId, String userId) async {
    final batch = _firestore.batch();
    
    try {
      // Delete like document
      final likeId = '${submissionId}_$userId';
      final likeRef = _firestore.collection('likes').doc(likeId);
      batch.delete(likeRef);
      
      // Decrement like count on submission
      final submissionRef = _firestore.collection('submissions').doc(submissionId);
      batch.update(submissionRef, {
        'likeCount': FieldValue.increment(-1),
      });
      
      await batch.commit();
      AppLogger.i('User $userId unliked submission $submissionId');
    } catch (e) {
      AppLogger.e('Error unliking submission $submissionId by user $userId', e);
      rethrow;
    }
  }

  Future<int> getLikeCount(String submissionId) async {
    try {
      final snapshot = await _firestore
          .collection('likes')
          .where('submissionId', isEqualTo: submissionId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.e('Error getting like count for submission $submissionId', e);
      return 0;
    }
  }

  // COMMENTS
  Stream<List<CommentModel>> getCommentsStream(String submissionId) {
    return _firestore
        .collection('comments')
        .where('submissionId', isEqualTo: submissionId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      AppLogger.d('Fetched ${snapshot.docs.length} comments for submission $submissionId from Firebase');
      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      AppLogger.e('Error fetching comments for submission $submissionId from Firebase', error);
      throw error;
    });
  }

  Future<List<CommentModel>> getComments(String submissionId) async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('submissionId', isEqualTo: submissionId)
          .orderBy('createdAt', descending: false)
          .get();
      
      AppLogger.d('Fetched ${snapshot.docs.length} comments for submission $submissionId from Firebase');
      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching comments for submission $submissionId from Firebase', e);
      rethrow;
    }
  }

  Future<CommentModel> addComment({
    required String submissionId,
    required String userId,
    required String text,
  }) async {
    try {
      final commentData = {
        'submissionId': submissionId,
        'uid': userId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('comments').add(commentData);
      
      // Return the created comment
      final doc = await docRef.get();
      final comment = CommentModel.fromFirestore(doc);
      
      AppLogger.i('User $userId added comment to submission $submissionId');
      return comment;
    } catch (e) {
      AppLogger.e('Error adding comment to submission $submissionId by user $userId', e);
      rethrow;
    }
  }

  Future<void> updateComment(String commentId, String newText) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'text': newText,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.i('Updated comment $commentId');
    } catch (e) {
      AppLogger.e('Error updating comment $commentId', e);
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
      AppLogger.i('Deleted comment $commentId');
    } catch (e) {
      AppLogger.e('Error deleting comment $commentId', e);
      rethrow;
    }
  }

  Future<int> getCommentCount(String submissionId) async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('submissionId', isEqualTo: submissionId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.e('Error getting comment count for submission $submissionId', e);
      return 0;
    }
  }

  // USER ACTIVITY
  Future<int> getUserLikeCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('likes')
          .where('uid', isEqualTo: userId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.e('Error getting like count for user $userId', e);
      return 0;
    }
  }

  Future<int> getUserCommentCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('uid', isEqualTo: userId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.e('Error getting comment count for user $userId', e);
      return 0;
    }
  }
}

final socialServiceProvider = Provider<SocialService>((ref) {
  return SocialService(FirebaseFirestore.instance);
});