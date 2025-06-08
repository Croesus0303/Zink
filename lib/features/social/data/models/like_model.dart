import 'package:cloud_firestore/cloud_firestore.dart';

class LikeModel {
  final String uid;
  final DateTime likedAt;

  LikeModel({
    required this.uid,
    required this.likedAt,
  });

  factory LikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LikeModel(
      uid: doc.id,
      likedAt: (data['likedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static String getCollectionPath(String eventId, String submissionId) => 
      'events/$eventId/submissions/$submissionId/likes';

  Map<String, dynamic> toFirestore() {
    return {
      'likedAt': FieldValue.serverTimestamp(),
    };
  }
}
