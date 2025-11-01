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
      decoration: BoxDecoration(
        color: AppColors.midnightGreen,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MediaQuery.of(context).size.width * 0.07),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.015,
              bottom: MediaQuery.of(context).size.height * 0.01,
            ),
            width: MediaQuery.of(context).size.width * 0.1,
            height: MediaQuery.of(context).size.height * 0.005,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.005),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.06,
              vertical: MediaQuery.of(context).size.height * 0.015,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Category',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.055,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (pendingCategories.isNotEmpty)
                      TextButton(
                        onPressed: () => filterNotifier.clearPending(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryOrange,
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.03,
                            vertical: MediaQuery.of(context).size.height * 0.0075,
                          ),
                        ),
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (pendingCategories.isNotEmpty) ...[
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Text(
                    '${pendingCategories.length} ${pendingCategories.length == 1 ? 'category' : 'categories'} selected',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.0325,
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
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
            ),
            child: Wrap(
              spacing: MediaQuery.of(context).size.width * 0.02,
              runSpacing: MediaQuery.of(context).size.height * 0.01,
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

          SizedBox(height: MediaQuery.of(context).size.height * 0.03),

          // Apply button
          Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.06,
              0,
              MediaQuery.of(context).size.width * 0.06,
              MediaQuery.of(context).size.height * 0.04,
            ),
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
                  padding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.04,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  pendingCategories.isEmpty
                      ? 'Show All'
                      : 'Apply ${pendingCategories.length} ${pendingCategories.length == 1 ? 'Filter' : 'Filters'}',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
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
        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: MediaQuery.of(context).size.height * 0.0125,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.rosyBrown
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.05),
            border: Border.all(
              color: isSelected
                  ? AppColors.midnightGreenLight
                  : AppColors.midnightGreenLight,
              width: MediaQuery.of(context).size.width * 0.0025,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CategoryConstants.getIcon(category),
                size: MediaQuery.of(context).size.width * 0.045,
                color: Colors.white.withValues(
                  alpha: isSelected ? 1.0 : 0.7,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
              Text(
                CategoryConstants.getDisplayName(category),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.white.withValues(
                    alpha: isSelected ? 1.0 : 0.8,
                  ),
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: MediaQuery.of(context).size.width * 0.015),
                Icon(
                  Icons.check_circle,
                  size: MediaQuery.of(context).size.width * 0.04,
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
