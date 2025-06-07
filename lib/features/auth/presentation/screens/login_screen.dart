import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();

      if (mounted) {
        if (result.isSuccess) {
          // Navigation will be handled automatically by the router
        } else if (result.isCancelled) {
          // User cancelled, no action needed
        } else if (result.errorMessage != null) {
          _showErrorSnackBar(result.errorMessage!);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Language selector in top right
            const Positioned(
              top: 8,
              right: 8,
              child: LanguageToggleButton(),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),

                  // App Name
                  Text(
                    AppLocalizations.of(context)!.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    AppLocalizations.of(context)!.appTagline,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Sign in with Google button
                  _SignInButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: Icons.g_mobiledata,
                    label: AppLocalizations.of(context)!.continueWithGoogle,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;

  const _SignInButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
              ),
            )
          else
            Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            isLoading ? 'Signing in...' : label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
