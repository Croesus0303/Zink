import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../events/providers/events_providers.dart';
import '../../../events/data/models/event_model.dart';
import '../../../submissions/data/services/submissions_service.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/separator_line.dart';

class PhotoSubmissionScreen extends ConsumerStatefulWidget {
  final String eventId;

  const PhotoSubmissionScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<PhotoSubmissionScreen> createState() =>
      _PhotoSubmissionScreenState();
}

class _PhotoSubmissionScreenState extends ConsumerState<PhotoSubmissionScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickImageFromCamera() async {
    try {
      AppLogger.d('Opening camera...');

      // Let image_picker handle permission requests natively
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        AppLogger.d('Photo captured successfully');
      } else {
        AppLogger.d('No photo was taken');
      }
    } on PlatformException catch (e) {
      AppLogger.e('Platform exception while picking image from camera', e);

      // Handle camera access denied - this means user denied permission
      if (e.code == 'camera_access_denied') {
        AppLogger.d('Camera access denied by user');
        if (mounted) {
          _showErrorSnackBar(
              AppLocalizations.of(context)!.cameraPermissionDenied);
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(
              AppLocalizations.of(context)!.failedToTakePhoto(e.message ?? e.code));
        }
      }
    } catch (e) {
      AppLogger.e('Error picking image from camera', e);
      if (mounted) {
        _showErrorSnackBar(
            AppLocalizations.of(context)!.failedToTakePhoto(e.toString()));
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      AppLogger.d('Opening gallery with requestFullMetadata to trigger permission...');

      // Use requestFullMetadata: false to use the iOS Photo Picker (no permission needed)
      // OR use requestFullMetadata: true to request full photo library access
      // Let's try opening gallery directly - image_picker should handle permissions
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
        requestFullMetadata: true, // This forces permission request on iOS
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        AppLogger.d('Photo selected successfully');
      } else {
        AppLogger.d('No photo was selected');
      }
    } on PlatformException catch (e) {
      AppLogger.e('Platform exception while picking image from gallery', e);

      // Handle photo library access denied
      if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        AppLogger.d('Photo library access denied by user, showing settings dialog');
        if (mounted) {
          _showPermissionSettingsDialog(isCamera: false);
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(
              AppLocalizations.of(context)!.failedToSelectPhoto(e.message ?? e.code));
        }
      }
    } catch (e) {
      AppLogger.e('Error picking image from gallery', e);
      if (mounted) {
        _showErrorSnackBar(
            AppLocalizations.of(context)!.failedToSelectPhoto(e.toString()));
      }
    }
  }

  void _showPermissionSettingsDialog({required bool isCamera}) {
    final String permissionType = isCamera ? 'Camera' : 'Photo Library';
    final String permissionMessage = isCamera
        ? 'Camera access is needed to take photos. Please grant permission in your device settings.'
        : 'Photo library access is needed to select photos. Please grant permission in your device settings.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.midnightGreen.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.06),
          side: BorderSide(
            color: AppColors.iceBorder,
            width: MediaQuery.of(context).size.width * 0.00375,
          ),
        ),
        title: Text(
          '$permissionType Permission Required',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width * 0.045,
          ),
        ),
        content: Text(
          permissionMessage,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: MediaQuery.of(context).size.width * 0.038,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: MediaQuery.of(context).size.width * 0.038,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.pineGreen.withValues(alpha: 0.8),
                  AppColors.pineGreen.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                onTap: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: MediaQuery.of(context).size.height * 0.015,
                  ),
                  child: Text(
                    'Open Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.width * 0.038,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPhoto() async {
    if (_selectedImage == null) {
      _showErrorSnackBar(AppLocalizations.of(context)!.pleaseSelectPhotoFirst);
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showErrorSnackBar(AppLocalizations.of(context)!.userNotAuthenticated);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final submissionsService = ref.read(submissionsServiceProvider);

      AppLogger.d('Starting photo submission for event ${widget.eventId}');

      final submission = await submissionsService.createSubmission(
        eventId: widget.eventId,
        userId: currentUser.uid,
        imageFile: _selectedImage!,
      );

      AppLogger.i('Photo submitted successfully: ${submission.id}');

      if (mounted) {
        // Refresh the submission count provider for this specific event
        ref.invalidate(userSubmissionCountForEventProvider(
            (userId: currentUser.uid, eventId: widget.eventId)));
        // Refresh the submissions list for the event
        ref.invalidate(submissionsProvider(widget.eventId));

        if (mounted) {
          _showSuccessSnackBar(
            AppLocalizations.of(context)!.submissionSuccessful,
          );

          // Navigate back to event detail
          Navigator.of(context).pop();
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to submit photo', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar(
            AppLocalizations.of(context)!.failedToSubmitPhoto(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    CustomSnackBar.showError(context, message);
  }

  void _showSuccessSnackBar(String message) {
    CustomSnackBar.showSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return eventsAsync.when(
      data: (events) {
        try {
          final event = events.firstWhere(
            (e) => e.id == widget.eventId,
            orElse: () => throw Exception('Event not found'),
          );
          return _buildSubmissionScreen(context, event);
        } catch (e) {
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
                AppLocalizations.of(context)!.submitPhoto,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: MediaQuery.of(context).size.width * 0.2,
                    color: AppColors.rosyBrown,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text(
                    AppLocalizations.of(context)!.eventNotFound,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      loading: () => Scaffold(
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
            AppLocalizations.of(context)!.submitPhoto,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.rosyBrown,
            strokeWidth: MediaQuery.of(context).size.width * 0.01,
          ),
        ),
      ),
      error: (error, stack) {
        AppLogger.e('Error loading event for submission', error, stack);
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
              AppLocalizations.of(context)!.submitPhoto,
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: MediaQuery.of(context).size.width * 0.2,
                  color: AppColors.rosyBrown,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  AppLocalizations.of(context)!.errorLoadingEvent,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(eventsProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context)!.retry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pineGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.06,
                      vertical: MediaQuery.of(context).size.height * 0.015,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmissionScreen(BuildContext context, EventModel event) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
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
            AppLocalizations.of(context)!.submitPhoto,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.pleaseSignInToSubmit,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.04,
            ),
          ),
        ),
      );
    }

    final submissionCountAsync = ref.watch(userSubmissionCountForEventProvider(
        (userId: currentUser.uid, eventId: event.id)));

    return submissionCountAsync.when(
      data: (submissionCount) =>
          _buildSubmissionScreenContent(context, event, submissionCount),
      loading: () => _buildLoadingScreen(context),
      error: (error, stack) => _buildErrorScreen(context, error),
    );
  }

  Widget _buildSubmissionScreenContent(
      BuildContext context, EventModel event, int submissionCount) {
    const maxSubmissions = 3;
    final hasReachedLimit = submissionCount >= maxSubmissions;

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
          AppLocalizations.of(context)!.submitPhoto,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  // Challenge info with submission count
                  _ChallengeInfoSection(
                    event: event,
                    submissionCount: submissionCount,
                    maxSubmissions: maxSubmissions,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                  const SeparatorLine(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                  // Photo selection/preview or limit message
                  if (hasReachedLimit)
                    _SubmissionLimitMessage()
                  else
                    _PhotoSection(
                      selectedImage: _selectedImage,
                      onTakePhoto: _pickImageFromCamera,
                      onChooseFromGallery: _pickImageFromGallery,
                      onRemovePhoto: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  if (!hasReachedLimit) ...[
                    SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                    const SeparatorLine(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                  ],
                  // Guidelines
                  if (!hasReachedLimit) _GuidelinesSection(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ],
              ),
            ),
          ),
      bottomNavigationBar: _selectedImage != null && !hasReachedLimit
          ? SafeArea(
              child: Padding(
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isSubmitting
                          ? [
                              AppColors.midnightGreen.withValues(alpha: 0.6),
                              AppColors.midnightGreen.withValues(alpha: 0.4),
                            ]
                          : [
                              AppColors.rosyBrown,
                              AppColors.rosyBrown.withValues(alpha: 0.8),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: MediaQuery.of(context).size.width * 0.0025,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.rosyBrown.withValues(alpha: 0.4),
                        blurRadius: MediaQuery.of(context).size.width * 0.03,
                        offset: Offset(0, MediaQuery.of(context).size.height * 0.0075),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                      ),
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.05,
                                height:
                                    MediaQuery.of(context).size.width * 0.05,
                                child: CircularProgressIndicator(
                                  strokeWidth: MediaQuery.of(context).size.width * 0.005,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.03),
                              Text(
                                AppLocalizations.of(context)!.submitting,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            AppLocalizations.of(context)!.submitPhoto,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
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
          AppLocalizations.of(context)!.submitPhoto,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.rosyBrown,
          strokeWidth: MediaQuery.of(context).size.width * 0.01,
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, dynamic error) {
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
          AppLocalizations.of(context)!.submitPhoto,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: MediaQuery.of(context).size.width * 0.2,
              color: AppColors.rosyBrown,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              AppLocalizations.of(context)!.errorLoadingSubmissionData,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: Text(AppLocalizations.of(context)!.goBack),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pineGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.06,
                  vertical: MediaQuery.of(context).size.height * 0.015,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SubmissionLimitMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.rosyBrown.withValues(alpha: 0.1),
            AppColors.rosyBrown.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
        border: Border.all(
            color: AppColors.rosyBrown.withValues(alpha: 0.3),
            width: MediaQuery.of(context).size.width * 0.00375),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: MediaQuery.of(context).size.width * 0.0375,
            offset: Offset(-MediaQuery.of(context).size.width * 0.005,
                -MediaQuery.of(context).size.width * 0.005),
          ),
          BoxShadow(
            color: AppColors.rosyBrown.withValues(alpha: 0.15),
            blurRadius: MediaQuery.of(context).size.width * 0.0375,
            offset: Offset(MediaQuery.of(context).size.width * 0.005,
                MediaQuery.of(context).size.width * 0.005),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.16,
            height: MediaQuery.of(context).size.width * 0.16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.rosyBrown.withValues(alpha: 0.8),
                  AppColors.rosyBrown.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
              boxShadow: [
                BoxShadow(
                  color: AppColors.rosyBrown.withValues(alpha: 0.3),
                  blurRadius: MediaQuery.of(context).size.width * 0.03,
                  offset: Offset(0, MediaQuery.of(context).size.height * 0.005),
                ),
              ],
            ),
            child: Icon(
              Icons.block,
              size: MediaQuery.of(context).size.width * 0.08,
              color: Colors.white,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Text(
            AppLocalizations.of(context)!.submissionLimitReached,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              shadows: [
                Shadow(
                  color: AppColors.rosyBrown.withValues(alpha: 0.6),
                  blurRadius: MediaQuery.of(context).size.width * 0.02,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          Text(
            AppLocalizations.of(context)!.usedAllSubmissions,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.035,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ChallengeInfoSection extends StatelessWidget {
  final EventModel event;
  final int submissionCount;
  final int maxSubmissions;

  const _ChallengeInfoSection({
    required this.event,
    required this.submissionCount,
    required this.maxSubmissions,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.25,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.05),
        child: Stack(
          children: [
            // Full background image
            Positioned.fill(
              child: event.referenceImageURL.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: event.referenceImageURL,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.rosyBrown.withValues(alpha: 0.4),
                              AppColors.pineGreen.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.08,
                            height: MediaQuery.of(context).size.width * 0.08,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: MediaQuery.of(context).size.width * 0.0075,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.rosyBrown.withValues(alpha: 0.4),
                              AppColors.pineGreen.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          color: Colors.white,
                          size: MediaQuery.of(context).size.width * 0.08,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.rosyBrown.withValues(alpha: 0.4),
                            AppColors.pineGreen.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width * 0.08,
                      ),
                    ),
            ),
            // Dark overlay for text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
            // Badge overlay at top-right
            if (event.badgeURL != null && event.badgeURL!.isNotEmpty)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.015,
                right: MediaQuery.of(context).size.width * 0.03,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.1,
                  height: MediaQuery.of(context).size.width * 0.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: MediaQuery.of(context).size.width * 0.02,
                        offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: event.badgeURL!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryOrange.withValues(alpha: 0.6),
                              AppColors.rosyBrown.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04,
                            height: MediaQuery.of(context).size.width * 0.04,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: MediaQuery.of(context).size.width * 0.005,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryOrange.withValues(alpha: 0.8),
                              AppColors.rosyBrown.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Status tag and content at bottom
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.015,
              left: MediaQuery.of(context).size.width * 0.03,
              right: MediaQuery.of(context).size.width * 0.03,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active/Ended tag (rosyBrown color as specified)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.025,
                        vertical: MediaQuery.of(context).size.height * 0.00625),
                    decoration: BoxDecoration(
                      color: AppColors.rosyBrown.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.02),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: MediaQuery.of(context).size.width * 0.01,
                          offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: MediaQuery.of(context).size.width * 0.03,
                          color: Colors.white,
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                        Text(
                          _formatTimeRemaining(event.endTime),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width * 0.03,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                  // Title
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.description.isNotEmpty) ...[
                    SizedBox(height: MediaQuery.of(context).size.height * 0.004),
                    // Description
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.032,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: MediaQuery.of(context).size.height * 0.004),
                  // Submission count
                  Text(
                    '$submissionCount of $maxSubmissions attempts used',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
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

  String _formatTimeRemaining(DateTime endTime) {
    final duration = endTime.difference(DateTime.now());
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      if (hours > 0) {
        return '${days}d ${hours}h left';
      } else {
        return '${days}d left';
      }
    } else if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else if (minutes > 0) {
      return '${minutes}m left';
    } else {
      return 'Ending soon';
    }
  }
}

class _PhotoSection extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseFromGallery;
  final VoidCallback onRemovePhoto;

  const _PhotoSection({
    required this.selectedImage,
    required this.onTakePhoto,
    required this.onChooseFromGallery,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedImage != null) ...[
          // Photo preview
          Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(
                      selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.width * 0.03,
                  right: MediaQuery.of(context).size.width * 0.03,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.rosyBrown,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: onRemovePhoto,
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.02),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.pineGreen.withValues(alpha: 0.15),
                        AppColors.pineGreen.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                    border: Border.all(
                      color: AppColors.pineGreen.withValues(alpha: 0.3),
                      width: MediaQuery.of(context).size.width * 0.0025,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                      onTap: onTakePhoto,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical:
                                MediaQuery.of(context).size.height * 0.015),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: AppColors.pineGreen,
                              size: MediaQuery.of(context).size.width * 0.045,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Text(
                              AppLocalizations.of(context)!.takePhoto,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.035,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.rosyBrown.withValues(alpha: 0.15),
                        AppColors.rosyBrown.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                    border: Border.all(
                      color: AppColors.rosyBrown.withValues(alpha: 0.3),
                      width: MediaQuery.of(context).size.width * 0.0025,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                      onTap: onChooseFromGallery,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical:
                                MediaQuery.of(context).size.height * 0.015),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library,
                              color: AppColors.rosyBrown,
                              size: MediaQuery.of(context).size.width * 0.045,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Text(
                              AppLocalizations.of(context)!.chooseFromGallery,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.035,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Photo selection placeholder
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: BoxDecoration(
              color: AppColors.midnightGreenLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: MediaQuery.of(context).size.width * 0.15,
                  color: AppColors.pineGreen,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  AppLocalizations.of(context)!.addYourPhoto,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.pineGreen.withValues(alpha: 0.8),
                        AppColors.pineGreen.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: MediaQuery.of(context).size.width * 0.0025,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                      onTap: onTakePhoto,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical:
                                MediaQuery.of(context).size.height * 0.015),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width * 0.045,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Text(
                              AppLocalizations.of(context)!.takePhoto,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.035,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.rosyBrown.withValues(alpha: 0.15),
                        AppColors.rosyBrown.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                    border: Border.all(
                      color: AppColors.rosyBrown.withValues(alpha: 0.3),
                      width: MediaQuery.of(context).size.width * 0.0025,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                      onTap: onChooseFromGallery,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical:
                                MediaQuery.of(context).size.height * 0.015),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library,
                              color: AppColors.rosyBrown,
                              size: MediaQuery.of(context).size.width * 0.045,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Text(
                              AppLocalizations.of(context)!.chooseFromGallery,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.035,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _GuidelinesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.submissionGuidelines,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            shadows: [
              Shadow(
                color: AppColors.rosyBrown.withValues(alpha: 0.6),
                blurRadius: MediaQuery.of(context).size.width * 0.02,
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.015),
        Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
          decoration: BoxDecoration(
            gradient: AppColors.iceGlassGradient,
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
            border: Border.all(
              color: AppColors.iceBorder,
              width: MediaQuery.of(context).size.width * 0.00375,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: MediaQuery.of(context).size.width * 0.0375,
                offset: Offset(-MediaQuery.of(context).size.width * 0.005,
                    -MediaQuery.of(context).size.width * 0.005),
              ),
              BoxShadow(
                color: AppColors.rosyBrown.withValues(alpha: 0.15),
                blurRadius: MediaQuery.of(context).size.width * 0.0375,
                offset: Offset(MediaQuery.of(context).size.width * 0.005,
                    MediaQuery.of(context).size.width * 0.005),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuidelineItem(
                icon: Icons.check_circle,
                text: AppLocalizations.of(context)!.matchChallengeTheme,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              _GuidelineItem(
                icon: Icons.check_circle,
                text: AppLocalizations.of(context)!.useGoodLighting,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              const _GuidelineItem(
                icon: Icons.check_circle,
                text: 'Keep content appropriate for all audiences',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuidelineItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GuidelineItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.06,
          height: MediaQuery.of(context).size.width * 0.06,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.pineGreen.withValues(alpha: 0.8),
                AppColors.pineGreen.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: MediaQuery.of(context).size.width * 0.0025,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.pineGreen.withValues(alpha: 0.3),
                blurRadius: MediaQuery.of(context).size.width * 0.01,
                offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: MediaQuery.of(context).size.width * 0.035,
            color: Colors.white,
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.03),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.035,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
