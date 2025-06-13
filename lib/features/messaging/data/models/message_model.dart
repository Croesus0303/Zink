class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final int timestamp;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(timestamp);

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] as String,
      text: map['text'] as String,
      timestamp: map['timestamp'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? text,
    int? timestamp,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel &&
        other.id == id &&
        other.senderId == senderId &&
        other.text == text &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        senderId.hashCode ^
        text.hashCode ^
        timestamp.hashCode;
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, text: $text, timestamp: $timestamp)';
  }
}