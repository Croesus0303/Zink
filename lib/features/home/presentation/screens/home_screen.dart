import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/language_selector.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appName),
        actions: [
          const LanguageToggleButton(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) async {
              if (value == 'signOut') {
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
              } else if (value == 'profile') {
                // Navigate to profile
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.profile),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_camera,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!
                  .welcome(user?.displayName ?? 'User'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.noActiveChallenges),
          ],
        ),
      ),
    );
  }
}
