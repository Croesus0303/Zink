import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/category_constants.dart';
import 'app_colors.dart';
import '../../features/home/presentation/providers/category_filter_provider.dart';

/// Bottom sheet for selecting category filters
class CategoryFilterBottomSheet extends ConsumerWidget {
  const CategoryFilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to rebuild when pending state changes
    ref.watch(categoryFilterProvider);
    final filterNotifier = ref.read(categoryFilterProvider.notifier);
    final pendingCategories = filterNotifier.getPendingState();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.midnightGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter by Category',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (pendingCategories.isNotEmpty)
                      TextButton(
                        onPressed: () => filterNotifier.clearPending(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryOrange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (pendingCategories.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${pendingCategories.length} ${pendingCategories.length == 1 ? 'category' : 'categories'} selected',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Category chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CategoryConstants.allCategories.map((category) {
                final isSelected = pendingCategories.contains(category);
                return _CategoryChip(
                  category: category,
                  isSelected: isSelected,
                  onTap: () => filterNotifier.toggleCategoryPending(category),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Apply button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  filterNotifier.applyPendingChanges();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rosyBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  pendingCategories.isEmpty
                      ? 'Show All'
                      : 'Apply ${pendingCategories.length} ${pendingCategories.length == 1 ? 'Filter' : 'Filters'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show the bottom sheet
  static Future<void> show(BuildContext context, WidgetRef ref) {
    // Initialize pending state before showing
    ref.read(categoryFilterProvider.notifier).initPendingState();

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CategoryFilterBottomSheet(),
    );
  }
}

/// Individual category chip widget
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.rosyBrown
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.midnightGreenLight
                  : AppColors.midnightGreenLight,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CategoryConstants.getIcon(category),
                size: 18,
                color: Colors.white.withValues(
                  alpha: isSelected ? 1.0 : 0.7,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CategoryConstants.getDisplayName(category),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.white.withValues(
                    alpha: isSelected ? 1.0 : 0.8,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
