import 'package:firebase_database/firebase_database.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../../../../core/utils/logger.dart';

class MessagingService {
  final FirebaseDatabase _database;

  MessagingService(this._database);

  DatabaseReference get _chatsRef => _database.ref('chats');
  DatabaseReference get _messagesRef => _database.ref('messages');
  DatabaseReference get _usersRef => _database.ref('users');

  // Get or create a chat between two users
  Future<ChatModel> getOrCreateChat(String currentUserId, String otherUserId) async {
    try {
      final chatId = ChatModel.generateChatId(currentUserId, otherUserId);
      final chatSnapshot = await _chatsRef.child(chatId).get();

      if (chatSnapshot.exists && chatSnapshot.value != null) {
        // Chat exists, load it
        final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map<Object?, Object?>);
        
        // Migrate existing chats that don't have unreadCount field
        if (chatData['unreadCount'] == null) {
          final participants = Map<String, bool>.from(chatData['participants'] as Map<Object?, Object?>);
          final unreadCount = <String, int>{};
          for (final participantId in participants.keys) {
            unreadCount[participantId] = 0;
          }
          
          // Update the chat with the unreadCount field
          await _chatsRef.child(chatId).child('unreadCount').set(unreadCount);
          chatData['unreadCount'] = unreadCount;
          AppLogger.i('Migrated chat $chatId to include unreadCount field');
        }
        
        AppLogger.i('Found existing chat: $chatId');
        return ChatModel.fromMap(chatId, chatData);
      } else {
        // Create new chat only if it doesn't exist
        final newChat = ChatModel(
          id: chatId,
          participants: {
            currentUserId: true,
            otherUserId: true,
          },
          unreadCount: {
            currentUserId: 0,
            otherUserId: 0,
          },
        );

        await _chatsRef.child(chatId).set(newChat.toMap());
        AppLogger.i('Created new chat: $chatId');
        return newChat;
      }
    } catch (e) {
      AppLogger.e('Error getting or creating chat between $currentUserId and $otherUserId', e);
      rethrow;
    }
  }

  // Get all chats for a user
  Stream<List<ChatModel>> getUserChats(String userId) {
    try {
      return _chatsRef
          .orderByChild('participants/$userId')
          .equalTo(true)
          .onValue
          .map((event) {
        final chats = <ChatModel>[];
        
        if (event.snapshot.exists && event.snapshot.value != null) {
          final chatsData = Map<String, dynamic>.from(event.snapshot.value as Map<Object?, Object?>);
          
          for (final entry in chatsData.entries) {
            try {
              final chatData = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              chats.add(ChatModel.fromMap(entry.key.toString(), chatData));
            } catch (e) {
              AppLogger.w('Error parsing chat ${entry.key}: $e');
            }
          }
        }
        
        // Sort by last message timestamp
        chats.sort((a, b) {
          final aTimestamp = a.lastMessage?.timestamp ?? 0;
          final bTimestamp = b.lastMessage?.timestamp ?? 0;
          return bTimestamp.compareTo(aTimestamp);
        });
        
        AppLogger.d('Fetched ${chats.length} chats for user $userId');
        return chats;
      });
    } catch (e) {
      AppLogger.e('Error getting chats for user $userId', e);
      return Stream.error(e);
    }
  }

  // Get messages for a chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    try {
      return _messagesRef
          .child(chatId)
          .orderByChild('timestamp')
          .onValue
          .map((event) {
        final messages = <MessageModel>[];
        
        if (event.snapshot.exists && event.snapshot.value != null) {
          final messagesData = Map<String, dynamic>.from(event.snapshot.value as Map<Object?, Object?>);
          
          for (final entry in messagesData.entries) {
            try {
              final messageData = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              final message = MessageModel.fromMap(entry.key.toString(), messageData);
              AppLogger.d('Parsed message: ${message.text} from ${message.senderId}');
              messages.add(message);
            } catch (e) {
              AppLogger.e('Error parsing message ${entry.key}: $e, data: ${entry.value}');
            }
          }
        }
        
        // Sort by timestamp (newest last for chat UI)
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        AppLogger.d('Fetched ${messages.length} messages for chat $chatId');
        return messages;
      });
    } catch (e) {
      AppLogger.e('Error getting messages for chat $chatId', e);
      return Stream.error(e);
    }
  }

  // Send a message with atomic unread count update
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final messageId = _messagesRef.child(chatId).push().key!;
      
      final message = MessageModel(
        id: messageId,
        senderId: senderId,
        text: text,
        timestamp: timestamp,
      );

      final lastMessage = LastMessage(
        text: text,
        senderId: senderId,
        timestamp: timestamp,
      );

      // Get chat participants to increment unread count for the recipient
      final chatSnapshot = await _chatsRef.child(chatId).get();
      Map<String, dynamic> unreadCountUpdates = {};
      
      if (chatSnapshot.exists) {
        final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
        final participants = Map<String, bool>.from(chatData['participants'] as Map<Object?, Object?>);
        var currentUnreadCount = chatData['unreadCount'] as Map<Object?, Object?>? ?? {};
        
        // Initialize unreadCount if it doesn't exist (migration for existing chats)
        if (currentUnreadCount.isEmpty) {
          currentUnreadCount = {};
          for (final participantId in participants.keys) {
            currentUnreadCount[participantId] = 0;
          }
          // Save the initialized unreadCount
          await _chatsRef.child(chatId).child('unreadCount').set(currentUnreadCount);
        }
        
        // Increment unread count for all participants except the sender
        for (final participantId in participants.keys) {
          if (participantId != senderId) {
            final currentCount = currentUnreadCount[participantId] as int? ?? 0;
            unreadCountUpdates['chats/$chatId/unreadCount/$participantId'] = currentCount + 1;
          }
        }
      }

      // Use atomic transaction to ensure consistency
      final updates = <String, dynamic>{
        'messages/$chatId/$messageId': message.toMap(),
        'chats/$chatId/lastMessage': lastMessage.toMap(),
        ...unreadCountUpdates,
      };

      await _database.ref().update(updates);
      AppLogger.i('Sent message in chat $chatId with unread count updates');
    } catch (e) {
      AppLogger.e('Error sending message in chat $chatId', e);
      rethrow;
    }
  }

  // Update user data in Realtime Database for messaging
  Future<void> updateUserData(String userId, String username, String? profileImageUrl, String? fcmToken) async {
    try {
      final userData = {
        'username': username,
        if (profileImageUrl != null) 'profileImage': profileImageUrl,
        if (fcmToken != null) 'fcmToken': fcmToken,
      };

      await _usersRef.child(userId).update(userData);
      AppLogger.i('Updated user data for messaging: $userId');
    } catch (e) {
      AppLogger.e('Error updating user data for $userId', e);
      rethrow;
    }
  }

  // Get user data from Realtime Database
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final snapshot = await _usersRef.child(userId).get();
      
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      AppLogger.e('Error getting user data for $userId', e);
      return null;
    }
  }

  // Delete a chat and all its messages
  Future<void> deleteChat(String chatId) async {
    try {
      await _database.ref().update({
        'chats/$chatId': null,
        'messages/$chatId': null,
      });
      AppLogger.i('Deleted chat: $chatId');
    } catch (e) {
      AppLogger.e('Error deleting chat $chatId', e);
      rethrow;
    }
  }

  // Mark chat as read - reset unread count atomically
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      // Use atomic transaction to update both readBy and reset unread count
      final updates = <String, dynamic>{
        'chats/$chatId/readBy/$userId': DateTime.now().millisecondsSinceEpoch,
        'chats/$chatId/unreadCount/$userId': 0,
      };

      await _database.ref().update(updates);
      AppLogger.i('Marked chat $chatId as read by $userId and reset unread count');
    } catch (e) {
      AppLogger.e('Error marking chat $chatId as read', e);
      rethrow;
    }
  }

  // Get total unread message count for a user (sum of unread counts from all chats)
  Stream<int> getUnreadMessageCount(String userId) {
    try {
      return _chatsRef
          .orderByChild('participants/$userId')
          .equalTo(true)
          .onValue
          .map((event) {
        int totalUnreadCount = 0;
        
        if (event.snapshot.exists && event.snapshot.value != null) {
          final chatsData = Map<String, dynamic>.from(event.snapshot.value as Map<Object?, Object?>);
          
          for (final entry in chatsData.entries) {
            try {
              final chatData = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              final chat = ChatModel.fromMap(entry.key.toString(), chatData);
              
              // Get unread count directly from chat model
              totalUnreadCount += chat.getUnreadCount(userId);
            } catch (e) {
              AppLogger.w('Error parsing chat ${entry.key} for unread count: $e');
            }
          }
        }
        
        AppLogger.d('User $userId has $totalUnreadCount total unread messages');
        return totalUnreadCount;
      });
    } catch (e) {
      AppLogger.e('Error getting unread count for user $userId', e);
      return Stream.value(0);
    }
  }

  // Get unread message count for a specific chat (using efficient unreadCount field)
  Future<int> getUnreadCountForChat(String chatId, String userId) async {
    try {
      final chat = await _chatsRef.child(chatId).get();
      if (!chat.exists) return 0;
      
      final chatData = Map<String, dynamic>.from(chat.value as Map);
      final chatModel = ChatModel.fromMap(chatId, chatData);
      
      return chatModel.getUnreadCount(userId);
    } catch (e) {
      AppLogger.e('Error getting unread count for chat $chatId', e);
      return 0;
    }
  }

  // Get unread message count for a specific chat (simplified for UI)
  int getUnreadCountForChatSimple(ChatModel chat, String userId) {
    return chat.getUnreadCount(userId);
  }
}

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(FirebaseDatabase.instance);
});