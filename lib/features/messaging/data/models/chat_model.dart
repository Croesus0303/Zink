class ChatModel {
  final String id;
  final Map<String, bool> participants;
  final LastMessage? lastMessage;

  const ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
  });

  List<String> get participantIds => participants.keys.toList();

  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId);
  }

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatModel(
      id: id,
      participants: Map<String, bool>.from(map['participants'] as Map<Object?, Object?>),
      lastMessage: map['lastMessage'] != null
          ? LastMessage.fromMap(Map<String, dynamic>.from(map['lastMessage'] as Map<Object?, Object?>))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      if (lastMessage != null) 'lastMessage': lastMessage!.toMap(),
    };
  }

  ChatModel copyWith({
    String? id,
    Map<String, bool>? participants,
    LastMessage? lastMessage,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  static String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatModel &&
        other.id == id &&
        _mapEquals(other.participants, participants) &&
        other.lastMessage == lastMessage;
  }

  bool _mapEquals(Map<String, bool> map1, Map<String, bool> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return id.hashCode ^ participants.hashCode ^ lastMessage.hashCode;
  }

  @override
  String toString() {
    return 'ChatModel(id: $id, participants: $participants, lastMessage: $lastMessage)';
  }
}

class LastMessage {
  final String text;
  final String senderId;
  final int timestamp;

  const LastMessage({
    required this.text,
    required this.senderId,
    required this.timestamp,
  });

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(timestamp);

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      text: map['text'] as String,
      senderId: map['senderId'] as String,
      timestamp: map['timestamp'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LastMessage &&
        other.text == text &&
        other.senderId == senderId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return text.hashCode ^ senderId.hashCode ^ timestamp.hashCode;
  }

  @override
  String toString() {
    return 'LastMessage(text: $text, senderId: $senderId, timestamp: $timestamp)';
  }
}