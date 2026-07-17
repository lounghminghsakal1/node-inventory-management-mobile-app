import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:node_management_app/core/utils/helper_functions.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/batch_inventory_model.dart';
import '../../providers/inventory_provider.dart';
import "../../../../core/widgets/app_shell.dart";

class BatchInventoryDetailScreen extends ConsumerStatefulWidget {
  final String batchInventoryId;

  const BatchInventoryDetailScreen({super.key, required this.batchInventoryId});

  @override
  ConsumerState<BatchInventoryDetailScreen> createState() =>
      _BatchInventoryDetailScreenState();
}

class _BatchInventoryDetailScreenState
    extends ConsumerState<BatchInventoryDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      ref
          .read(batchTransactionsProvider(widget.batchInventoryId).notifier)
          .fetchNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTxType(String type) {
    if (type.isEmpty) return 'Adjustment';
    if (type == 'GoodsReceivedNote') return 'Goods Received Note';
    if (type == 'ForwardShipment') return 'Forward Shipment';
    if (type == 'ReverseShipment') return 'Reverse Shipment';
    return type.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (Match m) => '${m[1]} ${m[2]}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      batchInventoryDetailProvider(widget.batchInventoryId),
    );
    final txState = ref.watch(
      batchTransactionsProvider(widget.batchInventoryId),
    );

    return Scaffold(
      appBar: const NodeOpsAppBar(
        title: "Batch Inventory Detail",
        hideLogoutButton: true,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                "Failed to load details",
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: 6),
              Text(
                err.toString().replaceAll('Exception: ', ''),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(
                  batchInventoryDetailProvider(widget.batchInventoryId),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
        data: (detail) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                batchInventoryDetailProvider(widget.batchInventoryId),
              );
              await ref
                  .read(
                    batchTransactionsProvider(widget.batchInventoryId).notifier,
                  )
                  .fetchInitial();
            },
            color: AppColors.primary,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // ── Top Summary Card ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              detail.productSku?.skuName ?? 'Unknown SKU',
                              style: AppTextStyles.headingLarge.copyWith(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "SKU Code: ${detail.productSku?.skuCode ?? 'N/A'}",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        color: AppColors.cardBorder.withValues(alpha: 0.6),
                        height: 1,
                      ),
                      const SizedBox(height: 12),

                      // Batch Details
                      Row(
                        children: [
                          Expanded(
                            child: _InfoTile(
                              label: "Batch Code",
                              value: detail.batch?.batchCode ?? 'N/A',
                            ),
                          ),
                          if (detail.batch?.manufacturingDate != null)
                            Expanded(
                              child: _InfoTile(
                                label: "Mfg Date",
                                value: HelperFunctions.formatDate(
                                  DateTime.parse(
                                    detail.batch!.manufacturingDate!,
                                  ),
                                  hasTime: false,
                                ),
                              ),
                            ),
                          if (detail.batch?.expiryDate != null)
                            Expanded(
                              child: _InfoTile(
                                label: "Expiry Date",
                                value: HelperFunctions.formatDate(
                                  DateTime.parse(detail.batch!.expiryDate!),
                                  hasTime: false,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Quantities Grid
                      Text(
                        "Stock Breakdown",
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.8,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          _StockBox(
                            label: "Available",
                            count: detail.availableQuantity,
                            color: AppColors.success,
                          ),
                          _StockBox(
                            label: "Blocked",
                            count: detail.blockedQuantity,
                            color: AppColors.warning,
                          ),
                          _StockBox(
                            label: "Total",
                            count: detail.totalQuantity,
                            color: AppColors.primary,
                          ),
                          if (detail.inTransitQuantity > 0 ||
                              detail.damagedQuantity > 0 ||
                              detail.missingQuantity > 0) ...[
                            _StockBox(
                              label: "In Transit",
                              count: detail.inTransitQuantity,
                              color: AppColors.info,
                            ),
                            _StockBox(
                              label: "Damaged",
                              count: detail.damagedQuantity,
                              color: AppColors.error,
                            ),
                            _StockBox(
                              label: "Missing",
                              count: detail.missingQuantity,
                              color: AppColors.error,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Transactions Section ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      txState.totalCount > 0
                          ? "Inventory Transactions (${txState.totalCount})"
                          : "Inventory Transactions",
                      style: AppTextStyles.headingLarge.copyWith(fontSize: 18),
                    ),
                    if (txState.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (txState.transactions.isEmpty && !txState.isLoading)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          size: 40,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "No transaction history available",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...txState.transactions.map(
                    (tx) =>
                        _TransactionCard(tx: tx, formatTxType: _formatTxType),
                  ),

                if (txState.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StockBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StockBox({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$count",
            style: AppTextStyles.headingMedium.copyWith(
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final BatchInventoryTransactionModel tx;
  final String Function(String) formatTxType;

  const _TransactionCard({required this.tx, required this.formatTxType});

  @override
  Widget build(BuildContext context) {
    final details = tx.transactionDetails;
    final txType = details['transaction_type']?.toString() ?? 'Adjustment';
    final shipmentType =
        details['shipment_type']?.toString().toLowerCase() ?? '';
    final adj = tx.adjustmentType.toLowerCase();

    bool isPositive;
    if (adj == 'add') {
      isPositive = true;
    } else if (adj == 'remove') {
      isPositive = false;
    } else {
      isPositive = tx.quantity > 0;
    }

    final int qtyVal = tx.quantity.abs();
    final String diffStr = isPositive ? '+$qtyVal' : '-$qtyVal';

    String displayTitle;
    if (txType == 'Shipment' && shipmentType == 'reverse_shipment') {
      displayTitle = 'Reverse Shipment';
    } else if (txType == 'Shipment' && shipmentType == 'forward_shipment') {
      displayTitle = 'Forward Shipment';
    } else if (txType == 'GoodsReceivedNote') {
      displayTitle = 'Goods Received Note';
    } else {
      displayTitle = formatTxType(txType);
    }

    String refText;
    if (details.containsKey('grn_number')) {
      refText = 'GRN #${details['grn_number']}';
    } else if (details.containsKey('shipment_number')) {
      refText = 'Shipment #${details['shipment_number']}';
    } else if (details.containsKey('stock_transfer_order_number')) {
      refText = 'STO #${details['stock_transfer_order_number']}';
    } else if (details.containsKey('inventory_adjustment_number')) {
      refText = 'Adj #${details['inventory_adjustment_number']}';
    } else if (details.containsKey('internal_transfer_number')) {
      refText = 'Transfer #${details['internal_transfer_number']}';
    } else if (details.containsKey('reference_number')) {
      refText = 'Ref #${details['reference_number']}';
    } else if (details.containsKey('id')) {
      refText = 'Ref #${details['id']}';
    } else {
      refText = 'Ref #${tx.id}';
    }

    final sourceName =
        tx.sourceDetails?['vendor_name'] ??
        tx.sourceDetails?['node_name'] ??
        tx.sourceDetails?['business_partner_name'] ??
        tx.sourceDetails?['customer_name'] ??
        tx.sourceDetails?['name'];
    final destName =
        tx.destinationDetails?['node_name'] ??
        tx.destinationDetails?['vendor_name'] ??
        tx.destinationDetails?['business_partner_name'] ??
        tx.destinationDetails?['customer_name'] ??
        tx.destinationDetails?['name'];
    String partyInfo = '';
    if (sourceName != null &&
        sourceName.toString().isNotEmpty &&
        destName != null &&
        destName.toString().isNotEmpty) {
      partyInfo = '$sourceName → $destName';
    } else if (sourceName != null && sourceName.toString().isNotEmpty) {
      partyInfo = 'From: $sourceName';
    } else if (destName != null && destName.toString().isNotEmpty) {
      partyInfo = 'To: $destName';
    }

    final dateText = HelperFunctions.formatDate(
      DateTime.parse(
        details['completed_date'] ??
            details['delivered_date'] ??
            details['returned_date'] ??
            details['created_at'] ??
            '',
      ),
      hasTime: false,
    );

    final prevQty = details['prev_quantity'] ?? details['previous_quantity'];
    final newQty = details['new_quantity'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isPositive ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  refText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (partyInfo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    partyInfo,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (dateText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dateText,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                diffStr,
                style: AppTextStyles.headingMedium.copyWith(
                  color: isPositive ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (prevQty != null && newQty != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Qty: $prevQty → $newQty',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
