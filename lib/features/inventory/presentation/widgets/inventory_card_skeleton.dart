import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_loading.dart';

/// Skeleton placeholder shared by the batch/serial/node inventory cards,
/// shown while their respective lists are loading.
class InventoryCardSkeleton extends StatelessWidget {
  const InventoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 160, height: 18),
            const SizedBox(height: 8),
            const ShimmerBox(width: 120, height: 12),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ShimmerBox(
                    height: 46,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ShimmerBox(
                    height: 46,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ShimmerBox(
                    height: 46,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
