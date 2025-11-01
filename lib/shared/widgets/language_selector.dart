import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/locale_provider.dart';
import 'app_colors.dart';

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
          SizedBox(width: MediaQuery.of(context).size.width * 0.01),
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
              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
              Text(
                'English',
                style: TextStyle(
                  fontWeight: locale.languageCode == 'en'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (locale.languageCode == 'en')
                Padding(
                  padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.02),
                  child: Icon(Icons.check, size: MediaQuery.of(context).size.width * 0.04),
                ),
            ],
          ),
        ),
        PopupMenuItem(
          value: const Locale('tr'),
          child: Row(
            children: [
              const Text('🇹🇷'),
              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
              Text(
                'Türkçe',
                style: TextStyle(
                  fontWeight: locale.languageCode == 'tr'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (locale.languageCode == 'tr')
                Padding(
                  padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.02),
                  child: Icon(Icons.check, size: MediaQuery.of(context).size.width * 0.04),
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

    return Container(
      width: MediaQuery.of(context).size.width * 0.11,
      height: MediaQuery.of(context).size.width * 0.11,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            AppColors.pineGreen.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
        border: Border.all(
          color: AppColors.iceBorder,
          width: MediaQuery.of(context).size.width * 0.0025,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: MediaQuery.of(context).size.width * 0.02,
            offset: Offset(-MediaQuery.of(context).size.width * 0.0025,
                -MediaQuery.of(context).size.width * 0.0025),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: MediaQuery.of(context).size.width * 0.02,
            offset: Offset(MediaQuery.of(context).size.width * 0.0025,
                MediaQuery.of(context).size.width * 0.0025),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
          onTap: () {
            ref.read(localeProvider.notifier).toggleLocale();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                locale.languageCode == 'en' ? '🇬🇧' : '🇹🇷',
                style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.0025),
              Text(
                locale.languageCode.toUpperCase(),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.025,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
