import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/providers/order_provider.dart';
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
    ('Packed', ShipmentStatus.packed),
    ('Invoiced', ShipmentStatus.invoiced),
    ('Dispatched', ShipmentStatus.dispatched),
    ('Delivered', ShipmentStatus.delivered),
    ('Return Initiated', ShipmentStatus.returnInitiated),
    ('Return Completed', ShipmentStatus.returnCompleted),
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
                  labelStyle: AppTextStyles.labelSmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
                  final matchesStatus = tab.$2 == null || s.status == tab.$2;
                  final q = _search.toLowerCase();
                  final matchesSearch =
                      q.isEmpty ||
                      s.shipmentNumber.toLowerCase().contains(q) ||
                      s.customerName.toLowerCase().contains(q) ||
                      (s.customerId?.toLowerCase().contains(q) ?? false) ||
                      s.orderNumber.toLowerCase().contains(q);
                  return matchesStatus && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 56,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No shipments found',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
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
    );
  }
}

void showCreateShipmentThroughOrderModal(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _OrderSearchBottomSheet(ref: ref),
  );
}

class _OrderSearchBottomSheet extends StatefulWidget {
  final WidgetRef ref;
  const _OrderSearchBottomSheet({required this.ref});

  @override
  State<_OrderSearchBottomSheet> createState() =>
      _OrderSearchBottomSheetState();
}

class _OrderSearchBottomSheetState extends State<_OrderSearchBottomSheet> {
  String _searchText = '';
  List<OrderSummary> _results = [];
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _errorMessage = null;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final repo = widget.ref.read(orderRepositoryProvider);
    var res = await repo.searchOrders(query.trim());
    if (res.isEmpty) {
      final dummy = widget.ref.read(confirmedOrdersProvider);
      final q = query.trim().toLowerCase();
      final matched = dummy
          .where(
            (o) =>
                o.orderNumber.toLowerCase() == q ||
                o.orderNumber.toLowerCase().contains(q) ||
                o.id.toLowerCase().contains(q),
          )
          .toList();
      res = matched
          .map(
            (o) => OrderSummary(
              id: int.tryParse(o.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 107,
              orderNumber: o.orderNumber,
              status: 'confirmed',
              confirmedAt: o.orderDate.toIso8601String(),
              customer: OrderCustomer(id: 1, name: o.customerName, code: '1'),
              shipments: [],
            ),
          )
          .toList();
    }
    if (!mounted) return;
    if (res.isNotEmpty) {
      setState(() {
        _results = res;
        _isLoading = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _results = [];
        _isLoading = false;
        _errorMessage = 'No order found matching "${query.trim()}"';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: SizedBox(
        height: 450,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create Shipment through Order',
                  style: AppTextStyles.headingMedium,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              style: AppTextStyles.bodyMedium,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Enter Order Number (e.g. EFP-O-10107)...',
                hintStyle: AppTextStyles.bodySmall,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _doSearch(_searchText),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                fillColor: AppColors.surface,
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
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (val) {
                _searchText = val;
              },
              onSubmitted: _doSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _results.isEmpty
                  ? Center(
                      child: Text(
                        _errorMessage ??
                            'Enter an order number and click search to create a shipment.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _errorMessage != null
                              ? AppColors.error
                              : AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (ctx, i) {
                        final o = _results[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.surface,
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            o.orderNumber,
                            style: AppTextStyles.bodyMedium,
                          ),
                          subtitle: Text(
                            o.customer.name,
                            style: AppTextStyles.caption,
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textMuted,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(
                              Uri(
                                path: '/shipments/create',
                                queryParameters: {
                                  'orderId': o.id.toString(),
                                  'orderNumber': o.orderNumber,
                                  'customerName': o.customer.name,
                                },
                              ).toString(),
                            );
                          },
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
