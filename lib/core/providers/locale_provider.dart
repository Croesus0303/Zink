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
    final languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      return Locale(languageCode);
    }
    // Default to system locale or English
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;

    state = locale;
    await _prefs.setString(_localeKey, locale.languageCode);
  }

  void toggleLocale() {
    // Toggle between English and Turkish
    final newLocale =
        state.languageCode == 'en' ? const Locale('tr') : const Locale('en');
    setLocale(newLocale);
  }
}

// Helper provider to get the current locale code
final currentLocaleCodeProvider = Provider<String>((ref) {
  return ref.watch(localeProvider).languageCode;
});
