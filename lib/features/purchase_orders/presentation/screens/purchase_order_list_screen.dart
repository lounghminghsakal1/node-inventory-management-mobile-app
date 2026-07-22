import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:node_management_app/core/widgets/back_to_home_scope.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../providers/purchase_order_provider.dart';
import '../widgets/purchase_order_card.dart';

class PurchaseOrderListScreen extends ConsumerStatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  ConsumerState<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState
    extends ConsumerState<PurchaseOrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  Timer? _debounce;

  static const _tabs = [('Pending', 'qc_pending'), ('All', null)];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) return;
      ref
          .read(purchaseOrderListProvider.notifier)
          .load(page: 1, byGrnStatus: _tabs[_tabCtrl.index].$2, byStatus: null);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseOrderListProvider);
    final allPos = state.purchaseOrders;

    return BackToHomeScope(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Search + Tabs ──────────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: AppTextStyles.bodyMedium,
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              hintText: 'Search by PO number...',
                              hintStyle: AppTextStyles.bodySmall,
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              fillColor: AppColors.card,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.cardBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.cardBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (v) {
                              setState(() => _search = v);
                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();
                              _debounce = Timer(
                                const Duration(milliseconds: 500),
                                () {
                                  ref
                                      .read(purchaseOrderListProvider.notifier)
                                      .updateFilters(
                                        byStatus: _tabs[_tabCtrl.index].$2,
                                        byPoNumber: v.trim().isEmpty
                                            ? null
                                            : v.trim(),
                                        fromDate: state.fromDate,
                                        toDate: state.toDate,
                                      );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Builder(
                          builder: (ctx) {
                            final hasFilters =
                                state.byPoNumber != null ||
                                state.fromDate != null ||
                                state.toDate != null;
                            return InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: AppColors.card,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (ctx) => _PoFilterSheet(
                                    initialPoNum: state.byPoNumber,
                                    initialFromDate: state.fromDate,
                                    initialToDate: state.toDate,
                                    onApply: (poNum, fromDate, toDate) {
                                      ref
                                          .read(
                                            purchaseOrderListProvider.notifier,
                                          )
                                          .updateFilters(
                                            byStatus: _tabs[_tabCtrl.index].$2,
                                            byPoNumber: poNum,
                                            fromDate: fromDate,
                                            toDate: toDate,
                                          );
                                    },
                                    onReset: () {
                                      _searchCtrl.clear();
                                      setState(() => _search = '');
                                      ref
                                          .read(
                                            purchaseOrderListProvider.notifier,
                                          )
                                          .clearFilters();
                                    },
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 42,
                                width: 42,
                                decoration: BoxDecoration(
                                  color: hasFilters
                                      ? AppColors.primary
                                      : AppColors.card,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: hasFilters
                                        ? AppColors.primary
                                        : AppColors.cardBorder,
                                  ),
                                ),
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: hasFilters
                                      ? Colors.white
                                      : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabCtrl,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: AppColors.cardBorder,
                    labelStyle: AppTextStyles.labelSmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
                  ),
                ],
              ),
            ),

            // ── PO List ────────────────────────────────────────────────────────
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.isLoading && !state.isMoreLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.error != null && allPos.isEmpty) {
                    return Center(
                      child: Text(
                        'Failed to load purchase orders\n${state.error}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    );
                  }

                  final filtered = allPos.toList();

                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(purchaseOrderListProvider.notifier)
                          .load(
                            page: 1,
                            byGrnStatus: _tabs[_tabCtrl.index].$2,
                            byStatus: null,
                          );
                    },
                    color: AppColors.primary,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (filtered.isNotEmpty &&
                            (notification is ScrollEndNotification ||
                                notification is ScrollUpdateNotification)) {
                          if (notification.metrics.extentAfter < 200) {
                            ref
                                .read(purchaseOrderListProvider.notifier)
                                .loadNextPage();
                          }
                        }
                        return false;
                      },
                      child: filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.receipt_long_outlined,
                                          size: 48,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _search.isNotEmpty
                                              ? 'No purchase orders matching "$_search"'
                                              : 'No purchase orders found',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  filtered.length +
                                  (state.isMoreLoading ? 1 : 0),
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                if (!state.isMoreLoading &&
                                    i >= filtered.length - 5 &&
                                    state.currentPage < state.totalPages) {
                                  Future.microtask(() {
                                    ref
                                        .read(purchaseOrderListProvider.notifier)
                                        .loadNextPage();
                                  });
                                }

                                if (i == filtered.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                }

                                final po = filtered[i];
                                return PurchaseOrderCard(
                                  po: po,
                                  onTap: () =>
                                      context.push('/purchase-orders/${po.id}'),
                                );
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoFilterSheet extends StatefulWidget {
  final String? initialPoNum;
  final String? initialFromDate;
  final String? initialToDate;
  final Function(String? poNum, String? fromDate, String? toDate) onApply;
  final VoidCallback onReset;

  const _PoFilterSheet({
    required this.initialPoNum,
    required this.initialFromDate,
    required this.initialToDate,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_PoFilterSheet> createState() => _PoFilterSheetState();
}

class _PoFilterSheetState extends State<_PoFilterSheet> {
  late TextEditingController _poCtrl;
  late TextEditingController _fromCtrl;
  late TextEditingController _toCtrl;

  @override
  void initState() {
    super.initState();
    _poCtrl = TextEditingController(text: widget.initialPoNum ?? '');
    _fromCtrl = TextEditingController(text: widget.initialFromDate ?? '');
    _toCtrl = TextEditingController(text: widget.initialToDate ?? '');
  }

  @override
  void dispose() {
    _poCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: AppColors.card,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ctrl.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filter Purchase Orders",
                  style: AppTextStyles.headingLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Text("PO Number", style: AppTextStyles.labelMedium),
            // const SizedBox(height: 8),
            // TextField(
            //   controller: _poCtrl,
            //   decoration: InputDecoration(
            //     hintText: "Enter exact PO number...",
            //     hintStyle: AppTextStyles.bodySmall,
            //     filled: true,
            //     fillColor: AppColors.surface,
            //     contentPadding: const EdgeInsets.symmetric(
            //       horizontal: 16,
            //       vertical: 12,
            //     ),
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(10),
            //       borderSide: const BorderSide(color: AppColors.cardBorder),
            //     ),
            //     enabledBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(10),
            //       borderSide: const BorderSide(color: AppColors.cardBorder),
            //     ),
            //     focusedBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(10),
            //       borderSide: const BorderSide(color: AppColors.primary),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("From Date", style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fromCtrl,
                        readOnly: true,
                        onTap: () => _selectDate(_fromCtrl),
                        decoration: InputDecoration(
                          hintText: "YYYY-MM-DD",
                          hintStyle: AppTextStyles.bodySmall,
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 16,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.cardBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.cardBorder,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("To Date", style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _toCtrl,
                        readOnly: true,
                        onTap: () => _selectDate(_toCtrl),
                        decoration: InputDecoration(
                          hintText: "YYYY-MM-DD",
                          hintStyle: AppTextStyles.bodySmall,
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 16,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.cardBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.cardBorder,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                      _poCtrl.clear();
                      _fromCtrl.clear();
                      _toCtrl.clear();
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    child: Text("Reset", style: AppTextStyles.labelMedium),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      widget.onApply(
                        _poCtrl.text.isEmpty ? null : _poCtrl.text,
                        _fromCtrl.text.isEmpty ? null : _fromCtrl.text,
                        _toCtrl.text.isEmpty ? null : _toCtrl.text,
                      );
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Apply Filters",
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
