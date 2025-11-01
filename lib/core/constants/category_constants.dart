import 'package:flutter/material.dart';

/// Category constants for events and submissions
class CategoryConstants {
  CategoryConstants._();

  // Category string constants
  static const String fashionStyle = 'fashion_style';
  static const String travelAdventure = 'travel_adventure';
  static const String foodGastronomy = 'food_gastronomy';
  static const String natureLandscape = 'nature_landscape';
  static const String beautySelfcare = 'beauty_selfcare';
  static const String fitnessHealthSports = 'fitness_health_sports';
  static const String pets = 'pets';
  static const String homeDecorDiyHobbies = 'home_decor_diy_hobbies';
  static const String technologyGadgets = 'technology_gadgets';
  static const String otherAbsurd = 'other_absurd';

  /// List of all valid categories
  static const List<String> allCategories = [
    fashionStyle,
    travelAdventure,
    foodGastronomy,
    natureLandscape,
    beautySelfcare,
    fitnessHealthSports,
    pets,
    homeDecorDiyHobbies,
    technologyGadgets,
    otherAbsurd,
  ];

  /// Get display name for a category
  static String getDisplayName(String category) {
    switch (category) {
      case fashionStyle:
        return 'Fashion & Style';
      case travelAdventure:
        return 'Travel & Adventure';
      case foodGastronomy:
        return 'Food & Gastronomy';
      case natureLandscape:
        return 'Nature & Landscape';
      case beautySelfcare:
        return 'Beauty & Selfcare';
      case fitnessHealthSports:
        return 'Fitness & Sports';
      case pets:
        return 'Pets';
      case homeDecorDiyHobbies:
        return 'Home & DIY';
      case technologyGadgets:
        return 'Tech & Gadgets';
      case otherAbsurd:
        return 'Other & Absurd';
      default:
        return category;
    }
  }

  /// Get icon for a category
  static IconData getIcon(String category) {
    switch (category) {
      case fashionStyle:
        return Icons.checkroom_rounded;
      case travelAdventure:
        return Icons.flight_takeoff_rounded;
      case foodGastronomy:
        return Icons.restaurant_rounded;
      case natureLandscape:
        return Icons.landscape_rounded;
      case beautySelfcare:
        return Icons.face_rounded;
      case fitnessHealthSports:
        return Icons.fitness_center_rounded;
      case pets:
        return Icons.pets_rounded;
      case homeDecorDiyHobbies:
        return Icons.home_rounded;
      case technologyGadgets:
        return Icons.devices_rounded;
      case otherAbsurd:
        return Icons.auto_awesome_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  /// Validate if a category is valid
  static bool isValid(String? category) {
    if (category == null) return false;
    return allCategories.contains(category);
  }

  /// Get emoji for a category (alternative to icons)
  static String getEmoji(String category) {
    switch (category) {
      case fashionStyle:
        return '👗';
      case travelAdventure:
        return '✈️';
      case foodGastronomy:
        return '🍽️';
      case natureLandscape:
        return '🏞️';
      case beautySelfcare:
        return '💄';
      case fitnessHealthSports:
        return '💪';
      case pets:
        return '🐾';
      case homeDecorDiyHobbies:
        return '🏡';
      case technologyGadgets:
        return '📱';
      case otherAbsurd:
        return '✨';
      default:
        return '📁';
    }
  }
}
