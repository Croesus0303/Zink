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

  GlassyButton({
    super.key,
    required this.child,
    double? borderRadius,
    this.shape = BoxShape.rectangle,
    this.onPressed,
    this.padding,
    this.constraints,
  }) : borderRadius = borderRadius ?? 15;

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
                width: shape == BoxShape.circle
                    ? MediaQuery.of(context).size.width * 0.005
                    : MediaQuery.of(context).size.width * 0.00375,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: MediaQuery.of(context).size.width * 0.01,
                  offset: Offset(
                    -MediaQuery.of(context).size.width * 0.005,
                    -MediaQuery.of(context).size.width * 0.005,
                  ),
                ),
                BoxShadow(
                  color: AppColors.midnightGreen.withValues(alpha: 0.3),
                  blurRadius: MediaQuery.of(context).size.width * 0.02,
                  offset: Offset(
                    MediaQuery.of(context).size.width * 0.005,
                    MediaQuery.of(context).size.width * 0.005,
                  ),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: MediaQuery.of(context).size.width * 0.015,
                  offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
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

  GlassyIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size,
    this.tooltip,
    double? iconSize,
    double? buttonSize,
    this.shape = BoxShape.rectangle,
  })  : iconSize = iconSize ?? 20,
        buttonSize = buttonSize ?? 48;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? buttonSize;
    final button = GlassyButton(
      shape: shape,
      borderRadius: MediaQuery.of(context).size.width * 0.0375,
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
      Radius.circular(configuration.size!.width * 0.04),
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
      width: shape == BoxShape.circle ? borderRadius * 0.13 : borderRadius * 0.1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.2),
        blurRadius: borderRadius * 0.27,
        offset: Offset(-borderRadius * 0.13, -borderRadius * 0.13),
      ),
      BoxShadow(
        color: AppColors.rosyBrown.withValues(alpha: 0.3),
        blurRadius: borderRadius * 0.53,
        offset: Offset(borderRadius * 0.13, borderRadius * 0.13),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: borderRadius * 0.4,
        offset: Offset(0, borderRadius * 0.13),
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
      width: borderRadius * 0.067,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.1),
        blurRadius: borderRadius * 0.2,
        offset: Offset(-borderRadius * 0.067, -borderRadius * 0.067),
      ),
      BoxShadow(
        color: AppColors.pineGreen.withValues(alpha: 0.2),
        blurRadius: borderRadius * 0.4,
        offset: Offset(borderRadius * 0.067, borderRadius * 0.067),
      ),
    ],
  );
}
