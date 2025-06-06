import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/locale_provider.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return PopupMenuButton<Locale>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.language,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 4),
          Text(
            locale.languageCode.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
      onSelected: (Locale newLocale) {
        ref.read(localeProvider.notifier).setLocale(newLocale);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: const Locale('en'),
          child: Row(
            children: [
              const Text('🇬🇧'),
              const SizedBox(width: 8),
              Text(
                'English',
                style: TextStyle(
                  fontWeight: locale.languageCode == 'en'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (locale.languageCode == 'en')
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, size: 16),
                ),
            ],
          ),
        ),
        PopupMenuItem(
          value: const Locale('tr'),
          child: Row(
            children: [
              const Text('🇹🇷'),
              const SizedBox(width: 8),
              Text(
                'Türkçe',
                style: TextStyle(
                  fontWeight: locale.languageCode == 'tr'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (locale.languageCode == 'tr')
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, size: 16),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return IconButton(
      icon: Text(
        locale.languageCode == 'en' ? '🇬🇧' : '🇹🇷',
        style: const TextStyle(fontSize: 24),
      ),
      onPressed: () {
        ref.read(localeProvider.notifier).toggleLocale();
      },
      tooltip: locale.languageCode == 'en'
          ? 'Switch to Turkish'
          : 'Switch to English',
    );
  }
}
