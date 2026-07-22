import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/serial_inventory_model.dart';
import '../../providers/inventory_provider.dart';
import '../screens/serial_inventory_detail_screen.dart';
import 'inventory_card_skeleton.dart';

class SerialInventoryListView extends ConsumerStatefulWidget {
  const SerialInventoryListView({super.key});

  @override
  ConsumerState<SerialInventoryListView> createState() =>
      _SerialInventoryListViewState();
}

class _SerialInventoryListViewState
    extends ConsumerState<SerialInventoryListView> {
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
      ref.read(serialInventoryListProvider.notifier).fetchNextPage();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchBySkuItemNumber(String v) {
    final trimmed = v.trim();
    final state = ref.read(serialInventoryListProvider);
    ref
        .read(serialInventoryListProvider.notifier)
        .updateFilters(
          bySkuItemNumber: trimmed.isEmpty ? null : trimmed,
          bySkuName: state.bySkuName,
          bySkuCode: state.bySkuCode,
          byStatus: state.byStatus,
        );
  }

  void _openFilterSheet(SerialInventoryListState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SerialFilterSheet(
        initialSerialNum: state.bySkuItemNumber,
        initialSkuName: state.bySkuName,
        initialSkuCode: state.bySkuCode,
        initialStatus: state.byStatus,
        onApply: (serialNum, skuName, skuCode, status) {
          ref
              .read(serialInventoryListProvider.notifier)
              .updateFilters(
                bySkuItemNumber: serialNum,
                bySkuName: skuName,
                bySkuCode: skuCode,
                byStatus: status,
              );
        },
        onReset: () {
          ref.read(serialInventoryListProvider.notifier).clearFilters();
          _searchController.clear();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serialInventoryListProvider);
    final hasFilters =
        state.byStatus != 'all' ||
        state.bySkuItemNumber != null ||
        state.bySkuCode != null ||
        state.bySkuName != null;

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
                    hintText: "Search serial number or SKU...",
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
                                serialInventoryListProvider,
                              );
                              ref
                                  .read(serialInventoryListProvider.notifier)
                                  .updateFilters(
                                    bySkuItemNumber: null,
                                    bySkuName: null,
                                    bySkuCode: state.bySkuCode,
                                    byStatus: state.byStatus,
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
                    _searchBySkuItemNumber(val);
                  },
                  onChanged: (v) {
                    setState(() {}); // refresh suffix clear-icon visibility
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 500),
                      () => _searchBySkuItemNumber(v),
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
                  .read(serialInventoryListProvider.notifier)
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
                          "Failed to load serial inventory",
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
                              .read(serialInventoryListProvider.notifier)
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
                          Icons.qr_code_2_rounded,
                          size: 56,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No serial items found",
                          style: AppTextStyles.headingMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Try adjusting your search or status filter",
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
                              .read(serialInventoryListProvider.notifier)
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
                      return _SerialCard(
                        item: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SerialInventoryDetailScreen(
                                serialItemId: item.id.toString(),
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

class _SerialCard extends StatelessWidget {
  final SerialInventoryModel item;
  final VoidCallback onTap;

  const _SerialCard({required this.item, required this.onTap});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_stock':
      case 'instock':
        return AppColors.success;
      case 'dispatched':
      case 'delivered':
        return AppColors.info;
      case 'in_transit':
      case 'intransit':
      case 'allocated':
        return AppColors.warning;
      case 'damaged':
      case 'missing':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(item.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Serial Number & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.qr_code_2_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.skuItemNumber,
                      style: AppTextStyles.headingMedium.copyWith(
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    item.status.replaceAll('_', ' ').toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // SKU Info
            Text(
              item.productSku?.skuName ?? 'Unknown SKU',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: "SKU: ${item.productSku?.skuCode ?? 'N/A'}"),
                  if (item.currentTransaction != null)
                    TextSpan(
                      text:
                          item.currentTransaction!.transactionReferenceType ==
                              'GoodsReceivedNote'
                          ? "  •  Ref: GRN - ${item.currentTransaction!.transactionReferenceId ?? 'N/A'}"
                          : "  •  Ref: ${item.currentTransaction!.transactionReferenceType} - ${item.currentTransaction!.transactionReferenceId ?? 'N/A'}",
                    ),
                ],
              ),
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SerialFilterSheet extends StatefulWidget {
  final String? initialSerialNum;
  final String? initialSkuName;
  final String? initialSkuCode;
  final String initialStatus;
  final Function(
    String? serialNum,
    String? skuName,
    String? skuCode,
    String status,
  )
  onApply;
  final VoidCallback onReset;

  const _SerialFilterSheet({
    required this.initialSerialNum,
    required this.initialSkuName,
    required this.initialSkuCode,
    required this.initialStatus,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_SerialFilterSheet> createState() => _SerialFilterSheetState();
}

class _SerialFilterSheetState extends State<_SerialFilterSheet> {
  late TextEditingController _serialCtrl;
  late TextEditingController _skuNameCtrl;
  late TextEditingController _skuCodeCtrl;
  late String _status;

  final List<String> _statuses = [
    'all',
    'in_stock',
    'dispatched',
    'in_transit',
    'allocated',
    'damaged',
  ];

  @override
  void initState() {
    super.initState();
    _serialCtrl = TextEditingController(text: widget.initialSerialNum ?? '');
    _skuNameCtrl = TextEditingController(text: widget.initialSkuName ?? '');
    _skuCodeCtrl = TextEditingController(text: widget.initialSkuCode ?? '');
    _status = widget.initialStatus;
  }

  @override
  void dispose() {
    _serialCtrl.dispose();
    _skuNameCtrl.dispose();
    _skuCodeCtrl.dispose();
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
              Text(
                "Filter Serial Inventory",
                style: AppTextStyles.headingLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: "Serial Number",
            controller: _serialCtrl,
            hint: "Enter exact/partial serial number...",
            suffix: _clearSuffix(_serialCtrl),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Text("Status", style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((s) {
                final isSelected = _status == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s.replaceAll('_', ' ').toUpperCase()),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: AppColors.surface,
                    onSelected: (selected) {
                      if (selected) setState(() => _status = s);
                    },
                  ),
                );
              }).toList(),
            ),
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
                      _serialCtrl.text.isEmpty ? null : _serialCtrl.text,
                      _skuNameCtrl.text.isEmpty ? null : _skuNameCtrl.text,
                      _skuCodeCtrl.text.isEmpty ? null : _skuCodeCtrl.text,
                      _status,
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
