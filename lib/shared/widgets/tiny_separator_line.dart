import 'package:flutter/material.dart';
import 'app_colors.dart';

class TinySeparatorLine extends StatelessWidget {
  final double? horizontalMargin;

  const TinySeparatorLine({
    super.key,
    this.horizontalMargin,
  });

  @override
  Widget build(BuildContext context) {
    final margin = horizontalMargin ?? MediaQuery.of(context).size.width * 0.1;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.auroraBorder.withAlpha(150),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
