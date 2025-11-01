import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/services/social_service.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../core/utils/logger.dart';
import '../screens/likes_list_screen.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class LikeButton extends ConsumerStatefulWidget {
  final String eventId;
  final String submissionId;
  final int initialLikeCount;
  final bool initialIsLiked;
  final VoidCallback? onLikeChanged;
  final void Function(Future<void> Function())? onLikeController;

  const LikeButton({
    super.key,
    required this.eventId,
    required this.submissionId,
    required this.initialLikeCount,
    this.initialIsLiked = false,
    this.onLikeChanged,
    this.onLikeController,
  });

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton> {
  late bool _isLiked;
  late int _likeCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likeCount = widget.initialLikeCount;

    // Expose the toggleLike method to parent widget
    widget.onLikeController?.call(_toggleLike);
  }

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIsLiked != widget.initialIsLiked) {
      _isLiked = widget.initialIsLiked;
    }
    if (oldWidget.initialLikeCount != widget.initialLikeCount) {
      _likeCount = widget.initialLikeCount;
    }
  }

  Future<void> _toggleLike() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      CustomSnackBar.showError(context, 'Please sign in to like photos');
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final socialService = ref.read(socialServiceProvider);

      if (_isLiked) {
        await socialService.unlikeSubmission(
            widget.eventId, widget.submissionId, currentUser.uid);
        setState(() {
          _isLiked = false;
        });
        AppLogger.d('Unliked submission ${widget.submissionId}');
      } else {
        await socialService.likeSubmission(
            widget.eventId, widget.submissionId, currentUser.uid);
        setState(() {
          _isLiked = true;
        });
        AppLogger.d('Liked submission ${widget.submissionId}');
      }

      widget.onLikeChanged?.call();
    } catch (e) {
      AppLogger.e(
          'Error toggling like for submission ${widget.submissionId}', e);
      if (!mounted) return;
      CustomSnackBar.showError(context, 'Failed to ${_isLiked ? 'unlike' : 'like'} photo');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLikesList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LikesListScreen(
          eventId: widget.eventId,
          submissionId: widget.submissionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like/Unlike button
        InkWell(
          onTap: _isLoading ? null : _toggleLike,
          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01),
            child: _isLoading
                ? SizedBox(
                    width: MediaQuery.of(context).size.width * 0.055,
                    height: MediaQuery.of(context).size.width * 0.055,
                    child: CircularProgressIndicator(
                      strokeWidth: MediaQuery.of(context).size.width * 0.005,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: MediaQuery.of(context).size.width * 0.06,
                    color: _isLiked ? const Color(0xFFbf988a) : Colors.white,
                  ),
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.01),
        // Clickable like count
        InkWell(
          onTap: _likeCount > 0 ? _showLikesList : null,
          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.02),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.005,
              vertical: MediaQuery.of(context).size.width * 0.005,
            ),
            child: Text(
              _likeCount.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).size.width * 0.04,
                decoration: TextDecoration.none,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: MediaQuery.of(context).size.width * 0.01,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
