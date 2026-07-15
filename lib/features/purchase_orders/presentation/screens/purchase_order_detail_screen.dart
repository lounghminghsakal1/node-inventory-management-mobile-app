import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:node_management_app/core/utils/helper_functions.dart';
import '../../../home/providers/home_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/tracking_type_badge.dart';
import '../../data/models/purchase_order_model.dart';
import '../../providers/purchase_order_provider.dart';
import '../../../grn/presentation/screens/create_grn_screen.dart';
import '../widgets/grn_accordion_item.dart';

class PurchaseOrderDetailScreen extends ConsumerStatefulWidget {
  final int poId;
  const PurchaseOrderDetailScreen({super.key, required this.poId});

  @override
  ConsumerState<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState
    extends ConsumerState<PurchaseOrderDetailScreen> {
  int? _expandedGrnId;
  bool _isLineItemsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final asyncPo = ref.watch(purchaseOrderByIdProvider(widget.poId));
    final splash = ref.watch(splashDataProvider).valueOrNull;
    final canCreateGrn =
        splash?.hasPermission('GoodsReceivedNote', 'create') ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NodeOpsAppBar(showBack: true, title: 'PO Details'),
      bottomNavigationBar: asyncPo.maybeWhen(
        data: (po) {
          if (!canCreateGrn) return null;
          final isAllGrnCompleted = po.goodsReceivedNotes.isEmpty
              ? true
              : po.goodsReceivedNotes.every((grn) => grn.status == 'complete');
          if (!isAllGrnCompleted) {
            return null;
          } else {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: SafeArea(
                top: false,
                child: splash!.hasPermission("GoodsReceivedNote", "create")
                    ? AppButton(
                        label: 'Create GRN',
                        icon: Icons.add_box_outlined,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CreateGrnScreen(
                                poId: po.id,
                                poNumber: po.purchaseOrderNumber,
                              ),
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
        },
        orElse: () => null,
      ),
      body: asyncPo.when(
        skipLoadingOnReload: false,
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load purchase order\n$e',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ),
        data: (po) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -- PO Summary Card -----------------------------------------
                _buildPoSummaryCard(po),
                const SizedBox(height: 24),

                // -- Vendor Details Card -------------------------------------
                // _buildVendorCard(po.vendor),
                // const SizedBox(height: 24),

                // -- PO Line Items Section -----------------------------------
                _buildLineItemsSection(po.lineItems),
                const SizedBox(height: 24),

                // -- Goods Received Notes Section ----------------------------
                Text(
                  'Goods Received Notes (GRNs)',
                  style: AppTextStyles.headingMedium,
                ),
                const SizedBox(height: 16),

                _buildGrnSection(po),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPoSummaryCard(PurchaseOrderModel po) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  po.purchaseOrderNumber,
                  style: AppTextStyles.headingLarge,
                ),
              ),
              StatusBadge(status: po.status),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _infoRow(
            Icons.inventory_2_outlined,
            'Total Units',
            '${po.totalUnits} units',
            AppColors.primary,
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.calendar_today_outlined,
            'Delivery Date',
            po.deliveryDate != null ? HelperFunctions.formatDate(DateTime.parse(po.deliveryDate!), hasTime: false) : 'N/A',
            AppColors.textPrimary,
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.event_busy_outlined,
            'Expiry Date',
            po.expiryDate != null ? HelperFunctions.formatDate(DateTime.parse(po.expiryDate!), hasTime: false) : 'No Expiry',
            AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.business_outlined,
            'Firm Name',
            po.vendor.firmName,
            AppColors.textPrimary,
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.tag_outlined,
            'Vendor Code',
            po.vendor.code,
            AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(VendorModel vendor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Vendor Information', style: AppTextStyles.headingSmall),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _infoRow(
            Icons.business_outlined,
            'Firm Name',
            vendor.firmName,
            AppColors.textPrimary,
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.tag_outlined,
            'Vendor Code',
            vendor.code,
            AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsSection(List<PurchaseOrderLineItemModel> lineItems) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isLineItemsExpanded
              ? AppColors.primary
              : AppColors.cardBorder,
          width: _isLineItemsExpanded ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Accordion Header
          InkWell(
            onTap: () {
              setState(() {
                _isLineItemsExpanded = !_isLineItemsExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.list_alt_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PO Line Items (${lineItems.length})',
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Items ordered in this purchase order',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isLineItemsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isLineItemsExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lineItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Center(
                        child: Text(
                          'No line items found.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...lineItems.map(
                      (li) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    li.displayName.isNotEmpty
                                        ? li.displayName
                                        : li.skuName,
                                    style: AppTextStyles.headingSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'SKU: ${li.skuCode}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      TrackingTypeBadge(
                                        trackingType: li.trackingType,
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: AppColors.cardBorder,
                                          ),
                                        ),
                                        child: Text(
                                          'Selection: ${li.selectionType.toUpperCase()}',
                                          style: AppTextStyles.caption.copyWith(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${li.orderedQuantity}',
                                    style: AppTextStyles.headingMedium.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'units',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrnSection(PurchaseOrderModel po) {
    final asyncGrns = ref.watch(grnListForPoProvider(widget.poId));

    return asyncGrns.when(
      skipLoadingOnReload: false,
      skipLoadingOnRefresh: false,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(
        child: Text(
          'Failed to load GRNs\n$e',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        ),
      ),
      data: (grns) {
        if (grns.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 40,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Goods Received Notes recorded yet.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: grns.map((grn) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GrnAccordionItem(
                grn: grn,
                po: po,
                isExpanded: _expandedGrnId == grn.id,
                onToggle: () {
                  setState(() {
                    _expandedGrnId = (_expandedGrnId == grn.id) ? null : grn.id;
                  });
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
