import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app_colors.dart';
import 'crystal_container.dart';

class CrystalListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final bool useCyanAccent;
  final bool useOrangeAccent;

  const CrystalListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.leading,
    this.trailing,
    this.onTap,
    this.margin,
    this.useCyanAccent = true,
    this.useOrangeAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget = leading;
    
    if (leadingWidget == null && imageUrl != null) {
      leadingWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryCyan.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.3),
                    AppColors.primaryCyan.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.image_outlined,
                color: AppColors.primaryCyan,
                size: 28,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.3),
                    AppColors.primaryOrange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.primaryOrange,
                size: 28,
              ),
            ),
          ),
        ),
      );
    }

    Widget? trailingWidget = trailing;
    if (trailingWidget == null && onTap != null) {
      trailingWidget = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: useCyanAccent ? AppColors.cyanWithOpacity : AppColors.orangeWithOpacity,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: useCyanAccent ? AppColors.primaryCyan : AppColors.primaryOrange,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.chevron_right,
          color: useCyanAccent ? AppColors.primaryCyan : AppColors.primaryOrange,
          size: 20,
        ),
      );
    }

    Widget subtitleWidget = const SizedBox.shrink();
    if (subtitle != null) {
      subtitleWidget = Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: useOrangeAccent ? AppColors.orangeWithOpacity : AppColors.cyanWithOpacity,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: useOrangeAccent ? AppColors.primaryOrange : AppColors.primaryCyan,
            width: 1,
          ),
        ),
        child: Text(
          subtitle!,
          style: TextStyle(
            color: useOrangeAccent ? AppColors.primaryOrange : AppColors.primaryCyan,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return CrystalContainer(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      useCyanAccent: useCyanAccent,
      useOrangeAccent: useOrangeAccent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: leadingWidget,
        title: Text(
          title,
          style: TextStyle(
            color: useCyanAccent ? AppColors.primaryCyan : AppColors.primaryOrange,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        subtitle: subtitleWidget,
        trailing: trailingWidget,
        onTap: onTap,
      ),
    );
  }
}