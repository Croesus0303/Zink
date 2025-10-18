import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../events/providers/events_providers.dart';
import '../../providers/messaging_providers.dart';
import '../../data/models/message_model.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
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
    _scrollController.addListener(_onScroll);
  }

  void _initializeChat() async {
    try {
      final chat =
          await ref.read(getOrCreateChatProvider(widget.otherUserId).future);
      if (mounted) {
        setState(() {
          _chatId = chat.id;
        });
        
        // Mark chat as read when entering the chat screen
        try {
          final markAsRead = ref.read(markChatAsReadProvider);
          await markAsRead(chat.id);
          AppLogger.i('Marked chat ${chat.id} as read');
        } catch (e) {
          AppLogger.w('Failed to mark chat as read: $e');
        }
      }
    } catch (e) {
      AppLogger.e('Error initializing chat', e);
      if (mounted) {
        CustomSnackBar.showError(context, AppLocalizations.of(context)!.failedToLoadChat(e.toString()));
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // With reverse ListView, we load more when reaching the maxScrollExtent (top of reversed list)
      // Only load when very close to prevent premature loading
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 5) {
        if (_chatId != null) {
          ref.read(paginatedMessagesProvider(_chatId!).notifier).loadMoreMessages();
        }
      }
    }
  }


  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      final sendMessage = ref.read(sendMessageProvider);
      await sendMessage(_chatId!, text);

      // With reverse ListView, new messages automatically appear at bottom
    } catch (e) {
      AppLogger.e('Error sending message', e);
      if (mounted) {
        CustomSnackBar.showError(context, AppLocalizations.of(context)!.failedToSendMessage(e.toString()));
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen.withValues(alpha: 0.9),
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.065,
        title: otherUserAsync.when(
          data: (user) => _buildAppBarTitle(user),
          loading: () => Text(
            AppLocalizations.of(context)!.loading,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.04,
            ),
          ),
          error: (_, __) => Text(
            AppLocalizations.of(context)!.user,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.04,
            ),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 12, top: 3, bottom: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                AppColors.pineGreen.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.iceBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(-1, -1),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.04,
            ),
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width * 0.08,
              minHeight: MediaQuery.of(context).size.width * 0.08,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
          child: Column(
            children: [
              SizedBox(
                height:
                    MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              ),
              // Messages list
              Expanded(
                child: _chatId != null
                    ? otherUserAsync.when(
                        data: (otherUser) =>
                            _buildPaginatedMessagesList(currentUser, otherUser),
                        loading: () => const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.pineGreen)),
                        error: (_, __) => _buildPaginatedMessagesList(currentUser, null),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.pineGreen)),
              ),
              // Message input
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(UserModel? user) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.pineGreen.withValues(alpha: 0.3),
                AppColors.rosyBrown.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.iceBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.pineGreen.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              if (user != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: user.uid),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: MediaQuery.of(context).size.width * 0.04,
              backgroundColor: Colors.transparent,
              backgroundImage: user?.photoURL != null
                  ? CachedNetworkImageProvider(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Text(
                      (user?.username ?? '').isNotEmpty
                          ? user!.username.substring(0, 1).toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.03),
        Expanded(
          child: Text(
            user?.username ?? AppLocalizations.of(context)!.unknownUser,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.04,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: AppColors.rosyBrown.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginatedMessagesList(dynamic currentUser, UserModel? otherUser) {
    final paginatedState = ref.watch(paginatedMessagesProvider(_chatId!));

    if (paginatedState.messages.isEmpty && !paginatedState.isLoading) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
          decoration: BoxDecoration(
            gradient: AppColors.iceGlassGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.iceBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(-2, -2),
              ),
              BoxShadow(
                color: AppColors.rosyBrown.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.2,
                height: MediaQuery.of(context).size.width * 0.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.pineGreen.withValues(alpha: 0.8),
                      AppColors.rosyBrown.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pineGreen.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: MediaQuery.of(context).size.width * 0.1,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              Text(
                AppLocalizations.of(context)!.noMessagesYet,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  shadows: [
                    Shadow(
                      color: AppColors.rosyBrown.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Text(
                AppLocalizations.of(context)!.startConversation,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (paginatedState.error != null) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
          decoration: BoxDecoration(
            gradient: AppColors.iceGlassGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.iceBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(-2, -2),
              ),
              BoxShadow(
                color: AppColors.rosyBrown.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.2,
                height: MediaQuery.of(context).size.width * 0.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.rosyBrown.withValues(alpha: 0.8),
                      AppColors.rosyBrown.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rosyBrown.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.error,
                  size: MediaQuery.of(context).size.width * 0.1,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              Text(
                AppLocalizations.of(context)!.errorLoadingMessages,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  shadows: [
                    Shadow(
                      color: AppColors.rosyBrown.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.pineGreen.withValues(alpha: 0.8),
                      AppColors.pineGreen.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pineGreen.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => ref.refresh(paginatedMessagesProvider(_chatId!)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.06,
                        vertical: MediaQuery.of(context).size.height * 0.015,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: MediaQuery.of(context).size.width * 0.05,
                          ),
                          SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 0.02),
                          Text(
                            AppLocalizations.of(context)!.retry,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
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
      );
    }

    // With reverse ListView, it naturally starts at bottom - no manual handling needed

    return Stack(
      children: [
        // Messages list
        Column(
          children: [
            // Invisible spacer for loading indicator
            if (paginatedState.isLoading && paginatedState.messages.isNotEmpty && paginatedState.isInitialized)
              const SizedBox(height: 40),
            
            Expanded(
              child: paginatedState.messages.isEmpty && !paginatedState.isInitialized
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pineGreen))
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true, // This makes the list start from bottom
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.02,
                        bottom: MediaQuery.of(context).size.height * 0.02,
                      ),
                      itemCount: paginatedState.messages.length,
                      itemBuilder: (context, index) {
                        // Reverse the index since we're using reverse: true
                        final reverseIndex = paginatedState.messages.length - 1 - index;
                        final message = paginatedState.messages[reverseIndex];
                        final isMe = currentUser?.uid == message.senderId;
                        final isLastMessage = reverseIndex == paginatedState.messages.length - 1;
                        final nextMessage = reverseIndex < paginatedState.messages.length - 1 
                            ? paginatedState.messages[reverseIndex + 1] 
                            : null;
                        final showAvatar = isLastMessage ||
                            (nextMessage != null &&
                                nextMessage.senderId != message.senderId);

                        return _MessageBubble(
                          message: message,
                          isMe: isMe,
                          showAvatar: showAvatar && !isMe,
                          otherUser: otherUser,
                        );
                      },
                    ),
            ),
          ],
        ),
        
        // Floating loading indicator at the top (where older messages load)
        if (paginatedState.isLoading && paginatedState.messages.isNotEmpty && paginatedState.isInitialized)
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Container(
              height: 30,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.pineGreen.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      margin: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.04,
        right: MediaQuery.of(context).size.width * 0.04,
        top: MediaQuery.of(context).size.width * 0.02,
        bottom: MediaQuery.of(context).size.width * 0.04 +
            MediaQuery.of(context).padding.bottom,
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.midnightGreen.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.midnightGreen.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.typeMessage,
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.04,
                    vertical: MediaQuery.of(context).size.height * 0.015,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.pineGreen.withValues(alpha: 0.8),
                  AppColors.pineGreen.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pineGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _sendMessage,
                child: Container(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: MediaQuery.of(context).size.width * 0.05,
                  ),
                ),
              ),
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.01,
        left: MediaQuery.of(context).size.width * 0.04,
        right: MediaQuery.of(context).size.width * 0.04,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe && showAvatar) ...[
                Padding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.width * 0.01),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.pineGreen.withValues(alpha: 0.3),
                          AppColors.rosyBrown.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.iceBorder,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pineGreen.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (otherUser != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileScreen(userId: otherUser!.uid),
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        radius: MediaQuery.of(context).size.width * 0.04,
                        backgroundColor: Colors.transparent,
                        backgroundImage: otherUser?.photoURL != null
                            ? CachedNetworkImageProvider(otherUser!.photoURL!)
                            : null,
                        child: otherUser?.photoURL == null
                            ? Text(
                                (otherUser?.username ?? '').isNotEmpty
                                    ? otherUser!.username.substring(0, 1).toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.03,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              ] else if (!isMe) ...[
                SizedBox(width: MediaQuery.of(context).size.width * 0.13),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                    minWidth: MediaQuery.of(context).size.width * 0.15,
                  ),
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.035),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? LinearGradient(
                            colors: [
                              AppColors.pineGreen.withValues(alpha: 0.8),
                              AppColors.pineGreen.withValues(alpha: 0.9),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              AppColors.midnightGreen.withValues(alpha: 0.2),
                              AppColors.midnightGreen.withValues(alpha: 0.1),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(15).copyWith(
                      bottomLeft:
                          !isMe && showAvatar ? const Radius.circular(3) : null,
                      bottomRight: isMe ? const Radius.circular(3) : null,
                    ),
                    border: Border.all(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.midnightGreen.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.038,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
              ],
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.003),
          Padding(
            padding: EdgeInsets.only(
              left: !isMe && showAvatar
                  ? MediaQuery.of(context).size.width * 0.13
                  : !isMe
                      ? MediaQuery.of(context).size.width * 0.16
                      : 0,
              right: isMe ? MediaQuery.of(context).size.width * 0.02 : 0,
            ),
            child: Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: AppColors.rosyBrown.withValues(alpha: 0.8),
                fontSize: MediaQuery.of(context).size.width * 0.025,
                fontWeight: FontWeight.w400,
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
      if (difference.inDays == 1) {
        return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
