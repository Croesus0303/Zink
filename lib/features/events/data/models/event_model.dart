import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String referenceImageURL;
  final DateTime startTime;
  final DateTime endTime;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.referenceImageURL,
    required this.startTime,
    required this.endTime,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      referenceImageURL: data['referenceImageURL'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
    );
  }

  static String get collectionPath => 'events';

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'referenceImageURL': referenceImageURL,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isExpired {
    return DateTime.now().isAfter(endTime);
  }

  Duration get remainingTime {
    if (isExpired) return Duration.zero;
    return endTime.difference(DateTime.now());
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? referenceImageURL,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      referenceImageURL: referenceImageURL ?? this.referenceImageURL,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
