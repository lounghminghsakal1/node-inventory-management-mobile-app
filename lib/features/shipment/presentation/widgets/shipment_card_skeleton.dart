import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_loading.dart';

/// Skeleton placeholder mirroring [ShipmentCard]'s layout, shown while the
/// shipment list is loading.
class ShipmentCardSkeleton extends StatelessWidget {
  const ShipmentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.15),
          width: 2,
        ),
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
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 14),
            const ShimmerBox(width: 160, height: 12),
            const SizedBox(height: 8),
            const ShimmerBox(width: 200, height: 12),
            const SizedBox(height: 8),
            const ShimmerBox(width: 100, height: 12),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerRight,
              child: ShimmerBox(width: 110, height: 10),
            ),
          ],
        ),
      ),
    );
  }
}
