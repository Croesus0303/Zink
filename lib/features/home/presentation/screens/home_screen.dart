import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../events/providers/events_providers.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/presentation/screens/event_detail_screen.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen.withOpacity(0.9),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: MediaQuery.of(context).size.height * 0.065,
        title: Row(
          children: [
            Container(
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
          Container(
            margin: const EdgeInsets.only(right: 6, left: 0, bottom: 3, top: 3),
            decoration: BoxDecoration(
              color: AppColors.rosyBrown.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.rosyBrown.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
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
          ),
          Container(
            margin: const EdgeInsets.only(right: 12, bottom: 3, top: 3),
            decoration: BoxDecoration(
              color: AppColors.pineGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.pineGreen.withOpacity(0.3),
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
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
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
              // Main content
              RefreshIndicator(
                color: AppColors.rosyBrown,
                onRefresh: () async {
                  ref.refresh(activeEventProvider);
                  ref.refresh(pastEventsProvider);
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                          height: MediaQuery.of(context).size.height *
                              0.15), // Space for app bar
                    ),
                    SliverToBoxAdapter(child: _WelcomeSection()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 16.0),
                        child: Text(
                          'Geçmiş Görevler',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: MediaQuery.of(context).size.width * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    _PastChallengesList(),
                    SliverToBoxAdapter(
                      child: SizedBox(
                          height: MediaQuery.of(context).size.height *
                              0.04), // Bottom padding
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
              color: Colors.white.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(-2, -2),
            ),
            BoxShadow(
              color: AppColors.rosyBrown.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(2, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                        AppColors.rosyBrown.withOpacity(0.3),
                        AppColors.pineGreen.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: activeEvent.referenceImageURL.isNotEmpty
                          ? Image.network(
                              activeEvent.referenceImageURL,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
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
                                    size:
                                        MediaQuery.of(context).size.width * 0.2,
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
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
                            color: AppColors.rosyBrown.withOpacity(0.6),
                            blurRadius: 12,
                          ),
                          Shadow(
                            color: AppColors.pineGreen.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.022),
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
            Colors.white.withOpacity(0.15),
            AppColors.rosyBrown.withOpacity(0.08),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.iceBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(-1, -1),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            'Şu anda aktif görev bulunmuyor',
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
            color: Colors.white.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                colors: [AppColors.rosyBrown, AppColors.pineGreen],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.rosyBrown.withOpacity(0.4),
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
            'Görevler yükleniyor...',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: MediaQuery.of(context).size.width * 0.055,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: AppColors.rosyBrown.withOpacity(0.5),
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
            color: Colors.white.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                  AppColors.rosyBrown.withOpacity(0.4),
                  AppColors.pineGreen.withOpacity(0.3),
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
            'Görevler yüklenirken hata oluştu',
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

class _PastChallengesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pastEventsAsync = ref.watch(pastEventsProvider);

    return pastEventsAsync.when(
      data: (pastEvents) => _buildList(context, pastEvents),
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
                  onPressed: () => ref.refresh(pastEventsProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rosyBrown,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.rosyBrown.withOpacity(0.3),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<EventModel> pastEvents) {
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
                color: Colors.white.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(-2, -2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                      AppColors.rosyBrown.withOpacity(0.4),
                      AppColors.pineGreen.withOpacity(0.3),
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
                'Henüz geçmiş görev yok',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: MediaQuery.of(context).size.width * 0.05,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: AppColors.rosyBrown.withOpacity(0.5),
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final event = pastEvents[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  AppColors.rosyBrown.withOpacity(0.06),
                  AppColors.pineGreen.withOpacity(0.04),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.iceBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(-1, -1),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                      builder: (context) =>
                          EventDetailScreen(eventId: event.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: MediaQuery.of(context).size.width * 0.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
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
                              color: AppColors.rosyBrown.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(-4, -4),
                            ),
                            BoxShadow(
                              color: AppColors.pineGreen.withOpacity(0.4),
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
                                ? Image.network(
                                    event.referenceImageURL,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              AppColors.rosyBrown
                                                  .withOpacity(0.4),
                                              AppColors.pineGreen
                                                  .withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.photo_camera_outlined,
                                          color: Colors.white,
                                          size: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.08,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.rosyBrown.withOpacity(0.4),
                                          AppColors.pineGreen.withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.photo_camera_outlined,
                                      color: Colors.white,
                                      size: MediaQuery.of(context).size.width *
                                          0.08,
                                    ),
                                  ),
                          ),
                        ),
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
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.005),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.rosyBrown.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.rosyBrown.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _formatDate(event.endTime),
                                style: TextStyle(
                                  color: AppColors.rosyBrown,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.rosyBrown.withOpacity(0.7),
                        size: MediaQuery.of(context).size.width * 0.04,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: pastEvents.length,
      ),
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
