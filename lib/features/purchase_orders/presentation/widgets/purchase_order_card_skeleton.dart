import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_loading.dart';

/// Skeleton placeholder mirroring [PurchaseOrderCard]'s layout, shown while
/// the purchase order list is loading.
class PurchaseOrderCardSkeleton extends StatelessWidget {
  const PurchaseOrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Row(
              children: [
                const Expanded(child: ShimmerBox(height: 18)),
                const SizedBox(width: 12),
                ShimmerBox(
                  width: 70,
                  height: 20,
                  borderRadius: BorderRadius.circular(20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 10),
            const ShimmerBox(width: 220, height: 12),
            const SizedBox(height: 10),
            const ShimmerBox(width: 150, height: 12),
            const SizedBox(height: 12),
            Row(
              children: [
                ShimmerBox(
                  width: 90,
                  height: 22,
                  borderRadius: BorderRadius.circular(6),
                ),
                const Spacer(),
                const ShimmerBox(width: 110, height: 28),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 12),
            const ShimmerBox(width: 80, height: 12),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(child: ShimmerBox(height: 14)),
                const SizedBox(width: 12),
                const ShimmerBox(width: 70, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
