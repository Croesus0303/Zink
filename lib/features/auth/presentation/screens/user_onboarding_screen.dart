import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers/auth_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class UserOnboardingScreen extends ConsumerStatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  ConsumerState<UserOnboardingScreen> createState() =>
      _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends ConsumerState<UserOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final username = _usernameController.text.trim();
      final age = int.parse(_ageController.text.trim());

      await authRepository.completeUserOnboarding(
        username: username,
        age: age,
      );

      AppLogger.i('User onboarding completed successfully');

      // Invalidate the current user data provider to refresh the router
      ref.invalidate(currentUserDataProvider);

      // Let the router handle the navigation automatically
      // The router will detect that onboarding is complete and redirect to home
    } catch (e) {
      AppLogger.e('Error completing user onboarding', e);
      if (mounted) {
        CustomSnackBar.showError(
            context, 'Failed to complete setup: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.usernameRequired;
    }
    if (value.trim().length < 3) {
      return AppLocalizations.of(context)!.usernameTooShort;
    }
    if (value.trim().length > 20) {
      return AppLocalizations.of(context)!.usernameTooLong;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return AppLocalizations.of(context)!.usernameInvalidChars;
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.ageRequired;
    }
    final age = int.tryParse(value.trim());
    if (age == null) {
      return AppLocalizations.of(context)!.enterValidNumber;
    }
    if (age < 13) {
      return AppLocalizations.of(context)!.ageTooYoung;
    }
    if (age > 120) {
      return AppLocalizations.of(context)!.enterValidAge;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
              child: Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        MediaQuery.of(context).size.width * 0.12,
                  ),
                  child: Container(
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
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.04),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.02),
                          // Welcome header
                          Text(
                            AppLocalizations.of(context)!.welcomeToZink,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.055,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: AppColors.pineGreen
                                      .withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.005),
                          Text(
                            AppLocalizations.of(context)!.onboardingSubtitle,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.035,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),

                          // Username field
                          Text(
                            AppLocalizations.of(context)!.chooseUsername,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.038,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.005),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    AppColors.iceBorder.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: TextFormField(
                              controller: _usernameController,
                              validator: _validateUsername,
                              enabled: !_isLoading,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    AppLocalizations.of(context)!.enterUsername,
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                prefixIcon: const Icon(
                                  Icons.alternate_email,
                                  color: AppColors.pineGreen,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(20),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),

                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.02),

                          // Age field
                          Text(
                            AppLocalizations.of(context)!.whatsYourAge,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.038,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.005),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    AppColors.iceBorder.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: TextFormField(
                              controller: _ageController,
                              validator: _validateAge,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    AppLocalizations.of(context)!.enterAge,
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                prefixIcon: const Icon(
                                  Icons.cake,
                                  color: AppColors.rosyBrown,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(20),
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _completeOnboarding(),
                            ),
                          ),

                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),

                          // Continue button
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.pineGreen.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    AppColors.pineGreen.withValues(alpha: 0.4),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.pineGreen
                                      .withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _isLoading ? null : _completeOnboarding,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isLoading) ...[
                                        const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                      ] else ...[
                                        const Icon(Icons.arrow_forward,
                                            color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .completeSetup,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.015),

                          // Privacy note
                          Text(
                            AppLocalizations.of(context)!.privacyNote,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.03,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
