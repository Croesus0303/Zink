import 'dart:async';
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

// Chat stream provider for real-time updates (for read receipts)
final chatStreamProvider = StreamProvider.autoDispose.family<ChatModel?, String>((ref, otherUserId) async* {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    yield null;
    return;
  }

  final messagingService = ref.watch(messagingServiceProvider);
  
  // First get or create the chat
  final chat = await messagingService.getOrCreateChat(currentUser.uid, otherUserId);
  yield chat;
  
  // Then listen for real-time updates
  yield* messagingService.getChatStream(chat.id);
});

// Paginated messages provider
final paginatedMessagesProvider = StateNotifierProvider.autoDispose.family<PaginatedMessagesNotifier, PaginatedMessagesState, String>((ref, chatId) {
  final messagingService = ref.watch(messagingServiceProvider);
  return PaginatedMessagesNotifier(messagingService, chatId);
});

// State for paginated messages
class PaginatedMessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool hasMoreMessages;
  final String? error;
  final bool isInitialized;

  const PaginatedMessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.hasMoreMessages = true,
    this.error,
    this.isInitialized = false,
  });

  PaginatedMessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? hasMoreMessages,
    String? error,
    bool? isInitialized,
  }) {
    return PaginatedMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// Notifier for paginated messages
class PaginatedMessagesNotifier extends StateNotifier<PaginatedMessagesState> {
  final MessagingService _messagingService;
  final String _chatId;
  StreamSubscription<MessageModel>? _newMessagesSubscription;
  List<MessageModel> _loadedMessages = [];
  static const int _pageSize = 10;
  bool _isLoadingMore = false;
  int? _oldestLoadedTimestamp; // Track the oldest message we've loaded

  PaginatedMessagesNotifier(this._messagingService, this._chatId) : super(const PaginatedMessagesState()) {
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _newMessagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    if (!mounted) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Try the paginated method first
      List<MessageModel> initialMessages = await _messagingService.getPaginatedMessages(_chatId, limit: _pageSize);
      
      // If paginated method fails or returns empty, fall back to the working stream method
      if (initialMessages.isEmpty) {
        final streamMessages = await _messagingService.getChatMessages(_chatId).first;
        if (streamMessages.isNotEmpty) {
          // Take only the last 10 messages
          if (streamMessages.length <= _pageSize) {
            initialMessages = streamMessages;
          } else {
            initialMessages = streamMessages.sublist(streamMessages.length - _pageSize);
          }
        }
      }
      
      if (!mounted) return;
      
      _loadedMessages = initialMessages;
      _oldestLoadedTimestamp = initialMessages.isNotEmpty ? initialMessages.first.timestamp : null;
      
      state = state.copyWith(
        messages: initialMessages,
        isLoading: false,
        hasMoreMessages: initialMessages.length == _pageSize,
        error: null,
        isInitialized: true,
      );
      
      _startListeningForNewMessages();
      
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isInitialized: true,
      );
    }
  }
  
  void _startListeningForNewMessages() {
    final newestTimestamp = _loadedMessages.isNotEmpty 
        ? _loadedMessages.last.timestamp 
        : DateTime.now().millisecondsSinceEpoch;
    
    _newMessagesSubscription = _messagingService.getNewMessagesAfter(_chatId, newestTimestamp).listen(
      (newMessage) {
        if (!mounted) return;
        
        // Add the new message to our loaded messages
        _loadedMessages.add(newMessage);
        
        // Update the state to include the new message
        state = state.copyWith(
          messages: List.from(_loadedMessages),
        );
      },
      onError: (error) {
        // Silent error handling - real-time updates will just stop working
      },
    );
  }

  Future<void> loadMoreMessages() async {
    if (!mounted || _isLoadingMore || !state.hasMoreMessages || state.isLoading) return;
    
    _isLoadingMore = true;
    state = state.copyWith(isLoading: true);
    
    try {
      // Load incrementally larger batches to get older messages
      final batchSize = _loadedMessages.length + _pageSize;
      
      final batchMessages = await _messagingService.getPaginatedMessages(
        _chatId, 
        limit: batchSize,
      );
      
      if (!mounted) return;
      
      // Filter out messages we already have and get only the older ones
      final existingIds = _loadedMessages.map((m) => m.id).toSet();
      final newOlderMessages = batchMessages
          .where((msg) => !existingIds.contains(msg.id) && msg.timestamp < (_oldestLoadedTimestamp ?? DateTime.now().millisecondsSinceEpoch))
          .toList();
      
      if (newOlderMessages.isNotEmpty) {
        // Sort and take only the next page worth
        newOlderMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final messagesToAdd = newOlderMessages.take(_pageSize).toList();
        
        // Sort back to ascending for display
        messagesToAdd.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        // Prepend older messages to our list
        _loadedMessages.insertAll(0, messagesToAdd);
        _oldestLoadedTimestamp = messagesToAdd.first.timestamp;
        
        // Check if there are more messages
        final hasMoreInBatch = newOlderMessages.length > messagesToAdd.length;
        final gotFullBatch = batchMessages.length == batchSize;
        
        state = state.copyWith(
          messages: List.from(_loadedMessages),
          isLoading: false,
          hasMoreMessages: hasMoreInBatch || gotFullBatch,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          hasMoreMessages: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    
    _isLoadingMore = false;
  }
}

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
      userData.username,
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

// Unread messages count provider
final unreadMessagesCountProvider = StreamProvider.autoDispose<int>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return Stream.value(0);
  }

  final messagingService = ref.watch(messagingServiceProvider);
  return messagingService.getUnreadMessageCount(currentUser.uid);
});

// Unread messages count as AsyncValue for easier consumption  
final unreadMessagesCountAsyncProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  return ref.watch(unreadMessagesCountProvider);
});

// Get unread count for a specific chat (using efficient method)
final chatUnreadCountProvider = Provider.autoDispose.family<int, ChatModel>((ref, chat) {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return 0;
  }

  return chat.getUnreadCount(currentUser.uid);
});