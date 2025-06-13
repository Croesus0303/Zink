import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../events/providers/events_providers.dart';
import '../../providers/messaging_providers.dart';
import '../../data/models/chat_model.dart';
import '../../../../core/utils/logger.dart';
import '../../../../l10n/app_localizations.dart';

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
      ),
      body: chatsAsync.when(
        data: (chats) => _buildChatsList(context, ref, chats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          AppLogger.e('Error loading chats', error, stack);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading chats: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(userChatsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatsList(BuildContext context, WidgetRef ref, List<ChatModel> chats) {
    if (chats.isEmpty) {
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
              'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation by visiting someone\'s profile',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return _ChatListItem(chat: chat);
      },
    );
  }
}

class _ChatListItem extends ConsumerWidget {
  final ChatModel chat;

  const _ChatListItem({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    final otherUserId = chat.getOtherParticipantId(currentUser.uid);
    final otherUserAsync = ref.watch(userDataProvider(otherUserId));

    return otherUserAsync.when(
      data: (otherUser) => _buildChatItem(context, ref, otherUser, otherUserId),
      loading: () => _buildLoadingItem(),
      error: (_, __) => _buildErrorItem(context, otherUserId),
    );
  }

  Widget _buildChatItem(BuildContext context, WidgetRef ref, dynamic otherUser, String otherUserId) {
    final currentUser = ref.watch(currentUserProvider);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: otherUser?.photoURL != null
              ? CachedNetworkImageProvider(otherUser!.photoURL!)
              : null,
          child: otherUser?.photoURL == null
              ? Text(
                  otherUser?.displayName?.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                )
              : null,
        ),
        title: Text(
          otherUser?.displayName ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: chat.lastMessage != null
            ? Row(
                children: [
                  if (chat.lastMessage!.senderId == currentUser?.uid)
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      chat.lastMessage!.text,
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Text(
                'No messages yet',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
        trailing: chat.lastMessage != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(chat.lastMessage!.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  // Future: Add unread badge here
                ],
              )
            : null,
        onTap: () {
          context.push('/chat/$otherUserId');
        },
        onLongPress: () {
          _showChatOptions(context, ref);
        },
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[300],
        ),
        title: Container(
          height: 16,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        subtitle: Container(
          height: 12,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorItem(BuildContext context, String otherUserId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          radius: 24,
          child: Icon(Icons.error),
        ),
        title: const Text('Unknown User'),
        subtitle: const Text('Failed to load user data'),
        onTap: () {
          context.push('/chat/$otherUserId');
        },
      ),
    );
  }

  void _showChatOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.of(context).pop();
                final confirmed = await _showDeleteConfirmationDialog(context);
                if (confirmed == true) {
                  try {
                    final deleteChat = ref.read(deleteChatProvider);
                    await deleteChat(chat.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat deleted')),
                      );
                    }
                  } catch (e) {
                    AppLogger.e('Error deleting chat', e);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete chat: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text(
          'Are you sure you want to delete this chat? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}