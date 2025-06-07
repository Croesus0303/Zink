import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuth = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login';

      if (!isAuth && !isAuthRoute) {
        return '/login';
      }
      if (isAuth && isAuthRoute) {
        return '/';
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
      path: '/event/:eventId',
      name: 'eventDetail',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return Scaffold(
          body: Center(
            child: Text('Event Detail: $eventId'),
          ),
        );
      },
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text('Profile Screen'),
        ),
      ),
      routes: [
        GoRoute(
          path: ':userId',
          name: 'userProfile',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return Scaffold(
              body: Center(
                child: Text('User Profile: $userId'),
              ),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/submit/:eventId',
      name: 'submitPhoto',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return Scaffold(
          body: Center(
            child: Text('Submit Photo for Event: $eventId'),
          ),
        );
      },
    ),
  ];
}
