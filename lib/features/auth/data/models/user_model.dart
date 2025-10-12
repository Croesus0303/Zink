import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String username;
  final int? age;
  final String? photoURL;
  final Map<String, String> socialLinks;
  final DateTime createdAt;
  final bool isOnboardingComplete;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.username,
    this.age,
    this.photoURL,
    Map<String, String>? socialLinks,
    DateTime? createdAt,
    this.isOnboardingComplete = false,
  })  : socialLinks = socialLinks ?? {},
        createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      username: data['username'] ?? '',
      age: data['age'],
      photoURL: data['photoURL'],
      socialLinks: Map<String, String>.from(data['socialLinks'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnboardingComplete: data['isOnboardingComplete'] ?? false,
    );
  }

  static String get collectionPath => 'users';

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'username': username,
      'age': age,
      'photoURL': photoURL,
      'socialLinks': socialLinks,
      'createdAt': FieldValue.serverTimestamp(),
      'isOnboardingComplete': isOnboardingComplete,
    };
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? username,
    int? age,
    String? photoURL,
    Map<String, String>? socialLinks,
    DateTime? createdAt,
    bool? isOnboardingComplete,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      age: age ?? this.age,
      photoURL: photoURL ?? this.photoURL,
      socialLinks: socialLinks ?? this.socialLinks,
      createdAt: createdAt ?? this.createdAt,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
    );
  }
}
