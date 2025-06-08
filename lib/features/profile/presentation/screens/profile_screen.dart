import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../events/providers/events_providers.dart';
import '../../../events/data/models/event_model.dart';
import '../../../submissions/data/models/submission_model.dart';
import '../../../../l10n/app_localizations.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = widget.userId == null || widget.userId == currentUser?.uid;
    final targetUserId = widget.userId ?? currentUser?.uid;
    
    if (targetUserId == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }
    
    final userDataAsync = ref.watch(userDataProvider(targetUserId));
    
    return userDataAsync.when(
      data: (user) => _buildProfile(context, ref, user, isOwnProfile),
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
  
  Widget _buildProfile(BuildContext context, WidgetRef ref, UserModel? user, bool isOwnProfile) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            title: Text(isOwnProfile ? AppLocalizations.of(context)!.profile : user?.displayName ?? 'Profile'),
            actions: [
              if (isOwnProfile)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'editProfile') {
                      // TODO: Navigate to edit profile
                    } else if (value == 'signOut') {
                      final authService = ref.read(authServiceProvider);
                      await authService.signOut();
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
            child: _ProfileHeader(user: user, isOwnProfile: isOwnProfile),
          ),
          SliverToBoxAdapter(
            child: _ProfileStats(),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.myChallenges),
                  Tab(text: AppLocalizations.of(context)!.submissions),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ChallengesTab(),
                _SubmissionsTab(userId: widget.userId ?? user?.uid ?? ''),
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

  const _ProfileHeader({
    required this.user,
    required this.isOwnProfile,
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
                  // TODO: Navigate to edit profile
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
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Challenges',
                value: '12',
              ),
              _StatItem(
                label: AppLocalizations.of(context)!.totalSubmissions(8).split(' ')[0],
                value: '8',
              ),
              _StatItem(
                label: 'Likes',
                value: '156',
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

class _ChallengesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    
    return eventsAsync.when(
      data: (events) => _buildEventsList(context, events),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading events: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(eventsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventsList(BuildContext context, List<EventModel> events) {
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: event.referenceImageURL,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                ),
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            title: Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(event.endTime)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: event.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.isActive ? 'Active' : 'Completed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/event/${event.id}');
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
    
    // For now, show a placeholder since we need event-specific submissions
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('User submissions coming soon'),
        ],
      ),
    );
  }
}