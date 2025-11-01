import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/app_colors.dart';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete Account',
                style: TextStyle(
                  color: AppColors.rosyBrown,
                  fontSize: MediaQuery.of(context).size.width * 0.055,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Text(
                'This action cannot be undone. This will permanently delete your account and all associated data.',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Text(
                'Please enter your password to confirm:',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: MediaQuery.of(context).size.width * 0.038,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                    borderSide: BorderSide(color: AppColors.iceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                    borderSide: BorderSide(color: AppColors.iceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                    borderSide: BorderSide(color: AppColors.pineGreen, width: MediaQuery.of(context).size.width * 0.005),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                    borderSide: BorderSide(color: AppColors.rosyBrown, width: MediaQuery.of(context).size.width * 0.005),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.pineGreen,
                      size: MediaQuery.of(context).size.width * 0.06,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                  errorText: _errorMessage,
                  errorStyle: TextStyle(
                    color: AppColors.rosyBrown,
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                  ),
                ),
                enabled: !_isLoading,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
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
                        onTap: _isLoading ? null : _deleteAccount,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.05,
                            vertical: MediaQuery.of(context).size.height * 0.015,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.04,
                                  height: MediaQuery.of(context).size.width * 0.04,
                                  child: CircularProgressIndicator(
                                    strokeWidth: MediaQuery.of(context).size.width * 0.005,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Delete Account',
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
            ],
          ),
        ),
      ),
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
                  'Final Confirmation',
                  style: TextStyle(
                    color: AppColors.rosyBrown,
                    fontSize: MediaQuery.of(context).size.width * 0.055,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  'Are you absolutely sure? This action cannot be undone and will permanently delete:\n\n'
                  '• Your profile and account data\n'
                  '• All your posts and submissions\n'
                  '• Your chat history\n'
                  '• All other associated data\n\n'
                  'This action is irreversible.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
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
                          onTap: () => Navigator.of(context).pop(true),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.05,
                              vertical: MediaQuery.of(context).size.height * 0.015,
                            ),
                            child: Text(
                              'Yes, Delete My Account',
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
              ],
            ),
          ),
        ),
      ),
    ) ?? false;
  }
}