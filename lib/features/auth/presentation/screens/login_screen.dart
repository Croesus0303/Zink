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
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
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
        backgroundColor: AppColors.midnightGreen,
        body: SafeArea(
              child: Padding(
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
                child: Column(
                  children: [
                    // Logo/Icon and App Info
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: MediaQuery.of(context).size.width * 0.3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.05),
                        child: Image.asset(
                          'assets/app_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.camera_alt_rounded,
                              size: MediaQuery.of(context).size.width * 0.12,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    Text(
                      AppLocalizations.of(context)!.appName,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                    // Auth Forms - Flexible Height
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.02,
                            vertical: MediaQuery.of(context).size.height * 0.02),
                        child: Column(
                          children: [
                            // Tab Bar - Segmented Control
                            Container(
                              height: MediaQuery.of(context).size.height * 0.055,
                              margin: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.width * 0.02,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.midnightGreen.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  color: AppColors.rosyBrown,
                                  borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.025),
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorPadding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.0075),
                                dividerColor: Colors.transparent,
                                labelColor: Colors.white,
                                unselectedLabelColor:
                                    Colors.white.withValues(alpha: 0.75),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: MediaQuery.of(context).size.width * 0.035,
                                ),
                                unselectedLabelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: MediaQuery.of(context).size.width * 0.035,
                                ),
                                tabs: const [
                                  Tab(text: 'Sign In'),
                                  Tab(text: 'Sign Up'),
                                ],
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

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
            ));
  }

  Widget _buildSignInTab() {
    return Form(
      key: _signInFormKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Email field
        Container(
          decoration: BoxDecoration(
            color: AppColors.midnightGreen.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: MediaQuery.of(context).size.width * 0.0025,
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
                  const Icon(Icons.email_outlined, color: Colors.white),
              labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
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
        SizedBox(height: MediaQuery.of(context).size.height * 0.015),

        // Password field
        Container(
          decoration: BoxDecoration(
            color: AppColors.midnightGreen.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: MediaQuery.of(context).size.width * 0.0025,
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
              prefixIcon: const Icon(Icons.lock_outlined, color: Colors.white),
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
              contentPadding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.pleaseEnterPassword;
              }
              return null;
            },
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),

        // Forgot password link
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.055,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.03,
                  vertical: MediaQuery.of(context).size.height * 0.01,
                ),
                minimumSize: Size(
                  MediaQuery.of(context).size.width * 0.22,
                  MediaQuery.of(context).size.height * 0.055,
                ),
              ),
              onPressed: _sendPasswordReset,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.03),

        // Sign in button
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.07,
          decoration: BoxDecoration(
            color: AppColors.pineGreen,
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
              onTap: _isLoading ? null : _signInWithEmailPassword,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.06,
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isLoading) ...[
                      Icon(
                        Icons.login,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    ],
                    Text(
                      _isLoading ? 'Signing in...' : 'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.03),

        // Google sign in button (only on Android)
        if (!Platform.isIOS)
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.07,
            decoration: BoxDecoration(
              color: AppColors.midnightGreen.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                onTap: _isLoading ? null : _signInWithGoogle,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.06,
                    vertical: MediaQuery.of(context).size.height * 0.02,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.g_mobiledata,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width * 0.06,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                      Text(
                        AppLocalizations.of(context)!.continueWithGoogle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.04,
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
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.07,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                onTap: _isLoading ? null : _signInWithApple,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.06,
                    vertical: MediaQuery.of(context).size.height * 0.02,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.apple,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                      Text(
                        AppLocalizations.of(context)!.continueWithApple,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.04,
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
    );
  }

  Widget _buildSignUpTab() {
    return Form(
      key: _signUpFormKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Email field
        Container(
          decoration: BoxDecoration(
            color: AppColors.midnightGreen.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: MediaQuery.of(context).size.width * 0.0025,
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
                  const Icon(Icons.email_outlined, color: Colors.white),
              labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
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
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),

        // Password field
        Container(
          decoration: BoxDecoration(
            color: AppColors.midnightGreen.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: MediaQuery.of(context).size.width * 0.0025,
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
              prefixIcon: const Icon(Icons.lock_outlined, color: Colors.white),
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
              contentPadding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
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
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),

        // Confirm password field
        Container(
          decoration: BoxDecoration(
            color: AppColors.midnightGreen.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: MediaQuery.of(context).size.width * 0.0025,
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
                  const Icon(Icons.lock_outlined, color: Colors.white),
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
              contentPadding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
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
        SizedBox(height: MediaQuery.of(context).size.height * 0.015),

        // Sign up button
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.07,
          decoration: BoxDecoration(
            color: AppColors.pineGreen,
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
              onTap: _isLoading ? null : _signUpWithEmailPassword,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.06,
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isLoading) ...[
                      Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    ],
                    Text(
                      _isLoading ? 'Signing up...' : 'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),

        // Google sign in button (only on Android)
        if (!Platform.isIOS)
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.07,
            decoration: BoxDecoration(
              color: AppColors.midnightGreen.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
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
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.07,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                onTap: _isLoading ? null : _signInWithApple,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.06,
                    vertical: MediaQuery.of(context).size.height * 0.02,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.apple,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                      Text(
                        AppLocalizations.of(context)!.continueWithApple,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.04,
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
    );
  }
}
