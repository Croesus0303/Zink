import 'package:cloud_firestore/cloud_firestore.dart';

class LikeModel {
  final String submissionId;
  final String uid;
  final DateTime createdAt;

  LikeModel({
    required this.submissionId,
    required this.uid,
    required this.createdAt,
  });

  factory LikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LikeModel(
      submissionId: data['submissionId'] ?? '',
      uid: data['uid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'submissionId': submissionId,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create a composite ID for the like document
  String get id => '${submissionId}_$uid';
}
