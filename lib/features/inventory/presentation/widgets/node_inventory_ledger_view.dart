import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/node_inventory_ledger_model.dart';
import '../../providers/inventory_provider.dart';

class NodeInventoryLedgerView extends ConsumerStatefulWidget {
  const NodeInventoryLedgerView({super.key});

  @override
  ConsumerState<NodeInventoryLedgerView> createState() => _NodeInventoryLedgerViewState();
}

class _NodeInventoryLedgerViewState extends ConsumerState<NodeInventoryLedgerView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      ref.read(nodeInventoryLedgerProvider.notifier).fetchNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context, NodeInventoryLedgerState state) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final fromStr = "${picked.start.year}-${picked.start.month.toString().padLeft(2, '0')}-${picked.start.day.toString().padLeft(2, '0')}";
      final toStr = "${picked.end.year}-${picked.end.month.toString().padLeft(2, '0')}-${picked.end.day.toString().padLeft(2, '0')}";
      ref.read(nodeInventoryLedgerProvider.notifier).filterByDates(fromStr, toStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeInventoryLedgerProvider);

    return Column(
      children: [
        // ── Search & Date Filters ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Column(
            children: [
              AppTextField(
                controller: _searchController,
                label: '',
                hint: 'Filter by SKU Code or ID...',
                prefixIcon: Icons.search,
                suffix: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(nodeInventoryLedgerProvider.notifier).clearFilters();
                        },
                      )
                    : null,
                onSubmitted: (val) {
                  ref.read(nodeInventoryLedgerProvider.notifier).updateFilters(
                        bySkuCode: val.trim().isNotEmpty ? val.trim() : null,
                      );
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDateRange(context, state),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.fromDate != null && state.toDate != null
                                    ? '${state.fromDate} → ${state.toDate}'
                                    : 'All Dates (Filter Range)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: state.fromDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: state.fromDate != null ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (state.fromDate != null || state.bySkuCode != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                      tooltip: 'Reset Filters',
                      onPressed: () {
                        _searchController.clear();
                        ref.read(nodeInventoryLedgerProvider.notifier).clearFilters();
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // ── Ledger List ───────────────────────────────────────────────────────
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
                            'Failed to load inventory ledger',
                            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => ref.read(nodeInventoryLedgerProvider.notifier).fetchInitial(),
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
                              Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'No ledger records found',
                                style: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(nodeInventoryLedgerProvider.notifier).fetchInitial();
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
                              return _buildLedgerCard(item);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildLedgerCard(NodeInventoryLedgerModel item) {
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        item.date,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.cardBorder.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 14),

            // Ledger Grid (Opening, Inward, Outward, Closing)
            Row(
              children: [
                Expanded(
                  child: _buildLedgerBox(
                    'Opening Qty',
                    '${item.openingQuantity}',
                    AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLedgerBox(
                    'Inward Qty',
                    '+${item.inwardQuantity}',
                    AppColors.success,
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLedgerBox(
                    'Outward Qty',
                    '-${item.outwardQuantity}',
                    AppColors.error,
                    isNegative: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLedgerBox(
                    'Closing Qty',
                    '${item.closingQuantity}',
                    AppColors.primary,
                    isBold: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerBox(String label, String value, Color color, {bool isBold = false, bool isPositive = false, bool isNegative = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBold ? AppColors.primary.withValues(alpha: 0.4) : AppColors.cardBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.headingMedium.copyWith(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
