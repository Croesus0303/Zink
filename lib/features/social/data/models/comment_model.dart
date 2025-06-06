import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String submissionId;
  final String uid;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.submissionId,
    required this.uid,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      submissionId: data['submissionId'] ?? '',
      uid: data['uid'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'submissionId': submissionId,
      'uid': uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  CommentModel copyWith({
    String? id,
    String? submissionId,
    String? uid,
    String? text,
    DateTime? createdAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      submissionId: submissionId ?? this.submissionId,
      uid: uid ?? this.uid,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
