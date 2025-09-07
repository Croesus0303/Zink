import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/auth_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
          CustomSnackBar.showError(context, result.errorMessage!);
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
          CustomSnackBar.showError(context, result.errorMessage!);
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
          CustomSnackBar.showError(context, result.errorMessage!);
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
          CustomSnackBar.showError(context, result.errorMessage!);
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
      CustomSnackBar.showError(context, 'Please enter your email address');
      return;
    }

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmail(_emailController.text.trim());

      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Password reset email sent! Check your inbox.');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to send password reset email: ${e.toString()}');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    AppLogger.i('LoginScreen build called');
    return Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
            child: SafeArea(
              child: Padding(
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
                child: Column(
                  children: [
                    // Logo/Icon and App Info
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.18,
                          height: MediaQuery.of(context).size.width * 0.18,
                          decoration: BoxDecoration(
                            gradient: AppColors.iceGlassGradient,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width * 0.06),
                            border: Border.all(
                              color: AppColors.iceBorder,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(-3, -3),
                              ),
                              BoxShadow(
                                color:
                                    AppColors.rosyBrown.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(3, 3),
                              ),
                            ],
                          ),
                          child: Container(
                            margin: EdgeInsets.all(
                                MediaQuery.of(context).size.width * 0.015),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  MediaQuery.of(context).size.width * 0.04),
                              child: Image.asset(
                                'assets/app_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.camera_alt_rounded,
                                    size: MediaQuery.of(context).size.width *
                                        0.12,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.width * 0.04),
                        Text(
                          AppLocalizations.of(context)!.appName,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color:
                                    AppColors.pineGreen.withValues(alpha: 0.6),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Auth Forms - Flexible Height
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.04,
                            vertical:
                                MediaQuery.of(context).size.height * 0.01),
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.05),
                        decoration: BoxDecoration(
                          gradient: AppColors.iceGlassGradient,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.iceBorder.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Tab Bar - Segmented Control
                            Container(
                              height: 44,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.iceBorder
                                      .withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  color: AppColors.pineGreen
                                      .withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.pineGreen
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorPadding: const EdgeInsets.all(3),
                                labelColor: Colors.white,
                                unselectedLabelColor:
                                    Colors.white.withValues(alpha: 0.75),
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                tabs: const [
                                  Tab(text: 'Sign In'),
                                  Tab(text: 'Sign Up'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Tab Bar View - Fixed Height
                            Expanded(
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildSignInTab() {
    return Form(
      key: _signInFormKey,
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Email field
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.iceBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.email,
              hintText: AppLocalizations.of(context)!.enterEmail,
              prefixIcon:
                  const Icon(Icons.email_outlined, color: AppColors.pineGreen),
              labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context)!.pleaseEnterEmail;
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value.trim())) {
                return AppLocalizations.of(context)!.pleaseEnterValidEmail;
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 12),

        // Password field
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.iceBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.password,
              hintText: AppLocalizations.of(context)!.enterPassword,
              prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.rosyBrown),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.pleaseEnterPassword;
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),

        // Forgot password link
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 44,
            child: TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(88, 44),
              ),
              onPressed: _sendPasswordReset,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Sign in button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.pineGreen.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.pineGreen.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.pineGreen.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isLoading ? null : _signInWithEmailPassword,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            Expanded(
                child: Divider(color: Colors.white.withValues(alpha: 0.4))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Expanded(
                child: Divider(color: Colors.white.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 16),

        // Google sign in button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isLoading ? null : _signInWithGoogle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.g_mobiledata, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.continueWithGoogle,
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

        // Apple sign in button (only on iOS)
        if (Platform.isIOS) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warmBeige.withValues(alpha: 0.15),
                  AppColors.primaryCyan.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warmBeige.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isLoading ? null : _signInWithApple,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.apple, color: AppColors.warmBeige, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.continueWithApple,
                        style: const TextStyle(
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
      ]),
      ),
    );
  }

  Widget _buildSignUpTab() {
    return Form(
      key: _signUpFormKey,
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Email field
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.iceBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.email,
              hintText: AppLocalizations.of(context)!.enterEmail,
              prefixIcon:
                  const Icon(Icons.email_outlined, color: AppColors.pineGreen),
              labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context)!.pleaseEnterEmail;
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value.trim())) {
                return AppLocalizations.of(context)!.pleaseEnterValidEmail;
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 12),

        // Password field
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.rosyBrown.withValues(alpha: 0.15),
                AppColors.pineGreen.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.iceBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.password,
              hintText: AppLocalizations.of(context)!.enterPassword,
              prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.rosyBrown),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.pleaseEnterPassword;
              }
              if (value.length < 6) {
                return AppLocalizations.of(context)!.passwordTooShort;
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 12),

        // Confirm password field
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.midnightGreen.withValues(alpha: 0.15),
                AppColors.pineGreen.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.iceBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.confirmPassword,
              hintText: AppLocalizations.of(context)!.reenterPassword,
              prefixIcon:
                  const Icon(Icons.lock_outlined, color: AppColors.midnightGreen),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.pleaseConfirmPassword;
              }
              if (value != _passwordController.text) {
                return AppLocalizations.of(context)!.passwordsDoNotMatch;
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
                AppColors.rosyBrown.withValues(alpha: 0.8),
                AppColors.rosyBrown.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.iceBorder.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isLoading ? null : _signUpWithEmailPassword,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isLoading) ...[
                      const Icon(Icons.person_add,
                          color: Colors.white, size: 20),
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
            Expanded(
                child: Divider(color: Colors.white.withValues(alpha: 0.4))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Expanded(
                child: Divider(color: Colors.white.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 16),

        // Google sign in button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isLoading ? null : _signInWithGoogle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.g_mobiledata,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.continueWithGoogle,
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

        // Apple sign in button (only on iOS)
        if (Platform.isIOS) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warmBeige.withValues(alpha: 0.15),
                  AppColors.primaryCyan.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warmBeige.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isLoading ? null : _signInWithApple,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.apple, color: AppColors.warmBeige, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.continueWithApple,
                        style: const TextStyle(
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
      ]),
      ),
    );
  }
}
