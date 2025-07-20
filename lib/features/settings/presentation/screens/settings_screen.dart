import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/logger.dart';
import '../widgets/delete_account_dialog.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen.withValues(alpha: 0.9),
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.065,
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: AppColors.rosyBrown.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.only(left: 12, top: 3, bottom: 3),
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
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.iceBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(-1, -1),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.04,
            ),
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width * 0.08,
              minHeight: MediaQuery.of(context).size.width * 0.08,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.04,
              MediaQuery.of(context).size.height * 0.12,
              MediaQuery.of(context).size.width * 0.04,
              MediaQuery.of(context).size.width * 0.04,
            ),
            children: [
              _buildSectionHeader(context, 'Account'),
              _buildAccountSection(context, ref, currentUser),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Preferences'),
              _buildPreferencesSection(context, ref, currentLocale.languageCode),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'App'),
              _buildAppSection(context, ref),
              const SizedBox(height: 32),
              _buildDangerZone(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.015),
      child: Text(
        title,
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.055,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: AppColors.rosyBrown.withValues(alpha: 0.6),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(
      BuildContext context, WidgetRef ref, currentUser) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.midnightGreen.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.iceBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: AppColors.rosyBrown.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      child: Column(
        children: [
          _buildSettingsListTile(
            context,
            icon: Icons.person,
            title: 'Profile',
            subtitle: currentUser?.email ?? 'Not signed in',
            iconColor: AppColors.primaryCyan,
            onTap: () => context.push('/profile'),
          ),
          Divider(
            height: 1,
            color: AppColors.primaryCyan.withOpacity(0.2),
            indent: 16,
            endIndent: 16,
          ),
          _buildSettingsListTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            iconColor: AppColors.primaryCyan,
            onTap: () => _showNotificationSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(
      BuildContext context, WidgetRef ref, String currentLocale) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.midnightGreen.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.iceBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: AppColors.rosyBrown.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      child: Column(
        children: [
          _buildSettingsListTile(
            context,
            icon: Icons.language,
            title: 'Language',
            subtitle: _getLanguageDisplayName(currentLocale),
            iconColor: AppColors.primaryOrange,
            onTap: () => _showLanguageDialog(context, ref, currentLocale),
          ),
          Divider(
            height: 1,
            color: AppColors.primaryOrange.withOpacity(0.2),
            indent: 16,
            endIndent: 16,
          ),
          _buildSettingsListTile(
            context,
            icon: Icons.palette,
            title: 'Theme',
            subtitle: 'System default',
            iconColor: AppColors.primaryOrange,
            onTap: () => _showThemeDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.midnightGreen.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.iceBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: AppColors.rosyBrown.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      child: Column(
        children: [
          _buildSettingsListTile(
            context,
            icon: Icons.info,
            title: 'About',
            subtitle: 'Version 1.0.0',
            iconColor: AppColors.primaryCyan,
            onTap: () => _showAboutDialog(context),
          ),
          Divider(
            height: 1,
            color: AppColors.primaryCyan.withOpacity(0.2),
            indent: 16,
            endIndent: 16,
          ),
          _buildSettingsListTile(
            context,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: null,
            iconColor: AppColors.primaryCyan,
            onTap: () => _showPrivacyPolicy(context),
          ),
          Divider(
            height: 1,
            color: AppColors.primaryCyan.withOpacity(0.2),
            indent: 16,
            endIndent: 16,
          ),
          _buildSettingsListTile(
            context,
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: null,
            iconColor: AppColors.primaryCyan,
            onTap: () => _showHelpAndSupport(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.rosyBrown.withValues(alpha: 0.15),
            AppColors.rosyBrown.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.rosyBrown.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: AppColors.rosyBrown.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      child: _buildSettingsListTile(
        context,
        icon: Icons.delete_forever,
        title: 'Delete Account',
        subtitle: 'Permanently delete your account and all data',
        iconColor: AppColors.rosyBrown,
        onTap: () => _showDeleteAccountDialog(context, ref),
        showTrailing: false,
      ),
    );
  }

  Widget _buildSettingsListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    Color? titleColor,
    required VoidCallback onTap,
    bool showTrailing = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.005),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: MediaQuery.of(context).size.height * 0.015,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.pineGreen.withValues(alpha: 0.1),
                AppColors.rosyBrown.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.iceBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.1,
                height: MediaQuery.of(context).size.width * 0.1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.pineGreen.withValues(alpha: 0.2),
                      AppColors.pineGreen.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon, 
                  color: Colors.white, 
                  size: MediaQuery.of(context).size.width * 0.05,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.042,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: MediaQuery.of(context).size.height * 0.004),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.038,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showTrailing)
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: MediaQuery.of(context).size.width * 0.05,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageDisplayName(String locale) {
    switch (locale) {
      case 'en':
        return 'English';
      case 'tr':
        return 'Türkçe';
      default:
        return 'English';
    }
  }

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, String currentLocale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: const Text(
          'Select Language',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English', style: TextStyle(color: AppColors.textPrimary)),
              value: 'en',
              groupValue: currentLocale,
              activeColor: AppColors.primaryCyan,
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(Locale(value));
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Türkçe', style: TextStyle(color: AppColors.textPrimary)),
              value: 'tr',
              groupValue: currentLocale,
              activeColor: AppColors.primaryCyan,
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(Locale(value));
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.primaryCyan),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Zink',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.camera_alt, size: 48),
      children: [
        const Text('A social photo sharing app for events and moments.'),
      ],
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zink Privacy Policy',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Last updated: ${DateTime.now().year}',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPrivacySection(
                  'Information We Collect',
                  'We collect information you provide directly to us, such as when you create an account, post photos, or communicate with others through our service.',
                ),
                _buildPrivacySection(
                  'How We Use Your Information', 
                  'We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.',
                ),
                _buildPrivacySection(
                  'Information Sharing',
                  'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.',
                ),
                _buildPrivacySection(
                  'Data Security',
                  'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
                ),
                _buildPrivacySection(
                  'Your Rights',
                  'You have the right to access, update, or delete your personal information. You can do this through your account settings or by contacting us.',
                ),
                _buildPrivacySection(
                  'Contact Us',
                  'If you have any questions about this Privacy Policy, please contact us through the Help & Support section.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // TODO: Replace with actual notification settings from a provider
          bool pushNotifications = true;
          bool eventNotifications = true;
          bool messageNotifications = true;
          bool likeNotifications = false;
          bool commentNotifications = true;

          return AlertDialog(
            backgroundColor: AppColors.backgroundSecondary,
            title: const Text(
              'Notification Settings',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Push Notifications', style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: const Text('Enable all push notifications', style: TextStyle(color: AppColors.textSecondary)),
                    value: pushNotifications,
                    activeColor: AppColors.primaryCyan,
                    onChanged: (value) {
                      setState(() {
                        pushNotifications = value;
                        // If disabling push notifications, disable all others
                        if (!value) {
                          eventNotifications = false;
                          messageNotifications = false;
                          likeNotifications = false;
                          commentNotifications = false;
                        }
                      });
                      AppLogger.i('Push notifications: $value');
                    },
                  ),
                  Divider(color: AppColors.primaryCyan.withOpacity(0.2)),
                  SwitchListTile(
                    title: const Text('Event Updates', style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: const Text('New events and event changes', style: TextStyle(color: AppColors.textSecondary)),
                    value: eventNotifications,
                    activeColor: AppColors.primaryCyan,
                    onChanged: pushNotifications ? (value) {
                      setState(() {
                        eventNotifications = value;
                      });
                      AppLogger.i('Event notifications: $value');
                    } : null,
                  ),
                  SwitchListTile(
                    title: const Text('Messages', style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: const Text('New chat messages', style: TextStyle(color: AppColors.textSecondary)),
                    value: messageNotifications,
                    activeColor: AppColors.primaryCyan,
                    onChanged: pushNotifications ? (value) {
                      setState(() {
                        messageNotifications = value;
                      });
                      AppLogger.i('Message notifications: $value');
                    } : null,
                  ),
                  SwitchListTile(
                    title: const Text('Likes', style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: const Text('When someone likes your posts', style: TextStyle(color: AppColors.textSecondary)),
                    value: likeNotifications,
                    activeColor: AppColors.primaryCyan,
                    onChanged: pushNotifications ? (value) {
                      setState(() {
                        likeNotifications = value;
                      });
                      AppLogger.i('Like notifications: $value');
                    } : null,
                  ),
                  SwitchListTile(
                    title: const Text('Comments', style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: const Text('When someone comments on your posts', style: TextStyle(color: AppColors.textSecondary)),
                    value: commentNotifications,
                    activeColor: AppColors.primaryCyan,
                    onChanged: pushNotifications ? (value) {
                      setState(() {
                        commentNotifications = value;
                      });
                      AppLogger.i('Comment notifications: $value');
                    } : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Save notification settings to provider/storage
                  AppLogger.i('Saving notification settings...');
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings saved'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: AppColors.primaryCyan),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showHelpAndSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: const Text(
          'Help & Support',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpSection(
                  context,
                  'Frequently Asked Questions',
                  [
                    'How do I create an account?\nTap the sign up button and follow the prompts to create your account.',
                    'How do I post a photo?\nTap the camera icon in the events section and select an active event.',
                    'How do I like a submission?\nTap the heart icon below any photo submission.',
                    'How do I edit my profile?\nGo to Profile > Menu > Edit Profile.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildHelpSection(
                  context,
                  'Contact Support',
                  [
                    'Email: support@zinkapp.com',
                    'Response time: 24-48 hours',
                    'For urgent issues, please include "URGENT" in your subject line.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildHelpSection(
                  context,
                  'App Version',
                  [
                    'Version: 1.0.0',
                    'Last updated: ${DateTime.now().year}',
                    'Platform: Mobile App',
                  ],
                ),
                const SizedBox(height: 16),
                _buildHelpSection(
                  context,
                  'Report a Bug',
                  [
                    'If you encounter any issues, please describe:',
                    '• What you were doing when the problem occurred',
                    '• Steps to reproduce the issue',
                    '• Your device model and OS version',
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        )),
      ],
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: const Text(
          'Select Theme',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System Default', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Follow device theme', style: TextStyle(color: AppColors.textSecondary)),
              value: 'system',
              groupValue: 'system', // TODO: Add theme provider
              activeColor: AppColors.primaryOrange,
              onChanged: (value) {
                // TODO: Implement theme switching
                AppLogger.i('Theme changed to: $value');
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Light', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Always use light theme', style: TextStyle(color: AppColors.textSecondary)),
              value: 'light',
              groupValue: 'system', // TODO: Add theme provider
              activeColor: AppColors.primaryOrange,
              onChanged: (value) {
                // TODO: Implement theme switching
                AppLogger.i('Theme changed to: $value');
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Always use dark theme', style: TextStyle(color: AppColors.textSecondary)),
              value: 'dark',
              groupValue: 'system', // TODO: Add theme provider
              activeColor: AppColors.primaryOrange,
              onChanged: (value) {
                // TODO: Implement theme switching
                AppLogger.i('Theme changed to: $value');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => DeleteAccountDialog(),
    );
  }
}
