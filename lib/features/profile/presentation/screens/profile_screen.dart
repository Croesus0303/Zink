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
    AppLogger.i('ProfileScreen: currentUser?.uid = ${currentUser?.uid}, widget.userId = ${widget.userId}, targetUserId = $targetUserId');
    AppLogger.i('ProfileScreen: authState = ${authState.toString()}');

    if (targetUserId == null) {
      AppLogger.w('ProfileScreen: targetUserId is null, showing user not found');
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
          title: const Text('Loading...', style: TextStyle(color: AppColors.textPrimary)),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.radialBackgroundGradient),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan),
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
          title: const Text('Error', style: TextStyle(color: AppColors.textPrimary)),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.radialBackgroundGradient),
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
                        colors: [AppColors.primaryCyan.withOpacity(0.8), AppColors.primaryCyanDark],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryCyan.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => ref.refresh(userDataProvider(targetUserId)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Retry', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
            title: const Text('Profile', style: TextStyle(color: AppColors.textPrimary)),
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: Container(
              decoration: BoxDecoration(gradient: AppColors.radialBackgroundGradient),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryCyan, AppColors.primaryOrange, AppColors.warmBeige],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 64,
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
                          colors: [AppColors.primaryOrange.withOpacity(0.8), AppColors.primaryOrangeDark],
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
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 20),
                                SizedBox(width: 12),
                                Text('Complete Setup', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
            title: const Text('Profile', style: TextStyle(color: AppColors.textPrimary)),
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: Container(
              decoration: BoxDecoration(gradient: AppColors.radialBackgroundGradient),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isOwnProfile
              ? AppLocalizations.of(context)!.profile
              : user?.displayName ?? 'Profile',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
        if (!isOwnProfile)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.cyanWithOpacity,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryCyan, width: 1),
            ),
            child: IconButton(
              onPressed: () => context.push('/chat/$targetUserId'),
              icon: const Icon(Icons.message, color: AppColors.primaryCyan),
              tooltip: 'Send Message',
            ),
          ),
        if (isOwnProfile)
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.orangeWithOpacity,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryOrange, width: 1),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.primaryOrange),
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
                PopupMenuItem<String>(
                  value: 'editProfile',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: AppColors.primaryCyan),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.editProfile,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'testStorage',
                  child: Row(
                    children: [
                      Icon(Icons.storage, color: AppColors.primaryCyan),
                      SizedBox(width: 8),
                      Text(
                        'Test Storage',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: AppColors.primaryCyan),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.settings,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'signOut',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: AppColors.primaryOrange),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.signOut,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.radialBackgroundGradient),
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
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryCyan.withOpacity(0.2),
              AppColors.primaryOrange.withOpacity(0.15),
              AppColors.warmBeige.withOpacity(0.1),
              AppColors.primaryCyanDark.withOpacity(0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.primaryCyan.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryCyan.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.primaryOrange.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(5, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryCyan,
                    AppColors.primaryOrange,
                    AppColors.warmBeige,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 52,
                backgroundColor: Colors.transparent,
                backgroundImage: user?.photoURL != null
                    ? CachedNetworkImageProvider(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? const Icon(Icons.person, size: 52, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Unknown User',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: AppColors.primaryCyan.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            if (user?.username != null && user!.username!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '@${user!.username!}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            _buildSocialMediaLinks(user),
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
          style: const TextStyle(
            color: AppColors.primaryOrange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryCyan.withOpacity(0.15),
              AppColors.primaryOrange.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryCyan.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryCyan.withOpacity(0.8),
                AppColors.primaryOrange.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryCyan.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
        child: CircularProgressIndicator(color: AppColors.primaryCyan),
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
                  colors: [AppColors.primaryCyan.withOpacity(0.8), AppColors.primaryCyanDark],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => ref.refresh(userSubmissionsFromUserCollectionProvider(targetUserId)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Retry', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
        child: CircularProgressIndicator(color: AppColors.primaryCyan),
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
                  colors: [AppColors.primaryOrange.withOpacity(0.8), AppColors.primaryOrangeDark],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => ref.refresh(userLikedSubmissionsProvider(targetUserId)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Retry', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
              border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: submission.imageURL,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.cardDark.withOpacity(0.3),
                  child: const Icon(
                    Icons.image,
                    color: AppColors.primaryCyan,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.cardDark.withOpacity(0.3),
                  child: const Icon(
                    Icons.error,
                    color: AppColors.primaryOrange,
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
              border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
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
                      color: AppColors.cardDark.withOpacity(0.3),
                      child: const Icon(
                        Icons.image,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.cardDark.withOpacity(0.3),
                      child: const Icon(
                        Icons.error,
                        color: AppColors.primaryOrange,
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
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: AppColors.primaryOrange,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cyanWithOpacity,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3), width: 1),
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

  Widget _buildSocialMediaButton(String platform, String url) {
    final socialData = _getSocialMediaData(platform);
    
    return GestureDetector(
      onTap: () => _launchURL(url, platform),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: socialData['gradient'] as List<Color>,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (socialData['gradient'] as List<Color>)[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          socialData['icon'] as IconData,
          color: Colors.white,
          size: 24,
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
            AppColors.primaryCyan,
            AppColors.primaryCyanDark,
          ],
        };
      default:
        return {
          'icon': Icons.link,
          'gradient': [
            AppColors.primaryOrange,
            AppColors.primaryOrange.withOpacity(0.8),
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
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https' && uri.scheme != 'mailto')) {
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
          AppLogger.i('Successfully launched URL with platform default: $formattedUrl');
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
            content: Text('Opening link in browser...'),
            backgroundColor: AppColors.primaryCyan,
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
