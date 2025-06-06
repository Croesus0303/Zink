import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/logger.dart';

class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

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
        // User is logged in, show the requested page
        return child;
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
