import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/tracking_type_badge.dart';
import '../../data/models/node_inventory_model.dart';
import '../../providers/inventory_provider.dart';

class NodeInventoryListView extends ConsumerStatefulWidget {
  const NodeInventoryListView({super.key});

  @override
  ConsumerState<NodeInventoryListView> createState() => _NodeInventoryListViewState();
}

class _NodeInventoryListViewState extends ConsumerState<NodeInventoryListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      ref.read(nodeInventoryListProvider.notifier).fetchNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showTransactionsModal(NodeInventoryModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NodeInventoryTransactionsModal(inventoryId: item.id.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeInventoryListProvider);

    return Column(
      children: [
        // ── Search & Filter Bar ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _searchController,
                      label: '',
                      hint: 'Search by SKU Name or Code...',
                      prefixIcon: Icons.search,
                      suffix: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(nodeInventoryListProvider.notifier).clearFilters();
                              },
                            )
                          : null,
                      onSubmitted: (val) {
                        ref.read(nodeInventoryListProvider.notifier).updateFilters(
                              bySkuName: val.trim().isNotEmpty ? val.trim() : null,
                              bySkuCode: val.trim().isNotEmpty ? val.trim() : null,
                            );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 18, color: state.availableOnly ? AppColors.success : AppColors.textMuted),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Available Stock Only',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: state.availableOnly ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: state.availableOnly ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: state.availableOnly,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      ref.read(nodeInventoryListProvider.notifier).filterAvailableOnly(val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── List View ─────────────────────────────────────────────────────────
        Expanded(
          child: state.isLoading && state.items.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : state.errorMessage != null && state.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load node inventory',
                            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => ref.read(nodeInventoryListProvider.notifier).fetchInitial(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : state.items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'No inventories found',
                                style: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(nodeInventoryListProvider.notifier).fetchInitial();
                          },
                          color: AppColors.primary,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.items.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                                );
                              }
                              final item = state.items[index];
                              return _buildInventoryCard(item);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildInventoryCard(NodeInventoryModel item) {
    final trackingType = item.trackingType.toLowerCase();


    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.skuName,
                        style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU Code: ${item.skuCode}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TrackingTypeBadge(trackingType: item.trackingType),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.cardBorder.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 14),

            // Quantities Grid
            Row(
              children: [
                Expanded(
                  child: _buildQtyBox('Total', item.totalQuantity, AppColors.textPrimary, isBold: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQtyBox('Available', item.availableQuantity, AppColors.success, isBold: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQtyBox('Blocked', item.blockedQuantity, AppColors.warning),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildQtyBox('In Transit', item.inTransitQuantity, AppColors.secondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQtyBox('Damaged', item.damagedQuantity, AppColors.error),
                ),
                const SizedBox(width: 8),
                Expanded(child: const SizedBox.shrink()),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.cardBorder.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 12),

            // Actions Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTransactionsModal(item),
                    icon: const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                    label: const Text('History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (trackingType == 'batch' || trackingType == 'serial') ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (trackingType == 'batch') {
                          ref.read(batchInventoryListProvider.notifier).updateFilters(bySkuCode: item.skuCode);
                          DefaultTabController.of(context).animateTo(1);
                        } else if (trackingType == 'serial') {
                          ref.read(serialInventoryListProvider.notifier).updateFilters(bySkuCode: item.skuCode);
                          DefaultTabController.of(context).animateTo(2);
                        }
                      },
                      icon: Icon(
                        trackingType == 'batch' ? Icons.layers_outlined : Icons.qr_code_2_outlined,
                        size: 18,
                      ),
                      label: Text(trackingType == 'batch' ? 'Batches' : 'Serials'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getTrackingTextColor(trackingType),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBox(String label, int value, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTextStyles.headingMedium.copyWith(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Transactions Modal ────────────────────────────────────────────────────────
class _NodeInventoryTransactionsModal extends ConsumerStatefulWidget {
  final String inventoryId;

  const _NodeInventoryTransactionsModal({required this.inventoryId});

  @override
  ConsumerState<_NodeInventoryTransactionsModal> createState() => _NodeInventoryTransactionsModalState();
}

class _NodeInventoryTransactionsModalState extends ConsumerState<_NodeInventoryTransactionsModal> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      ref.read(nodeInventoryTransactionsProvider(widget.inventoryId).notifier).fetchNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeInventoryTransactionsProvider(widget.inventoryId));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Modal Handle Bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transaction History', style: AppTextStyles.headingLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (state.nodeInventory != null)
                          Text(
                            '${state.nodeInventory!.skuName} (${state.nodeInventory!.skuCode})',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: state.isLoading && state.transactions.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : state.transactions.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions recorded',
                            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: state.transactions.length + (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.transactions.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                              );
                            }
                            final tx = state.transactions[index];
                            final isPositive = tx.newQuantity >= tx.prevQuantity;
                            final diff = tx.newQuantity - tx.prevQuantity;
                            final diffStr = diff >= 0 ? '+$diff' : '$diff';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
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
                                          tx.transactionType.toUpperCase(),
                                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ref: ${tx.transactionReferenceType} #${tx.transactionReferenceId}',
                                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tx.createdAt,
                                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                                        ),
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
                                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
