import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'core/providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/user_onboarding_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/auth/providers/auth_providers.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.i('Firebase initialized successfully');
  } catch (e, stackTrace) {
    AppLogger.e('Failed to initialize Firebase', e, stackTrace);
  }

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const ZinkApp(),
    ),
  );
}

class ZinkApp extends ConsumerWidget {
  const ZinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.i('ZinkApp build() called');
    
    // Initialize notification service when app starts
    ref.listen(authStateProvider, (previous, next) {
      // Initialize notifications when user logs in
      if (previous?.valueOrNull == null && next.valueOrNull != null) {
        final notificationService = ref.read(notificationServiceProvider);
        notificationService.initialize();
      }
    });
    
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Zink',
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('tr'), // Turkish
      ],
      routerConfig: router,
    );
  }
}

