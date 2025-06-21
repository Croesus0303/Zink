import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/logger.dart';
import '../widgets/delete_account_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }

  Widget _buildAccountSection(
      BuildContext context, WidgetRef ref, currentUser) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            subtitle: Text(currentUser?.email ?? 'Not signed in'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/profile');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Manage notification preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNotificationSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(
      BuildContext context, WidgetRef ref, String currentLocale) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(_getLanguageDisplayName(currentLocale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, ref, currentLocale),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('System default'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacyPolicy(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHelpAndSupport(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.red.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Danger Zone',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
            title: Text(
              'Delete Account',
              style: TextStyle(color: Colors.red.shade700),
            ),
            subtitle:
                const Text('Permanently delete your account and all data'),
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
        ],
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
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLocale,
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(Locale(value));
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Türkçe'),
              value: 'tr',
              groupValue: currentLocale,
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
            child: const Text('Cancel'),
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
        title: const Text('Privacy Policy'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zink Privacy Policy',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Last updated: ${DateTime.now().year}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
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
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
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
            title: const Text('Notification Settings'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Enable all push notifications'),
                    value: pushNotifications,
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
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Event Updates'),
                    subtitle: const Text('New events and event changes'),
                    value: eventNotifications,
                    onChanged: pushNotifications ? (value) {
                      setState(() {
                        eventNotifications = value;
                      });
                      AppLogger.i('Event notifications: $value');
                    } : null,
                  ),
                  SwitchListTile(
                    title: const Text('Messages'),
                    subtitle: const Text('New chat messages'),
                    value: messageNotifications,
                    onChanged: pushNotifications ? (value) {
                      setState(() {
                        messageNotifications = value;
                      });
                      AppLogger.i('Message notifications: $value');
                    } : null,
                  ),
                  SwitchListTile(
                    title: const Text('Likes'),
                    subtitle: const Text('When someone likes your posts'),
                    value: likeNotifications,
                    onChanged: pushNotifications ? (value) {
                      setState(() {
                        likeNotifications = value;
                      });
                      AppLogger.i('Like notifications: $value');
                    } : null,
                  ),
                  SwitchListTile(
                    title: const Text('Comments'),
                    subtitle: const Text('When someone comments on your posts'),
                    value: commentNotifications,
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
                child: const Text('Cancel'),
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
                child: const Text('Save'),
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
        title: const Text('Help & Support'),
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
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            item,
            style: const TextStyle(fontSize: 14),
          ),
        )),
      ],
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System Default'),
              subtitle: const Text('Follow device theme'),
              value: 'system',
              groupValue: 'system', // TODO: Add theme provider
              onChanged: (value) {
                // TODO: Implement theme switching
                AppLogger.i('Theme changed to: $value');
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              subtitle: const Text('Always use light theme'),
              value: 'light',
              groupValue: 'system', // TODO: Add theme provider
              onChanged: (value) {
                // TODO: Implement theme switching
                AppLogger.i('Theme changed to: $value');
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              subtitle: const Text('Always use dark theme'),
              value: 'dark',
              groupValue: 'system', // TODO: Add theme provider
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
            child: const Text('Cancel'),
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
