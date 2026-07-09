import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/node_inventory_model.dart';
import '../../providers/inventory_provider.dart';
import '../../../../core/widgets/app_shell.dart';

class NodeInventoryDetailScreen extends ConsumerStatefulWidget {
  final String inventoryId;

  const NodeInventoryDetailScreen({super.key, required this.inventoryId});

  @override
  ConsumerState<NodeInventoryDetailScreen> createState() =>
      _NodeInventoryDetailScreenState();
}

class _NodeInventoryDetailScreenState
    extends ConsumerState<NodeInventoryDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      ref
          .read(nodeInventoryTransactionsProvider(widget.inventoryId).notifier)
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
      nodeInventoryDetailProvider(widget.inventoryId),
    );
    final txState = ref.watch(
      nodeInventoryTransactionsProvider(widget.inventoryId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NodeOpsAppBar(
        title: "Inventory Detail",
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
                onPressed: () {
                  ref.invalidate(
                    nodeInventoryDetailProvider(widget.inventoryId),
                  );
                  ref
                      .read(
                        nodeInventoryTransactionsProvider(
                          widget.inventoryId,
                        ).notifier,
                      )
                      .fetchInitial();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
        data: (detail) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(nodeInventoryDetailProvider(widget.inventoryId));
              await ref
                  .read(
                    nodeInventoryTransactionsProvider(
                      widget.inventoryId,
                    ).notifier,
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
                      Text(
                        detail.skuName.isNotEmpty
                            ? detail.skuName
                            : 'Unknown SKU',
                        style: AppTextStyles.headingLarge.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "SKU Code: ${detail.skuCode.isNotEmpty ? detail.skuCode : 'N/A'} • Tracking: ${detail.trackingType.toUpperCase()}",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        color: AppColors.cardBorder.withValues(alpha: 0.6),
                        height: 1,
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
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
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
  final NodeInventoryTransactionModel tx;
  final String Function(String) formatTxType;

  const _TransactionCard({required this.tx, required this.formatTxType});

  @override
  Widget build(BuildContext context) {
    final adj = tx.adjustmentType.toLowerCase();
    final bool isPositive;
    if (adj == 'add') {
      isPositive = true;
    } else if (adj == 'remove') {
      isPositive = false;
    } else {
      isPositive = tx.newQuantity >= tx.prevQuantity;
    }

    final diff = tx.newQuantity - tx.prevQuantity;
    final int qtyVal = tx.quantity != 0 ? tx.quantity.abs() : diff.abs();
    final String diffStr = isPositive ? '+$qtyVal' : '-$qtyVal';

    final String refText;
    if (tx.details != null && tx.details!.referenceNumber.isNotEmpty) {
      refText =
          '${formatTxType(tx.details!.transactionType)} #${tx.details!.referenceNumber}';
    } else if (tx.transactionReferenceType.isNotEmpty &&
        tx.transactionReferenceId != 0) {
      refText =
          'Ref: ${tx.transactionReferenceType} #${tx.transactionReferenceId}';
    } else if (tx.details != null && tx.details!.id != 0) {
      refText = 'Ref #${tx.details!.id}';
    } else {
      refText = 'Ref #${tx.id}';
    }

    String partyInfo = '';
    if (tx.sourceDetails != null &&
        tx.sourceDetails!.name.isNotEmpty &&
        tx.destinationDetails != null &&
        tx.destinationDetails!.name.isNotEmpty) {
      partyInfo = '${tx.sourceDetails!.name} → ${tx.destinationDetails!.name}';
    } else if (tx.sourceDetails != null && tx.sourceDetails!.name.isNotEmpty) {
      partyInfo = 'From: ${tx.sourceDetails!.name}';
    } else if (tx.destinationDetails != null &&
        tx.destinationDetails!.name.isNotEmpty) {
      partyInfo = 'To: ${tx.destinationDetails!.name}';
    }

    final dateText = tx.createdAt.isNotEmpty
        ? tx.createdAt
        : (tx.details?.completedDate ?? '');

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
                  formatTxType(tx.transactionType),
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
              const SizedBox(height: 2),
              Text(
                'Qty: ${tx.prevQuantity} → ${tx.newQuantity}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
