import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/dashboard_stats.dart';

class RecentActivityCard extends StatelessWidget {
  final ActivityItem item;

  const RecentActivityCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(item.type);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(config.icon, size: 20, color: config.color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTextStyles.headingSmall),
                const SizedBox(height: 2),
                Text(item.subtitle, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Text(
            item.timeAgo,
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  _ActivityConfig _getConfig(ActivityType type) {
    switch (type) {
      case ActivityType.shipment:
        return _ActivityConfig(Icons.local_shipping_outlined, AppColors.primary);
      case ActivityType.grn:
        return _ActivityConfig(Icons.inventory_2_outlined, AppColors.secondary);
      case ActivityType.return_:
        return _ActivityConfig(Icons.assignment_return_outlined, AppColors.warning);
      case ActivityType.adjustment:
        return _ActivityConfig(Icons.tune_outlined, AppColors.accent);
      case ActivityType.audit:
        return _ActivityConfig(Icons.fact_check_outlined, AppColors.accentGreen);
    }
  }
}

class _ActivityConfig {
  final IconData icon;
  final Color color;
  const _ActivityConfig(this.icon, this.color);
}
