import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/category_constants.dart';
import '../../../../core/utils/logger.dart';

/// Provider for category filter state
final categoryFilterProvider =
    StateNotifierProvider<CategoryFilterNotifier, Set<String>>((ref) {
  return CategoryFilterNotifier();
});

/// Notifier for managing category filter state with persistence
class CategoryFilterNotifier extends StateNotifier<Set<String>> {
  CategoryFilterNotifier() : super({}) {
    _loadFromPrefs();
  }

  static const String _prefsKey = 'selected_categories';

  /// Temporary state for pending changes (before Apply button is pressed)
  Set<String> _pendingState = {};

  /// Get pending state for UI display
  Set<String> getPendingState() => _pendingState;

  /// Initialize pending state when opening bottom sheet
  void initPendingState() {
    _pendingState = Set<String>.from(state);
    AppLogger.d('Initialized pending state: ${_pendingState.isEmpty ? "All" : _pendingState.join(", ")}');
  }

  /// Toggle a category in pending state (doesn't apply immediately)
  void toggleCategoryPending(String category) {
    if (!CategoryConstants.isValid(category)) {
      AppLogger.e('Invalid category: $category');
      return;
    }

    if (_pendingState.contains(category)) {
      _pendingState.remove(category);
    } else {
      _pendingState.add(category);
    }

    // Force rebuild without changing actual state
    state = Set<String>.from(state);
    AppLogger.d('Pending filter updated: ${_pendingState.isEmpty ? "All" : _pendingState.join(", ")}');
  }

  /// Clear pending state
  void clearPending() {
    _pendingState = {};
    // Force rebuild
    state = Set<String>.from(state);
    AppLogger.d('Cleared pending filters');
  }

  /// Apply pending changes to actual state
  void applyPendingChanges() {
    state = Set<String>.from(_pendingState);
    _saveToPrefs();
    AppLogger.d('Applied category filters: ${state.isEmpty ? "All" : state.join(", ")}');
  }

  /// Clear all category selections (show all) - used for direct clear
  void clearAll() {
    state = {};
    _pendingState = {};
    _saveToPrefs();
    AppLogger.d('Category filter cleared - showing all');
  }

  /// Check if a category is selected (in actual state)
  bool isSelected(String category) {
    return state.contains(category);
  }

  /// Check if a category is selected in pending state
  bool isPendingSelected(String category) {
    return _pendingState.contains(category);
  }

  /// Get the list of selected categories (for query)
  List<String>? getSelectedCategories() {
    return state.isEmpty ? null : state.toList();
  }

  /// Load saved selection from SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefsKey);

      if (savedJson != null) {
        final List<dynamic> savedList = jsonDecode(savedJson);
        final validCategories = savedList
            .whereType<String>()
            .where((cat) => CategoryConstants.isValid(cat))
            .toSet();

        if (validCategories.isNotEmpty) {
          state = validCategories;
          AppLogger.d(
              'Loaded category filter from prefs: ${validCategories.join(", ")}');
        }
      }
    } catch (e) {
      AppLogger.e('Failed to load category filter from prefs: $e');
    }
  }

  /// Save current selection to SharedPreferences
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toList());
      await prefs.setString(_prefsKey, jsonString);
      AppLogger.d('Saved category filter to prefs');
    } catch (e) {
      AppLogger.e('Failed to save category filter to prefs: $e');
    }
  }
}
