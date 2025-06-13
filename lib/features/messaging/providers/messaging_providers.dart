import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/models/message_model.dart';
import '../data/models/chat_model.dart';
import '../data/services/messaging_service.dart';
import '../../auth/providers/auth_providers.dart';

// User chats stream provider
final userChatsProvider = StreamProvider.autoDispose<List<ChatModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  final messagingService = ref.watch(messagingServiceProvider);
  return messagingService.getUserChats(currentUser.uid);
});

// Chat messages stream provider
final chatMessagesProvider = StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, chatId) {
  final messagingService = ref.watch(messagingServiceProvider);
  return messagingService.getChatMessages(chatId);
});

// Get or create chat provider
final getOrCreateChatProvider = FutureProvider.autoDispose.family<ChatModel, String>((ref, otherUserId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    throw Exception('User not authenticated');
  }

  final messagingService = ref.watch(messagingServiceProvider);
  return messagingService.getOrCreateChat(currentUser.uid, otherUserId);
});

// Send message provider
final sendMessageProvider = Provider.autoDispose<Future<void> Function(String, String)>((ref) {
  return (String chatId, String text) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final messagingService = ref.read(messagingServiceProvider);
    await messagingService.sendMessage(chatId, currentUser.uid, text);
  };
});

// Update user messaging data provider
final updateUserMessagingDataProvider = Provider.autoDispose<Future<void> Function(String?, String?)>((ref) {
  return (String? profileImageUrl, String? fcmToken) async {
    final currentUser = ref.read(currentUserProvider);
    final currentUserData = ref.read(currentUserDataProvider);
    
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final userData = currentUserData.value;
    if (userData == null) {
      throw Exception('User data not available');
    }

    final messagingService = ref.read(messagingServiceProvider);
    await messagingService.updateUserData(
      currentUser.uid,
      userData.displayName ?? 'Unknown User',
      profileImageUrl ?? userData.photoURL,
      fcmToken,
    );
  };
});

// Get messaging user data provider
final messagingUserDataProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, userId) async {
  final messagingService = ref.watch(messagingServiceProvider);
  return messagingService.getUserData(userId);
});

// Delete chat provider
final deleteChatProvider = Provider.autoDispose<Future<void> Function(String)>((ref) {
  return (String chatId) async {
    final messagingService = ref.read(messagingServiceProvider);
    await messagingService.deleteChat(chatId);
    
    // Refresh user chats after deletion
    ref.invalidate(userChatsProvider);
  };
});

// Mark chat as read provider
final markChatAsReadProvider = Provider.autoDispose<Future<void> Function(String)>((ref) {
  return (String chatId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final messagingService = ref.read(messagingServiceProvider);
    await messagingService.markChatAsRead(chatId, currentUser.uid);
  };
});

// Chat exists provider
final chatExistsProvider = FutureProvider.autoDispose.family<bool, String>((ref, otherUserId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return false;
  }

  try {
    final chatId = ChatModel.generateChatId(currentUser.uid, otherUserId);
    final messagingService = ref.watch(messagingServiceProvider);
    final chatData = await messagingService.getUserData(chatId);
    return chatData != null;
  } catch (e) {
    return false;
  }
});

// Unread messages count provider (for future implementation)
final unreadMessagesCountProvider = Provider.autoDispose<int>((ref) {
  final chats = ref.watch(userChatsProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  return chats.when(
    data: (chatList) {
      if (currentUser == null) return 0;
      
      // For now, return 0. This can be implemented later with read receipts
      return 0;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});