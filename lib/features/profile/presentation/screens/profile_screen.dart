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
import '../../../../shared/widgets/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/glassy_button.dart';
import '../../../../shared/widgets/tiny_separator_line.dart';
import '../widgets/animated_badge_showcase.dart';

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
  bool _hasLoadedLikes = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Listen to tab animation for smooth transitions
    _tabController.animation!.addListener(() {
      setState(() {});
    });

    // Listen to tab changes to load likes lazily
    _tabController.addListener(() {
      if (_tabController.index == 2 && !_hasLoadedLikes) {
        // Tab index 2 is the Likes tab
        setState(() {
          _hasLoadedLikes = true;
        });
      }
    });

    // Reload profile data when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProfileData();
    });
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
      // Note: userBadgesProvider is derived from submissions, no need to invalidate
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

    // Check if critical data is still loading - especially important for first login
    final isLoading = authStateAsync.isLoading ||
        currentUserDataAsync.isLoading ||
        userDataAsync.isLoading ||
        userSubmissionsAsync.isLoading ||
        userLikedSubmissionsAsync.isLoading;

    // Show loading screen while essential data loads
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.midnightGreen,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.pineGreen,
            strokeWidth: MediaQuery.of(context).size.width * 0.01,
          ),
        ),
      );
    }

    return userDataAsync.when(
      data: (user) =>
          _buildProfile(context, ref, user, isOwnProfile, targetUserId),
      loading: () => const Scaffold(
        backgroundColor: AppColors.midnightGreen,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.pineGreen),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.midnightGreen,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!
                    .errorLoadingProfile(error.toString()),
                style: const TextStyle(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
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
                  borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: MediaQuery.of(context).size.width * 0.0025,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pineGreen.withValues(alpha: 0.4),
                      blurRadius: MediaQuery.of(context).size.width * 0.03,
                      offset: Offset(0, MediaQuery.of(context).size.height * 0.0075),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                    onTap: () => ref.refresh(userDataProvider(targetUserId)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.06,
                          vertical: MediaQuery.of(context).size.height * 0.02),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width * 0.05),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                          Text(AppLocalizations.of(context)!.retry,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
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

  Widget _buildProfile(BuildContext context, WidgetRef ref, UserModel? user,
      bool isOwnProfile, String targetUserId) {
    // Handle case where user document doesn't exist (new users before onboarding)
    if (user == null) {
      if (isOwnProfile) {
        return Scaffold(
          backgroundColor: AppColors.midnightGreen,
          body: Center(
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
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.075),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.rosyBrown,
                        blurRadius: MediaQuery.of(context).size.width * 0.05,
                        offset: Offset(0, MediaQuery.of(context).size.height * 0.01),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: MediaQuery.of(context).size.width * 0.15,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Text(
                  AppLocalizations.of(context)!.profileNotSetUp,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: MediaQuery.of(context).size.width * 0.055,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Text(
                  AppLocalizations.of(context)!.pleaseCompleteProfileSetup,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryOrange.withValues(alpha: 0.8),
                        AppColors.primaryOrangeDark
                      ],
                    ),
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withValues(alpha: 0.9),
                        blurRadius: MediaQuery.of(context).size.width * 0.03,
                        offset: Offset(0, MediaQuery.of(context).size.height * 0.0075),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                      onTap: () => context.go('/onboarding'),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.08,
                            vertical: MediaQuery.of(context).size.height * 0.0225),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit,
                                color: Colors.white,
                                size: MediaQuery.of(context).size.width * 0.05),
                            SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                            Text(AppLocalizations.of(context)!.completeSetup,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: MediaQuery.of(context).size.width * 0.04,
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
      } else {
        return Scaffold(
          backgroundColor: AppColors.midnightGreen,
          body: Center(
            child: Text(
              'User not found',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: MediaQuery.of(context).size.width * 0.045),
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.midnightGreen,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Tab content with proper padding
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.075),
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildHomeTab(context, ref, targetUserId, isOwnProfile),
                        _buildUserSubmissions(context, ref, targetUserId),
                        _buildLikedSubmissions(context, ref, targetUserId),
                      ],
                    ),
                  ),
                ),
              ),
              // Spacer between content and tabs
              Container(
                height: MediaQuery.of(context).size.height * 0.01,
                color: AppColors.midnightGreen,
              ),
              // Bottom tab bar
              _buildBottomTabBar(context),
            ],
          ),
          // Back button (top left) - moved to top of stack for proper click handling
          Positioned(
            top: MediaQuery.of(context).padding.top + MediaQuery.of(context).size.height * 0.01,
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
              top: MediaQuery.of(context).padding.top + MediaQuery.of(context).size.height * 0.01,
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
              top: MediaQuery.of(context).padding.top + MediaQuery.of(context).size.height * 0.01,
              right: MediaQuery.of(context).size.width * 0.04,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Settings button
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width * 0.07,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  // Sign Out button
                  IconButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha: 0.6),
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.06),
                          ),
                          content: Container(
                            decoration: BoxDecoration(
                              color: AppColors.midnightGreen
                                  .withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.06),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: MediaQuery.of(context).size.width * 0.00375,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: MediaQuery.of(context).size.width * 0.05,
                                  offset: Offset(0, MediaQuery.of(context).size.height * 0.0125),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.signOut,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: MediaQuery.of(context).size.width * 0.05,
                                    ),
                                  ),
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .signOutConfirmation,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: MediaQuery.of(context).size.width * 0.04,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(
                                          AppLocalizations.of(context)!.cancel,
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: MediaQuery.of(context).size.width * 0.04,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
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
                                              BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                                            onTap: () =>
                                                Navigator.of(context).pop(true),
                                            child: Padding(
                                              padding:
                                                  EdgeInsets.symmetric(
                                                horizontal: MediaQuery.of(context).size.width * 0.05,
                                                vertical: MediaQuery.of(context).size.height * 0.015,
                                              ),
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .signOut,
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
                          if (context.mounted) {
                            context.go('/login');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            CustomSnackBar.showError(
                                context, 'Sign out failed: ${e.toString()}');
                          }
                        }
                      }
                    },
                    icon: Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width * 0.07,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // Centered Profile text - moved to top of stack
          Positioned(
            top: MediaQuery.of(context).padding.top +
                MediaQuery.of(context).size.height * 0.01 +
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
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTabBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.025),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.08,
        vertical: MediaQuery.of(context).size.height * 0.01,
      ),
      height: MediaQuery.of(context).size.height * 0.065,
      decoration: BoxDecoration(
        color: AppColors.midnightGreen,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: MediaQuery.of(context).size.width * 0.00375,
          ),
        ),
        boxShadow: [
          // Sharper upward shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: MediaQuery.of(context).size.width * 0.02,
            offset: Offset(0, -MediaQuery.of(context).size.height * 0.005),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabBubble(context, 0, Icons.home),
          _buildTabBubble(context, 1, Icons.grid_on),
          _buildTabBubble(context, 2, Icons.favorite),
        ],
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
            final borderRadius = MediaQuery.of(context).size.width * 0.05;
            final decoration = BoxDecoration.lerp(
              createPineGreenDecoration(borderRadius: borderRadius),
              createRosyBrownDecoration(borderRadius: borderRadius),
              progress,
            );

            // Calculate shine opacity
            final shineAlphaTop = 0.3 + (0.2 * progress);
            final shineAlphaBottom = 0.15 + (0.1 * progress);

            // Calculate icon opacity and size - consistent 0.8 for inactive
            final iconAlpha = 0.8 + (0.2 * progress);
            final iconSize = MediaQuery.of(context).size.width * 0.055 + (MediaQuery.of(context).size.width * 0.005 * progress);

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
                        blurRadius: MediaQuery.of(context).size.width * 0.04 * progress,
                        spreadRadius: MediaQuery.of(context).size.width * 0.005 * progress,
                      ),
                    ...(decoration.boxShadow ?? []),
                  ],
                ),
                child: Stack(
                  children: [
                    // Glassy shine overlay - always present for crystalline effect
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(borderRadius),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.topLeft,
                              radius: 1.2,
                              colors: [
                                Colors.white.withValues(alpha: shineAlphaTop),
                                Colors.white
                                    .withValues(alpha: shineAlphaBottom),
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
      data: (submissions) => _buildSubmissionGrid(submissions),
      loading: () => _buildSubmissionGrid([]), // Show empty grid while loading
      error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading submissions',
                style: TextStyle(color: AppColors.textPrimary,
                    fontSize: MediaQuery.of(context).size.width * 0.04),
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
                  borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: MediaQuery.of(context).size.width * 0.0025,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pineGreen.withValues(alpha: 0.4),
                      blurRadius: MediaQuery.of(context).size.width * 0.03,
                      offset: Offset(0, MediaQuery.of(context).size.height * 0.0075),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                    onTap: () => ref.refresh(
                        userSubmissionsFromUserCollectionProvider(
                            targetUserId)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.06,
                          vertical: MediaQuery.of(context).size.height * 0.02),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width * 0.05),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                          Text(AppLocalizations.of(context)!.retry,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
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

  Widget _buildLikedSubmissions(
      BuildContext context, WidgetRef ref, String targetUserId) {
    // Only load liked submissions if the tab has been accessed
    if (!_hasLoadedLikes) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryOrange,
          strokeWidth: MediaQuery.of(context).size.width * 0.0075,
        ),
      );
    }

    final likedSubmissionsAsync =
        ref.watch(userLikedSubmissionsProvider(targetUserId));

    return likedSubmissionsAsync.when(
      data: (submissions) => _buildLikedSubmissionGrid(submissions),
      loading: () => Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryOrange,
          strokeWidth: MediaQuery.of(context).size.width * 0.0075,
        ),
      ),
      error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading liked submissions',
                style: TextStyle(color: AppColors.textPrimary,
                    fontSize: MediaQuery.of(context).size.width * 0.04),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.rosyBrown,
                      AppColors.rosyBrown,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: MediaQuery.of(context).size.width * 0.0025,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rosyBrown,
                      blurRadius: MediaQuery.of(context).size.width * 0.03,
                      offset: Offset(0, MediaQuery.of(context).size.height * 0.0075),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                    onTap: () =>
                        ref.refresh(userLikedSubmissionsProvider(targetUserId)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.06,
                          vertical: MediaQuery.of(context).size.height * 0.02),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width * 0.05),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                          Text(AppLocalizations.of(context)!.retry,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
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

  Widget _buildSubmissionGrid(List<SubmissionModel> submissions) {
    if (submissions.isEmpty) {
      return Center(
        child: Text(
          'No submissions yet',
          style: TextStyle(color: AppColors.textSecondary,
              fontSize: MediaQuery.of(context).size.width * 0.04),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width * 0.01,
          MediaQuery.of(context).size.height * 0.005,
          MediaQuery.of(context).size.width * 0.01,
          MediaQuery.of(context).size.height * 0.01),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: MediaQuery.of(context).size.width * 0.005,
        mainAxisSpacing: MediaQuery.of(context).size.width * 0.005,
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
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
              border: Border.all(
                color: AppColors.pineGreen.withValues(alpha: 0.3),
                width: MediaQuery.of(context).size.width * 0.00375,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pineGreen.withValues(alpha: 0.1),
                  blurRadius: MediaQuery.of(context).size.width * 0.02,
                  offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
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
      return Center(
        child: Text(
          'No liked submissions yet',
          style: TextStyle(color: AppColors.textSecondary,
              fontSize: MediaQuery.of(context).size.width * 0.04),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width * 0.01,
          MediaQuery.of(context).size.height * 0.005,
          MediaQuery.of(context).size.width * 0.01,
          MediaQuery.of(context).size.height * 0.01),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: MediaQuery.of(context).size.width * 0.005,
        mainAxisSpacing: MediaQuery.of(context).size.width * 0.005,
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
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
              border: Border.all(
                color: AppColors.rosyBrown,
                width: MediaQuery.of(context).size.width * 0.00375,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.rosyBrown,
                  blurRadius: MediaQuery.of(context).size.width * 0.02,
                  offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeTab(BuildContext context, WidgetRef ref, String targetUserId,
      bool isOwnProfile) {
    final userDataAsync = ref.watch(userDataProvider(targetUserId));
    final badges = ref.watch(userBadgesProvider(targetUserId));

    return userDataAsync.when(
      data: (user) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.06),
              // Profile picture with edit button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildSimpleAvatar(context, user),
                  if (isOwnProfile)
                    Positioned(
                      bottom: MediaQuery.of(context).size.width * 0.01,
                      right: MediaQuery.of(context).size.width * 0.01,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (user != null) {
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
                        },
                        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.25),
                        splashColor:
                            AppColors.primaryOrange.withValues(alpha: 0.3),
                        highlightColor:
                            AppColors.primaryOrange.withValues(alpha: 0.15),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.092,
                          height: MediaQuery.of(context).size.width * 0.092,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.rosyBrown,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: MediaQuery.of(context).size.width * 0.0025,
                            ),
                            boxShadow: [
                              // Primary shadow
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: MediaQuery.of(context).size.width * 0.015,
                                offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
                              ),
                              // White rim light
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.15),
                                blurRadius: MediaQuery.of(context).size.width * 0.01,
                                offset: const Offset(0, 0),
                                spreadRadius: MediaQuery.of(context).size.width * 0.00125,
                              ),
                              // Coral glow for accent
                              BoxShadow(
                                color: AppColors.primaryOrange
                                    .withValues(alpha: 0.25),
                                blurRadius: MediaQuery.of(context).size.width * 0.025,
                                offset: Offset(0, MediaQuery.of(context).size.height * 0.00375),
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
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
            Text(
              user?.username ?? 'Unknown User',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.053,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: AppColors.rosyBrown,
                    blurRadius: MediaQuery.of(context).size.width * 0.03,
                  ),
                  Shadow(
                    color: AppColors.pineGreen.withValues(alpha: 0.4),
                    blurRadius: MediaQuery.of(context).size.width * 0.02,
                    offset: Offset(MediaQuery.of(context).size.width * 0.005,
                        MediaQuery.of(context).size.height * 0.0025),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            // Social media buttons
            _buildSocialMediaLinks(user),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),

            // Divider line
            const TinySeparatorLine(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            // Badges title
            Text(
              'Badges',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // Badge showcase
            Expanded(
              child: AnimatedBadgeShowcase(
                badges: badges,
                currentUserId: targetUserId,
              ),
            ),
          ],
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: AppColors.pineGreen,
          strokeWidth: MediaQuery.of(context).size.width * 0.01,
        ),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading profile',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: MediaQuery.of(context).size.width * 0.04,
          ),
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
      spacing: MediaQuery.of(context).size.width * 0.06,
      runSpacing: MediaQuery.of(context).size.height * 0.015,
      alignment: WrapAlignment.center,
      children: validSocialLinks.map((entry) {
        return _buildSocialMediaButton(entry.key, entry.value);
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
          width: MediaQuery.of(context).size.width * 0.0075,
        ),
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01),
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
                      blurRadius: MediaQuery.of(context).size.width * 0.02,
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
        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.025),
        splashColor: coralTint.withValues(alpha: 0.1),
        highlightColor: coralTint.withValues(alpha: 0.1),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.12,
          height: MediaQuery.of(context).size.width * 0.12,
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
          decoration: BoxDecoration(
            color: AppColors.rosyBrown,
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.025),
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
}
