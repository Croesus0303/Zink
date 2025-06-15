import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'crystal_app_bar.dart';

class CrystalScaffold extends StatelessWidget {
  final Widget body;
  final String? appBarTitle;
  final Widget? appBarTitleWidget;
  final List<Widget>? appBarActions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool showLogo;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;

  const CrystalScaffold({
    super.key,
    required this.body,
    this.appBarTitle,
    this.appBarTitleWidget,
    this.appBarActions,
    this.showBackButton = true,
    this.onBackPressed,
    this.showLogo = false,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          appBar: CrystalAppBar(
            title: appBarTitle,
            titleWidget: appBarTitleWidget,
            actions: appBarActions,
            showBackButton: showBackButton,
            onBackPressed: onBackPressed,
            showLogo: showLogo,
          ),
          body: body,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
        ),
      ),
    );
  }
}