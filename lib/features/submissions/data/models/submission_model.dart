import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String eventId;
  final String uid;
  final String imageURL;
  final String? badgeURL;
  final String? category;
  final DateTime createdAt;
  final int likeCount;

  SubmissionModel({
    required this.id,
    required this.eventId,
    required this.uid,
    required this.imageURL,
    this.badgeURL,
    this.category,
    required this.createdAt,
    this.likeCount = 0,
  });

  factory SubmissionModel.fromFirestore(DocumentSnapshot doc, String eventId) {
    final data = doc.data() as Map<String, dynamic>;
    return SubmissionModel(
      id: doc.id,
      eventId: eventId,
      uid: data['uid'] ?? '',
      imageURL: data['imageURL'] ?? '',
      badgeURL: data['badgeURL'],
      category: data['category'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: data['likeCount'] ?? 0,
    );
  }

  static String getCollectionPath(String eventId) => 'events/$eventId/submissions';

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'imageURL': imageURL,
      if (badgeURL != null) 'badgeURL': badgeURL,
      if (category != null) 'category': category,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': likeCount,
    };
  }

  SubmissionModel copyWith({
    String? id,
    String? eventId,
    String? uid,
    String? imageURL,
    String? badgeURL,
    String? category,
    DateTime? createdAt,
    int? likeCount,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      uid: uid ?? this.uid,
      imageURL: imageURL ?? this.imageURL,
      badgeURL: badgeURL ?? this.badgeURL,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}
