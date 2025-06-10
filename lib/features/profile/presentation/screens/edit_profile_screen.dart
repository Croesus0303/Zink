import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/logger.dart';

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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editProfile),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : (widget.user.photoURL != null
                            ? NetworkImage(widget.user.photoURL!)
                                as ImageProvider
                            : null),
                    child:
                        _selectedImage == null && widget.user.photoURL == null
                            ? Text(
                                widget.user.displayName
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(fontSize: 36),
                              )
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Icon(
                          Icons.camera_alt,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Social Links Section
            _buildSectionTitle(AppLocalizations.of(context)!.socialLinks),
            const SizedBox(height: 16),

            _buildSocialLinkField(
              controller: _instagramController,
              label: 'Instagram',
              hint: 'Enter your Instagram username',
              icon: Icons.camera_alt,
            ),
            const SizedBox(height: 16),

            _buildSocialLinkField(
              controller: _twitterController,
              label: 'Twitter',
              hint: 'Enter your Twitter handle',
              icon: Icons.alternate_email,
            ),
            const SizedBox(height: 16),

            _buildSocialLinkField(
              controller: _facebookController,
              label: 'Facebook',
              hint: 'Enter your Facebook profile name',
              icon: Icons.facebook,
            ),
            const SizedBox(height: 16),

            _buildSocialLinkField(
              controller: _linkedinController,
              label: 'LinkedIn',
              hint: 'Enter your LinkedIn profile name',
              icon: Icons.business,
            ),
            const SizedBox(height: 16),

            _buildSocialLinkField(
              controller: _websiteController,
              label: 'Website',
              hint: 'Enter your website URL',
              icon: Icons.link,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSocialLinkField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
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
    );
  }
}
