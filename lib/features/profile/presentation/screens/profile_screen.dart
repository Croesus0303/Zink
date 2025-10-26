import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../events/providers/events_providers.dart';
import '../../../submissions/data/models/submission_model.dart';
import '../../../submissions/presentation/screens/single_submission_screen.dart';
import '../../../../l10n/app_localizations.dart';
import 'edit_profile_screen.dart';
import 'storage_test_screen.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/glassy_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({
    super.key,
    this.userId,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Reload profile data when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProfileData();
    });
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool isDestructive = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.06,
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.015,
        vertical: MediaQuery.of(context).size.height * 0.005,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: MediaQuery.of(context).size.height * 0.015,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDestructive
              ? [
                  AppColors.rosyBrown.withValues(alpha: 0.15),
                  AppColors.rosyBrown.withValues(alpha: 0.08),
                ]
              : isPrimary
                  ? [
                      AppColors.pineGreen.withValues(alpha: 0.2),
                      AppColors.pineGreen.withValues(alpha: 0.1),
                    ]
                  : [
                      AppColors.midnightGreen.withValues(alpha: 0.2),
                      AppColors.midnightGreen.withValues(alpha: 0.1),
                    ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive
              ? AppColors.rosyBrown.withValues(alpha: 0.4)
              : isPrimary
                  ? AppColors.pineGreen.withValues(alpha: 0.4)
                  : AppColors.iceBorder.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDestructive
                ? AppColors.rosyBrown.withValues(alpha: 0.1)
                : isPrimary
                    ? AppColors.pineGreen.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.08,
            height: MediaQuery.of(context).size.width * 0.08,
            decoration: BoxDecoration(
              color: isDestructive
                  ? AppColors.rosyBrown.withValues(alpha: 0.2)
                  : isPrimary
                      ? AppColors.pineGreen.withValues(alpha: 0.2)
                      : AppColors.iceBorder.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDestructive
                  ? AppColors.rosyBrown
                  : isPrimary
                      ? AppColors.pineGreen
                      : Colors.white.withValues(alpha: 0.9),
              size: MediaQuery.of(context).size.width * 0.04,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.04),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.036,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshProfileData() {
    final currentUser = ref.read(currentUserProvider);
    final targetUserId = widget.userId ?? currentUser?.uid;

    if (targetUserId != null) {
      // Invalidate all profile-related providers to force reload
      ref.invalidate(userDataProvider(targetUserId));
      ref.invalidate(userSubmissionsFromUserCollectionProvider(targetUserId));
      ref.invalidate(userLikedSubmissionIdsProvider(targetUserId));
      ref.invalidate(userLikedSubmissionsProvider(targetUserId));
      ref.invalidate(userSubmissionCountProvider(targetUserId));
      ref.invalidate(userLikeCountFromUserCollectionProvider(targetUserId));
      ref.invalidate(userBadgesProvider(targetUserId));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile =
        widget.userId == null || widget.userId == currentUser?.uid;
    final targetUserId = widget.userId ?? currentUser?.uid;

    if (targetUserId == null) {
      return Scaffold(
        body: Center(child: Text(AppLocalizations.of(context)!.userNotFound)),
      );
    }

    // Watch all essential profile data first
    final authStateAsync = ref.watch(authStateProvider);
    final currentUserDataAsync = ref.watch(currentUserDataProvider);
    final userDataAsync = ref.watch(userDataProvider(targetUserId));
    final userSubmissionsAsync =
        ref.watch(userSubmissionsFromUserCollectionProvider(targetUserId));
    final userLikedSubmissionsAsync =
        ref.watch(userLikedSubmissionsProvider(targetUserId));
    final userBadgesAsync = ref.watch(userBadgesProvider(targetUserId));

    // Check if critical data is still loading - especially important for first login
    final isLoading = authStateAsync.isLoading ||
        currentUserDataAsync.isLoading ||
        userDataAsync.isLoading ||
        userSubmissionsAsync.isLoading ||
        userLikedSubmissionsAsync.isLoading ||
        userBadgesAsync.isLoading;

    // Show loading screen while essential data loads
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.pineGreen,
                strokeWidth: 4,
              ),
            ),
          ),
        ),
      );
    }

    return userDataAsync.when(
      data: (user) =>
          _buildProfile(context, ref, user, isOwnProfile, targetUserId),
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.pineGreen),
            ),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .errorLoadingProfile(error.toString()),
                    style: const TextStyle(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
                        onTap: () =>
                            ref.refresh(userDataProvider(targetUserId)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.retry,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, UserModel? user,
      bool isOwnProfile, String targetUserId) {
    // Handle case where user document doesn't exist (new users before onboarding)
    if (user == null) {
      if (isOwnProfile) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration:
                  BoxDecoration(gradient: AppColors.auroraRadialGradient),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: MediaQuery.of(context).size.width * 0.3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.rosyBrown,
                            AppColors.pineGreen,
                            AppColors.midnightGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rosyBrown.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: MediaQuery.of(context).size.width * 0.15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.profileNotSetUp,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.pleaseCompleteProfileSetup,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryOrange.withValues(alpha: 0.8),
                            AppColors.primaryOrangeDark
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryOrange.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.go('/onboarding'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 18),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit, color: Colors.white, size: 20),
                                const SizedBox(width: 12),
                                Text(AppLocalizations.of(context)!.completeSetup,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
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
      } else {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration:
                  BoxDecoration(gradient: AppColors.auroraRadialGradient),
              child: const Center(
                child: Text(
                  'User not found',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background image - full screen
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay - full screen
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
            ),
          ),
          // Main content
          Column(
            children: [
              // Tab content with proper padding
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildHomeTab(context, ref, targetUserId),
                        _buildUserSubmissions(context, ref, targetUserId),
                        _buildLikedSubmissions(context, ref, targetUserId),
                        _buildBadgesTab(context, ref, targetUserId),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom tab bar
              _buildBottomTabBar(context),
            ],
          ),
          // Back button (top left) - moved to top of stack for proper click handling
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: MediaQuery.of(context).size.width * 0.04,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: MediaQuery.of(context).size.width * 0.08,
              ),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          // Message or Settings button (top right) - moved to top of stack for proper click handling
          if (!isOwnProfile)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: MediaQuery.of(context).size.width * 0.04,
              child: IconButton(
                icon: Icon(
                  Icons.message,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.08,
                ),
                onPressed: () => context.push('/chat/$targetUserId'),
                tooltip: AppLocalizations.of(context)!.messages,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          if (isOwnProfile)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: MediaQuery.of(context).size.width * 0.04,
              child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: MediaQuery.of(context).size.width * 0.08,
                  ),
                  padding: EdgeInsets.zero,
                  color: AppColors.midnightGreen.withValues(alpha: 0.98),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.iceBorder,
                      width: 1.5,
                    ),
                  ),
                  elevation: 12,
                  offset: Offset(0, MediaQuery.of(context).size.height * 0.02),
                  position: PopupMenuPosition.under,
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width * 0.45,
                    maxWidth: MediaQuery.of(context).size.width * 0.52,
                  ),
                  menuPadding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.015),
                  onSelected: (value) async {
                    if (value == 'editProfile') {
                      {
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(user: user),
                          ),
                        )
                            .then((_) {
                          _refreshProfileData();
                        });
                      }
                    } else if (value == 'testStorage') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const StorageTestScreen(),
                        ),
                      );
                    } else if (value == 'settings') {
                      context.push('/settings');
                    } else if (value == 'signOut') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha: 0.6),
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          content: Container(
                            decoration: BoxDecoration(
                              color: AppColors.midnightGreen
                                  .withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.iceBorder,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.signOut,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .signOutConfirmation,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(
                                          AppLocalizations.of(context)!.cancel,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.rosyBrown
                                                  .withValues(alpha: 0.8),
                                              AppColors.rosyBrown,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            onTap: () =>
                                                Navigator.of(context).pop(true),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 12,
                                              ),
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .signOut,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
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
                            ),
                          ),
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          final authService = ref.read(authServiceProvider);
                          await authService.signOut();
                        } catch (e) {
                          if (context.mounted) {
                            CustomSnackBar.showError(
                                context, 'Sign out failed: ${e.toString()}');
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    // Edit Profile
                    PopupMenuItem<String>(
                      value: 'editProfile',
                      child: _buildMenuItem(
                        context: context,
                        icon: Icons.edit,
                        label: AppLocalizations.of(context)!.editProfile,
                        isPrimary: true,
                      ),
                    ),
                    // Settings
                    PopupMenuItem<String>(
                      value: 'settings',
                      child: _buildMenuItem(
                        context: context,
                        icon: Icons.settings,
                        label: AppLocalizations.of(context)!.settings,
                        isPrimary: false,
                      ),
                    ),
                    // Divider for Sign Out
                    PopupMenuItem<String>(
                      enabled: false,
                      height: 1,
                      child: Container(
                        height: 1,
                        margin: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.02,
                          vertical: MediaQuery.of(context).size.height * 0.01,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.rosyBrown.withValues(alpha: 0.3),
                              AppColors.rosyBrown.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Sign Out
                    PopupMenuItem<String>(
                      value: 'signOut',
                      child: _buildMenuItem(
                        context: context,
                        icon: Icons.logout,
                        label: AppLocalizations.of(context)!.signOut,
                        isPrimary: false,
                        isDestructive: true,
                      ),
                    ),
                  ],
                ),
              ),
          // Centered Profile text - moved to top of stack
          Positioned(
            top: MediaQuery.of(context).padding.top +
                8 +
                (MediaQuery.of(context).size.width * 0.08 / 2) -
                (MediaQuery.of(context).size.width * 0.045 / 2),
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Text(
                isOwnProfile
                    ? AppLocalizations.of(context)!.profile
                    : user.username,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.043,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                  shadows: [
                    Shadow(
                      color: AppColors.rosyBrown.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTabBar(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.08,
          vertical: MediaQuery.of(context).size.height * 0.01,
        ),
        height: MediaQuery.of(context).size.height * 0.065,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          boxShadow: [
            // Sharper upward shadow for depth
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTabBubble(context, 0, Icons.home),
            _buildTabBubble(context, 1, Icons.grid_on),
            _buildTabBubble(context, 2, Icons.favorite),
            _buildTabBubble(context, 3, Icons.emoji_events),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBubble(BuildContext context, int index, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedBuilder(
          animation: _tabController.animation!,
          builder: (context, child) {
            final animationValue = _tabController.animation!.value;
            final distance = (animationValue - index).abs();
            final progress = 1.0 - distance.clamp(0.0, 1.0);

            // Animate width - wider bubbles, even wider when active
            final baseWidth = MediaQuery.of(context).size.width * 0.14;
            final activeWidth = MediaQuery.of(context).size.width * 0.16;
            final width = baseWidth + (activeWidth - baseWidth) * progress;

            // Animate between pine green and rosy brown
            final decoration = BoxDecoration.lerp(
              createPineGreenDecoration(borderRadius: 20),
              createRosyBrownDecoration(borderRadius: 20),
              progress,
            );

            // Calculate shine opacity
            final shineAlphaTop = 0.3 + (0.2 * progress);
            final shineAlphaBottom = 0.15 + (0.1 * progress);

            // Calculate icon opacity and size - consistent 0.8 for inactive
            final iconAlpha = 0.8 + (0.2 * progress);
            final iconSize = 22.0 + (2.0 * progress);

            // Unified coral accent - rgba(230, 120, 90, 0.25)
            const coralGlow = Color(0xFFE6785A); // rgb(230, 120, 90)

            return Center(
              child: Container(
                width: width,
                height: MediaQuery.of(context).size.height * 0.045,
                decoration: decoration!.copyWith(
                  boxShadow: [
                    if (progress > 0.1)
                      BoxShadow(
                        color: coralGlow.withValues(alpha: 0.25 * progress),
                        blurRadius: 16 * progress,
                        spreadRadius: 2 * progress,
                      ),
                    ...(decoration.boxShadow ?? []),
                  ],
                ),
                child: Stack(
                  children: [
                    // Glassy shine overlay - always present for crystalline effect
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.topLeft,
                              radius: 1.2,
                              colors: [
                                Colors.white.withValues(alpha: shineAlphaTop),
                                Colors.white.withValues(alpha: shineAlphaBottom),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.3, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Icon
                    Center(
                      child: Icon(
                        icon,
                        color: Colors.white.withValues(alpha: iconAlpha),
                        size: iconSize,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

extension on _ProfileScreenState {
  Widget _buildUserSubmissions(
      BuildContext context, WidgetRef ref, String targetUserId) {
    final submissionsAsync =
        ref.watch(userSubmissionsFromUserCollectionProvider(targetUserId));

    return submissionsAsync.when(
      data: (submissions) => Padding(
        padding: const EdgeInsets.only(top: 56),
        child: _buildSubmissionGrid(submissions),
      ),
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 56),
        child: _buildSubmissionGrid([]),
      ), // Show empty grid while loading
      error: (error, stack) => Padding(
        padding: const EdgeInsets.only(top: 56),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Error loading submissions',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
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
                    onTap: () => ref.refresh(
                        userSubmissionsFromUserCollectionProvider(
                            targetUserId)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.retry,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildLikedSubmissions(
      BuildContext context, WidgetRef ref, String targetUserId) {
    final likedSubmissionsAsync =
        ref.watch(userLikedSubmissionsProvider(targetUserId));

    return likedSubmissionsAsync.when(
      data: (submissions) => Padding(
        padding: const EdgeInsets.only(top: 56),
        child: _buildLikedSubmissionGrid(submissions),
      ),
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 56),
        child: _buildLikedSubmissionGrid([]),
      ), // Show empty grid while loading
      error: (error, stack) => Padding(
        padding: const EdgeInsets.only(top: 56),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Error loading liked submissions',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.rosyBrown.withValues(alpha: 0.8),
                      AppColors.rosyBrown.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rosyBrown.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        ref.refresh(userLikedSubmissionsProvider(targetUserId)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.retry,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildSubmissionGrid(List<SubmissionModel> submissions) {
    if (submissions.isEmpty) {
      return const Center(
        child: Text(
          'No submissions yet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SingleSubmissionScreen(
                  eventId: submission.eventId,
                  submissionId: submission.id,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.pineGreen.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pineGreen.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: submission.imageURL,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.cardDark.withValues(alpha: 0.3),
                  child: const Icon(
                    Icons.image,
                    color: AppColors.pineGreen,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.cardDark.withValues(alpha: 0.3),
                  child: const Icon(
                    Icons.error,
                    color: AppColors.rosyBrown,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLikedSubmissionGrid(List<Map<String, dynamic>> submissions) {
    if (submissions.isEmpty) {
      return const Center(
        child: Text(
          'No liked submissions yet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submissionData = submissions[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SingleSubmissionScreen(
                  eventId: submissionData['eventId'] ?? '',
                  submissionId: submissionData['submissionId'] ?? '',
                  fromProfile: true,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.rosyBrown.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.rosyBrown.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: submissionData['imageURL'] ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: AppColors.cardDark.withValues(alpha: 0.3),
                      child: const Icon(
                        Icons.image,
                        color: AppColors.rosyBrown,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.cardDark.withValues(alpha: 0.3),
                      child: const Icon(
                        Icons.error,
                        color: AppColors.rosyBrown,
                      ),
                    ),
                  ),
                  // Like indicator in the top right corner
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.rosyBrown.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: AppColors.rosyBrown,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeTab(
      BuildContext context, WidgetRef ref, String targetUserId) {
    final userDataAsync = ref.watch(userDataProvider(targetUserId));
    final badgesAsync = ref.watch(userBadgesProvider(targetUserId));
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = targetUserId == currentUser?.uid;

    return userDataAsync.when(
      data: (user) {
        // Get badges for the physics background
        final badges = badgesAsync.maybeWhen(
          data: (badgesList) => badgesList,
          orElse: () => <String>[],
        );

        return Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                // Profile picture and username section
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildSimpleAvatar(context, user),
                  if (isOwnProfile)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: user != null
                              ? () {
                                  Navigator.of(context)
                                      .push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditProfileScreen(user: user),
                                    ),
                                  )
                                      .then((_) {
                                    _refreshProfileData();
                                  });
                                }
                              : null,
                          borderRadius: BorderRadius.circular(100),
                          splashColor: AppColors.primaryOrange.withValues(alpha: 0.3),
                          highlightColor: AppColors.primaryOrange.withValues(alpha: 0.15),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.092,
                            height: MediaQuery.of(context).size.width * 0.092,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.rosyBrown.withValues(alpha: 0.6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                              boxShadow: [
                                // Primary shadow - rgba(0,0,0,0.35) blur 6px, offset 2px down
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                                // White rim light
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 0),
                                  spreadRadius: 0.5,
                                ),
                                // Coral glow for accent
                                BoxShadow(
                                  color: AppColors.primaryOrange.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width * 0.041,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                user?.username ?? 'Unknown User',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.053,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: AppColors.rosyBrown.withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                    Shadow(
                      color: AppColors.pineGreen.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Social media buttons
              _buildSocialMediaLinks(user),
              const SizedBox(height: 24),

              // Level badge - flexible to fit available space
              Expanded(
                child: Center(
                  child: _buildLevelBadge(context, badges.length),
                ),
              ),
            ],
          ),
          // Subtle lighting gradient overlay for 3-layer depth on OLED
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.35, 0.5, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.pineGreen,
        ),
      ),
      error: (error, stack) => const Center(
        child: Text(
          'Error loading profile',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBadgesTab(
      BuildContext context, WidgetRef ref, String targetUserId) {
    final badgesAsync = ref.watch(userBadgesProvider(targetUserId));

    return badgesAsync.when(
      data: (badges) {
        // Calculate level for empty state display
        final levelInfo = _getLevelInfo(badges.length);
        final level = levelInfo['level'] as int;

        if (badges.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 56),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/levels/level_$level.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No badges yet',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badgeURL = badges[index];
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: badgeURL,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange.withValues(alpha: 0.4),
                          AppColors.rosyBrown.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryOrange,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    // Show level image for error state
                    final levelInfo = _getLevelInfo(badges.length);
                    final level = levelInfo['level'] as int;
                    return Image.asset(
                      'assets/levels/level_$level.png',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryOrange,
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Error loading badges',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withValues(alpha: 0.8),
                    AppColors.primaryOrange.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => ref.refresh(userBadgesProvider(targetUserId)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Retry',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
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

  Widget _buildSocialMediaLinks(UserModel? user) {
    if (user?.socialLinks.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    // Filter out only valid social links
    final validSocialLinks = user!.socialLinks.entries
        .where((entry) => _isValidURL(entry.value))
        .toList();

    // If no valid social links, don't show the section
    if (validSocialLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 24,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: validSocialLinks.map((entry) {
        return _buildSocialMediaButton(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildVerticalSocialMediaLinks(UserModel? user) {
    if (user?.socialLinks.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    // Filter out only valid social links
    final validSocialLinks = user!.socialLinks.entries
        .where((entry) => _isValidURL(entry.value))
        .toList();

    // If no valid social links, don't show the section
    if (validSocialLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: validSocialLinks.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSocialMediaButton(entry.key, entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildSimpleAvatar(BuildContext context, UserModel? user) {
    final photoURL = user?.photoURL;
    final hasPhoto = photoURL != null && photoURL.isNotEmpty;
    final username = user?.username ?? 'U';
    final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.rosyBrown,
            AppColors.pineGreen,
            AppColors.midnightGreen,
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 3,
        ),
        boxShadow: [
          // Deeper primary shadow for z-depth
          BoxShadow(
            color: AppColors.rosyBrown.withValues(alpha: 0.6),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: 2,
          ),
          // Secondary shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          // Highlight for 3D effect
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: CircleAvatar(
        radius: MediaQuery.of(context).size.width * 0.171,
        backgroundColor: Colors.transparent,
        backgroundImage: hasPhoto ? CachedNetworkImageProvider(photoURL) : null,
        child: !hasPhoto
            ? Text(
                firstLetter,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.135,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSocialMediaButton(String platform, String url) {
    final socialData = _getSocialMediaData(platform);

    // Coral tint color for tap/hover - #EE8D6F with 10% overlay
    const coralTint = Color(0xFFEE8D6F);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchURL(url, platform),
        borderRadius: BorderRadius.circular(10),
        splashColor: coralTint.withValues(alpha: 0.1),
        highlightColor: coralTint.withValues(alpha: 0.1),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.12,
          height: MediaQuery.of(context).size.width * 0.12,
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
          decoration: BoxDecoration(
            color: AppColors.rosyBrown.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: socialData.containsKey('image')
              ? Image.asset(
                  socialData['image'] as String,
                  color: Colors.white.withValues(alpha: 0.9),
                  fit: BoxFit.contain,
                )
              : Icon(
                  socialData['icon'] as IconData,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: MediaQuery.of(context).size.width * 0.05,
                ),
        ),
      ),
    );
  }

  bool _isValidURL(String url) {
    url = url.trim();

    // Check minimum length
    if (url.isEmpty) return false;

    // Check if it's a proper URL
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return true;
    }

    // Check if it contains a domain-like structure
    if (url.contains('.') && url.contains('/')) {
      return true;
    }

    // Check if it's a domain without path
    if (url.contains('.') && !url.contains(' ') && url.split('.').length >= 2) {
      return true;
    }

    // Check if it's an email
    if (url.contains('@') && !url.contains('/')) {
      return true;
    }

    // Allow social media usernames (common case)
    // Most social media usernames are alphanumeric with underscores/dots/dashes
    if (RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(url) && url.isNotEmpty) {
      return true;
    }

    // Allow Twitter-style handles
    if (url.startsWith('@') && url.length > 1) {
      return true;
    }

    return false;
  }

  Map<String, dynamic> _getSocialMediaData(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return {
          'image': 'assets/icons/instagram_logo.png',
        };
      case 'twitter':
      case 'x':
        return {
          'image': 'assets/icons/x_logo.png',
        };
      case 'github':
        return {
          'icon': Icons.code,
        };
      case 'youtube':
        return {
          'icon': Icons.play_arrow,
        };
      case 'facebook':
        return {
          'image': 'assets/icons/facebook_logo.png',
        };
      case 'tiktok':
        return {
          'icon': Icons.music_note,
        };
      case 'snapchat':
        return {
          'icon': Icons.camera,
        };
      case 'discord':
        return {
          'icon': Icons.chat,
        };
      default:
        return {
          'icon': Icons.link,
        };
    }
  }

  Future<void> _launchURL(String url, String platform) async {
    try {
      // Validate and format the URL
      String formattedUrl = _formatURL(url, platform);
      AppLogger.i('Attempting to launch URL: $formattedUrl');

      final uri = Uri.parse(formattedUrl);

      // Validate the URI
      if (!uri.hasScheme ||
          (uri.scheme != 'http' &&
              uri.scheme != 'https' &&
              uri.scheme != 'mailto')) {
        throw FormatException('Invalid URL scheme: ${uri.scheme}');
      }

      bool launched = false;

      // Try external application mode first (preferred for social media)
      try {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
        launched = true;
        AppLogger.i('Successfully launched URL in external app: $formattedUrl');
      } catch (e) {
        AppLogger.w('External application launch failed: $e');

        // Fallback to platform default
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          launched = true;
          AppLogger.i(
              'Successfully launched URL with platform default: $formattedUrl');
        } catch (e2) {
          AppLogger.w('Platform default launch failed: $e2');

          // Last resort: in-app web view
          try {
            await launchUrl(
              uri,
              mode: LaunchMode.inAppWebView,
              webViewConfiguration: const WebViewConfiguration(
                enableJavaScript: true,
                enableDomStorage: true,
              ),
            );
            launched = true;
            AppLogger.i('Successfully launched URL in web view: $formattedUrl');
          } catch (e3) {
            AppLogger.e('All launch modes failed: $e3');
          }
        }
      }

      if (!launched) {
        throw Exception('Failed to launch URL with all available methods');
      }
    } catch (e) {
      AppLogger.e('Error launching URL: $url', e);
      if (mounted) {
        CustomSnackBar.showInfo(context, 'Opening link in browser...');
      }
    }
  }

  String _formatURL(String url, String platform) {
    // Remove whitespace
    url = url.trim();

    // If the URL is too short or obviously invalid, don't try to launch it
    if (url.isEmpty) {
      throw FormatException('URL too short: $url');
    }

    // If it already has a scheme, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Special handling for email
    if (url.contains('@') && !url.contains('/')) {
      return 'mailto:$url';
    }

    // Platform-specific URL generation for usernames
    switch (platform.toLowerCase()) {
      case 'instagram':
        return 'https://instagram.com/${_cleanUsername(url)}';
      case 'twitter':
      case 'x':
        return 'https://twitter.com/${_cleanUsername(url)}';
      case 'facebook':
        return 'https://facebook.com/${_cleanUsername(url)}';
      case 'github':
        return 'https://github.com/${_cleanUsername(url)}';
      case 'youtube':
        return 'https://youtube.com/@${_cleanUsername(url)}';
      case 'tiktok':
        return 'https://tiktok.com/@${_cleanUsername(url)}';
      case 'snapchat':
        return 'https://snapchat.com/add/${_cleanUsername(url)}';
      case 'discord':
        // Discord doesn't have direct profile URLs, return as-is
        return 'https://$url';
      default:
        // For unknown platforms, add https
        return 'https://$url';
    }
  }

  String _cleanUsername(String username) {
    // Remove @ symbol if present (common for Twitter handles)
    if (username.startsWith('@')) {
      username = username.substring(1);
    }
    return username;
  }

  // Level system helper methods
  String _getLevelName(BuildContext context, int level) {
    switch (level) {
      case 1:
        return AppLocalizations.of(context)!.levelCurious;
      case 2:
        return AppLocalizations.of(context)!.levelSharing;
      case 3:
        return AppLocalizations.of(context)!.levelConnecting;
      case 4:
        return AppLocalizations.of(context)!.levelContributing;
      case 5:
        return AppLocalizations.of(context)!.levelSupporting;
      case 6:
        return AppLocalizations.of(context)!.levelTrusted;
      case 7:
        return AppLocalizations.of(context)!.levelGuide;
      default:
        return AppLocalizations.of(context)!.levelCurious;
    }
  }

  Map<String, dynamic> _getLevelInfo(int badgeCount) {
    // Level thresholds: 1:0, 2:5, 3:12, 4:20, 5:30, 6:42, 7:56
    const levels = [
      {'level': 1, 'threshold': 0},
      {'level': 2, 'threshold': 5},
      {'level': 3, 'threshold': 12},
      {'level': 4, 'threshold': 20},
      {'level': 5, 'threshold': 30},
      {'level': 6, 'threshold': 42},
      {'level': 7, 'threshold': 56},
    ];

    for (int i = levels.length - 1; i >= 0; i--) {
      if (badgeCount >= (levels[i]['threshold'] as int)) {
        return levels[i];
      }
    }
    return levels[0];
  }

  Widget _buildLevelBadge(BuildContext context, int badgeCount) {
    final levelInfo = _getLevelInfo(badgeCount);
    final level = levelInfo['level'] as int;
    final levelName = _getLevelName(context, level);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showLevelTooltip(context, badgeCount),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.48,
            height: MediaQuery.of(context).size.width * 0.48,
            child: Image.asset(
              'assets/levels/level_$level.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryOrange.withValues(alpha: 0.3),
                        AppColors.rosyBrown.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events,
                      color: AppColors.primaryOrange,
                      size: 80,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.rosyBrown.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                // Soft drop shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                // Subtle coral glow
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Reflection highlight overlay - top third
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                // Text content
                Text(
                  levelName,
                  style: TextStyle(
                    color: const Color(0xFFFFF4F0), // Off-white #FFF4F0
                    fontSize: MediaQuery.of(context).size.width * 0.037,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    shadows: [
                      // Soft drop shadow
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelTooltip(BuildContext context, int currentBadgeCount) {
    final currentLevelInfo = _getLevelInfo(currentBadgeCount);
    final currentLevel = currentLevelInfo['level'] as int;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.midnightGreen.withValues(alpha: 0.95),
                AppColors.midnightGreen.withValues(alpha: 0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryOrange.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryOrange.withValues(alpha: 0.3),
                      AppColors.rosyBrown.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: AppColors.primaryOrange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.levelSystem,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Levels list
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildLevelRow(context, 1, 0, currentLevel, currentBadgeCount),
                    _buildLevelRow(context, 2, 5, currentLevel, currentBadgeCount),
                    _buildLevelRow(context, 3, 12, currentLevel, currentBadgeCount),
                    _buildLevelRow(context, 4, 20, currentLevel, currentBadgeCount),
                    _buildLevelRow(context, 5, 30, currentLevel, currentBadgeCount),
                    _buildLevelRow(context, 6, 42, currentLevel, currentBadgeCount),
                    _buildLevelRow(context, 7, 56, currentLevel, currentBadgeCount),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelRow(BuildContext context, int level, int threshold, int currentLevel, int currentBadgeCount) {
    final isUnlocked = level <= currentLevel;
    final isCurrent = level == currentLevel;
    final name = _getLevelName(context, level);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isCurrent
            ? LinearGradient(
                colors: [
                  AppColors.primaryOrange.withValues(alpha: 0.3),
                  AppColors.rosyBrown.withValues(alpha: 0.3),
                ],
              )
            : LinearGradient(
                colors: [
                  AppColors.midnightGreen.withValues(alpha: 0.3),
                  AppColors.midnightGreen.withValues(alpha: 0.2),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? AppColors.primaryOrange.withValues(alpha: 0.5)
              : isUnlocked
                  ? AppColors.pineGreen.withValues(alpha: 0.3)
                  : AppColors.textSecondary.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Level image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked
                    ? AppColors.primaryOrange.withValues(alpha: 0.5)
                    : AppColors.textSecondary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: isUnlocked
                  ? Image.asset(
                      'assets/levels/level_$level.png',
                      fit: BoxFit.cover,
                    )
                  : ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.grey.withValues(alpha: 0.7),
                        BlendMode.saturation,
                      ),
                      child: Image.asset(
                        'assets/levels/level_$level.png',
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Level info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.levelNumber(level),
                      style: TextStyle(
                        color: isUnlocked
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.currentLevel,
                          style: const TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    color: isUnlocked
                        ? AppColors.primaryOrange
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  threshold == 0
                      ? AppLocalizations.of(context)!.startingLevel
                      : AppLocalizations.of(context)!.requiresBadges(threshold),
                  style: TextStyle(
                    color: isUnlocked
                        ? AppColors.textSecondary
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Lock/Check icon
          Icon(
            isUnlocked ? Icons.check_circle : Icons.lock,
            color: isUnlocked
                ? AppColors.pineGreen
                : AppColors.textSecondary.withValues(alpha: 0.4),
            size: 28,
          ),
        ],
      ),
    );
  }
}
