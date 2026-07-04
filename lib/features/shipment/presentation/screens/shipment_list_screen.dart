import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/shipment.dart';
import '../../providers/shipment_provider.dart';
import '../widgets/shipment_card.dart';

class ShipmentListScreen extends ConsumerStatefulWidget {
  const ShipmentListScreen({super.key});

  @override
  ConsumerState<ShipmentListScreen> createState() => _ShipmentListScreenState();
}

class _ShipmentListScreenState extends ConsumerState<ShipmentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';

  final _tabs = [
    ('All', null),
    ('Created', ShipmentStatus.created),
    ('Allocated', ShipmentStatus.allocated),
    ('Invoiced', ShipmentStatus.invoiced),
    ('Dispatched', ShipmentStatus.dispatched),
    ('Delivered', ShipmentStatus.delivered),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shipmentListProvider);
    final allShipments = state.shipments;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Search + Tabs ────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: TextField(
                    style: AppTextStyles.bodyMedium,
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: 'Search by shipment ID or customer...',
                      hintStyle: AppTextStyles.bodySmall,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      fillColor: AppColors.card,
                      filled: true,
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
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                // Tabs
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
          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: _tabs.map((tab) {
          final filtered = allShipments.where((s) {
            final matchesStatus =
                tab.$2 == null || s.status == tab.$2;
            final q = _search.toLowerCase();
            final matchesSearch = q.isEmpty ||
                s.shipmentNumber.toLowerCase().contains(q) ||
                s.customerName.toLowerCase().contains(q) ||
                s.orderNumber.toLowerCase().contains(q);
            return matchesStatus && matchesSearch;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No shipments found',
                      style: AppTextStyles.headingMedium
                          .copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Text(
                    tab.$2 == null
                        ? 'Create a shipment to get started'
                        : 'No ${tab.$1.toLowerCase()} shipments',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: () async =>
                ref.read(shipmentListProvider.notifier).load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShipmentCard(
                  shipment: filtered[i],
                  onTap: () =>
                      context.push('/shipments/${filtered[i].id}'),
                ),
              ),
            ),
          );
          }).toList(),
        ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/shipments/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Create Shipment',
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
      ),
    );
  }
}
