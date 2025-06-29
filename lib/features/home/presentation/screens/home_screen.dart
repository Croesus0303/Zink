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
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 90,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A0E1A).withOpacity(0.98),
                Color(0xFF1A1F2E).withOpacity(0.9),
                AppColors.primaryCyan.withOpacity(0.1),
                Colors.transparent,
              ],
              stops: [0.0, 0.6, 0.85, 1.0],
            ),
          ),
        ),
        title: null,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8,left:0,bottom: 8,top : 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryCyan.withOpacity(0.9),
                  AppColors.primaryCyan.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => context.push('/chats'),
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 22,
              ),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: EdgeInsets.zero,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryOrange.withOpacity(0.9),
                  AppColors.primaryOrange.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => context.push('/profile'),
              icon: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 22,
              ),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.radialBackgroundGradient,
          ),
          child: Stack(
            children: [
              // Logo positioned in the same place as app bar title
              Positioned(
                top: 50, // Adjust based on status bar + app bar position
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 200,
                    height: 60,
                    child: Image.asset(
                      'assets/app_logo.png',
                      width: 200,
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryCyan, AppColors.primaryOrange],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Zink',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Main content
              RefreshIndicator(
                color: AppColors.primaryCyan,
                onRefresh: () async {
                  ref.refresh(activeEventProvider);
                  ref.refresh(pastEventsProvider);
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 120), // Space for app bar + logo
                    ),
                SliverToBoxAdapter(child: _WelcomeSection()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 16.0),
                    child: Text(
                      'Geçmiş Görevler',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: AppColors.primaryCyan.withOpacity(0.4),
                            blurRadius: 12,
                          ),
                          Shadow(
                            color: AppColors.primaryOrange.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _PastChallengesList(),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32), // Bottom padding
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
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        padding: const EdgeInsets.all(16.0),
        borderRadius: 32.0,
        useCyanAccent: true,
        child: SizedBox(
          height: 540, // Further increased for better proportions
          child: Column(
            children: [
            // Active event badge above photo
            Container(
              padding: const EdgeInsets.only(top: 12, bottom: 24), // More padding
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryCyan.withOpacity(0.8),
                      AppColors.primaryCyan.withOpacity(0.6),
                      AppColors.primaryOrange.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.primaryCyan.withOpacity(0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.radio_button_checked,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Aktif Görev',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        shadows: [
                          Shadow(
                            color: AppColors.primaryCyan.withOpacity(0.5),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                      AppColors.primaryCyan,
                      AppColors.primaryOrange,
                      AppColors.warmBeige,
                      AppColors.primaryOrangeDark,
                    ],
                    stops: [0.0, 0.4, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan.withOpacity(0.5),
                      blurRadius: 25,
                      offset: const Offset(-10, -10),
                    ),
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.5),
                      blurRadius: 25,
                      offset: const Offset(10, 10),
                    ),
                    BoxShadow(
                      color: AppColors.warmBeige.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 15),
                    ),
                  ],
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
                                      AppColors.primaryCyan,
                                      AppColors.primaryOrange,
                                      AppColors.warmBeige,
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.photo_camera_outlined,
                                  color: Colors.white,
                                  size: 80,
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
                                  AppColors.primaryCyan,
                                  AppColors.primaryOrange,
                                  AppColors.warmBeige,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.photo_camera_outlined,
                              color: Colors.white,
                              size: 80,
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
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryCyan.withOpacity(0.4),
                          blurRadius: 12,
                        ),
                        Shadow(
                          color: AppColors.primaryOrange.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    activeEvent.description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 17,
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
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryCyan.withOpacity(0.25),
            AppColors.primaryOrange.withOpacity(0.2),
            AppColors.warmBeige.withOpacity(0.15),
            AppColors.primaryCyanDark.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.primaryCyan.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryCyan,
                  AppColors.primaryOrange,
                  AppColors.warmBeige,
                  AppColors.primaryOrangeDark,
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withOpacity(0.6),
                  blurRadius: 30,
                  offset: const Offset(-8, -8),
                ),
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.6),
                  blurRadius: 30,
                  offset: const Offset(8, 8),
                ),
                BoxShadow(
                  color: AppColors.warmBeige.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.waving_hand,
              color: Colors.white,
              size: 72,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hoşgeldin ${user?.displayName ?? 'Buğra'}!',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: AppColors.primaryCyan.withOpacity(0.5),
                  blurRadius: 12,
                ),
                Shadow(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryOrange.withOpacity(0.8),
                  AppColors.primaryOrangeDark.withOpacity(0.6),
                  AppColors.warmBeige.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.primaryOrange.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Şu anda aktif görev bulunmuyor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryOrange.withOpacity(0.5),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      padding: const EdgeInsets.all(32.0),
      borderRadius: 28.0,
      useCyanAccent: true,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryCyan, AppColors.primaryCyanDark],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withOpacity(0.4),
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
          const SizedBox(height: 24),
          Text(
            'Görevler yükleniyor...',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: AppColors.primaryCyan.withOpacity(0.3),
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
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      padding: const EdgeInsets.all(32.0),
      borderRadius: 28.0,
      useOrangeAccent: true,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryOrange, AppColors.primaryOrangeDark],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Görevler yüklenirken hata oluştu',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
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
            child: CircularProgressIndicator(color: AppColors.primaryCyan),
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(pastEventsProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.primaryOrange.withOpacity(0.3),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryCyan.withOpacity(0.2),
                AppColors.primaryOrange.withOpacity(0.15),
                AppColors.warmBeige.withOpacity(0.1),
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
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryCyan,
                      AppColors.primaryOrange,
                      AppColors.warmBeige,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(-6, -6),
                    ),
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(6, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Henüz geçmiş görev yok',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: AppColors.primaryCyan.withOpacity(0.3),
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
                  AppColors.primaryCyan.withOpacity(0.15),
                  AppColors.primaryOrange.withOpacity(0.12),
                  AppColors.warmBeige.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryCyan.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryCyan,
                        AppColors.primaryOrange,
                        AppColors.warmBeige,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(-4, -4),
                      ),
                      BoxShadow(
                        color: AppColors.primaryOrange.withOpacity(0.4),
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
                                      colors: [
                                        AppColors.primaryCyan,
                                        AppColors.primaryOrange,
                                        AppColors.warmBeige,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera_outlined,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryCyan,
                                    AppColors.primaryOrange,
                                    AppColors.warmBeige,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.photo_camera_outlined,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryCyan.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _formatDate(event.endTime),
                          style: TextStyle(
                            color: AppColors.primaryCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primaryCyan.withOpacity(0.7),
                  size: 16,
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
