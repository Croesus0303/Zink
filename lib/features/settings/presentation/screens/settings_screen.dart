import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/delete_account_dialog.dart';
import '../../../../shared/widgets/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.midnightGreen,
      body: Stack(
        children: [
          // Main content
          ListView(
            padding: EdgeInsets.fromLTRB(
              0,
              MediaQuery.of(context).padding.top + MediaQuery.of(context).size.height * 0.075,
              0,
              MediaQuery.of(context).size.width * 0.04,
            ),
            children: [
              _buildAppSection(context, ref),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              _buildDangerZone(context, ref),
            ],
          ),
          // Back button (top left)
          Positioned(
            top: MediaQuery.of(context).padding.top + MediaQuery.of(context).size.height * 0.01,
            left: MediaQuery.of(context).size.width * 0.04,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: MediaQuery.of(context).size.width * 0.08,
              ),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          // Title (top center)
          Positioned(
            top: MediaQuery.of(context).padding.top + MediaQuery.of(context).size.height * 0.02,
            left: 0,
            right: 0,
            child: Center(
              child: IgnorePointer(
                child: Text(
                  AppLocalizations.of(context)!.settings,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.043,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    shadows: [
                      Shadow(
                        color: AppColors.rosyBrown.withValues(alpha: 0.4),
                        blurRadius: MediaQuery.of(context).size.width * 0.02,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildSettingsListTile(
          context,
          icon: Icons.info_outline,
          title: AppLocalizations.of(context)!.about,
          subtitle: AppLocalizations.of(context)!.version('1.0.0'),
          iconColor: Colors.white.withValues(alpha: 0.65),
          onTap: () => _showAboutDialog(context),
        ),
        Divider(
          height: MediaQuery.of(context).size.width * 0.0025,
          thickness: MediaQuery.of(context).size.width * 0.0025,
          color: Colors.white.withValues(alpha: 0.2),
          indent: 0,
          endIndent: 0,
        ),
        _buildSettingsListTile(
          context,
          icon: Icons.privacy_tip_outlined,
          title: AppLocalizations.of(context)!.privacyPolicy,
          subtitle: null,
          iconColor: Colors.white.withValues(alpha: 0.65),
          onTap: () => _showPrivacyPolicy(context),
        ),
        Divider(
          height: MediaQuery.of(context).size.width * 0.0025,
          thickness: MediaQuery.of(context).size.width * 0.0025,
          color: Colors.white.withValues(alpha: 0.2),
          indent: 0,
          endIndent: 0,
        ),
        _buildSettingsListTile(
          context,
          icon: Icons.help_outline,
          title: AppLocalizations.of(context)!.helpAndSupport,
          subtitle: null,
          iconColor: Colors.white.withValues(alpha: 0.65),
          onTap: () => _showHelpAndSupport(context),
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.025),
      child: _buildSettingsListTile(
        context,
        icon: Icons.delete_outline,
        title: AppLocalizations.of(context)!.deleteAccount,
        subtitle: AppLocalizations.of(context)!.permanentlyDeleteAccount,
        iconColor: AppColors.rosyBrown,
        onTap: () => _showDeleteAccountDialog(context, ref),
        showTrailing: false,
        isDangerous: true,
      ),
    );
  }

  Widget _buildSettingsListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    bool showTrailing = true,
    bool isDangerous = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: isDangerous
            ? AppColors.rosyBrown.withValues(alpha: 0.15)
            : null,
        highlightColor: isDangerous
            ? AppColors.rosyBrown.withValues(alpha: 0.1)
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: MediaQuery.of(context).size.height * 0.015,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.0025),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: MediaQuery.of(context).size.width * 0.06,
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
                        color: isDangerous ? AppColors.rosyBrown : Colors.white,
                        letterSpacing: 0.3,
                        shadows: isDangerous
                            ? [
                                Shadow(
                                  color: AppColors.rosyBrown.withValues(alpha: 0.4),
                                  blurRadius: MediaQuery.of(context).size.width * 0.02,
                                  offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.004),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.038,
                          color: Colors.white.withValues(alpha: 0.7),
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
                  color: Colors.white.withValues(alpha: 0.6),
                  size: MediaQuery.of(context).size.width * 0.05,
                ),
            ],
          ),
        ),
      ),
    );
  }



  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.06),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: AppColors.midnightGreen.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.06),
            border: Border.all(
              color: AppColors.iceBorder,
              width: MediaQuery.of(context).size.width * 0.00375,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: MediaQuery.of(context).size.width * 0.05,
                offset: Offset(0, MediaQuery.of(context).size.height * 0.0125),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'About Zink',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: MediaQuery.of(context).size.width * 0.055,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                Image.asset(
                  'assets/app_logo.png',
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: MediaQuery.of(context).size.width * 0.2,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  'Zink',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: MediaQuery.of(context).size.width * 0.038,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  'A social photo sharing app for events and moments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.rosyBrown.withValues(alpha: 0.8),
                        AppColors.rosyBrown,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.08,
                          vertical: MediaQuery.of(context).size.height * 0.015,
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.625),
          decoration: BoxDecoration(
            color: AppColors.midnightGreen.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.06),
            border: Border.all(
              color: AppColors.iceBorder,
              width: MediaQuery.of(context).size.width * 0.00375,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: MediaQuery.of(context).size.width * 0.05,
                offset: Offset(0, MediaQuery.of(context).size.height * 0.0125),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: MediaQuery.of(context).size.width * 0.055,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zink Privacy Policy',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                        Text(
                          'Last updated: ${DateTime.now().year}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                            fontSize: MediaQuery.of(context).size.width * 0.038,
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        _buildPrivacySection(
                          context,
                          'Information We Collect',
                          'We collect information you provide directly to us, such as when you create an account, post photos, or communicate with others through our service.',
                        ),
                        _buildPrivacySection(
                          context,
                          'How We Use Your Information',
                          'We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.',
                        ),
                        _buildPrivacySection(
                          context,
                          'Information Sharing',
                          'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.',
                        ),
                        _buildPrivacySection(
                          context,
                          'Data Security',
                          'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
                        ),
                        _buildPrivacySection(
                          context,
                          'Your Rights',
                          'You have the right to access, update, or delete your personal information. You can do this through your account settings or by contacting us.',
                        ),
                        _buildPrivacySection(
                          context,
                          'Contact Us',
                          'If you have any questions about this Privacy Policy, please contact us through the Help & Support section.',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.rosyBrown.withValues(alpha: 0.8),
                          AppColors.rosyBrown,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.08,
                            vertical: MediaQuery.of(context).size.height * 0.015,
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width * 0.04,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context, String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width * 0.04,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Text(
            content,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.035,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }


  void _showHelpAndSupport(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.625),
          decoration: BoxDecoration(
            color: AppColors.midnightGreen.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.06),
            border: Border.all(
              color: AppColors.iceBorder,
              width: MediaQuery.of(context).size.width * 0.00375,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: MediaQuery.of(context).size.width * 0.05,
                offset: Offset(0, MediaQuery.of(context).size.height * 0.0125),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Help & Support',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: MediaQuery.of(context).size.width * 0.055,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                Expanded(
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
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        _buildHelpSection(
                          context,
                          'Contact Support',
                          [
                            'Email: support@zinkapp.com',
                            'Response time: 24-48 hours',
                            'For urgent issues, please include "URGENT" in your subject line.',
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        _buildHelpSection(
                          context,
                          'App Version',
                          [
                            'Version: 1.0.0',
                            'Last updated: ${DateTime.now().year}',
                            'Platform: Mobile App',
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.rosyBrown.withValues(alpha: 0.8),
                          AppColors.rosyBrown,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.08,
                            vertical: MediaQuery.of(context).size.height * 0.015,
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width * 0.04,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection(
      BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width * 0.04,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.01),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  color: AppColors.textSecondary,
                ),
              ),
            )),
      ],
    );
  }


  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const DeleteAccountDialog(),
    );
  }
}
