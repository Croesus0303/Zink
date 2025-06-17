import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../../providers/auth_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/crystal_scaffold.dart';
import '../../../../shared/widgets/crystal_container.dart';
import '../../../../shared/widgets/crystal_button.dart';
import '../../../../shared/widgets/crystal_text_field.dart';
import '../../../../shared/widgets/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Email/Password form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Clear form when screen is initialized (in case user logged out)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearAllFields();
    });
  }

  void _clearAllFields() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();

    // Reset form validations
    _signInFormKey.currentState?.reset();
    _signUpFormKey.currentState?.reset();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      // Clear form fields when switching tabs
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      // Reset form validations
      _signInFormKey.currentState?.reset();
      _signUpFormKey.currentState?.reset();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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

  Future<void> _signInWithApple() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithApple();

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

  Future<void> _signInWithEmailPassword() async {
    if (!_signInFormKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (result.isSuccess) {
          // Navigation will be handled automatically by the router
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

  Future<void> _signUpWithEmailPassword() async {
    if (!_signUpFormKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (result.isSuccess) {
          // Navigation will be handled automatically by the router
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

  Future<void> _sendPasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email address');
      return;
    }

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmail(_emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            'Failed to send password reset email: ${e.toString()}');
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
    AppLogger.i('LoginScreen build called');
    return CrystalScaffold(
      showBackButton: false,
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
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Logo/Icon and App Info
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.primaryCyan, AppColors.primaryCyanDark],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCyan.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context)!.appName,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryCyan,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.appTagline,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Auth Forms
                  CrystalContainer(
                    useCyanAccent: true,
                    child: Column(
                      children: [
                        // Tab Bar
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardDark.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: AppColors.primaryCyan,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: AppColors.textSecondary,
                            tabs: const [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Sign Up'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tab Bar View
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildSignInTab(),
                              _buildSignUpTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInTab() {
    return Form(
      key: _signInFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            CrystalTextField(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value.trim())) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password field
            CrystalTextField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outlined,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Forgot password link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _sendPasswordReset,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: AppColors.primaryCyan),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sign in button
            CrystalButton(
              text: _isLoading ? 'Signing in...' : 'Sign In',
              onPressed: _isLoading ? () {} : _signInWithEmailPassword,
              icon: _isLoading ? null : Icons.login,
            ),
            const SizedBox(height: 16),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: AppColors.textSecondary)),
                ),
                Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
              ],
            ),
            const SizedBox(height: 16),

            // Google sign in button
            CrystalButton(
              text: AppLocalizations.of(context)!.continueWithGoogle,
              onPressed: _isLoading ? () {} : _signInWithGoogle,
              icon: Icons.g_mobiledata,
              isOutlined: true,
            ),
            
            // Apple sign in button (only on iOS)
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              CrystalButton(
                text: AppLocalizations.of(context)!.continueWithApple,
                onPressed: _isLoading ? () {} : _signInWithApple,
                icon: Icons.apple,
                isOutlined: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpTab() {
    return Form(
      key: _signUpFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            CrystalTextField(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value.trim())) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password field
            CrystalTextField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outlined,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm password field
            CrystalTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              hintText: 'Re-enter your password',
              prefixIcon: Icons.lock_outlined,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Sign up button
            CrystalButton(
              text: _isLoading ? 'Signing up...' : 'Sign Up',
              onPressed: _isLoading ? () {} : _signUpWithEmailPassword,
              icon: _isLoading ? null : Icons.person_add,
            ),
            const SizedBox(height: 16),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: AppColors.textSecondary)),
                ),
                Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
              ],
            ),
            const SizedBox(height: 16),

            // Google sign in button
            CrystalButton(
              text: AppLocalizations.of(context)!.continueWithGoogle,
              onPressed: _isLoading ? () {} : _signInWithGoogle,
              icon: Icons.g_mobiledata,
              isOutlined: true,
            ),
            
            // Apple sign in button (only on iOS)
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              CrystalButton(
                text: AppLocalizations.of(context)!.continueWithApple,
                onPressed: _isLoading ? () {} : _signInWithApple,
                icon: Icons.apple,
                isOutlined: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
