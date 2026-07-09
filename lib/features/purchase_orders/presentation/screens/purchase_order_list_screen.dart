import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String _search = '';

  static const _tabs = [
    ('All', null),
    ('Approved', 'approved'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) return;
      ref.read(purchaseOrderListProvider.notifier).load(
            page: 1,
            byStatus: _tabs[_tabCtrl.index].$2,
          );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseOrderListProvider);
    final allPos = state.purchaseOrders;

    return Scaffold(
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
                  child: TextField(
                    style: AppTextStyles.bodyMedium,
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: 'Search by PO number or vendor...',
                      hintStyle: AppTextStyles.bodySmall,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      fillColor: AppColors.card,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
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
                  labelStyle: AppTextStyles.labelSmall
                      .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
                ),
              ],
            ),
          ),

          // ── PO List ────────────────────────────────────────────────────────
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading && allPos.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null && allPos.isEmpty) {
                  return Center(
                    child: Text('Failed to load purchase orders\n${state.error}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                  );
                }

                final statusFilter = _tabs[_tabCtrl.index].$2;
                final filtered = allPos.where((po) {
                  if (statusFilter != null &&
                      po.status.toLowerCase() != statusFilter) {
                    return false;
                  }
                  if (_search.isNotEmpty) {
                    final q = _search.toLowerCase();
                    return po.purchaseOrderNumber.toLowerCase().contains(q) ||
                        po.vendor.firmName.toLowerCase().contains(q) ||
                        po.vendor.code.toLowerCase().contains(q);
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          _search.isNotEmpty
                              ? 'No purchase orders matching "$_search"'
                              : 'No purchase orders found',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification ||
                        notification is ScrollUpdateNotification) {
                      if (notification.metrics.extentAfter < 200) {
                        ref.read(purchaseOrderListProvider.notifier).loadNextPage();
                      }
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () async =>
                        ref.read(purchaseOrderListProvider.notifier).load(
                              page: 1,
                              byStatus: _tabs[_tabCtrl.index].$2,
                            ),
                    color: AppColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length + (state.isMoreLoading ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        if (i == filtered.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
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
    );
  }
}
