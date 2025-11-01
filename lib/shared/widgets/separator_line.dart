import 'package:flutter/material.dart';

/// A modern, solid white separator line widget
///
/// This widget creates a thin horizontal line with white color and customizable opacity.
/// Commonly used to separate sections in the UI.
class SeparatorLine extends StatelessWidget {
  /// The opacity of the white line (default: 0.3)
  final double opacity;

  /// The horizontal margins on left and right (default: 6% of screen width)
  final double? horizontalMargin;

  /// The height of the line (default: 0.25% of screen width)
  final double? height;

  const SeparatorLine({
    super.key,
    this.opacity = 0.3,
    this.horizontalMargin,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHorizontalMargin = horizontalMargin ?? MediaQuery.of(context).size.width * 0.06;
    final effectiveHeight = height ?? MediaQuery.of(context).size.width * 0.0025;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: effectiveHorizontalMargin),
      height: effectiveHeight,
      color: Colors.white.withValues(alpha: opacity),
    );
  }
}
