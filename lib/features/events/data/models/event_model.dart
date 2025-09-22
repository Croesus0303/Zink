import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String referenceImageURL;
  final String? badgeURL;
  final DateTime startTime;
  final DateTime endTime;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.referenceImageURL,
    this.badgeURL,
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
      badgeURL: data['badgeURL'],
      startTime: _parseTimestamp(data['startTime']),
      endTime: _parseTimestamp(data['endTime']),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      throw ArgumentError('Invalid timestamp format: $timestamp');
    }
  }

  static String get collectionPath => 'events';

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'referenceImageURL': referenceImageURL,
      if (badgeURL != null) 'badgeURL': badgeURL,
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

  bool get shouldShowSpotlight {
    final spotlightTime = startTime.add(const Duration(hours: 6));
    return DateTime.now().isAfter(spotlightTime);
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
    String? badgeURL,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      referenceImageURL: referenceImageURL ?? this.referenceImageURL,
      badgeURL: badgeURL ?? this.badgeURL,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
