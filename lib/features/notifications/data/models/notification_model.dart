import 'package:firebase_database/firebase_database.dart';

enum NotificationType {
  like,
  comment,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final bool seen;
  final DateTime createdAt;
  final DateTime? seenAt;

  // Common fields
  final String? submissionId;
  final String? postOwnerId;
  final String? eventId;

  // Like-specific fields
  final String? likerUserId;
  final String? likerUsername;

  // Comment-specific fields
  final String? commenterUserId;
  final String? commenterUsername;
  final String? commentId;
  final String? commentText;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.seen,
    required this.createdAt,
    this.seenAt,
    this.submissionId,
    this.postOwnerId,
    this.eventId,
    this.likerUserId,
    this.likerUsername,
    this.commenterUserId,
    this.commenterUsername,
    this.commentId,
    this.commentText,
  });

  factory NotificationModel.fromRealtimeDatabase(String id, Map<String, dynamic> data) {
    NotificationType type;
    switch (data['type'] as String) {
      case 'like':
        type = NotificationType.like;
        break;
      case 'comment':
        type = NotificationType.comment;
        break;
      default:
        type = NotificationType.like;
    }

    return NotificationModel(
      id: id,
      type: type,
      title: data['title'] as String,
      message: data['message'] as String,
      seen: data['seen'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      seenAt: data['seenAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['seenAt'] as int) 
          : null,
      submissionId: data['submissionId'] as String?,
      postOwnerId: data['postOwnerId'] as String?,
      eventId: data['eventId'] as String?,
      likerUserId: data['likerUserId'] as String?,
      likerUsername: data['likerUsername'] as String?,
      commenterUserId: data['commenterUserId'] as String?,
      commenterUsername: data['commenterUsername'] as String?,
      commentId: data['commentId'] as String?,
      commentText: data['commentText'] as String?,
    );
  }

  // Convenience factory for creating from DataSnapshot
  factory NotificationModel.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return NotificationModel.fromRealtimeDatabase(snapshot.key!, data);
  }

  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'type': type.name,
      'title': title,
      'message': message,
      'seen': seen,
      'createdAt': createdAt.millisecondsSinceEpoch,
      if (seenAt != null) 'seenAt': seenAt!.millisecondsSinceEpoch,
      if (submissionId != null) 'submissionId': submissionId,
      if (postOwnerId != null) 'postOwnerId': postOwnerId,
      if (eventId != null) 'eventId': eventId,
      if (likerUserId != null) 'likerUserId': likerUserId,
      if (likerUsername != null) 'likerUsername': likerUsername,
      if (commenterUserId != null) 'commenterUserId': commenterUserId,
      if (commenterUsername != null) 'commenterUsername': commenterUsername,
      if (commentId != null) 'commentId': commentId,
      if (commentText != null) 'commentText': commentText,
    };
  }

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    bool? seen,
    DateTime? createdAt,
    DateTime? seenAt,
    String? submissionId,
    String? postOwnerId,
    String? eventId,
    String? likerUserId,
    String? likerUsername,
    String? commenterUserId,
    String? commenterUsername,
    String? commentId,
    String? commentText,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      seen: seen ?? this.seen,
      createdAt: createdAt ?? this.createdAt,
      seenAt: seenAt ?? this.seenAt,
      submissionId: submissionId ?? this.submissionId,
      postOwnerId: postOwnerId ?? this.postOwnerId,
      eventId: eventId ?? this.eventId,
      likerUserId: likerUserId ?? this.likerUserId,
      likerUsername: likerUsername ?? this.likerUsername,
      commenterUserId: commenterUserId ?? this.commenterUserId,
      commenterUsername: commenterUsername ?? this.commenterUsername,
      commentId: commentId ?? this.commentId,
      commentText: commentText ?? this.commentText,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NotificationModel &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.seen == seen &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        title.hashCode ^
        message.hashCode ^
        seen.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, seen: $seen, createdAt: $createdAt)';
  }
}