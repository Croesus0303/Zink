import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/category_constants.dart';
import '../../features/home/presentation/providers/category_filter_provider.dart';
import 'app_colors.dart';
import 'category_filter_bottom_sheet.dart';

/// Horizontal scrollable category filter chips
class CategoryFilterChips extends ConsumerWidget {
  const CategoryFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategories = ref.watch(categoryFilterProvider);
    final hasFilters = selectedCategories.isNotEmpty;
    final filterChipsHeight = MediaQuery.of(context).size.height * 0.04;

    return Container(
      height: filterChipsHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.midnightGreen,
        border: Border(
          bottom: BorderSide(
            color: AppColors.midnightGreenLight,
            width: MediaQuery.of(context).size.width * 0.0025,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: filterChipsHeight * 0.15,
        ),
        children: [
          // Show selected category chips (max 3)
          if (hasFilters) ...[
            ...selectedCategories.take(3).map((category) {
              return Padding(
                padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.02),
                child: _SelectedCategoryChip(
                  category: category,
                  onTap: () => CategoryFilterBottomSheet.show(context, ref),
                ),
              );
            }),

            // Show "+X more" if more than 3 selected
            if (selectedCategories.length > 3)
              Padding(
                padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.02),
                child: _CountChip(
                  count: selectedCategories.length - 3,
                  onTap: () => CategoryFilterBottomSheet.show(context, ref),
                ),
              ),
          ],

          // Filter button (always show)
          _FilterActionChip(
            hasFilters: hasFilters,
            onTap: () => CategoryFilterBottomSheet.show(context, ref),
          ),
        ],
      ),
    );
  }
}

/// Individual selected category chip
class _SelectedCategoryChip extends StatelessWidget {
  const _SelectedCategoryChip({
    required this.category,
    required this.onTap,
  });

  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.03,
            vertical: MediaQuery.of(context).size.height * 0.0025,
          ),
          decoration: BoxDecoration(
            color: AppColors.rosyBrown,
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
            border: Border.all(
              color: AppColors.midnightGreenLight,
              width: MediaQuery.of(context).size.width * 0.0025,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CategoryConstants.getIcon(category),
                size: MediaQuery.of(context).size.width * 0.035,
                color: Colors.white,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.01),
              Text(
                CategoryConstants.getDisplayName(category),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.0275,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: MediaQuery.of(context).size.width * 0.0005,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Count chip showing "+X" when too many categories selected
class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.025,
            vertical: MediaQuery.of(context).size.height * 0.0025,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: MediaQuery.of(context).size.width * 0.0025,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                blurRadius: MediaQuery.of(context).size.width * 0.02,
                offset: Offset(0, MediaQuery.of(context).size.height * 0.0025),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: MediaQuery.of(context).size.width * 0.035,
                color: Colors.white,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.005),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.0275,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter action chip (always visible)
class _FilterActionChip extends StatelessWidget {
  const _FilterActionChip({
    required this.hasFilters,
    required this.onTap,
  });

  final bool hasFilters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.03,
            vertical: MediaQuery.of(context).size.height * 0.0025,
          ),
          decoration: BoxDecoration(
            color: AppColors.midnightGreenLight,
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
            border: Border.all(
              color: AppColors.midnightGreenLight,
              width: MediaQuery.of(context).size.width * 0.0025,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: MediaQuery.of(context).size.width * 0.035,
                color: hasFilters
                    ? AppColors.primaryOrange
                    : Colors.white.withValues(alpha: 0.9),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.01),
              Text(
                hasFilters ? 'Edit Filters' : 'Add Filters',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.0275,
                  fontWeight: FontWeight.w600,
                  color: hasFilters
                      ? AppColors.primaryOrange
                      : Colors.white.withValues(alpha: 0.9),
                  letterSpacing: MediaQuery.of(context).size.width * 0.0005,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
