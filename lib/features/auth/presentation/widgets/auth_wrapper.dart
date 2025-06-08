import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../../../core/utils/logger.dart';

class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUserData = ref.watch(currentUserDataProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          AppLogger.d('User not authenticated, redirecting to login');
          // User is not logged in, redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // User is authenticated, check onboarding status
        return currentUserData.when(
          data: (userData) {
            if (userData == null || !userData.isOnboardingComplete) {
              // User needs onboarding
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/onboarding');
              });
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            // User is fully set up, show the requested page
            return child;
          },
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) {
            AppLogger.e('User data error', error, stack);
            // On error, redirect to onboarding
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/onboarding');
            });
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        AppLogger.e('Auth state error', error, stack);
        return Scaffold(
          body: Center(
            child: Text('Error: ${error.toString()}'),
          ),
        );
      },
    );
  }
}
