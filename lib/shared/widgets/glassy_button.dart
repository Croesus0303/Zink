import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A reusable button container with rosy brown gradient and glassy shine effect
class GlassyButton extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final BoxShape shape;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  const GlassyButton({
    super.key,
    required this.child,
    this.borderRadius = 15,
    this.shape = BoxShape.rectangle,
    this.onPressed,
    this.padding,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: constraints ?? const BoxConstraints(),
      child: Stack(
        children: [
          Container(
            constraints: constraints,
            padding: padding,
            decoration: BoxDecoration(
              shape: shape,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.midnightGreen.withValues(alpha: 0.9),
                  AppColors.midnightGreen.withValues(alpha: 0.85),
                  AppColors.midnightGreen.withValues(alpha: 0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: shape == BoxShape.circle ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(-2, -2),
                ),
                BoxShadow(
                  color: AppColors.midnightGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
          // Glassy shine overlay - ignore pointer to allow clicks through
          Positioned.fill(
            child: IgnorePointer(
              child: shape == BoxShape.circle
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.0,
                          colors: [
                            Colors.white.withValues(alpha: 0.5),
                            Colors.white.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.3, 1.0],
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(borderRadius),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topLeft,
                            radius: 1.2,
                            colors: [
                              Colors.white.withValues(alpha: 0.4),
                              Colors.white.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 1.0],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );

    if (onPressed != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: content,
      );
    }

    return content;
  }
}

/// A glassy icon button with rosy brown gradient
class GlassyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double? size;
  final String? tooltip;
  final double iconSize;
  final double buttonSize;
  final BoxShape shape;

  const GlassyIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size,
    this.tooltip,
    this.iconSize = 20,
    this.buttonSize = 48,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? buttonSize;
    final button = GlassyButton(
      shape: shape,
      borderRadius: 15,
      onPressed: onPressed,
      constraints: BoxConstraints.tightFor(
        width: effectiveSize,
        height: effectiveSize,
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Custom tab indicator with glassy shine effect
class GlassyTabIndicator extends Decoration {
  final BoxDecoration baseDecoration;

  const GlassyTabIndicator({required this.baseDecoration});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _GlassyTabIndicatorPainter(baseDecoration, onChanged);
  }
}

class _GlassyTabIndicatorPainter extends BoxPainter {
  final BoxDecoration baseDecoration;

  _GlassyTabIndicatorPainter(this.baseDecoration, VoidCallback? onChanged)
      : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & configuration.size!;

    // Paint base decoration
    final paint = baseDecoration.createBoxPainter(() {});
    paint.paint(canvas, offset, configuration);

    // Paint glassy shine overlay
    final shinePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.2,
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(rect);

    final shineRect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(16),
    );

    canvas.drawRRect(shineRect, shinePaint);
  }
}

/// Helper method to create a standard rosy brown BoxDecoration
BoxDecoration createRosyBrownDecoration({
  double borderRadius = 15,
  BoxShape shape = BoxShape.rectangle,
}) {
  return BoxDecoration(
    shape: shape,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.rosyBrown.withValues(alpha: 0.7),
        AppColors.rosyBrown.withValues(alpha: 0.5),
        AppColors.rosyBrown.withValues(alpha: 0.6),
      ],
      stops: const [0.0, 0.5, 1.0],
    ),
    borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.3),
      width: shape == BoxShape.circle ? 2 : 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.2),
        blurRadius: 4,
        offset: const Offset(-2, -2),
      ),
      BoxShadow(
        color: AppColors.rosyBrown.withValues(alpha: 0.3),
        blurRadius: 8,
        offset: const Offset(2, 2),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

/// Helper method to create a pine green BoxDecoration with crystalline effect
BoxDecoration createPineGreenDecoration({
  double borderRadius = 15,
  BoxShape shape = BoxShape.rectangle,
}) {
  return BoxDecoration(
    shape: shape,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.pineGreen.withValues(alpha: 0.3),
        AppColors.pineGreen.withValues(alpha: 0.2),
        AppColors.pineGreen.withValues(alpha: 0.25),
      ],
      stops: const [0.0, 0.5, 1.0],
    ),
    borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
    border: Border.all(
      color: AppColors.pineGreen.withValues(alpha: 0.4),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.1),
        blurRadius: 3,
        offset: const Offset(-1, -1),
      ),
      BoxShadow(
        color: AppColors.pineGreen.withValues(alpha: 0.2),
        blurRadius: 6,
        offset: const Offset(1, 1),
      ),
    ],
  );
}
