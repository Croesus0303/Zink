import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/user_onboarding_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/submissions/presentation/screens/photo_submission_screen.dart';
import '../../features/submissions/presentation/screens/single_submission_screen.dart';
import '../../features/messaging/presentation/screens/chat_screen.dart';
import '../../features/messaging/presentation/screens/chats_list_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../utils/logger.dart';
import '../../l10n/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUserDataAsync = ref.watch(currentUserDataProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    errorBuilder: AppRouter.errorPageBuilder,
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == '/login';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      AppLogger.i(
          'Router redirect: ${state.matchedLocation}, isLogin: $isLoginRoute');

      return authState.when(
        data: (user) {
          AppLogger.i('Auth state data: user = ${user?.uid ?? 'null'}');
          // User is not authenticated
          if (user == null) {
            if (isLoginRoute) {
              AppLogger.i('Already on login route, no redirect needed');
              return null;
            } else {
              AppLogger.i(
                  'User null, redirecting to login from ${state.matchedLocation}');
              return '/login';
            }
          }

          // User is authenticated, check onboarding status
          return currentUserDataAsync.when(
            data: (userData) {
              AppLogger.i(
                  'Router decision - User data: ${userData?.isOnboardingComplete ?? 'null'}, Current path: ${state.matchedLocation}');
              // User needs onboarding
              if (userData == null || userData.isOnboardingComplete != true) {
                final redirect = isOnboardingRoute ? null : '/onboarding';
                AppLogger.i('User needs onboarding, redirecting from ${state.matchedLocation} to: $redirect');
                return redirect;
              }

              // User is fully set up, redirect from auth pages
              if (isLoginRoute || isOnboardingRoute) {
                AppLogger.i('User authenticated, redirecting to home');
                return '/';
              }

              AppLogger.i('No redirect needed');
              return null; // No redirect needed
            },
            loading: () {
              AppLogger.i('User data loading, staying on current page');
              return null; // Stay on current page while loading
            },
            error: (_, __) {
              final redirect = isOnboardingRoute ? null : '/onboarding';
              AppLogger.i('User data error, redirecting to: $redirect');
              return redirect;
            },
          );
        },
        loading: () {
          AppLogger.i('Auth state loading, staying on current page');
          return null; // Stay on current page while loading
        },
        error: (_, __) {
          final redirect = isLoginRoute ? null : '/login';
          AppLogger.i('Auth state error, redirecting to: $redirect');
          return redirect;
        },
      );
    },
    routes: AppRouter.routes,
  );
});

class AppRouter {
  static final List<RouteBase> routes = [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const UserOnboardingScreen(),
    ),
    GoRoute(
      path: '/event/:eventId',
      name: 'eventDetail',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return EventDetailScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
      routes: [
        GoRoute(
          path: ':userId',
          name: 'userProfile',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return ProfileScreen(userId: userId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/submit/:eventId',
      name: 'submitPhoto',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return PhotoSubmissionScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/submission/:eventId/:submissionId',
      name: 'singleSubmission',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        final submissionId = state.pathParameters['submissionId']!;
        final fromProfile = state.uri.queryParameters['fromProfile'] == 'true';
        return SingleSubmissionScreen(
          eventId: eventId,
          submissionId: submissionId,
          fromProfile: fromProfile,
        );
      },
    ),
    GoRoute(
      path: '/chats',
      name: 'chats',
      builder: (context, state) => const ChatsListScreen(),
    ),
    GoRoute(
      path: '/chat/:userId',
      name: 'chat',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ChatScreen(otherUserId: userId);
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ];

  // Add error page widget
  static Widget errorPageBuilder(BuildContext context, GoRouterState state) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.error)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.pageNotFound(state.matchedLocation)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text(AppLocalizations.of(context)!.goHome),
            ),
          ],
        ),
      ),
    );
  }
}
