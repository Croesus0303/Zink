import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../../providers/auth_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/glass_container.dart';
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.radialBackgroundGradient,
          ),
          child: SafeArea(
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
                    height: MediaQuery.of(context).size.height * 0.28,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryCyan,
                                AppColors.primaryOrange,
                                AppColors.warmBeige,
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCyan.withOpacity(0.4),
                                blurRadius: 25,
                                offset: const Offset(-8, -8),
                              ),
                              BoxShadow(
                                color: AppColors.primaryOrange.withOpacity(0.4),
                                blurRadius: 25,
                                offset: const Offset(8, 8),
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(27),
                              child: Image.asset(
                                'assets/app_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 70,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context)!.appName,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            shadows: [
                              Shadow(
                                color: AppColors.primaryCyan.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.appTagline,
                          style: const TextStyle(
                            fontSize: 17,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Auth Forms - Fixed Height
                  Container(
                    height: MediaQuery.of(context).size.height * 0.65,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryCyan.withOpacity(0.15),
                          AppColors.primaryOrange.withOpacity(0.12),
                          AppColors.warmBeige.withOpacity(0.08),
                          AppColors.primaryCyanDark.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppColors.primaryCyan.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryCyan.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.primaryOrange.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(5, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tab Bar
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryCyan.withOpacity(0.1),
                                AppColors.primaryOrange.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryCyan.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryCyan.withOpacity(0.8),
                                  AppColors.primaryOrange.withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryCyan.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: AppColors.textSecondary,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            tabs: const [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Sign Up'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tab Bar View - Fixed Height
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
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
      )));
  }

  Widget _buildSignInTab() {
    return Form(
      key: _signInFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.1),
                    AppColors.primaryOrange.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryCyan),
                  labelStyle: TextStyle(color: AppColors.primaryCyan),
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
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
            ),
            const SizedBox(height: 16),

            // Password field
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.1),
                    AppColors.primaryCyan.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icon(Icons.lock_outlined, color: AppColors.primaryOrange),
                  labelStyle: TextStyle(color: AppColors.primaryOrange),
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
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
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.8),
                    AppColors.primaryCyanDark.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isLoading ? null : _signInWithEmailPassword,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isLoading) ...[
                          const Icon(Icons.login, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _isLoading ? 'Signing in...' : 'Sign In',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.15),
                    AppColors.primaryCyan.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryOrange.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isLoading ? null : _signInWithGoogle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.g_mobiledata, color: AppColors.primaryOrange, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.continueWithGoogle,
                          style: TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Apple sign in button (only on iOS)
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warmBeige.withOpacity(0.15),
                      AppColors.primaryCyan.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warmBeige.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading ? null : _signInWithApple,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apple, color: AppColors.warmBeige, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.continueWithApple,
                            style: TextStyle(
                              color: AppColors.warmBeige,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.1),
                    AppColors.primaryOrange.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryCyan),
                  labelStyle: TextStyle(color: AppColors.primaryCyan),
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
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
            ),
            const SizedBox(height: 16),

            // Password field
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.1),
                    AppColors.primaryCyan.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icon(Icons.lock_outlined, color: AppColors.primaryOrange),
                  labelStyle: TextStyle(color: AppColors.primaryOrange),
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
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
            ),
            const SizedBox(height: 16),

            // Confirm password field
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warmBeige.withOpacity(0.1),
                    AppColors.primaryCyan.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warmBeige.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: Icon(Icons.lock_outlined, color: AppColors.warmBeige),
                  labelStyle: TextStyle(color: AppColors.warmBeige),
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
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
            ),
            const SizedBox(height: 24),

            // Sign up button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.8),
                    AppColors.primaryOrangeDark.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isLoading ? null : _signUpWithEmailPassword,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isLoading) ...[
                          const Icon(Icons.person_add, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _isLoading ? 'Signing up...' : 'Sign Up',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.15),
                    AppColors.primaryCyan.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryOrange.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isLoading ? null : _signInWithGoogle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.g_mobiledata, color: AppColors.primaryOrange, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.continueWithGoogle,
                          style: TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Apple sign in button (only on iOS)
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warmBeige.withOpacity(0.15),
                      AppColors.primaryCyan.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warmBeige.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading ? null : _signInWithApple,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apple, color: AppColors.warmBeige, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.continueWithApple,
                            style: TextStyle(
                              color: AppColors.warmBeige,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
