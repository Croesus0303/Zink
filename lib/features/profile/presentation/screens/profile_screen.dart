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
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading profile: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userDataProvider(targetUserId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, UserModel? user,
      bool isOwnProfile, String targetUserId) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            title: Text(isOwnProfile
                ? AppLocalizations.of(context)!.profile
                : user?.displayName ?? 'Profile'),
            actions: [
              if (!isOwnProfile)
                IconButton(
                  onPressed: () {
                    context.push('/chat/$targetUserId');
                  },
                  icon: const Icon(Icons.message),
                  tooltip: 'Send Message',
                ),
              if (isOwnProfile)
                PopupMenuButton<String>(
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
                          // Refresh profile data when returning from edit screen
                          _refreshProfileData();
                        });
                      }
                    } else if (value == 'testStorage') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const StorageTestScreen(),
                        ),
                      );
                    } else if (value == 'signOut') {
                      try {
                        final authService = ref.read(authServiceProvider);
                        await authService.signOut();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sign out failed: ${e.toString()}'),
                              backgroundColor: Colors.red,
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
                          const Icon(Icons.edit),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.editProfile),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'testStorage',
                      child: Row(
                        children: [
                          Icon(Icons.storage),
                          SizedBox(width: 8),
                          Text('Test Storage'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'signOut',
                      child: Row(
                        children: [
                          const Icon(Icons.logout),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.signOut),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: _ProfileHeader(
                user: user,
                isOwnProfile: isOwnProfile,
                onProfileEdited: _refreshProfileData),
          ),
          SliverToBoxAdapter(
            child: _ProfileStats(userId: targetUserId),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.submissions),
                  const Tab(text: 'Likes'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SubmissionsTab(userId: widget.userId ?? user?.uid ?? ''),
                _LikesTab(userId: widget.userId ?? user?.uid ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final bool isOwnProfile;
  final VoidCallback? onProfileEdited;

  const _ProfileHeader({
    required this.user,
    required this.isOwnProfile,
    this.onProfileEdited,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile picture
          CircleAvatar(
            radius: 50,
            backgroundImage: user?.photoURL != null
                ? CachedNetworkImageProvider(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? Text(
                    user?.displayName?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            user?.displayName ?? 'Unknown User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          // Username or email
          Text(
            '@${user?.displayName?.toLowerCase().replaceAll(' ', '') ?? 'user'}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          // Social links
          if (user?.socialLinks != null && user!.socialLinks.isNotEmpty)
            _SocialLinksSection(socialLinks: user!.socialLinks),
          const SizedBox(height: 16),
          // Edit profile button
          if (isOwnProfile)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (user != null) {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: user),
                      ),
                    )
                        .then((_) {
                      // Refresh profile data when returning from edit screen
                      if (onProfileEdited != null) onProfileEdited!();
                    });
                  }
                },
                icon: const Icon(Icons.edit),
                label: Text(AppLocalizations.of(context)!.editProfile),
              ),
            ),
        ],
      ),
    );
  }
}

class _SocialLinksSection extends StatelessWidget {
  final Map<String, String> socialLinks;

  const _SocialLinksSection({required this.socialLinks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.socialLinks,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: socialLinks.entries.map((entry) {
            return Chip(
              avatar: _getSocialIcon(entry.key),
              label: Text(entry.value),
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return const Icon(Icons.camera_alt, size: 18);
      case 'twitter':
        return const Icon(Icons.alternate_email, size: 18);
      case 'facebook':
        return const Icon(Icons.facebook, size: 18);
      default:
        return const Icon(Icons.link, size: 18);
    }
  }
}

class _ProfileStats extends ConsumerWidget {
  final String userId;

  const _ProfileStats({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionCountAsync = ref.watch(userSubmissionCountProvider(userId));
    final likeCountAsync =
        ref.watch(userLikeCountFromUserCollectionProvider(userId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              submissionCountAsync.when(
                data: (count) => _StatItem(
                  label: AppLocalizations.of(context)!
                      .totalSubmissions(count)
                      .split(' ')[0],
                  value: count.toString(),
                ),
                loading: () => _StatItem(
                  label: AppLocalizations.of(context)!
                      .totalSubmissions(0)
                      .split(' ')[0],
                  value: '-',
                ),
                error: (_, __) => _StatItem(
                  label: AppLocalizations.of(context)!
                      .totalSubmissions(0)
                      .split(' ')[0],
                  value: '0',
                ),
              ),
              likeCountAsync.when(
                data: (count) => _StatItem(
                  label: 'Likes',
                  value: count.toString(),
                ),
                loading: () => const _StatItem(
                  label: 'Likes',
                  value: '-',
                ),
                error: (_, __) => const _StatItem(
                  label: 'Likes',
                  value: '0',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}

class _SubmissionsTab extends ConsumerWidget {
  final String userId;

  const _SubmissionsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) {
      return const Center(
        child: Text('No user selected'),
      );
    }

    final submissionsAsync =
        ref.watch(userSubmissionsFromUserCollectionProvider(userId));

    return submissionsAsync.when(
      data: (submissions) => submissions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No submissions yet'),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: submissions.length,
              itemBuilder: (context, index) {
                final submission = submissions[index];
                return _SubmissionGridItem(submission: submission);
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading submissions: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .refresh(userSubmissionsFromUserCollectionProvider(userId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikesTab extends ConsumerWidget {
  final String userId;

  const _LikesTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) {
      return const Center(
        child: Text('No user selected'),
      );
    }

    final likedSubmissionsAsync =
        ref.watch(userLikedSubmissionsProvider(userId));

    return likedSubmissionsAsync.when(
      data: (likedSubmissions) => likedSubmissions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No liked posts yet'),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: likedSubmissions.length,
              itemBuilder: (context, index) {
                final likedSubmission = likedSubmissions[index];
                return _LikedSubmissionGridItem(
                  submissionData: likedSubmission,
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading likes: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.refresh(userLikedSubmissionsProvider(userId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionGridItem extends StatelessWidget {
  final SubmissionModel submission;

  const _SubmissionGridItem({required this.submission});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to single submission view for user's own posts
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SingleSubmissionScreen(
              eventId: submission.eventId,
              submissionId: submission.id,
              fromProfile: true,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: submission.imageURL,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}

class _LikedSubmissionGridItem extends StatelessWidget {
  final Map<String, dynamic> submissionData;

  const _LikedSubmissionGridItem({required this.submissionData});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to single submission view for liked posts
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SingleSubmissionScreen(
              eventId: submissionData['eventId'],
              submissionId: submissionData['submissionId'],
              fromProfile: true,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: submissionData['imageURL'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
            // Like indicator in the top right corner
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(179),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
