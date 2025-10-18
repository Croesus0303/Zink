import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../notifications/providers/notifications_providers.dart';
import '../../../messaging/providers/messaging_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/timeline_tab.dart';
import '../widgets/events_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authStateProvider);
    final currentUserDataAsync = ref.watch(currentUserDataProvider);
    final unreadCountAsync = ref.watch(enhancedUnreadNotificationsCountProvider);
    final unreadMessagesCountAsync = ref.watch(unreadMessagesCountAsyncProvider);
    final shouldShowPromptAsync = ref.watch(shouldShowNotificationPromptProvider);

    final isLoading = authStateAsync.isLoading ||
                     currentUserDataAsync.isLoading ||
                     unreadCountAsync.isLoading || 
                     unreadMessagesCountAsync.isLoading ||
                     shouldShowPromptAsync.isLoading;

    if (isLoading) {
      return _buildLoadingScreen(context);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen.withValues(alpha: 0.9),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: MediaQuery.of(context).size.height * 0.065,
        title: Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.25,
              height: MediaQuery.of(context).size.height * 0.07,
              child: Image.asset(
                'assets/app_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.camera_alt,
                          color: Colors.white,
                          size: MediaQuery.of(context).size.width * 0.04),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.015),
                      Text(
                        'Zink',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          _buildNotificationButton(context, unreadCountAsync),
          _buildMessagesButton(context, unreadMessagesCountAsync),
          _buildProfileButton(context),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.midnightGreen.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: AppColors.iceBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          indicatorColor: AppColors.primaryOrange,
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.032,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.03,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              icon: Icon(
                Icons.timeline,
                size: MediaQuery.of(context).size.width * 0.06,
              ),
              text: AppLocalizations.of(context)!.timeline,
            ),
            Tab(
              icon: Icon(
                Icons.event,
                size: MediaQuery.of(context).size.width * 0.06,
              ),
              text: AppLocalizations.of(context)!.events,
            ),
          ],
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
          decoration: BoxDecoration(
            gradient: AppColors.auroraRadialGradient,
          ),
          child: Stack(
            children: [
              // Main content area
              TabBarView(
                controller: _tabController,
                children: const [
                  TimelineTab(),
                  EventsTab(),
                ],
              ),
              // Notification permission prompt overlay
              const _NotificationPermissionPrompt(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen.withValues(alpha: 0.9),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: MediaQuery.of(context).size.height * 0.065,
        title: Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.25,
              height: MediaQuery.of(context).size.height * 0.07,
              child: Image.asset(
                'assets/app_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.camera_alt,
                          color: Colors.white,
                          size: MediaQuery.of(context).size.width * 0.04),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.015),
                      Text(
                        'Zink',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.auroraRadialGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.rosyBrown,
              strokeWidth: 4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, AsyncValue<int> unreadCountAsync) {
    return Container(
      margin: const EdgeInsets.only(right: 6, left: 0, bottom: 3, top: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.04,
            ),
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width * 0.08,
              minHeight: MediaQuery.of(context).size.width * 0.08,
            ),
            padding: EdgeInsets.zero,
          ),
          unreadCountAsync.when(
            data: (count) => count > 0
                ? Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.05,
                      height: MediaQuery.of(context).size.width * 0.05,
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width * 0.05,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(alpha: 0.6),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width * 0.024,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesButton(BuildContext context, AsyncValue<int> unreadMessagesCountAsync) {
    return Container(
      margin: const EdgeInsets.only(right: 6, left: 0, bottom: 3, top: 3),
      decoration: BoxDecoration(
        color: AppColors.rosyBrown.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.rosyBrown.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => context.push('/chats'),
            icon: Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.04,
            ),
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width * 0.08,
              minHeight: MediaQuery.of(context).size.width * 0.08,
            ),
            padding: EdgeInsets.zero,
          ),
          unreadMessagesCountAsync.when(
            data: (count) => count > 0
                ? Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.05,
                      height: MediaQuery.of(context).size.width * 0.05,
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width * 0.05,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rosyBrown,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rosyBrown.withValues(alpha: 0.6),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width * 0.024,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12, bottom: 3, top: 3),
      decoration: BoxDecoration(
        color: AppColors.pineGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.pineGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: () => context.push('/profile'),
        icon: Icon(
          Icons.person_outline,
          color: Colors.white,
          size: MediaQuery.of(context).size.width * 0.04,
        ),
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width * 0.08,
          minHeight: MediaQuery.of(context).size.width * 0.08,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _NotificationPermissionPrompt extends ConsumerWidget {
  const _NotificationPermissionPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShowPromptAsync = ref.watch(shouldShowNotificationPromptProvider);

    return shouldShowPromptAsync.when(
      data: (shouldShow) {
        if (!shouldShow) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryOrange.withValues(alpha: 0.15),
                AppColors.rosyBrown.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryOrange.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.notifications,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.notificationPermissionMessage,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: MediaQuery.of(context).size.width * 0.038,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final notificationService = ref.read(notificationServiceProvider);
                            await notificationService.dismissNotificationPrompt();
                            ref.invalidate(shouldShowNotificationPromptProvider);
                          },
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.notNow,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final notificationService = ref.read(notificationServiceProvider);
                            final granted = await notificationService.requestNotificationPermission();
                            
                            if (granted) {
                              final notificationService = ref.read(notificationServiceProvider);
                              await notificationService.debugFCMSetup();
                              ref.invalidate(shouldShowNotificationPromptProvider);
                              
                              if (context.mounted) {
                                CustomSnackBar.showSuccess(context, AppLocalizations.of(context)!.notificationPermissionGranted);
                              }
                            } else {
                              final notificationService = ref.read(notificationServiceProvider);
                              await notificationService.dismissNotificationPrompt();
                              ref.invalidate(shouldShowNotificationPromptProvider);
                              
                              if (context.mounted) {
                                CustomSnackBar.showError(context, AppLocalizations.of(context)!.notificationPermissionDenied);
                              }
                            }
                          },
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.allowPermission,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) {
        AppLogger.e('Error checking notification permission', error, stack);
        return const SizedBox.shrink();
      },
    );
  }
}