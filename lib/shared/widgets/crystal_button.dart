import 'package:flutter/material.dart';
import 'app_colors.dart';

class CrystalButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isOrange;
  final IconData? icon;
  final bool isOutlined;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const CrystalButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isOrange = false,
    this.icon,
    this.isOutlined = false,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = isOrange
        ? (isOutlined ? AppColors.orangeWithOpacity : AppColors.primaryOrange)
        : (isOutlined ? AppColors.cyanWithOpacity : AppColors.primaryCyan);
    
    Color borderColor = isOrange ? AppColors.primaryOrange : AppColors.primaryCyan;
    Color textColor = isOutlined ? borderColor : Colors.white;

    Widget buttonChild = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          )
        : Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          );

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Center(child: buttonChild),
          ),
        ),
      ),
    );
  }
}