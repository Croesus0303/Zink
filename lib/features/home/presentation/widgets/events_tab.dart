import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../events/providers/events_providers.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/presentation/screens/event_detail_screen.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class EventsTab extends ConsumerWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: RefreshIndicator(
          color: AppColors.rosyBrown,
          onRefresh: () async {
            ref.invalidate(activeEventProvider);
            ref.invalidate(pastEventsProvider);
            await Future.delayed(const Duration(seconds: 1));
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo is ScrollEndNotification &&
                  scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                ref.read(paginatedPastEventsProvider.notifier).loadMoreEvents();
              }
              return false;
            },
            child: const CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _WelcomeSection()),
                SliverToBoxAdapter(child: _PastEventsHeader()),
                _PaginatedPastChallengesList(),
                SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeSection extends ConsumerWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final activeEventAsync = ref.watch(activeEventProvider);

    return activeEventAsync.when(
      data: (activeEvent) => activeEvent != null
          ? _buildActiveTaskSection(context, activeEvent)
          : _buildWelcomeSection(context, user),
      loading: () => _buildLoadingSection(context),
      error: (error, stack) => _buildErrorSection(context),
    );
  }

  Widget _buildActiveTaskSection(BuildContext context, EventModel activeEvent) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(eventId: activeEvent.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: AppColors.iceGlassGradient,
          borderRadius: BorderRadius.circular(32.0),
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
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: Column(
            children: [
              // Reference photo (main space)
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.rosyBrown.withValues(alpha: 0.3),
                        AppColors.pineGreen.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: activeEvent.referenceImageURL.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: activeEvent.referenceImageURL,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (context, url) => Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.rosyBrown,
                                          AppColors.pineGreen,
                                          AppColors.midnightGreen,
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 4,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.rosyBrown,
                                          AppColors.pineGreen,
                                          AppColors.midnightGreen,
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.photo_camera_outlined,
                                      color: Colors.white,
                                      size: MediaQuery.of(context).size.width * 0.2,
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.rosyBrown,
                                        AppColors.pineGreen,
                                        AppColors.midnightGreen,
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.photo_camera_outlined,
                                    color: Colors.white,
                                    size: MediaQuery.of(context).size.width * 0.2,
                                  ),
                                ),
                        ),
                      ),
                      // Badge overlay
                      if (activeEvent.badgeURL != null && activeEvent.badgeURL!.isNotEmpty)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.12,
                            height: MediaQuery.of(context).size.width * 0.12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: activeEvent.badgeURL!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryOrange.withValues(alpha: 0.6),
                                        AppColors.rosyBrown.withValues(alpha: 0.6),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryOrange.withValues(alpha: 0.8),
                                        AppColors.rosyBrown.withValues(alpha: 0.8),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.emoji_events,
                                    color: Colors.white,
                                    size: MediaQuery.of(context).size.width * 0.06,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Title and description below photo
              Container(
                padding: const EdgeInsets.only(top: 28),
                child: Column(
                  children: [
                    Text(
                      activeEvent.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: MediaQuery.of(context).size.width * 0.065,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.022),
                    Text(
                      activeEvent.description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: MediaQuery.of(context).size.width * 0.043,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        borderRadius: BorderRadius.circular(20),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            color: Colors.white,
            size: MediaQuery.of(context).size.width * 0.045,
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
          Text(
            AppLocalizations.of(context)!.noActiveTasksRight,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.038,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        gradient: AppColors.iceGlassGradient,
        borderRadius: BorderRadius.circular(28.0),
        border: Border.all(
          color: AppColors.iceBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.25,
            height: MediaQuery.of(context).size.width * 0.25,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.rosyBrown, AppColors.pineGreen],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.rosyBrown.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          Text(
            AppLocalizations.of(context)!.tasksLoading,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: MediaQuery.of(context).size.width * 0.055,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: AppColors.rosyBrown.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        gradient: AppColors.iceGlassGradient,
        borderRadius: BorderRadius.circular(28.0),
        border: Border.all(
          color: AppColors.iceBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.25,
            height: MediaQuery.of(context).size.width * 0.25,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.rosyBrown.withValues(alpha: 0.4),
                  AppColors.pineGreen.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.12,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          Text(
            AppLocalizations.of(context)!.errorLoadingTasks,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: MediaQuery.of(context).size.width * 0.05,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PastEventsHeader extends StatelessWidget {
  const _PastEventsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 16.0),
      child: Text(
        AppLocalizations.of(context)!.pastTasks,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: MediaQuery.of(context).size.width * 0.06,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PaginatedPastChallengesList extends ConsumerWidget {
  const _PaginatedPastChallengesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pastEventsAsync = ref.watch(paginatedPastEventsProvider);
    final notifier = ref.read(paginatedPastEventsProvider.notifier);

    return pastEventsAsync.when(
      data: (pastEvents) => _buildList(context, pastEvents, notifier),
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.rosyBrown),
          ),
        ),
      ),
      error: (error, stack) {
        AppLogger.e('Error loading past events', error, stack);
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Text(
                  'Error loading past events: $error',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ElevatedButton(
                  onPressed: () => notifier.refresh(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rosyBrown,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.rosyBrown.withValues(alpha: 0.3),
                  ),
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<EventModel> pastEvents, PaginatedPastEventsNotifier notifier) {
    if (pastEvents.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            gradient: AppColors.iceGlassGradient,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.iceBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(-2, -2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.3,
                height: MediaQuery.of(context).size.width * 0.3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.rosyBrown.withValues(alpha: 0.4),
                      AppColors.pineGreen.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.history,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.14,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              Text(
                AppLocalizations.of(context)!.noPastTasksYet,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: MediaQuery.of(context).size.width * 0.05,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: AppColors.rosyBrown.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final itemCount = pastEvents.length + (notifier.hasMoreData ? 1 : 0);
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= pastEvents.length) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Center(
                child: notifier.isLoadingMore
                    ? const CircularProgressIndicator(color: AppColors.rosyBrown)
                    : const SizedBox.shrink(),
              ),
            );
          }
          
          final event = pastEvents[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  AppColors.rosyBrown.withValues(alpha: 0.06),
                  AppColors.pineGreen.withValues(alpha: 0.04),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.iceBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(-1, -1),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EventDetailScreen(eventId: event.id),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.2,
                                height: MediaQuery.of(context).size.width * 0.2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.rosyBrown,
                                      AppColors.pineGreen,
                                      AppColors.midnightGreen,
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.rosyBrown.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(-4, -4),
                                    ),
                                    BoxShadow(
                                      color: AppColors.pineGreen.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(4, 4),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: event.referenceImageURL.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: event.referenceImageURL,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    AppColors.rosyBrown.withValues(alpha: 0.4),
                                                    AppColors.pineGreen.withValues(alpha: 0.3),
                                                  ],
                                                ),
                                              ),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 32,
                                                  height: 32,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 3,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    AppColors.rosyBrown.withValues(alpha: 0.4),
                                                    AppColors.pineGreen.withValues(alpha: 0.3),
                                                  ],
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.photo_camera_outlined,
                                                color: Colors.white,
                                                size: MediaQuery.of(context).size.width * 0.08,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AppColors.rosyBrown.withValues(alpha: 0.4),
                                                  AppColors.pineGreen.withValues(alpha: 0.3),
                                                ],
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.photo_camera_outlined,
                                              color: Colors.white,
                                              size: MediaQuery.of(context).size.width * 0.08,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: MediaQuery.of(context).size.width * 0.04,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: event.isExpired
                                        ? AppColors.midnightGreen.withValues(alpha: 0.6)
                                        : AppColors.primaryCyan.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: event.isExpired
                                          ? AppColors.midnightGreen.withValues(alpha: 0.8)
                                          : AppColors.primaryCyan.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    event.isExpired
                                        ? AppLocalizations.of(context)!.ended
                                        : AppLocalizations.of(context)!.active,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: MediaQuery.of(context).size.width * 0.028,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.rosyBrown.withValues(alpha: 0.7),
                            size: MediaQuery.of(context).size.width * 0.04,
                          ),
                        ],
                      ),
                    ),
                    // Badge overlay for past events
                    if (event.badgeURL != null && event.badgeURL!.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.08,
                          height: MediaQuery.of(context).size.width * 0.08,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: event.badgeURL!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryOrange.withValues(alpha: 0.6),
                                      AppColors.rosyBrown.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryOrange.withValues(alpha: 0.8),
                                      AppColors.rosyBrown.withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.emoji_events,
                                  color: Colors.white,
                                  size: MediaQuery.of(context).size.width * 0.04,
                                ),
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
        },
        childCount: itemCount,
      ),
    );
  }
}

