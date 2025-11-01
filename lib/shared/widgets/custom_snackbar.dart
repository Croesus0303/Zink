import 'package:flutter/material.dart';
import 'app_colors.dart';

enum SnackBarType { success, error, info }

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _GlassmorphismSnackBarContent(
          message: message,
          type: type,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.error);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.info);
  }
}

class _GlassmorphismSnackBarContent extends StatelessWidget {
  final String message;
  final SnackBarType type;

  const _GlassmorphismSnackBarContent({
    required this.message,
    required this.type,
  });

  Color get _primaryColor {
    switch (type) {
      case SnackBarType.success:
        return AppColors.pineGreen;
      case SnackBarType.error:
        return AppColors.rosyBrown;
      case SnackBarType.info:
        return AppColors.primaryCyan;
    }
  }

  IconData get _icon {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle_outline;
      case SnackBarType.error:
        return Icons.error_outline;
      case SnackBarType.info:
        return Icons.info_outline;
    }
  }

  LinearGradient get _glassmorphismGradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.25),
        _primaryColor.withValues(alpha: 0.20),
        _primaryColor.withValues(alpha: 0.15),
        Colors.white.withValues(alpha: 0.12),
      ],
      stops: const [0.0, 0.25, 0.75, 1.0],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: MediaQuery.of(context).size.height * 0.015,
      ),
      decoration: BoxDecoration(
        gradient: _glassmorphismGradient,
        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.4),
          width: MediaQuery.of(context).size.width * 0.003,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.15),
            blurRadius: MediaQuery.of(context).size.width * 0.03,
            offset: Offset(
              -MediaQuery.of(context).size.width * 0.0025,
              -MediaQuery.of(context).size.width * 0.0025,
            ),
          ),
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.25),
            blurRadius: MediaQuery.of(context).size.width * 0.03,
            offset: Offset(
              MediaQuery.of(context).size.width * 0.0025,
              MediaQuery.of(context).size.width * 0.0025,
            ),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: MediaQuery.of(context).size.width * 0.02,
            offset: Offset(0, MediaQuery.of(context).size.height * 0.00375),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.08,
            height: MediaQuery.of(context).size.width * 0.08,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withValues(alpha: 0.8),
                  _primaryColor.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.02),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: MediaQuery.of(context).size.width * 0.0025,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.3),
                  blurRadius: MediaQuery.of(context).size.width * 0.015,
                  offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
                ),
              ],
            ),
            child: Icon(
              _icon,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.04,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.036,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: _primaryColor.withValues(alpha: 0.6),
                    blurRadius: MediaQuery.of(context).size.width * 0.01,
                  ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}