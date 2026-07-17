import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/shipment.dart';

class ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback onTap;

  const ShipmentCard({super.key, required this.shipment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isReverse = shipment.shipmentType == 'reverse_shipment';
    final typeLabel = isReverse ? 'Reverse Shipment' : 'Forward Shipment';
    final typeColor = isReverse ? AppColors.warning : AppColors.primary;
    final typeIcon = isReverse
        ? Icons.assignment_return_outlined
        : Icons.local_shipping_outlined;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Shipment Number & Status Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Sh.No: ${shipment.shipmentNumber}",
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                StatusBadge(status: shipment.status.value),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Order Number
            _infoRow(
              Icons.receipt_outlined,
              'Order: #${shipment.orderNumber}',
              AppColors.textSecondary,
            ),
            const SizedBox(height: 6),

            // Customer Code & ID
            _infoRow(
              Icons.person_outline_rounded,
              'Customer Code: ${shipment.customerCode ?? shipment.customerId ?? "-"}',
              AppColors.textPrimary,
            ),
            const SizedBox(height: 6),

            // Items Count
            _infoRow(
              Icons.shopping_bag_outlined,
              '${shipment.totalItems} Items',
              AppColors.textSecondary,
            ),
            const SizedBox(height: 12),

            if (isReverse || shipment.parentShipmentNumber != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (isReverse) _chipInfo(typeLabel, typeIcon, typeColor),
                  if (shipment.parentShipmentNumber != null)
                    _chipInfo(
                      'Parent: ${shipment.parentShipmentNumber}',
                      Icons.link_rounded,
                      AppColors.secondary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatDate(shipment.createdAt),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _chipInfo(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
