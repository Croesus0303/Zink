import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryCyan = Color(0xFF4DD0E1);
  static const Color primaryCyanDark = Color(0xFF00BCD4);
  static const Color primaryOrange = Color(0xFFFF7043);
  static const Color primaryOrangeDark = Color(0xFFFF5722);
  
  static const Color backgroundDark = Color(0xFF1A2B33);
  static const Color backgroundMedium = Color(0xFF2A1F1A);
  static const Color backgroundLight = Color(0xFF1F1F1F);
  
  static const Color cardDark = Color(0xFF2A3942);
  static const Color cardLight = Color(0xFF1F2A33);
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF4CAF50);
  
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundDark, backgroundMedium, backgroundLight],
    stops: [0.0, 0.6, 1.0],
  );
  
  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardDark, cardLight],
  );
  
  static Color get cyanWithOpacity => primaryCyan.withOpacity(0.2);
  static Color get orangeWithOpacity => primaryOrange.withOpacity(0.2);
}