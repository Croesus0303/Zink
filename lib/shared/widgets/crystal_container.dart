import 'package:flutter/material.dart';
import 'app_colors.dart';

class CrystalContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final bool showShadow;
  final bool useCyanAccent;
  final bool useOrangeAccent;
  final Color? backgroundColor;

  const CrystalContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.borderColor,
    this.showShadow = true,
    this.useCyanAccent = false,
    this.useOrangeAccent = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Color effectiveBorderColor = borderColor ??
        (useCyanAccent
            ? AppColors.primaryCyan
            : useOrangeAccent
                ? AppColors.primaryOrange
                : AppColors.primaryCyan);

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: backgroundColor != null
            ? null
            : AppColors.cardGradient,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.5,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primaryCyan.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}