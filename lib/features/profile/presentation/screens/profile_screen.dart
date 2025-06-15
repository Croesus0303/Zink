import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../events/providers/events_providers.dart';
import '../../../submissions/data/models/submission_model.dart';
import '../../../submissions/presentation/screens/single_submission_screen.dart';
import '../../../../l10n/app_localizations.dart';
import 'edit_profile_screen.dart';
import 'storage_test_screen.dart';
import '../../../../shared/widgets/crystal_scaffold.dart';
import '../../../../shared/widgets/crystal_container.dart';
import '../../../../shared/widgets/crystal_button.dart';
import '../../../../shared/widgets/app_colors.dart';

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
    final isOwnProfile =
        widget.userId == null || widget.userId == currentUser?.uid;
    final targetUserId = widget.userId ?? currentUser?.uid;

    if (targetUserId == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    final userDataAsync = ref.watch(userDataProvider(targetUserId));

    return userDataAsync.when(
      data: (user) =>
          _buildProfile(context, ref, user, isOwnProfile, targetUserId),
      loading: () => CrystalScaffold(
        appBarTitle: 'Loading...',
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      ),
      error: (error, stack) => CrystalScaffold(
        appBarTitle: 'Error',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading profile: $error',
                style: const TextStyle(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CrystalButton(
                text: 'Retry',
                onPressed: () => ref.refresh(userDataProvider(targetUserId)),
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, UserModel? user,
      bool isOwnProfile, String targetUserId) {
    return CrystalScaffold(
      appBarTitle: isOwnProfile
          ? AppLocalizations.of(context)!.profile
          : user?.displayName ?? 'Profile',
      appBarActions: [
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
      body: CustomScrollView(
        slivers: [
          _buildProfileHeader(context, user, isOwnProfile),
          _buildTabBar(context),
          _buildTabContent(context, ref, targetUserId, isOwnProfile),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, UserModel? user, bool isOwnProfile) {
    return SliverToBoxAdapter(
      child: CrystalContainer(
        margin: const EdgeInsets.all(16),
        useCyanAccent: true,
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryCyan,
              backgroundImage: user?.photoURL != null
                  ? CachedNetworkImageProvider(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Unknown User',
              style: const TextStyle(
                color: AppColors.primaryCyan,
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cardDark.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.primaryCyan,
            borderRadius: BorderRadius.circular(16),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
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
            CrystalButton(
              text: 'Retry',
              onPressed: () => ref.refresh(
                  userSubmissionsFromUserCollectionProvider(targetUserId)),
              icon: Icons.refresh,
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
            CrystalButton(
              text: 'Retry',
              onPressed: () =>
                  ref.refresh(userLikedSubmissionsProvider(targetUserId)),
              icon: Icons.refresh,
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
}
