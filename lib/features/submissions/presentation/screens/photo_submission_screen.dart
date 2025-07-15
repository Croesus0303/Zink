import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../events/providers/events_providers.dart';
import '../../../events/data/models/event_model.dart';
import '../../../submissions/data/services/submissions_service.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_colors.dart';

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
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select photo: $e');
    }
  }

  Future<void> _submitPhoto() async {
    if (_selectedImage == null) {
      _showErrorSnackBar('Please select a photo first');
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showErrorSnackBar('User not authenticated');
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
        ref.invalidate(userSubmissionCountForEventProvider((userId: currentUser.uid, eventId: widget.eventId)));
        
        _showSuccessSnackBar(
          AppLocalizations.of(context)!.submissionSuccessful,
        );

        // Navigate back to event detail
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to submit photo', e, stackTrace);
      _showErrorSnackBar('Failed to submit photo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: AppColors.midnightGreen.withOpacity(0.9),
              elevation: 0,
              title: Text(
                'Event Not Found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration:
                    BoxDecoration(gradient: AppColors.auroraRadialGradient),
                child: Center(
                  child: Container(
                    margin: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.08),
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.06),
                    decoration: BoxDecoration(
                      gradient: AppColors.iceGlassGradient,
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: AppColors.iceBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(-2, -2),
                        ),
                        BoxShadow(
                          color: AppColors.rosyBrown.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: MediaQuery.of(context).size.width * 0.16,
                          color: AppColors.rosyBrown,
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02),
                        Text(
                          'Event not found',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.045,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
            child: const Center(
                child: CircularProgressIndicator(color: AppColors.pineGreen)),
          ),
        ),
      ),
      error: (error, stack) {
        AppLogger.e('Error loading event for submission', error, stack);
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: AppColors.midnightGreen.withOpacity(0.9),
            elevation: 0,
            title: Text(
              'Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration:
                  BoxDecoration(gradient: AppColors.auroraRadialGradient),
              child: Center(
                child: Container(
                  margin:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
                  decoration: BoxDecoration(
                    gradient: AppColors.iceGlassGradient,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.iceBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(-2, -2),
                      ),
                      BoxShadow(
                        color: AppColors.rosyBrown.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: MediaQuery.of(context).size.width * 0.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.rosyBrown.withOpacity(0.8),
                              AppColors.rosyBrown.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.rosyBrown.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.error,
                          size: MediaQuery.of(context).size.width * 0.1,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025),
                      Text(
                        'Error loading event',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          shadows: [
                            Shadow(
                              color: AppColors.rosyBrown.withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.pineGreen.withOpacity(0.8),
                              AppColors.pineGreen.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pineGreen.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => ref.refresh(eventsProvider),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.06,
                                vertical:
                                    MediaQuery.of(context).size.height * 0.015,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.02),
                                  Text(
                                    'Retry',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.04,
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
                  ),
                ),
              ),
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
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: AppColors.midnightGreen.withOpacity(0.9),
          elevation: 0,
          title: Text(
            'Authentication Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
            child: Center(
              child: Text(
                'Please sign in to submit photos',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final submissionCountAsync = ref.watch(userSubmissionCountForEventProvider((userId: currentUser.uid, eventId: event.id)));

    return submissionCountAsync.when(
      data: (submissionCount) => _buildSubmissionScreenContent(context, event, submissionCount),
      loading: () => _buildLoadingScreen(context),
      error: (error, stack) => _buildErrorScreen(context, error),
    );
  }

  Widget _buildSubmissionScreenContent(BuildContext context, EventModel event, int submissionCount) {
    const maxSubmissions = 3;
    final hasReachedLimit = submissionCount >= maxSubmissions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen.withOpacity(0.9),
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.065,
        title: Text(
          AppLocalizations.of(context)!.submitPhoto,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: AppColors.rosyBrown.withOpacity(0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.03,
              top: 3,
              bottom: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                AppColors.pineGreen.withOpacity(0.08),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.iceBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(-1, -1),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
          if (_selectedImage != null && !hasReachedLimit)
            Container(
              margin: EdgeInsets.only(
                  right: MediaQuery.of(context).size.width * 0.03,
                  top: 3,
                  bottom: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isSubmitting
                      ? [
                          AppColors.midnightGreen.withOpacity(0.6),
                          AppColors.midnightGreen.withOpacity(0.4),
                        ]
                      : [
                          AppColors.rosyBrown.withOpacity(0.8),
                          AppColors.rosyBrown.withOpacity(0.9),
                        ],
                ),
                borderRadius: BorderRadius.circular(15),
                border:
                    Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.rosyBrown.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: _isSubmitting ? null : _submitPhoto,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.04,
                        vertical: MediaQuery.of(context).size.height * 0.01),
                    child: _isSubmitting
                        ? SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04,
                            height: MediaQuery.of(context).size.width * 0.04,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.submit,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.035,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Challenge info
                      _ChallengeInfoSection(event: event),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025),
                      // Submission count info
                      _SubmissionCountInfo(
                        submissionCount: submissionCount,
                        maxSubmissions: maxSubmissions,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025),
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
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025),
                      // Guidelines
                      if (!hasReachedLimit) _GuidelinesSection(),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _selectedImage != null && !hasReachedLimit
          ? Container(
              margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isSubmitting
                        ? [
                            AppColors.midnightGreen.withOpacity(0.6),
                            AppColors.midnightGreen.withOpacity(0.4),
                          ]
                        : [
                            AppColors.rosyBrown.withOpacity(0.8),
                            AppColors.rosyBrown.withOpacity(0.9),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rosyBrown.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isSubmitting ? null : _submitPhoto,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.02),
                      child: _isSubmitting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.05,
                                  height:
                                      MediaQuery.of(context).size.width * 0.05,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.03),
                                Text(
                                  'Submitting...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04,
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
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen.withOpacity(0.9),
        elevation: 0,
        title: Text(
          'Loading...',
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.pineGreen),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, dynamic error) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.midnightGreen.withOpacity(0.9),
        elevation: 0,
        title: Text(
          'Error',
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.auroraRadialGradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading submission data',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmissionCountInfo extends StatelessWidget {
  final int submissionCount;
  final int maxSubmissions;

  const _SubmissionCountInfo({
    required this.submissionCount,
    required this.maxSubmissions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            AppColors.pineGreen.withOpacity(0.08),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: AppColors.pineGreen.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.12,
            height: MediaQuery.of(context).size.width * 0.12,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.pineGreen.withOpacity(0.8),
                  AppColors.pineGreen.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pineGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.photo_library,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.06,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submissions',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$submissionCount of $maxSubmissions used',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            AppColors.rosyBrown.withOpacity(0.1),
            AppColors.rosyBrown.withOpacity(0.05),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rosyBrown.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: AppColors.rosyBrown.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(2, 2),
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
                  AppColors.rosyBrown.withOpacity(0.8),
                  AppColors.rosyBrown.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.rosyBrown.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
            'Submission Limit Reached',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              shadows: [
                Shadow(
                  color: AppColors.rosyBrown.withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          Text(
            'You have used all your submissions for this event.',
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

  const _ChallengeInfoSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Challenge',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            shadows: [
              Shadow(
                color: AppColors.rosyBrown.withOpacity(0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.015),
        Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          decoration: BoxDecoration(
            gradient: AppColors.iceGlassGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.iceBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(-2, -2),
              ),
              BoxShadow(
                color: AppColors.rosyBrown.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.pineGreen.withOpacity(0.3),
                      AppColors.rosyBrown.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.iceBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pineGreen.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: event.referenceImageURL,
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.width * 0.15,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: MediaQuery.of(context).size.width * 0.15,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.midnightGreen.withOpacity(0.3),
                            AppColors.midnightGreen.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.image,
                        color: AppColors.textSecondary,
                        size: MediaQuery.of(context).size.width * 0.06,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: MediaQuery.of(context).size.width * 0.15,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.rosyBrown.withOpacity(0.3),
                            AppColors.rosyBrown.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.error,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width * 0.06,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.04),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: AppColors.textPrimary,
                          shadows: [
                            Shadow(
                              color: AppColors.rosyBrown.withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.008),
                      Text(
                        event.description,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.isActive) ...<Widget>[
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.01),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.025,
                            vertical:
                                MediaQuery.of(context).size.height * 0.008,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.pineGreen.withOpacity(0.8),
                                AppColors.pineGreen.withOpacity(0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.pineGreen.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: MediaQuery.of(context).size.width * 0.035,
                                color: Colors.white,
                              ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.015),
                              Text(
                                _formatTimeRemaining(event.endTime),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimeRemaining(DateTime endTime) {
    final duration = endTime.difference(DateTime.now());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
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
        Text(
          'Your Photo',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            shadows: [
              Shadow(
                color: AppColors.rosyBrown.withOpacity(0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.015),
        if (selectedImage != null) ...[
          // Photo preview
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.iceGlassGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.iceBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(-2, -2),
                ),
                BoxShadow(
                  color: AppColors.rosyBrown.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.rosyBrown.withOpacity(0.9),
                          AppColors.rosyBrown.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.rosyBrown.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: onRemovePhoto,
                        child: Container(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width * 0.02),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: MediaQuery.of(context).size.width * 0.05,
                          ),
                        ),
                      ),
                    ),
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
                        AppColors.pineGreen.withOpacity(0.15),
                        AppColors.pineGreen.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.pineGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
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
                        AppColors.rosyBrown.withOpacity(0.15),
                        AppColors.rosyBrown.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.rosyBrown.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
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
              gradient: AppColors.iceGlassGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.iceBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(-2, -2),
                ),
                BoxShadow(
                  color: AppColors.rosyBrown.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.15,
                  height: MediaQuery.of(context).size.width * 0.15,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.pineGreen.withOpacity(0.8),
                        AppColors.rosyBrown.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pineGreen.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_photo_alternate,
                    size: MediaQuery.of(context).size.width * 0.08,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  'Add your photo',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    shadows: [
                      Shadow(
                        color: AppColors.rosyBrown.withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ],
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
                        AppColors.pineGreen.withOpacity(0.8),
                        AppColors.pineGreen.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pineGreen.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
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
                        AppColors.rosyBrown.withOpacity(0.15),
                        AppColors.rosyBrown.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.rosyBrown.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
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
          'Submission Guidelines',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            shadows: [
              Shadow(
                color: AppColors.rosyBrown.withOpacity(0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.015),
        Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
          decoration: BoxDecoration(
            gradient: AppColors.iceGlassGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.iceBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(-2, -2),
              ),
              BoxShadow(
                color: AppColors.rosyBrown.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuidelineItem(
                icon: Icons.check_circle,
                text: 'Make sure your photo matches the challenge theme',
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              _GuidelineItem(
                icon: Icons.check_circle,
                text: 'Use good lighting and clear focus',
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              _GuidelineItem(
                icon: Icons.check_circle,
                text:
                    'Original photos only - no screenshots or downloaded images',
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              _GuidelineItem(
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
                AppColors.pineGreen.withOpacity(0.8),
                AppColors.pineGreen.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.pineGreen.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
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
