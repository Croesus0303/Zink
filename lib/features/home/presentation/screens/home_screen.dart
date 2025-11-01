import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../notifications/providers/notifications_providers.dart';
import '../../../messaging/providers/messaging_providers.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/category_filter_chips.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/timeline_tab.dart';
import '../widgets/events_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _tabBarAnimationController;
  final GlobalKey<TimelineTabState> _timelineKey = GlobalKey<TimelineTabState>();
  final GlobalKey<EventsTabState> _eventsKey = GlobalKey<EventsTabState>();

  bool _isTabBarVisible = true;
  double _lastScrollPosition = 0;
  static const double _scrollThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Animation controller for tab bar slide animation
    _tabBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0, // Start visible
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _tabBarAnimationController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Intentionally empty - tab change detection happens in onTap handler
  }

  void _handleTabTap(int index) {
    if (_tabController.index == index) {
      // Show tab bar before scrolling to top
      _showTabBar();

      // User tapped on the already active tab - scroll to top
      if (index == 0) {
        _timelineKey.currentState?.scrollToTop();
      } else if (index == 1) {
        _eventsKey.currentState?.scrollToTop();
      }
    } else {
      // Always show tab bar when switching tabs
      _showTabBar();
    }
  }

  void _onScrollUpdate(double currentScrollPosition) {
    final scrollDelta = currentScrollPosition - _lastScrollPosition;
    _lastScrollPosition = currentScrollPosition;

    // At the top of the page, always show tab bar
    if (currentScrollPosition <= 0) {
      _showTabBar();
      return;
    }

    // Scrolling down (delta > 0) and past threshold - hide tab bar
    if (scrollDelta > 5 && currentScrollPosition > _scrollThreshold) {
      _hideTabBar();
    }
    // Scrolling up (delta < 0) - show tab bar immediately
    else if (scrollDelta < -5) {
      _showTabBar();
    }
  }

  void _showTabBar() {
    if (!_isTabBarVisible) {
      setState(() {
        _isTabBarVisible = true;
      });
      _tabBarAnimationController.forward();
    }
  }

  void _hideTabBar() {
    if (_isTabBarVisible) {
      setState(() {
        _isTabBarVisible = false;
      });
      _tabBarAnimationController.reverse();
    }
  }

  void _onScrollToTopTapped() {
    _showTabBar();
  }

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authStateProvider);
    final currentUserDataAsync = ref.watch(currentUserDataProvider);
    final unreadCountAsync = ref.watch(enhancedUnreadNotificationsCountProvider);
    final unreadMessagesCountAsync = ref.watch(unreadMessagesCountAsyncProvider);

    final isLoading = authStateAsync.isLoading ||
                     currentUserDataAsync.isLoading ||
                     unreadCountAsync.isLoading ||
                     unreadMessagesCountAsync.isLoading;

    if (isLoading) {
      return _buildLoadingScreen(context);
    }

    return Scaffold(
      backgroundColor: AppColors.midnightGreen,
      body: Stack(
        children: [
          // Main content area with animated padding
          AnimatedBuilder(
            animation: _tabBarAnimationController,
            builder: (context, child) {
              final topBarHeight = MediaQuery.of(context).padding.top +
                                   MediaQuery.of(context).size.height * 0.08;
              final filterChipsHeight = MediaQuery.of(context).size.height * 0.04 * _tabBarAnimationController.value;
              return Padding(
                padding: EdgeInsets.only(
                  top: topBarHeight + filterChipsHeight,
                ),
                child: child!,
              );
            },
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              removeRight: true,
              child: TabBarView(
                controller: _tabController,
                children: [
                  TimelineTab(
                    key: _timelineKey,
                    onScrollUpdate: _onScrollUpdate,
                    onScrollToTopTapped: _onScrollToTopTapped,
                  ),
                  EventsTab(
                    key: _eventsKey,
                    onScrollUpdate: _onScrollUpdate,
                    onScrollToTopTapped: _onScrollToTopTapped,
                  ),
                ],
              ),
            ),
          ),
          // Animated bottom tab bar
          AnimatedBuilder(
            animation: _tabBarAnimationController,
            builder: (context, child) {
              final tabBarHeight = MediaQuery.of(context).size.height * 0.055;
              final slideOffset = (1.0 - _tabBarAnimationController.value) * tabBarHeight;
              return Positioned(
                left: 0,
                right: 0,
                bottom: -slideOffset,
                child: child!,
              );
            },
            child: Container(
              height: MediaQuery.of(context).size.height * 0.055,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.midnightGreen.withValues(alpha: 0.98),
                    AppColors.midnightGreen,
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.auroraBorder.withValues(alpha: 0.3),
                    width: MediaQuery.of(context).size.width * 0.004,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: MediaQuery.of(context).size.width * 0.04,
                    offset: Offset(0, -MediaQuery.of(context).size.height * 0.004),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                onTap: _handleTabTap,
                labelColor: AppColors.rosyBrown,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.rosyBrown,
                indicatorWeight: MediaQuery.of(context).size.height * 0.003,
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: EdgeInsets.zero,
                tabs: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.055,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_rounded,
                          size: MediaQuery.of(context).size.width * 0.06,
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        Text(
                          'Home Page',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.032,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.055,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_rounded,
                          size: MediaQuery.of(context).size.width * 0.06,
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        Text(
                          AppLocalizations.of(context)!.events,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.032,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Category filter chips (animated with tab bar)
          AnimatedBuilder(
            animation: _tabBarAnimationController,
            builder: (context, child) {
              final opacity = _tabBarAnimationController.value;
              final filterChipsHeight = MediaQuery.of(context).size.height * 0.04;
              final slideOffset = (1.0 - _tabBarAnimationController.value) * filterChipsHeight;
              final topBarHeight = MediaQuery.of(context).padding.top +
                                   MediaQuery.of(context).size.height * 0.08;
              return Positioned(
                left: 0,
                right: 0,
                top: topBarHeight - slideOffset,
                child: Opacity(
                  opacity: opacity,
                  child: child!,
                ),
              );
            },
            child: const CategoryFilterChips(),
          ),
          // Scroll to top button (positioned at filter chips level, appears in front)
          AnimatedBuilder(
            animation: _tabBarAnimationController,
            builder: (context, child) {
              final topBarHeight = MediaQuery.of(context).padding.top +
                                   MediaQuery.of(context).size.height * 0.08;
              final showButton = _tabController.index == 0
                  ? _timelineKey.currentState?.showScrollToTop ?? false
                  : _eventsKey.currentState?.showScrollToTop ?? false;

              return Positioned(
                top: topBarHeight + MediaQuery.of(context).size.height * 0.01,
                right: MediaQuery.of(context).size.width * 0.05,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: showButton ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !showButton,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.pineGreen.withValues(alpha: 0.95),
                              AppColors.pineGreenDark.withValues(alpha: 0.95),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: MediaQuery.of(context).size.width * 0.005,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pineGreen.withValues(alpha: 0.4),
                              blurRadius: MediaQuery.of(context).size.width * 0.03,
                              offset: Offset(0, MediaQuery.of(context).size.height * 0.005),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            if (_tabController.index == 0) {
                              _timelineKey.currentState?.scrollToTop();
                            } else {
                              _eventsKey.currentState?.scrollToTop();
                            }
                          },
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                            child: Icon(
                              Icons.arrow_upward,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width * 0.06,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Top bar with logo and action buttons (on top of everything)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.08,
                color: AppColors.midnightGreen,
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.03,
                  vertical: MediaQuery.of(context).size.height * 0.01,
                ),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App logo on the left
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
                  // Action buttons on the right
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNotificationButton(context, unreadCountAsync),
                      _buildMessagesButton(context, unreadMessagesCountAsync),
                      _buildProfileButton(context),
                    ],
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

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightGreen,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.rosyBrown,
          strokeWidth: MediaQuery.of(context).size.width * 0.01,
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, AsyncValue<int> unreadCountAsync) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: MediaQuery.of(context).size.width * 0.07,
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
                          width: MediaQuery.of(context).size.width * 0.004,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(alpha: 0.6),
                            blurRadius: MediaQuery.of(context).size.width * 0.015,
                            offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
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
    );
  }

  Widget _buildMessagesButton(BuildContext context, AsyncValue<int> unreadMessagesCountAsync) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => context.push('/chats'),
          icon: Icon(
            Icons.mail_outline_rounded,
            color: Colors.white,
            size: MediaQuery.of(context).size.width * 0.07,
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
                          width: MediaQuery.of(context).size.width * 0.004,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rosyBrown.withValues(alpha: 0.6),
                            blurRadius: MediaQuery.of(context).size.width * 0.015,
                            offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
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
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return IconButton(
      onPressed: () => context.push('/profile'),
      icon: Icon(
        Icons.person_outline_rounded,
        color: Colors.white,
        size: MediaQuery.of(context).size.width * 0.07,
      ),
      padding: EdgeInsets.zero,
    );
  }
}