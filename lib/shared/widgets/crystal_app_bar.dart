import 'package:flutter/material.dart';
import 'app_colors.dart';

class CrystalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool showLogo;

  const CrystalAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget? leading;
    if (showBackButton && Navigator.of(context).canPop()) {
      leading = Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.cyanWithOpacity,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryCyan, width: 1),
        ),
        child: IconButton(
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryCyan),
        ),
      );
    }

    Widget? titleContent;
    if (showLogo) {
      titleContent = Image.asset(
        'assets/app_logo.png',
        height: 120,
        fit: BoxFit.contain,
      );
    } else if (titleWidget != null) {
      titleContent = titleWidget;
    } else if (title != null) {
      titleContent = Text(
        title!,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return AppBar(
      backgroundColor: const Color(0x90000000),
      elevation: 0,
      leading: leading,
      automaticallyImplyLeading: false,
      title: titleContent,
      centerTitle: true,
      actions: actions,
      surfaceTintColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}