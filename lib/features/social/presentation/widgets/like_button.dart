import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/social_service.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../core/utils/logger.dart';
import '../screens/likes_list_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like photos')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to ${_isLiked ? 'unlike' : 'like'} photo')),
      );
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
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: _isLiked ? Colors.red : Colors.grey[600],
                  ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
        // Clickable like count
        InkWell(
          onTap: _likeCount > 0 ? _showLikesList : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              _likeCount.toString(),
              style: TextStyle(
                color: _likeCount > 0 ? Colors.blue[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
                decoration: _likeCount > 0 ? TextDecoration.underline : null,
                decorationColor: Colors.blue[400],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
