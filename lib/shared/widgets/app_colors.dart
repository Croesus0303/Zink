import 'package:flutter/material.dart';

class AppColors {
  // Primary colors from logo
  static const Color primaryCyan = Color(0xFF4FC3F7);
  static const Color primaryCyanDark = Color(0xFF29B6F6);
  static const Color primaryOrange = Color(0xFFFF8A65);
  static const Color primaryOrangeDark = Color(0xFFFF5722);
  static const Color warmBeige = Color(0xFFE1BEA1);
  
  // Modern glassmorphism background - optimized for glass effects
  static const Color backgroundPrimary = Color(0xFF0F1419);
  static const Color backgroundSecondary = Color(0xFF1E2328);
  static const Color backgroundTertiary = Color(0xFF2D3239);
  static const Color backgroundQuaternary = Color(0xFF242A30);
  
  // Glass card colors
  static const Color glassLight = Color(0x20FFFFFF);
  static const Color glassMedium = Color(0x15FFFFFF);
  static const Color glassDark = Color(0x10FFFFFF);
  
  // Legacy colors (for backward compatibility - will be removed later)
  static const Color backgroundDark = Color(0xFF1A2B33);
  static const Color backgroundMedium = Color(0xFF2A1F1A);
  static const Color backgroundLight = Color(0xFF1F1F1F);
  static const Color cardDark = Color(0xFF2A3942);
  static const Color cardLight = Color(0xFF1F2A33);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8C5D1);
  static const Color textTertiary = Color(0xFF8A95A3);
  
  // Status colors
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  
  // Clean glassmorphism background - smooth and elegant
  static LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      backgroundPrimary,
      backgroundSecondary,
      backgroundTertiary,
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Subtle color overlay for warmth
  static RadialGradient get radialBackgroundGradient => RadialGradient(
    center: Alignment.topCenter,
    radius: 1.8,
    colors: [
      primaryCyan.withOpacity(0.06),
      Colors.transparent,
      primaryOrange.withOpacity(0.04),
      Colors.transparent,
    ],
    stops: [0.0, 0.4, 0.7, 1.0],
  );
  
  // Legacy gradients (for backward compatibility - will be removed later)
  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardDark, cardLight],
  );
  
  // Glass container gradient
  static LinearGradient get glassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      glassLight,
      glassMedium,
    ],
  );
  
  // Primary cyan glass effect
  static LinearGradient get cyanGlassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryCyan.withOpacity(0.2),
      primaryCyan.withOpacity(0.1),
    ],
  );
  
  // Primary orange glass effect
  static LinearGradient get orangeGlassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryOrange.withOpacity(0.2),
      primaryOrange.withOpacity(0.1),
    ],
  );
  
  // Utility colors
  static Color get cyanWithOpacity => primaryCyan.withOpacity(0.15);
  static Color get orangeWithOpacity => primaryOrange.withOpacity(0.15);
  static Color get beigeWithOpacity => warmBeige.withOpacity(0.15);
  
  // Border colors for glass effect
  static Color get glassBorder => Colors.white.withOpacity(0.2);
  static Color get cyanBorder => primaryCyan.withOpacity(0.3);
  static Color get orangeBorder => primaryOrange.withOpacity(0.3);
}