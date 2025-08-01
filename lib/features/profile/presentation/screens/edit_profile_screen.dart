import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/app_colors.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _instagramController;
  late TextEditingController _twitterController;
  late TextEditingController _facebookController;
  late TextEditingController _linkedinController;
  late TextEditingController _websiteController;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _instagramController =
        TextEditingController(text: widget.user.socialLinks['instagram'] ?? '');
    _twitterController =
        TextEditingController(text: widget.user.socialLinks['twitter'] ?? '');
    _facebookController =
        TextEditingController(text: widget.user.socialLinks['facebook'] ?? '');
    _linkedinController =
        TextEditingController(text: widget.user.socialLinks['linkedin'] ?? '');
    _websiteController =
        TextEditingController(text: widget.user.socialLinks['website'] ?? '');
  }

  @override
  void dispose() {
    _instagramController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      AppLogger.e('Error picking image', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      AppLogger.e('Error taking photo', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.chooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(AppLocalizations.of(context)!.takePhoto),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      AppLogger.i('Starting profile save...');
      final authRepository = ref.read(authRepositoryProvider);
      AppLogger.i('Auth repository obtained: $authRepository');

      // Prepare social links
      final socialLinks = <String, String>{};
      if (_instagramController.text.isNotEmpty) {
        socialLinks['instagram'] = _instagramController.text.trim();
      }
      if (_twitterController.text.isNotEmpty) {
        socialLinks['twitter'] = _twitterController.text.trim();
      }
      if (_facebookController.text.isNotEmpty) {
        socialLinks['facebook'] = _facebookController.text.trim();
      }
      if (_linkedinController.text.isNotEmpty) {
        socialLinks['linkedin'] = _linkedinController.text.trim();
      }
      if (_websiteController.text.isNotEmpty) {
        socialLinks['website'] = _websiteController.text.trim();
      }

      AppLogger.i('Social links prepared: $socialLinks');
      AppLogger.i('Selected image: ${_selectedImage?.path ?? 'None'}');

      // Update profile with both social links and image
      await authRepository.updateUserProfile(
        socialLinks: socialLinks,
        profileImage: _selectedImage,
      );

      AppLogger.i('Profile update completed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.e('Error updating profile', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen.withValues(alpha: 0.9),
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.08,
        title: Text(
          AppLocalizations.of(context)!.editProfile,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: AppColors.rosyBrown.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.only(left: 12, top: 3, bottom: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                AppColors.pineGreen.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.iceBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(-1, -1),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.04,
            ),
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width * 0.08,
              minHeight: MediaQuery.of(context).size.width * 0.08,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
            height: 48, // Minimum accessible tap target
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.pineGreen.withValues(alpha: 0.9),
                  AppColors.pineGreen.withValues(alpha: 1.0),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pineGreen.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: MediaQuery.of(context).size.height * 0.01,
                ),
                minimumSize: Size(MediaQuery.of(context).size.width * 0.2, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)!.save,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.midnightGreen.withValues(alpha: 0.85),
                AppColors.midnightGreen.withValues(alpha: 0.75),
              ],
            ),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * 0.06,
                MediaQuery.of(context).size.height * 0.12,
                MediaQuery.of(context).size.width * 0.06,
                MediaQuery.of(context).size.height * 0.08,
              ),
              children: [
                // Profile Picture Section
                Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.02,
                    ),
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                    decoration: BoxDecoration(
                      gradient: AppColors.iceGlassGradient,
                      borderRadius: BorderRadius.circular(100),
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
                          color: AppColors.rosyBrown.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.pineGreen.withValues(alpha: 0.2),
                                AppColors.rosyBrown.withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(80),
                            border: Border.all(
                              color: AppColors.iceBorder,
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: MediaQuery.of(context).size.width * 0.15,
                            backgroundColor: Colors.transparent,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!) as ImageProvider
                                : (widget.user.photoURL != null
                                    ? NetworkImage(widget.user.photoURL!)
                                        as ImageProvider
                                    : null),
                            child: _selectedImage == null && widget.user.photoURL == null
                                ? Text(
                                    widget.user.displayName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width * 0.08,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.pineGreen,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.pineGreen.withValues(alpha: 0.9),
                                  AppColors.pineGreen.withValues(alpha: 0.8),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.pineGreen.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: _showImagePickerOptions,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: MediaQuery.of(context).size.width * 0.04,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                // Social Links Section
                _buildSectionTitle(AppLocalizations.of(context)!.socialLinks),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                _buildSocialLinkField(
                  controller: _instagramController,
                  label: 'Instagram',
                  hint: '@username',
                  icon: Icons.camera_alt,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),

                _buildSocialLinkField(
                  controller: _twitterController,
                  label: 'Twitter',
                  hint: '@handle',
                  icon: Icons.social_distance,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),

                _buildSocialLinkField(
                  controller: _facebookController,
                  label: 'Facebook',
                  hint: 'Profile name',
                  icon: Icons.facebook,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),

                _buildSocialLinkField(
                  controller: _linkedinController,
                  label: 'LinkedIn',
                  hint: 'Profile name',
                  icon: Icons.business_center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),

                _buildSocialLinkField(
                  controller: _websiteController,
                  label: 'Website',
                  hint: 'https://yoursite.com',
                  icon: Icons.public,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.06),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.01,
        top: MediaQuery.of(context).size.height * 0.015,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.06,
        vertical: MediaQuery.of(context).size.height * 0.022,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.pineGreen.withValues(alpha: 0.8),
            AppColors.pineGreen.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pineGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.055,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinkField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Persistent Label
        Padding(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width * 0.025,
            bottom: MediaQuery.of(context).size.height * 0.012,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.042,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              height: 1.4,
            ),
          ),
        ),
        // Input Field
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.midnightGreen.withValues(alpha: 0.5),
                AppColors.midnightGreen.withValues(alpha: 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.pineGreen.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.042, // Minimum 16px equivalent
              fontWeight: FontWeight.w500,
              height: 1.4, // Better line spacing
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), // Better contrast
                fontSize: MediaQuery.of(context).size.width * 0.038, // Larger hint text
                fontWeight: FontWeight.w400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.pineGreen,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.rosyBrown,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.rosyBrown,
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.pineGreen,
                size: MediaQuery.of(context).size.width * 0.05,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.045,
                vertical: MediaQuery.of(context).size.height * 0.02,
              ),
              errorStyle: TextStyle(
                color: AppColors.rosyBrown,
                fontSize: MediaQuery.of(context).size.width * 0.032,
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (label == 'Website') {
                  if (!RegExp(r'^https?://').hasMatch(value.trim())) {
                    return 'Website must start with http:// or https://';
                  }
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
