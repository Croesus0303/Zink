import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../events/providers/events_providers.dart';
import '../../providers/messaging_providers.dart';
import '../../data/models/chat_model.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../l10n/app_localizations.dart';

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatsProvider);

    return Scaffold(
      backgroundColor: AppColors.midnightGreen,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: MediaQuery.of(context).size.width * 0.07,
          ),
          padding: EdgeInsets.zero,
        ),
        title: Text(
          AppLocalizations.of(context)!.messages,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: chatsAsync.when(
        data: (chats) => _buildChatsList(context, ref, chats),
        loading: () => Center(
          child: CircularProgressIndicator(
            color: AppColors.rosyBrown,
            strokeWidth: MediaQuery.of(context).size.width * 0.01,
          ),
        ),
        error: (error, stack) {
          AppLogger.e('Error loading chats', error, stack);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: MediaQuery.of(context).size.width * 0.2,
                  color: AppColors.rosyBrown,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  AppLocalizations.of(context)!.errorLoadingChats,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(userChatsProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context)!.retry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pineGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.06,
                      vertical: MediaQuery.of(context).size.height * 0.015,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatsList(
      BuildContext context, WidgetRef ref, List<ChatModel> chats) {
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: MediaQuery.of(context).size.width * 0.2,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              AppLocalizations.of(context)!.noConversationsYet,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              AppLocalizations.of(context)!.noConversationsDescription,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.035,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.02,
        right: MediaQuery.of(context).size.width * 0.02,
        top: MediaQuery.of(context).size.height * 0.02,
        bottom: MediaQuery.of(context).size.width * 0.04,
      ),
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
      loading: () => _buildLoadingItem(context),
      error: (_, __) => _buildErrorItem(context, otherUserId),
    );
  }

  Widget _buildChatItem(BuildContext context, WidgetRef ref, dynamic otherUser,
      String otherUserId) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const SizedBox.shrink();
    }
    
    final hasUnread = chat.hasUnreadMessages(currentUser.uid);

    return Container(
      decoration: BoxDecoration(
        color: hasUnread
            ? AppColors.midnightGreenLight.withValues(alpha: 0.5)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: AppColors.midnightGreenLight,
            width: MediaQuery.of(context).size.width * 0.0025,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/chat/$otherUserId');
          },
          onLongPress: () {
            _showChatOptions(context, ref);
          },
          child: Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
            child: Row(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.rosyBrown,
                        AppColors.pineGreen,
                        AppColors.midnightGreen,
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: MediaQuery.of(context).size.width * 0.06,
                    backgroundColor: Colors.transparent,
                    backgroundImage: otherUser?.photoURL != null
                        ? CachedNetworkImageProvider(otherUser!.photoURL!)
                        : null,
                    child: otherUser?.photoURL == null
                        ? Text(
                            otherUser?.username
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                '?',
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.025),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUser?.username ?? AppLocalizations.of(context)!.unknownUser,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.005),
                      chat.lastMessage != null
                          ? Row(
                              children: [
                                if (chat.lastMessage!.senderId ==
                                    currentUser.uid)
                                  Padding(
                                    padding: EdgeInsets.only(
                                        right:
                                            MediaQuery.of(context).size.width *
                                                0.015),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      size: MediaQuery.of(context).size.width *
                                          0.03,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    chat.lastMessage!.text,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.035,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              AppLocalizations.of(context)!.noMessagesYet,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.035,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                    ],
                  ),
                ),
                if (chat.lastMessage != null) ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(chat.lastMessage!.createdAt),
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: MediaQuery.of(context).size.width * 0.028,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      // Unread count badge
                      SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                      Builder(
                        builder: (context) {
                          final count = chat.getUnreadCount(currentUser.uid);
                          
                          return count > 0
                            ? Container(
                                width: MediaQuery.of(context).size.width * 0.05,
                                height: MediaQuery.of(context).size.width * 0.05,
                                constraints: BoxConstraints(
                                  minWidth: MediaQuery.of(context).size.width * 0.05,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.rosyBrown,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    count > 99 ? '99+' : count.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: MediaQuery.of(context).size.width * 0.025,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingItem(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.midnightGreenLight,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.rosyBrown.withValues(alpha: 0.3),
                  AppColors.pineGreen.withValues(alpha: 0.3),
                  AppColors.midnightGreen.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: CircleAvatar(
              radius: MediaQuery.of(context).size.width * 0.06,
              backgroundColor: Colors.transparent,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.02,
                  width: MediaQuery.of(context).size.width * 0.3,
                  decoration: BoxDecoration(
                    color: AppColors.midnightGreenLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.01),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Container(
                  height: MediaQuery.of(context).size.height * 0.015,
                  width: MediaQuery.of(context).size.width * 0.2,
                  decoration: BoxDecoration(
                    color: AppColors.midnightGreenLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.01),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorItem(BuildContext context, String otherUserId) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.midnightGreenLight,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/chat/$otherUserId');
          },
          child: Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
            child: Row(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.rosyBrown,
                        AppColors.pineGreen,
                        AppColors.midnightGreen,
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: MediaQuery.of(context).size.width * 0.06,
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.error,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width * 0.06,
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.025),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.unknownUser,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.005),
                      Text(
                        AppLocalizations.of(context)!.failedToLoadUserData,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChatOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: GlassContainer(
            borderRadius: MediaQuery.of(context).size.width * 0.05,
            useOrangeAccent: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                      onTap: () async {
                        Navigator.of(context).pop();
                        final confirmed =
                            await _showDeleteConfirmationDialog(context);
                        if (confirmed == true) {
                          try {
                            final deleteChat = ref.read(deleteChatProvider);
                            await deleteChat(chat.id);
                            if (context.mounted) {
                              CustomSnackBar.showSuccess(context, AppLocalizations.of(context)!.chatDeleted);
                            }
                          } catch (e) {
                            AppLogger.e('Error deleting chat', e);
                            if (context.mounted) {
                              CustomSnackBar.showError(context, 'Failed to delete chat: $e');
                            }
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.04,
                          vertical: MediaQuery.of(context).size.height * 0.015,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.1,
                              height: MediaQuery.of(context).size.width * 0.1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryOrange.withValues(alpha: 0.8),
                                    AppColors.primaryOrangeDark
                                        .withValues(alpha: 0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                                border: Border.all(
                                  color:
                                      AppColors.primaryOrange.withValues(alpha: 0.3),
                                  width: MediaQuery.of(context).size.width * 0.0025,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryOrange
                                        .withValues(alpha: 0.3),
                                    blurRadius: MediaQuery.of(context).size.width * 0.02,
                                    offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: MediaQuery.of(context).size.width * 0.05,
                              ),
                            ),
                            SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                            Text(
                              AppLocalizations.of(context)!.deleteChat,
                              style: TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: MediaQuery.of(context).size.width * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: GlassContainer(
            borderRadius: MediaQuery.of(context).size.width * 0.06,
            useOrangeAccent: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                Container(
                  width: MediaQuery.of(context).size.width * 0.15,
                  height: MediaQuery.of(context).size.width * 0.15,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryOrange.withValues(alpha: 0.8),
                        AppColors.primaryOrangeDark.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withValues(alpha: 0.3),
                        blurRadius: MediaQuery.of(context).size.width * 0.03,
                        offset: Offset(0, MediaQuery.of(context).size.height * 0.005),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: MediaQuery.of(context).size.width * 0.07,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                Text(
                  AppLocalizations.of(context)!.deleteChat,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryOrange,
                    shadows: [
                      Shadow(
                        color: AppColors.primaryOrange.withValues(alpha: 0.3),
                        blurRadius: MediaQuery.of(context).size.width * 0.02,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
                  child: Text(
                    AppLocalizations.of(context)!.sureDeleteChat,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.backgroundSecondary.withValues(alpha: 0.8),
                                AppColors.backgroundSecondary.withValues(alpha: 0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                            border: Border.all(
                              color: AppColors.primaryCyan.withValues(alpha: 0.3),
                              width: MediaQuery.of(context).size.width * 0.0025,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                              onTap: () => Navigator.of(context).pop(false),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: MediaQuery.of(context).size.height * 0.015,
                                ),
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: MediaQuery.of(context).size.width * 0.04,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryOrange.withValues(alpha: 0.8),
                                AppColors.primaryOrangeDark.withValues(alpha: 0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                            border: Border.all(
                              color: AppColors.primaryOrange.withValues(alpha: 0.3),
                              width: MediaQuery.of(context).size.width * 0.0025,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryOrange.withValues(alpha: 0.4),
                                blurRadius: MediaQuery.of(context).size.width * 0.03,
                                offset: Offset(0, MediaQuery.of(context).size.height * 0.0075),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                              onTap: () => Navigator.of(context).pop(true),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: MediaQuery.of(context).size.height * 0.015,
                                ),
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(context)!.delete,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: MediaQuery.of(context).size.width * 0.04,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              ],
            ),
          ),
        ),
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
