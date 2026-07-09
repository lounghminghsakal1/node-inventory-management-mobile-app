import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/batch_inventory_model.dart';
import '../../providers/inventory_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      batchInventoryDetailProvider(widget.batchInventoryId),
    );
    final txState = ref.watch(
      batchTransactionsProvider(widget.batchInventoryId),
    );

    return Scaffold(
      // appBar: const NodeOpsAppBar(title: "Batch Inventory Detail"),
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
                                value: detail.batch!.manufacturingDate!,
                              ),
                            ),
                          if (detail.batch?.expiryDate != null)
                            Expanded(
                              child: _InfoTile(
                                label: "Expiry Date",
                                value: detail.batch!.expiryDate!,
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
                  ...txState.transactions.map((tx) => _TransactionCard(tx: tx)),

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

  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isAdd = tx.adjustmentType.toLowerCase() == 'add' || tx.quantity > 0;
    final qtyColor = isAdd ? AppColors.success : AppColors.error;
    final qtyPrefix = isAdd ? "+" : "";

    final details = tx.transactionDetails;
    final txType = details['transaction_type']?.toString() ?? 'Adjustment';

    String refInfo = "";
    if (details.containsKey('grn_number')) {
      refInfo = "GRN: ${details['grn_number']}";
    } else if (details.containsKey('stock_transfer_order_number')) {
      refInfo = "STO: ${details['stock_transfer_order_number']}";
    } else if (details.containsKey('shipment_number')) {
      refInfo =
          "Shipment: ${details['shipment_number']} (${details['shipment_type'] ?? ''})";
    } else if (details.containsKey('inventory_adjustment_number')) {
      refInfo = "Adj: ${details['inventory_adjustment_number']}";
    } else if (details.containsKey('internal_transfer_number')) {
      refInfo = "Transfer: ${details['internal_transfer_number']}";
    } else if (details.containsKey('reference_number')) {
      refInfo = "Ref: ${details['reference_number']}";
    }

    final sourceName =
        tx.sourceDetails?['vendor_name'] ?? tx.sourceDetails?['node_name'];
    final destName =
        tx.destinationDetails?['node_name'] ??
        tx.destinationDetails?['vendor_name'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  txType,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "$qtyPrefix${tx.quantity}",
                style: AppTextStyles.headingMedium.copyWith(
                  color: qtyColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (refInfo.isNotEmpty) ...[
            Text(
              refInfo,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
          ],

          if (sourceName != null || destName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (sourceName != null) ...[
                  Text(
                    "From: ",
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    "$sourceName",
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (sourceName != null && destName != null)
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                if (sourceName != null && destName != null)
                  const SizedBox(width: 8),
                if (destName != null) ...[
                  Text(
                    "To: ",
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    "$destName",
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
