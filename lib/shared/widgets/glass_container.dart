import 'package:flutter/material.dart';
import 'dart:ui';
import 'app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool useCyanAccent;
  final bool useOrangeAccent;
  final bool useBeigeAccent;
  final double blur;
  final double opacity;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.useCyanAccent = false,
    this.useOrangeAccent = false,
    this.useBeigeAccent = false,
    this.blur = 3,
    this.opacity = 0.4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.glassBorder;
    LinearGradient gradient = AppColors.glassGradient;

    if (useCyanAccent) {
      borderColor = AppColors.primaryCyan.withValues(alpha: 0.6);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryCyan.withValues(alpha: 0.3),
          AppColors.primaryOrange.withValues(alpha: 0.2),
          AppColors.primaryCyan.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
    } else if (useOrangeAccent) {
      borderColor = AppColors.primaryOrange.withValues(alpha: 0.6);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryOrange.withValues(alpha: 0.3),
          AppColors.warmBeige.withValues(alpha: 0.2),
          AppColors.primaryOrangeDark.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
    } else if (useBeigeAccent) {
      borderColor = AppColors.warmBeige.withValues(alpha: 0.6);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.warmBeige.withValues(alpha: 0.3),
          AppColors.primaryCyan.withValues(alpha: 0.2),
          AppColors.primaryOrange.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
    }

    return Container(
      margin: margin,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool useCyanAccent;
  final bool useOrangeAccent;
  final bool isOutlined;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.useCyanAccent = true,
    this.useOrangeAccent = false,
    this.isOutlined = false,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    Color primaryColor = useCyanAccent ? AppColors.primaryCyan : AppColors.primaryOrange;
    Color borderColor = useCyanAccent ? AppColors.cyanBorder : AppColors.orangeBorder;
    
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: isOutlined 
                ? null 
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withValues(alpha: 0.8),
                      primaryColor.withValues(alpha: 0.6),
                    ],
                  ),
              border: Border.all(
                color: borderColor,
                width: isOutlined ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isOutlined ? primaryColor : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: isOutlined ? primaryColor : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}