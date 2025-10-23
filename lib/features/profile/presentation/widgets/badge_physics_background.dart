import 'dart:async';
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
    with TickerProviderStateMixin {
  final List<BadgeParticle> _particles = [];
  final Random _random = Random();
  Timer? _animationTimer;
  Size? _containerSize;
  int _nextBadgeIndex = 0;
  static const int maxBadges = 15;
  static const double badgeSize = 60.0;
  static const double minSpeed = 60.0;
  static const double maxSpeed = 90.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeParticles();
      _startAnimation();
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _initializeParticles() {
    if (widget.badgeUrls.isEmpty || _containerSize == null) return;

    final count = min(widget.badgeUrls.length, maxBadges);
    for (int i = 0; i < count; i++) {
      _addParticleAtRandomPosition(widget.badgeUrls[i]);
      _nextBadgeIndex++;
    }
  }

  void _addParticleAtRandomPosition(String badgeUrl) {
    if (_containerSize == null) return;

    final particle = BadgeParticle(
      badgeUrl: badgeUrl,
      x: _random.nextDouble() * (_containerSize!.width - badgeSize),
      y: _random.nextDouble() *
          (_containerSize!.height -
              badgeSize), // Random position anywhere on screen
      velocityX: (minSpeed + _random.nextDouble() * (maxSpeed - minSpeed)) *
          (_random.nextBool() ? 1 : -1),
      velocityY: minSpeed +
          _random.nextDouble() * (maxSpeed - minSpeed), // Random downward speed
    );

    setState(() {
      _particles.add(particle);
    });
  }

  void _addParticleFromTop(String badgeUrl) {
    if (_containerSize == null) return;

    final particle = BadgeParticle(
      badgeUrl: badgeUrl,
      x: _random.nextDouble() * (_containerSize!.width - badgeSize),
      y: -badgeSize, // Start from top (above screen)
      velocityX: (minSpeed + _random.nextDouble() * (maxSpeed - minSpeed)) *
          (_random.nextBool() ? 1 : -1),
      velocityY: minSpeed +
          _random.nextDouble() *
              (maxSpeed - minSpeed), // Always positive (downward)
    );

    setState(() {
      _particles.add(particle);
    });
  }

  void _startAnimation() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_containerSize == null) return;
      _updateParticles();
    });
  }

  void _updateParticles() {
    if (_containerSize == null) return;

    setState(() {
      const deltaTime = 0.016; // 16ms in seconds
      final particlesToRemove = <BadgeParticle>[];

      // Update positions
      for (var particle in _particles) {
        particle.x += particle.velocityX * deltaTime;
        particle.y += particle.velocityY * deltaTime;

        // Bounce off left and right walls only
        if (particle.x <= 0 ||
            particle.x + badgeSize >= _containerSize!.width) {
          particle.velocityX *= -1;
          particle.x = particle.x <= 0 ? 0 : _containerSize!.width - badgeSize;
        }

        // Wrap around top and bottom edges
        if (particle.y > _containerSize!.height) {
          // Badge moved off the bottom - check if we need to replace or wrap
          if (widget.badgeUrls.length <= maxBadges) {
            // Wrap to top - same badge continues
            particle.y = -badgeSize;
          } else {
            // Mark for replacement with next badge
            particlesToRemove.add(particle);
          }
        } else if (particle.y < -badgeSize) {
          // Badge moved off the top - wrap to bottom
          particle.y = _containerSize!.height;
        }
      }

      // Handle particles that need replacement (only when >15 badges)
      for (var particle in particlesToRemove) {
        _particles.remove(particle);

        // Replace with next badge from the list
        if (_nextBadgeIndex < widget.badgeUrls.length) {
          _addParticleFromTop(widget.badgeUrls[_nextBadgeIndex]);
          _nextBadgeIndex++;
        } else {
          // We've gone through all badges, restart from beginning
          _nextBadgeIndex = 0;
          _addParticleFromTop(widget.badgeUrls[_nextBadgeIndex]);
          _nextBadgeIndex++;
        }
      }

      // Check for collisions between particles
      for (int i = 0; i < _particles.length; i++) {
        for (int j = i + 1; j < _particles.length; j++) {
          final p1 = _particles[i];
          final p2 = _particles[j];

          final dx = (p2.x + badgeSize / 2) - (p1.x + badgeSize / 2);
          final dy = (p2.y + badgeSize / 2) - (p1.y + badgeSize / 2);
          final distance = sqrt(dx * dx + dy * dy);

          if (distance < badgeSize) {
            // Elastic collision
            final angle = atan2(dy, dx);
            final sinAngle = sin(angle);
            final cosAngle = cos(angle);

            // Rotate velocity vectors
            final v1x = p1.velocityX * cosAngle + p1.velocityY * sinAngle;
            final v1y = p1.velocityY * cosAngle - p1.velocityX * sinAngle;
            final v2x = p2.velocityX * cosAngle + p2.velocityY * sinAngle;
            final v2y = p2.velocityY * cosAngle - p2.velocityX * sinAngle;

            // Swap velocity components along collision axis
            final temp = v1x;
            final newV1x = v2x;
            final newV2x = temp;

            // Rotate back
            p1.velocityX = newV1x * cosAngle - v1y * sinAngle;
            p1.velocityY = v1y * cosAngle + newV1x * sinAngle;
            p2.velocityX = newV2x * cosAngle - v2y * sinAngle;
            p2.velocityY = v2y * cosAngle + newV2x * sinAngle;

            // Separate particles
            final overlap = badgeSize - distance;
            final separationX = overlap * cosAngle / 2;
            final separationY = overlap * sinAngle / 2;
            p1.x -= separationX;
            p1.y -= separationY;
            p2.x += separationX;
            p2.y += separationY;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_containerSize == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _containerSize =
                  Size(constraints.maxWidth, constraints.maxHeight);
            });
            _initializeParticles();
          });
        }

        return Stack(
          children: [
            // Animated badges in the background
            ..._particles.map((particle) {
              return Positioned(
                left: particle.x,
                top: particle.y,
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
                      imageUrl: particle.badgeUrl,
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
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            // Content on top
            widget.child,
          ],
        );
      },
    );
  }
}

class BadgeParticle {
  String badgeUrl;
  double x;
  double y;
  double velocityX;
  double velocityY;

  BadgeParticle({
    required this.badgeUrl,
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
  });
}
