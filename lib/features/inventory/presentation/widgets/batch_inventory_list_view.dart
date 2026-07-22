import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/batch_inventory_model.dart';
import '../../providers/inventory_provider.dart';
import '../screens/batch_inventory_detail_screen.dart';
import 'inventory_card_skeleton.dart';

class BatchInventoryListView extends ConsumerStatefulWidget {
  const BatchInventoryListView({super.key});

  @override
  ConsumerState<BatchInventoryListView> createState() =>
      _BatchInventoryListViewState();
}

class _BatchInventoryListViewState
    extends ConsumerState<BatchInventoryListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      ref.read(batchInventoryListProvider.notifier).fetchNextPage();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchBySkuName(String v) {
    final trimmed = v.trim();
    final state = ref.read(batchInventoryListProvider);
    ref
        .read(batchInventoryListProvider.notifier)
        .updateFilters(
          bySkuName: trimmed.isEmpty ? null : trimmed,
          bySkuCode: state.bySkuCode,
          byBatchId: state.byBatchId,
          availableOnly: state.availableOnly,
        );
  }

  void _openFilterSheet(BatchInventoryListState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BatchFilterSheet(
        initialSkuName: state.bySkuName,
        initialSkuCode: state.bySkuCode,
        initialBatchId: state.byBatchId,
        initialAvailableOnly: state.availableOnly,
        onApply: (skuName, skuCode, batchId, availOnly) {
          ref
              .read(batchInventoryListProvider.notifier)
              .updateFilters(
                bySkuName: skuName,
                bySkuCode: skuCode,
                byBatchId: batchId,
                availableOnly: availOnly,
              );
        },
        onReset: () {
          ref.read(batchInventoryListProvider.notifier).clearFilters();
          _searchController.clear();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchInventoryListProvider);
    final hasFilters =
        state.bySkuName != null ||
        state.bySkuCode != null ||
        state.byBatchId != null ||
        !state.availableOnly;

    return Column(
      children: [
        // ── Search & Filter Bar ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search SKU name or code...",
                    hintStyle: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () {
                              _searchDebounce?.cancel();
                              _searchController.clear();
                              setState(() {});
                              final state = ref.read(
                                batchInventoryListProvider,
                              );
                              ref
                                  .read(batchInventoryListProvider.notifier)
                                  .updateFilters(
                                    bySkuName: null,
                                    bySkuCode: null,
                                    byBatchId: state.byBatchId,
                                    availableOnly: state.availableOnly,
                                  );
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onSubmitted: (val) {
                    _searchDebounce?.cancel();
                    _searchBySkuName(val);
                  },
                  onChanged: (v) {
                    setState(() {}); // refresh suffix clear-icon visibility
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 500),
                      () => _searchBySkuName(v),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _openFilterSheet(state),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasFilters ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasFilters
                          ? AppColors.primary
                          : AppColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: hasFilters ? Colors.white : AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── List View ────────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(batchInventoryListProvider.notifier)
                  .fetchInitial();
            },
            color: AppColors.primary,
            child: state.isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: 6,
                    itemBuilder: (_, _) => const InventoryCardSkeleton(),
                  )
                : state.errorMessage != null && state.items.isEmpty
                ? Center(
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
                          "Failed to load inventory",
                          style: AppTextStyles.headingMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.errorMessage!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(batchInventoryListProvider.notifier)
                              .fetchInitial(),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text("Retry"),
                        ),
                      ],
                    ),
                  )
                : state.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 56,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No batch inventories found",
                          style: AppTextStyles.headingMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Try adjusting your search or filters",
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount:
                        state.items.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (!state.isLoadingMore &&
                          state.hasMore &&
                          index >= state.items.length - 3) {
                        Future.microtask(() {
                          ref
                              .read(batchInventoryListProvider.notifier)
                              .fetchNextPage();
                        });
                      }
                      if (index == state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        );
                      }
                      final item = state.items[index];
                      return _BatchCard(
                        item: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BatchInventoryDetailScreen(
                                batchInventoryId: item.id.toString(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _BatchCard extends StatelessWidget {
  final BatchInventoryModel item;
  final VoidCallback onTap;

  const _BatchCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
            // Header: Batch Code
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.batch?.batchCode != null &&
                            item.batch!.batchCode.isNotEmpty
                        ? item.batch!.batchCode
                        : 'Unknown Batch',
                    style: AppTextStyles.headingMedium.copyWith(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // SKU Name & SKU Code
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productSku?.skuName ?? 'Unknown SKU',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "SKU: ${item.productSku?.skuCode ?? 'N/A'}",
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quantity Chips Grid
            Row(
              children: [
                Expanded(
                  child: _QtyBadge(
                    label: "Total",
                    count: item.totalQuantity,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QtyBadge(
                    label: "Avail. ",
                    count: item.availableQuantity,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QtyBadge(
                    label: "Blocked",
                    count: item.blockedQuantity,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),

            if (item.inTransitQuantity > 0 ||
                item.damagedQuantity > 0 ||
                item.missingQuantity > 0) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final badges = <Widget>[];
                  if (item.inTransitQuantity > 0)
                    badges.add(
                      _QtyBadge(
                        label: "In Transit",
                        count: item.inTransitQuantity,
                        color: AppColors.info,
                      ),
                    );
                  if (item.damagedQuantity > 0)
                    badges.add(
                      _QtyBadge(
                        label: "Damaged",
                        count: item.damagedQuantity,
                        color: AppColors.error,
                      ),
                    );
                  if (item.missingQuantity > 0)
                    badges.add(
                      _QtyBadge(
                        label: "Missing",
                        count: item.missingQuantity,
                        color: AppColors.error,
                      ),
                    );

                  while (badges.length < 3) {
                    badges.add(const SizedBox.shrink());
                  }

                  return Row(
                    children: [
                      Expanded(child: badges[0]),
                      const SizedBox(width: 8),
                      Expanded(child: badges[1]),
                      const SizedBox(width: 8),
                      Expanded(child: badges[2]),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QtyBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _QtyBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            TextSpan(
              text: "$count",
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchFilterSheet extends StatefulWidget {
  final String? initialSkuName;
  final String? initialSkuCode;
  final String? initialBatchId;
  final bool initialAvailableOnly;
  final Function(
    String? skuName,
    String? skuCode,
    String? batchId,
    bool availableOnly,
  )
  onApply;
  final VoidCallback onReset;

  const _BatchFilterSheet({
    required this.initialSkuName,
    required this.initialSkuCode,
    required this.initialBatchId,
    required this.initialAvailableOnly,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_BatchFilterSheet> createState() => _BatchFilterSheetState();
}

class _BatchFilterSheetState extends State<_BatchFilterSheet> {
  late TextEditingController _skuNameCtrl;
  late TextEditingController _skuCodeCtrl;
  late TextEditingController _batchIdCtrl;
  late bool _availableOnly;

  @override
  void initState() {
    super.initState();
    _skuNameCtrl = TextEditingController(text: widget.initialSkuName ?? '');
    _skuCodeCtrl = TextEditingController(text: widget.initialSkuCode ?? '');
    _batchIdCtrl = TextEditingController(text: widget.initialBatchId ?? '');
    _availableOnly = widget.initialAvailableOnly;
  }

  @override
  void dispose() {
    _skuNameCtrl.dispose();
    _skuCodeCtrl.dispose();
    _batchIdCtrl.dispose();
    super.dispose();
  }

  Widget _clearSuffix(TextEditingController ctrl) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (context, value, child) {
        if (value.text.isEmpty) return const SizedBox.shrink();
        return IconButton(
          icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
          onPressed: () => ctrl.clear(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Filter Batch Inventory", style: AppTextStyles.headingLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: "SKU Name",
            controller: _skuNameCtrl,
            hint: "Enter SKU name...",
            suffix: _clearSuffix(_skuNameCtrl),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: "SKU Code",
            controller: _skuCodeCtrl,
            hint: "Enter SKU code...",
            suffix: _clearSuffix(_skuCodeCtrl),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: "Batch Code or ID",
            controller: _batchIdCtrl,
            hint: "Enter Batch code/ID...",
            suffix: _clearSuffix(_batchIdCtrl),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              "Available Inventory Only",
              style: AppTextStyles.bodyMedium,
            ),
            subtitle: Text(
              "Hide records where available quantity is 0",
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            value: _availableOnly,
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _availableOnly = val),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    widget.onReset();
                    Navigator.pop(context);
                  },
                  child: Text("Reset", style: AppTextStyles.labelMedium),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: "Apply Filters",
                  onPressed: () {
                    widget.onApply(
                      _skuNameCtrl.text.isEmpty ? null : _skuNameCtrl.text,
                      _skuCodeCtrl.text.isEmpty ? null : _skuCodeCtrl.text,
                      _batchIdCtrl.text.isEmpty ? null : _batchIdCtrl.text,
                      _availableOnly,
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
