import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../events/providers/events_providers.dart';
import '../../providers/messaging_providers.dart';
import '../../data/models/message_model.dart';
import '../../../../core/utils/logger.dart';
import '../../../../l10n/app_localizations.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final UserModel? otherUser;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    this.otherUser,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    try {
      final chat = await ref.read(getOrCreateChatProvider(widget.otherUserId).future);
      if (mounted) {
        setState(() {
          _chatId = chat.id;
        });
      }
    } catch (e) {
      AppLogger.e('Error initializing chat', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      final sendMessage = ref.read(sendMessageProvider);
      await sendMessage(_chatId!, text);
      
      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      AppLogger.e('Error sending message', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
        // Restore the message text if sending failed
        _messageController.text = text;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final otherUserAsync = ref.watch(userDataProvider(widget.otherUserId));

    return Scaffold(
      appBar: AppBar(
        title: otherUserAsync.when(
          data: (user) => _buildAppBarTitle(user),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('User'),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _chatId != null 
                ? _buildMessagesList(currentUser)
                : const Center(child: CircularProgressIndicator()),
          ),
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(UserModel? user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage: user?.photoURL != null
              ? CachedNetworkImageProvider(user!.photoURL!)
              : null,
          child: user?.photoURL == null
              ? Text(
                  user?.displayName?.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(fontSize: 14),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            user?.displayName ?? 'Unknown User',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList(dynamic currentUser) {
    final messagesAsync = ref.watch(chatMessagesProvider(_chatId!));

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Auto-scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = currentUser?.uid == message.senderId;
            final isLastMessage = index == messages.length - 1;
            final nextMessage = index < messages.length - 1 ? messages[index + 1] : null;
            final showAvatar = isLastMessage || 
                                (nextMessage != null && nextMessage.senderId != message.senderId);

            return _MessageBubble(
              message: message,
              isMe: isMe,
              showAvatar: showAvatar && !isMe,
              otherUser: widget.otherUser,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        AppLogger.e('Error loading messages', error, stack);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading messages: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(chatMessagesProvider(_chatId!)),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.submitPhoto ?? 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final UserModel? otherUser;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    this.otherUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 12,
              backgroundImage: otherUser?.photoURL != null
                  ? CachedNetworkImageProvider(otherUser!.photoURL!)
                  : null,
              child: otherUser?.photoURL == null
                  ? Text(
                      otherUser?.displayName?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 10),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 32),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMe 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: !isMe && showAvatar ? const Radius.circular(4) : null,
                  bottomRight: isMe ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe 
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isMe 
                          ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}