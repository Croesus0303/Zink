import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/logger.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/notification_service.dart';
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

// TODO: Add a splash screen
class ZinkApp extends ConsumerStatefulWidget {
  const ZinkApp({super.key});

  @override
  ConsumerState<ZinkApp> createState() => _ZinkAppState();
}

class _ZinkAppState extends ConsumerState<ZinkApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
      
      // Subscribe to general app notifications
      await notificationService.subscribeToTopic('all_users');
      
      AppLogger.i('Notifications initialized successfully');
    } catch (e) {
      AppLogger.e('Failed to initialize notifications', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.i('ZinkApp build() called');
    
    return Consumer(
      builder: (context, ref, child) {
        try {
          AppLogger.i('Attempting to load router provider...');
          final router = ref.watch(routerProvider);
          AppLogger.i('Router provider loaded');
          
          AppLogger.i('Attempting to load locale provider...');
          final locale = ref.watch(localeProvider);
          AppLogger.i('Locale provider loaded');

          AppLogger.i('Router and locale providers loaded successfully');

          return MaterialApp.router(
            title: 'Zink',
            theme: AppTheme.lightTheme(context),
            darkTheme: AppTheme.darkTheme(context),
            themeMode: ThemeMode.system,
            routerConfig: router,
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
          );
        } catch (e, stackTrace) {
          AppLogger.e('Error in ZinkApp build', e, stackTrace);
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('App Initialization Error'),
                    const SizedBox(height: 8),
                    Text(e.toString()),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
