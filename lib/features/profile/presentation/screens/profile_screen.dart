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
    _tabController = TabController(length: 2, vsync: this);

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
    final authState = ref.watch(authStateProvider);
    final isOwnProfile =
        widget.userId == null || widget.userId == currentUser?.uid;
    final targetUserId = widget.userId ?? currentUser?.uid;

    // Debug logging
    AppLogger.i(
        'ProfileScreen: currentUser?.uid = ${currentUser?.uid}, widget.userId = ${widget.userId}, targetUserId = $targetUserId');
    AppLogger.i('ProfileScreen: authState = ${authState.toString()}');

    if (targetUserId == null) {
      AppLogger.w(
          'ProfileScreen: targetUserId is null, showing user not found');
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    final userDataAsync = ref.watch(userDataProvider(targetUserId));

    return userDataAsync.when(
      data: (user) =>
          _buildProfile(context, ref, user, isOwnProfile, targetUserId),
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Loading...',
              style: TextStyle(color: AppColors.textPrimary)),
          centerTitle: true,
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
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.pineGreen),
            ),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Error',
              style: TextStyle(color: AppColors.textPrimary)),
          centerTitle: true,
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading profile: $error',
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh,
                                  color: Colors.white, size: 20),
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
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Profile',
                style: TextStyle(color: AppColors.textPrimary)),
            centerTitle: true,
          ),
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
                    const Text(
                      'Profile not set up yet',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please complete your profile setup',
                      style: TextStyle(
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
                            AppColors.primaryOrange.withOpacity(0.8),
                            AppColors.primaryOrangeDark
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withOpacity(0.4),
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
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 20),
                                SizedBox(width: 12),
                                Text('Complete Setup',
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
            ),
          ),
        );
      } else {
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Profile',
                style: TextStyle(color: AppColors.textPrimary)),
            centerTitle: true,
          ),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen.withValues(alpha: 0.9),
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.065,
        title: Text(
          isOwnProfile
              ? AppLocalizations.of(context)!.profile
              : user?.displayName ?? 'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width * 0.045,
          ),
        ),
        centerTitle: true,
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
        actions: [
          if (!isOwnProfile)
            Container(
              margin: EdgeInsets.only(
                  right: MediaQuery.of(context).size.width * 0.02,
                  top: 3,
                  bottom: 3),
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
                border: Border.all(color: AppColors.iceBorder, width: 1),
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
                onPressed: () => context.push('/chat/$targetUserId'),
                icon: Icon(
                  Icons.message,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.04,
                ),
                tooltip: 'Send Message',
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width * 0.08,
                  minHeight: MediaQuery.of(context).size.width * 0.08,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          if (isOwnProfile)
            Container(
              margin: EdgeInsets.only(
                  right: MediaQuery.of(context).size.width * 0.04,
                  top: 3,
                  bottom: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    AppColors.rosyBrown.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.iceBorder, width: 1),
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
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.04,
                ),
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
                    if (user != null) {
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
                    try {
                      final authService = ref.read(authServiceProvider);
                      await authService.signOut();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sign out failed: ${e.toString()}'),
                            backgroundColor: AppColors.errorColor,
                          ),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  // Caret indicator
                  PopupMenuItem<String>(
                    enabled: false,
                    height: 0,
                    child: Container(
                      alignment: Alignment.centerRight,
                      margin: EdgeInsets.only(
                        right: MediaQuery.of(context).size.width * 0.02,
                        bottom: MediaQuery.of(context).size.height * 0.01,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: AppColors.iceBorder,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                  ),
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
        ],
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
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: 100), // Space for app bar
              ),
              _buildProfileHeader(context, user, isOwnProfile),
              _buildTabBar(context),
              _buildTabContent(context, ref, targetUserId, isOwnProfile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, UserModel? user, bool isOwnProfile) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
        decoration: BoxDecoration(
          gradient: AppColors.iceGlassGradient,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.iceBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(-2, -2),
            ),
            BoxShadow(
              color: AppColors.rosyBrown.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(2, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.rosyBrown.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: MediaQuery.of(context).size.width * 0.13,
                backgroundColor: Colors.transparent,
                backgroundImage: user?.photoURL != null
                    ? CachedNetworkImageProvider(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Icon(
                        Icons.person,
                        size: MediaQuery.of(context).size.width * 0.13,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Unknown User',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: MediaQuery.of(context).size.width * 0.065,
                fontWeight: FontWeight.bold,
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
            if (user?.username != null && user!.username!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '@${user!.username!}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            _buildSocialMediaLinks(user),
            const SizedBox(height: 16),
            _buildBadges(context, ref, user),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Posts', '0'),
                _buildStatItem('Likes', '0'),
                _buildStatItem('Rank', '#-'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.rosyBrown,
            fontSize: MediaQuery.of(context).size.width * 0.05,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: AppColors.rosyBrown.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: MediaQuery.of(context).size.width * 0.035,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.12),
              AppColors.pineGreen.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
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
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.pineGreen.withValues(alpha: 0.8),
                AppColors.rosyBrown.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.pineGreen.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width * 0.04,
          ),
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Liked'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, WidgetRef ref,
      String targetUserId, bool isOwnProfile) {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildUserSubmissions(context, ref, targetUserId),
          _buildLikedSubmissions(context, ref, targetUserId),
        ],
      ),
    );
  }

  Widget _buildUserSubmissions(
      BuildContext context, WidgetRef ref, String targetUserId) {
    final submissionsAsync =
        ref.watch(userSubmissionsFromUserCollectionProvider(targetUserId));

    return submissionsAsync.when(
      data: (submissions) => _buildSubmissionGrid(submissions),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.pineGreen),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading submissions',
              style: const TextStyle(color: AppColors.textPrimary),
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
                      userSubmissionsFromUserCollectionProvider(targetUserId)),
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

  Widget _buildLikedSubmissions(
      BuildContext context, WidgetRef ref, String targetUserId) {
    final likedSubmissionsAsync =
        ref.watch(userLikedSubmissionsProvider(targetUserId));

    return likedSubmissionsAsync.when(
      data: (submissions) => _buildLikedSubmissionGrid(submissions),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.pineGreen),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading liked submissions',
              style: const TextStyle(color: AppColors.textPrimary),
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
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: MediaQuery.of(context).size.height * 0.015,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            AppColors.pineGreen.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: validSocialLinks.map((entry) {
          return _buildSocialMediaButton(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildBadges(BuildContext context, WidgetRef ref, UserModel? user) {
    if (user == null) {
      return const SizedBox.shrink();
    }

    final badgesAsync = ref.watch(userBadgesProvider(user.uid));

    return badgesAsync.when(
      data: (badges) {
        if (badges.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: MediaQuery.of(context).size.height * 0.015,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                AppColors.rosyBrown.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
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
          child: Column(
            children: [
              Text(
                'Event Badges',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: badges.map((badgeURL) {
                  return _buildBadgeItem(badgeURL);
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildBadgeItem(String badgeURL) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.12,
      height: MediaQuery.of(context).size.width * 0.12,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.rosyBrown.withValues(alpha: 0.2),
            AppColors.pineGreen.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.rosyBrown.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.rosyBrown.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: badgeURL,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.rosyBrown.withValues(alpha: 0.3),
                  AppColors.pineGreen.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppColors.rosyBrown,
              size: 24,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.rosyBrown.withValues(alpha: 0.3),
                  AppColors.pineGreen.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppColors.rosyBrown,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialMediaButton(String platform, String url) {
    final socialData = _getSocialMediaData(platform);

    return GestureDetector(
      onTap: () => _launchURL(url, platform),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.12,
        height: MediaQuery.of(context).size.width * 0.12,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: socialData['gradient'] as List<Color>,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (socialData['gradient'] as List<Color>)[0]
                  .withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          socialData['icon'] as IconData,
          color: Colors.white,
          size: MediaQuery.of(context).size.width * 0.06,
        ),
      ),
    );
  }

  bool _isValidURL(String url) {
    url = url.trim();

    // Check minimum length
    if (url.length < 1) return false;

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
    if (RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(url) && url.length >= 1) {
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
          'icon': Icons.camera_alt,
          'gradient': [
            const Color(0xFF833AB4),
            const Color(0xFFE1306C),
            const Color(0xFFFD1D1D),
            const Color(0xFFF77737),
          ],
        };
      case 'twitter':
      case 'x':
        return {
          'icon': Icons.alternate_email,
          'gradient': [
            const Color(0xFF1DA1F2),
            const Color(0xFF0084B4),
          ],
        };
      case 'linkedin':
        return {
          'icon': Icons.work,
          'gradient': [
            const Color(0xFF0077B5),
            const Color(0xFF005885),
          ],
        };
      case 'github':
        return {
          'icon': Icons.code,
          'gradient': [
            const Color(0xFF333333),
            const Color(0xFF000000),
          ],
        };
      case 'youtube':
        return {
          'icon': Icons.play_arrow,
          'gradient': [
            const Color(0xFFFF0000),
            const Color(0xFFCC0000),
          ],
        };
      case 'facebook':
        return {
          'icon': Icons.facebook,
          'gradient': [
            const Color(0xFF4267B2),
            const Color(0xFF365899),
          ],
        };
      case 'tiktok':
        return {
          'icon': Icons.music_note,
          'gradient': [
            const Color(0xFF000000),
            const Color(0xFF333333),
          ],
        };
      case 'snapchat':
        return {
          'icon': Icons.camera,
          'gradient': [
            const Color(0xFFFFFC00),
            const Color(0xFFCCCA00),
          ],
        };
      case 'discord':
        return {
          'icon': Icons.chat,
          'gradient': [
            const Color(0xFF7289DA),
            const Color(0xFF5B6DAE),
          ],
        };
      case 'website':
      case 'portfolio':
        return {
          'icon': Icons.language,
          'gradient': [
            AppColors.pineGreen,
            AppColors.midnightGreen,
          ],
        };
      default:
        return {
          'icon': Icons.link,
          'gradient': [
            AppColors.rosyBrown,
            AppColors.rosyBrown.withValues(alpha: 0.8),
          ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Opening link in browser...'),
            backgroundColor: AppColors.pineGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatURL(String url, String platform) {
    // Remove whitespace
    url = url.trim();

    // If the URL is too short or obviously invalid, don't try to launch it
    if (url.length < 1) {
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
      case 'linkedin':
        return 'https://linkedin.com/in/${_cleanUsername(url)}';
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
      case 'website':
      case 'portfolio':
        // For websites, add https if no scheme
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
