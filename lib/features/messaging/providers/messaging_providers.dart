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
  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  List<MessageModel> _allMessages = [];
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _isLoadingMore = false;

  PaginatedMessagesNotifier(this._messagingService, this._chatId) : super(const PaginatedMessagesState()) {
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    if (!mounted) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Start listening to all messages but only show the latest 10
      _messagesSubscription = _messagingService.getChatMessages(_chatId).listen(
        (allMessages) {
          if (!mounted) return;
          
          _allMessages = allMessages;
          
          // Only reset page if this is truly the first load
          if (!state.isInitialized) {
            _currentPage = 0;
            
            // First load - show last 10 messages
            final messagesToShow = _getMessagesForCurrentPage();
            
            state = state.copyWith(
              messages: messagesToShow,
              isLoading: false,
              hasMoreMessages: _allMessages.length > _pageSize,
              error: null,
              isInitialized: true,
            );
          } else {
            // Subsequent updates - handle new messages smoothly
            final currentDisplayedCount = state.messages.length;
            final messagesToShow = _getMessagesForCurrentPage();
            
            // Only update if there are truly new messages at the end
            if (messagesToShow.length > currentDisplayedCount) {
              // New message arrived - add it smoothly
              state = state.copyWith(
                messages: messagesToShow,
                hasMoreMessages: _allMessages.length > (_currentPage + 1) * _pageSize,
              );
            }
          }
        },
        onError: (error) {
          if (!mounted) return;
          state = state.copyWith(
            isLoading: false,
            error: error.toString(),
            isInitialized: true,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isInitialized: true,
      );
    }
  }

  List<MessageModel> _getMessagesForCurrentPage() {
    if (_allMessages.isEmpty) return [];
    
    // Calculate how many messages to show based on current page
    final totalMessagesToShow = (_currentPage + 1) * _pageSize;
    
    // Get the latest messages up to the total we want to show
    if (totalMessagesToShow >= _allMessages.length) {
      return _allMessages;
    } else {
      final startIndex = _allMessages.length - totalMessagesToShow;
      return _allMessages.sublist(startIndex);
    }
  }

  Future<void> loadMoreMessages() async {
    if (!mounted || _isLoadingMore || !state.hasMoreMessages || state.isLoading) return;
    
    _isLoadingMore = true;
    state = state.copyWith(isLoading: true);
    
    // Small delay to prevent too rapid loading
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (!mounted) {
      _isLoadingMore = false;
      return;
    }
    
    _currentPage++;
    final messagesToShow = _getMessagesForCurrentPage();
    final hasMore = _allMessages.length > (_currentPage + 1) * _pageSize;
    
    state = state.copyWith(
      messages: messagesToShow,
      isLoading: false,
      hasMoreMessages: hasMore,
    );
    
    _isLoadingMore = false;
  }

}