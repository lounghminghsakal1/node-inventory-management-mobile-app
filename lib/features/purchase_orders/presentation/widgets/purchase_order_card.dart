import 'package:flutter/material.dart';
import 'package:node_management_app/core/utils/helper_functions.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/purchase_order_model.dart';

class PurchaseOrderCard extends StatefulWidget {
  final PurchaseOrderModel po;
  final VoidCallback onTap;

  const PurchaseOrderCard({super.key, required this.po, required this.onTap});

  @override
  State<PurchaseOrderCard> createState() => _PurchaseOrderCardState();
}

class _PurchaseOrderCardState extends State<PurchaseOrderCard> {
  bool _isExpanded = false;

  String _formatStatusText(String status) {
    final formatted = status.replaceAll('_', ' ').trim();
    if (formatted.isEmpty) return 'Unknown';
    if (status == "complete") return "Completed";
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final po = widget.po;

    return GestureDetector(
      onTap: widget.onTap,
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
            // Header row: PO Number + Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    "PO.No: ${po.purchaseOrderNumber}",
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                StatusBadge(status: po.status),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Vendor Info
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${po.vendor.firmName} (${po.vendor.code})',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (po.createdByName != null && po.createdByName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Created by: ${po.createdByName}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),

            // Units & Dates
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${po.totalUnits} units',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (po.deliveryDate != null && po.createdDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Created: ${HelperFunctions.formatDate(DateTime.parse(po.createdDate!), hasTime: false)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Delivery: ${HelperFunctions.formatDate(DateTime.parse(po.deliveryDate!), hasTime: false)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),

            if (po.grns.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                'GRNs (${po.grns.length})',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              
              // GRN List
              ...List.generate(
                _isExpanded ? po.grns.length : (po.grns.length > 3 ? 3 : po.grns.length),
                (index) {
                  final grn = po.grns[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  grn.grnNumber,
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Text(
                              _formatStatusText(grn.status),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (grn.createdAt != null && grn.createdAt!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Text(
                              'Created: ${HelperFunctions.formatDate(DateTime.parse(grn.createdAt!).toLocal(), hasTime: true)}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              
              if (po.grns.length > 3)
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _isExpanded ? 'Show Less' : 'Show More',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

