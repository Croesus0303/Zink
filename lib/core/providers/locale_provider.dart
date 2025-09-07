import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;
  static const _localeKey = 'app_locale';

  LocaleNotifier(this._prefs) : super(_loadLocale(_prefs));

  static Locale _loadLocale(SharedPreferences prefs) {
    // Always default to English - language switching is disabled
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    // Language switching is disabled - always keep English
    if (locale.languageCode != 'en') {
      return;
    }
    
    if (state == locale) return;
    state = locale;
    await _prefs.setString(_localeKey, locale.languageCode);
  }

  void toggleLocale() {
    // Language switching is disabled - do nothing
    return;
  }
}

// Helper provider to get the current locale code
final currentLocaleCodeProvider = Provider<String>((ref) {
  return ref.watch(localeProvider).languageCode;
});
