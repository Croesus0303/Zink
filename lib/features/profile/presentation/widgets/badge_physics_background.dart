import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/widgets/app_colors.dart';

class BadgePhysicsBackground extends StatefulWidget {
  final List<String> badgeUrls;
  final Widget child;

  const BadgePhysicsBackground({
    super.key,
    required this.badgeUrls,
    required this.child,
  });

  @override
  State<BadgePhysicsBackground> createState() => _BadgePhysicsBackgroundState();
}

class _BadgePhysicsBackgroundState extends State<BadgePhysicsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _scrollOffset = 0;
  static const double badgeSize = 50.0;
  static const double badgeSpacing = 20.0;
  static const double rowHeight = badgeSize + badgeSpacing;
  static const int maxStaticBadges = 12;
  static const int visibleBadgesPerColumn = 5;
  static const double scrollSpeed = 30.0; // pixels per second

  @override
  void initState() {
    super.initState();

    // Only animate if there are more than 12 badges
    if (widget.badgeUrls.length > maxStaticBadges) {
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1000),
      )..addListener(() {
          setState(() {
            _scrollOffset += scrollSpeed / 60; // Update at 60fps
            final totalHeight = (widget.badgeUrls.length / 2).ceil() * rowHeight;
            if (_scrollOffset >= totalHeight) {
              _scrollOffset -= totalHeight;
            }
          });
        });
      _animationController.repeat();
    } else {
      // Create a dummy controller that doesn't animate
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final levelBadgeWidth = constraints.maxWidth * 0.45;
        final leftColumnX = (constraints.maxWidth - levelBadgeWidth) / 4 - badgeSize / 2;
        final rightColumnX = constraints.maxWidth - leftColumnX - badgeSize;

        // Split badges into left and right columns
        final leftBadges = <String>[];
        final rightBadges = <String>[];
        for (int i = 0; i < widget.badgeUrls.length; i++) {
          if (i.isEven) {
            leftBadges.add(widget.badgeUrls[i]);
          } else {
            rightBadges.add(widget.badgeUrls[i]);
          }
        }

        return Stack(
          children: [
            // Left column
            if (leftBadges.isNotEmpty)
              _buildVerticalColumn(
                leftBadges,
                leftColumnX,
                constraints.maxHeight,
              ),
            // Right column
            if (rightBadges.isNotEmpty)
              _buildVerticalColumn(
                rightBadges,
                rightColumnX,
                constraints.maxHeight,
              ),
            // Content on top (level badge in center)
            widget.child,
          ],
        );
      },
    );
  }

  Widget _buildVerticalColumn(List<String> badges, double xPosition, double containerHeight) {
    if (widget.badgeUrls.length <= maxStaticBadges) {
      // Static display - show badges evenly spaced
      return Stack(
        children: List.generate(badges.length, (index) {
          final spacing = containerHeight / (badges.length + 1);
          final yPosition = spacing * (index + 1) - badgeSize / 2;

          return _buildBadgeAt(
            badges[index],
            xPosition,
            yPosition,
            1.0, // Full opacity
          );
        }),
      );
    } else {
      // Animated scrolling display
      const visibleBadgeCount = visibleBadgesPerColumn * 2; // Double for seamless loop
      return Stack(
        children: List.generate(visibleBadgeCount, (index) {
          final badgeIndex = index % badges.length;
          final yPosition = (index * rowHeight) - _scrollOffset;
          final opacity = _calculateVerticalOpacity(yPosition, containerHeight);

          if (opacity <= 0.01) return const SizedBox.shrink();

          return _buildBadgeAt(
            badges[badgeIndex],
            xPosition,
            yPosition,
            opacity,
          );
        }),
      );
    }
  }

  Widget _buildBadgeAt(
    String badgeUrl,
    double xPosition,
    double yPosition,
    double opacity,
  ) {
    return Positioned(
      left: xPosition,
      top: yPosition,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryOrange.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: badgeUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryOrange.withValues(alpha: 0.3),
                      AppColors.rosyBrown.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryOrange.withValues(alpha: 0.5),
                      AppColors.rosyBrown.withValues(alpha: 0.5),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.primaryOrange,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateVerticalOpacity(double yPosition, double containerHeight) {
    // Fade out badges at top and bottom edges
    const fadeDistance = 80.0;

    if (yPosition < 0) {
      // Top edge
      return max(0.0, 1 + (yPosition / fadeDistance));
    } else if (yPosition > containerHeight - badgeSize) {
      // Bottom edge
      return max(0.0, 1 - ((yPosition - (containerHeight - badgeSize)) / fadeDistance));
    }

    return 1.0;
  }
}
