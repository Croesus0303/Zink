import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/social_service.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../core/utils/logger.dart';
import '../screens/likes_list_screen.dart';
import '../../../../shared/widgets/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class LikeButton extends ConsumerStatefulWidget {
  final String eventId;
  final String submissionId;
  final int initialLikeCount;
  final bool initialIsLiked;
  final VoidCallback? onLikeChanged;

  const LikeButton({
    super.key,
    required this.eventId,
    required this.submissionId,
    required this.initialLikeCount,
    this.initialIsLiked = false,
    this.onLikeChanged,
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.025,
        vertical: MediaQuery.of(context).size.height * 0.008,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF247c6d).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF247c6d).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Like/Unlike button
          InkWell(
            onTap: _isLoading ? null : _toggleLike,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: _isLoading
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width * 0.04,
                      height: MediaQuery.of(context).size.width * 0.04,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      size: MediaQuery.of(context).size.width * 0.04,
                      color: _isLiked ? const Color(0xFFbf988a) : Colors.white,
                    ),
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.01),
          // Clickable like count
          InkWell(
            onTap: _likeCount > 0 ? _showLikesList : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                _likeCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: MediaQuery.of(context).size.width * 0.032,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
