import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String? photoURL;
  final Map<String, String> socialLinks;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.displayName,
    this.photoURL,
    Map<String, String>? socialLinks,
    DateTime? createdAt,
  })  : socialLinks = socialLinks ?? {},
        createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      socialLinks: Map<String, String>.from(data['socialLinks'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'photoURL': photoURL,
      'socialLinks': socialLinks,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? photoURL,
    Map<String, String>? socialLinks,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      socialLinks: socialLinks ?? this.socialLinks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
