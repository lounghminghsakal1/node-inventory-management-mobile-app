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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    shipment.shipmentNumber,
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                StatusBadge(status: shipment.status.value),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Order & Customer
            _infoRow(Icons.receipt_outlined, shipment.orderNumber,
                AppColors.textSecondary),
            const SizedBox(height: 6),
            _infoRow(Icons.storefront_outlined, shipment.customerName,
                AppColors.textPrimary),
            const SizedBox(height: 10),

            // Items & date
            Row(
              children: [
                _chipInfo('${shipment.totalItems} items',
                    Icons.category_outlined, AppColors.primary),
                const SizedBox(width: 8),
                _chipInfo('${shipment.totalQty} units',
                    Icons.inventory_outlined, AppColors.secondary),
                const Spacer(),
                Text(
                  _formatDate(shipment.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),

            if (shipment.driverDetails != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car_outlined,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      '${shipment.driverDetails!.name} · ${shipment.driverDetails!.vehicleNumber}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.warning, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],

            if (shipment.status == ShipmentStatus.invoiced ||
                shipment.status == ShipmentStatus.dispatched ||
                shipment.status == ShipmentStatus.delivered) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Downloading Invoice PDF...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'https://flaerhomes.com/invoices/${shipment.shipmentNumber}.pdf',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.download_rounded,
                          size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
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
          child: Text(text,
              style: AppTextStyles.bodySmall.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
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
          Text(label,
              style: AppTextStyles.caption.copyWith(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
