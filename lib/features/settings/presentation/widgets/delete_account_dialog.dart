import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  ConsumerState<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Delete Account',
        style: TextStyle(color: Colors.red),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This action cannot be undone. This will permanently delete your account and all associated data.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          const Text(
            'Please enter your password to confirm:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              errorText: _errorMessage,
            ),
            enabled: !_isLoading,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _deleteAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Delete Account'),
        ),
      ],
    );
  }

  Future<void> _deleteAccount() async {
    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Password is required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('No user found');
      }

      final email = currentUser.email;
      if (email == null) {
        throw Exception('User email not found');
      }

      // First, show confirmation dialog
      final confirmed = await _showFinalConfirmation();
      if (!confirmed) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Re-authenticate user with password
      final authService = ref.read(authServiceProvider);
      await authService.reauthenticateWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      // Delete the account
      await authService.deleteAccount();

      if (mounted && context.mounted) {
        Navigator.of(context).pop(); // Close dialog
        context.go('/'); // Navigate to home
        
        CustomSnackBar.showSuccess(context, 'Account deleted successfully');
      }
    } catch (e) {
      AppLogger.e('Error deleting account', e);
      
      setState(() {
        _isLoading = false;
        if (e.toString().contains('wrong-password') || 
            e.toString().contains('invalid-credential')) {
          _errorMessage = 'Incorrect password. Please try again.';
        } else if (e.toString().contains('too-many-requests')) {
          _errorMessage = 'Too many failed attempts. Please try again later.';
        } else {
          _errorMessage = 'Failed to delete account. Please try again.';
        }
      });
    }
  }

  Future<bool> _showFinalConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Final Confirmation',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you absolutely sure? This action cannot be undone and will permanently delete:\n\n'
          '• Your profile and account data\n'
          '• All your posts and submissions\n'
          '• Your chat history\n'
          '• All other associated data\n\n'
          'This action is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Delete My Account'),
          ),
        ],
      ),
    ) ?? false;
  }
}