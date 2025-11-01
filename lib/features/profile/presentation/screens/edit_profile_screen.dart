import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

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
  }

  @override
  void dispose() {
    _instagramController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
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
        CustomSnackBar.showError(
            context, 'Error selecting image: ${e.toString()}');
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
        CustomSnackBar.showError(
            context, 'Error taking photo: ${e.toString()}');
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MediaQuery.of(context).size.width * 0.05),
        ),
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

      AppLogger.i('Social links prepared: $socialLinks');
      AppLogger.i('Selected image: ${_selectedImage?.path ?? 'None'}');

      // Update profile with both social links and image
      await authRepository.updateUserProfile(
        socialLinks: socialLinks,
        profileImage: _selectedImage,
      );

      AppLogger.i('Profile update completed successfully');

      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Profile updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.e('Error updating profile', e);
      if (mounted) {
        CustomSnackBar.showError(
            context, 'Error updating profile: ${e.toString()}');
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
      backgroundColor: AppColors.midnightGreen,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: MediaQuery.of(context).size.width * 0.07,
          ),
          padding: EdgeInsets.zero,
        ),
        title: Text(
          AppLocalizations.of(context)!.editProfile,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(
              right: MediaQuery.of(context).size.width * 0.03,
              top: MediaQuery.of(context).size.height * 0.01,
              bottom: MediaQuery.of(context).size.height * 0.01,
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pineGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: MediaQuery.of(context).size.height * 0.01,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.03),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width * 0.05,
                      height: MediaQuery.of(context).size.width * 0.05,
                      child: CircularProgressIndicator(
                        strokeWidth: MediaQuery.of(context).size.width * 0.005,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)!.save,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width * 0.06,
          ),
          children: [
            // Profile Picture Section
            Center(
              child: Container(
                margin: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.rosyBrown,
                            AppColors.pineGreen,
                            AppColors.midnightGreen,
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: MediaQuery.of(context).size.width * 0.18,
                        backgroundColor: Colors.transparent,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider
                            : (widget.user.photoURL != null
                                ? CachedNetworkImageProvider(
                                    widget.user.photoURL!) as ImageProvider
                                : null),
                        child: _selectedImage == null &&
                                widget.user.photoURL == null
                            ? Text(
                                widget.user.username
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.1,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.025),
                        decoration: const BoxDecoration(
                          color: AppColors.pineGreen,
                          shape: BoxShape.circle,
                        ),
                        child: GestureDetector(
                          onTap: _showImagePickerOptions,
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: MediaQuery.of(context).size.width * 0.05,
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
              hint: 'username',
              imagePath: 'assets/icons/instagram_logo.png',
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),

            _buildSocialLinkField(
              controller: _twitterController,
              label: 'Twitter',
              hint: 'username',
              imagePath: 'assets/icons/x_logo.png',
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),

            _buildSocialLinkField(
              controller: _facebookController,
              label: 'Facebook',
              hint: 'username',
              imagePath: 'assets/icons/facebook_logo.png',
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.01,
        top: MediaQuery.of(context).size.height * 0.015,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.05,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSocialLinkField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    String? imagePath,
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
            color: AppColors.midnightGreen.withValues(alpha: 0.5),
            borderRadius:
                BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: MediaQuery.of(context).size.width * 0.0025,
            ),
          ),
          child: TextFormField(
            controller: controller,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width *
                  0.042, // Minimum 16px equivalent
              fontWeight: FontWeight.w500,
              height: 1.4, // Better line spacing
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), // Better contrast
                fontSize: MediaQuery.of(context).size.width *
                    0.038, // Larger hint text
                fontWeight: FontWeight.w400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width * 0.04),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width * 0.04),
                borderSide: BorderSide(
                  color: AppColors.rosyBrown,
                  width: MediaQuery.of(context).size.width * 0.005,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.rosyBrown,
                  width: 2,
                ),
              ),
              prefixIcon: imagePath != null
                  ? Padding(
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.035),
                      child: Image.asset(
                        imagePath,
                        width: MediaQuery.of(context).size.width * 0.045,
                        height: MediaQuery.of(context).size.width * 0.045,
                        color: Colors.white,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(
                      icon,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width * 0.045,
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
              return null;
            },
          ),
        ),
      ],
    );
  }
}
