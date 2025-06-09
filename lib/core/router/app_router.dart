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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUserDataAsync = ref.watch(currentUserDataProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuth = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      
      // If not authenticated, redirect to login (except if already on login)
      if (!isAuth && !isAuthRoute) {
        return '/login';
      }
      
      // If authenticated, check user data for onboarding status
      if (isAuth) {
        return currentUserDataAsync.when(
          data: (userData) {
            if (userData == null) {
              // User authenticated but no Firestore document - needs onboarding
              return isOnboardingRoute ? null : '/onboarding';
            }
            
            // Check if user needs onboarding
            if (!userData.isOnboardingComplete) {
              return isOnboardingRoute ? null : '/onboarding';
            }
            
            // User is fully set up, don't allow login or onboarding pages
            if (isAuthRoute || isOnboardingRoute) {
              return '/';
            }
            
            return null;
          },
          loading: () => null, // Let loading state handle itself
          error: (error, stack) {
            // On error, redirect to onboarding to be safe
            return isOnboardingRoute ? null : '/onboarding';
          },
        );
      }
      
      return null;
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
  ];
}
