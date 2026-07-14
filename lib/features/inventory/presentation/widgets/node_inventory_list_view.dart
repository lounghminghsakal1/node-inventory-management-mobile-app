import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/node_inventory_model.dart';
import '../../providers/inventory_provider.dart';
import '../screens/node_inventory_detail_screen.dart';

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

  void _openFilterSheet(NodeInventoryListState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NodeInventoryFilterSheet(
        initialSkuName: state.bySkuName,
        initialSkuCode: state.bySkuCode,
        initialSkuId: state.bySkuId,
        initialAvailableOnly: state.availableOnly,
        onApply: (skuName, skuCode, skuId, availOnly) {
          ref.read(nodeInventoryListProvider.notifier).updateFilters(
                bySkuName: skuName,
                bySkuCode: skuCode,
                bySkuId: skuId,
                availableOnly: availOnly,
              );
        },
        onReset: () {
          ref.read(nodeInventoryListProvider.notifier).clearFilters();
          _searchController.clear();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeInventoryListProvider);

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
                    hintText: "Search by SKU Name or Code...",
                    hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(nodeInventoryListProvider.notifier).updateFilters(bySkuName: '', bySkuCode: '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    ref.read(nodeInventoryListProvider.notifier).updateFilters(bySkuName: val.trim());
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
                    color: (state.bySkuCode != null || state.bySkuId != null || !state.availableOnly)
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (state.bySkuCode != null || state.bySkuId != null || !state.availableOnly)
                          ? AppColors.primary
                          : AppColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: (state.bySkuCode != null || state.bySkuId != null || !state.availableOnly)
                        ? Colors.white
                        : AppColors.textMuted,
                    size: 22,
                  ),
                ),
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

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NodeInventoryDetailScreen(inventoryId: item.id.toString()),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                ],
              ),
              const SizedBox(height: 16),

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
                  Expanded(
                    child: _buildQtyBox('Missing', item.missingQuantity, AppColors.error),
                  ),
                ],
              ),

              if (trackingType == 'batch' || trackingType == 'serial') ...[
                const SizedBox(height: 16),
                Divider(color: AppColors.cardBorder.withValues(alpha: 0.5), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
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
                ),
              ],
            ],
          ),
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


class _NodeInventoryFilterSheet extends StatefulWidget {
  final String? initialSkuName;
  final String? initialSkuCode;
  final String? initialSkuId;
  final bool initialAvailableOnly;
  final Function(String? skuName, String? skuCode, String? skuId, bool availableOnly) onApply;
  final VoidCallback onReset;

  const _NodeInventoryFilterSheet({
    required this.initialSkuName,
    required this.initialSkuCode,
    required this.initialSkuId,
    required this.initialAvailableOnly,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_NodeInventoryFilterSheet> createState() => _NodeInventoryFilterSheetState();
}

class _NodeInventoryFilterSheetState extends State<_NodeInventoryFilterSheet> {
  late TextEditingController _skuNameCtrl;
  late TextEditingController _skuCodeCtrl;
  late TextEditingController _skuIdCtrl;
  late bool _availableOnly;

  @override
  void initState() {
    super.initState();
    _skuNameCtrl = TextEditingController(text: widget.initialSkuName ?? '');
    _skuCodeCtrl = TextEditingController(text: widget.initialSkuCode ?? '');
    _skuIdCtrl = TextEditingController(text: widget.initialSkuId ?? '');
    _availableOnly = widget.initialAvailableOnly;
  }

  @override
  void dispose() {
    _skuNameCtrl.dispose();
    _skuCodeCtrl.dispose();
    _skuIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Filter Node Inventory", style: AppTextStyles.headingLarge),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(label: "SKU Name", controller: _skuNameCtrl, hint: "Enter SKU name..."),
          const SizedBox(height: 12),
          AppTextField(label: "SKU Code", controller: _skuCodeCtrl, hint: "Enter SKU code..."),
          const SizedBox(height: 12),
          AppTextField(label: "SKU ID", controller: _skuIdCtrl, hint: "Enter SKU ID..."),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text("Available Inventory Only", style: AppTextStyles.bodyMedium),
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
                  onPressed: () {
                    widget.onReset();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Reset", style: AppTextStyles.labelLarge),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      _skuNameCtrl.text.trim().isEmpty ? null : _skuNameCtrl.text.trim(),
                      _skuCodeCtrl.text.trim().isEmpty ? null : _skuCodeCtrl.text.trim(),
                      _skuIdCtrl.text.trim().isEmpty ? null : _skuIdCtrl.text.trim(),
                      _availableOnly,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Apply Filters", style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
