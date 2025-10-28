import 'package:flutter/material.dart';

/// A modern, solid white separator line widget
///
/// This widget creates a thin horizontal line with white color and customizable opacity.
/// Commonly used to separate sections in the UI.
class SeparatorLine extends StatelessWidget {
  /// The opacity of the white line (default: 0.3)
  final double opacity;

  /// The horizontal margins on left and right (default: 24.0)
  final double horizontalMargin;

  /// The height of the line (default: 1.0)
  final double height;

  const SeparatorLine({
    super.key,
    this.opacity = 0.3,
    this.horizontalMargin = 24.0,
    this.height = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      height: height,
      color: Colors.white.withValues(alpha: opacity),
    );
  }
}
