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
    with TickerProviderStateMixin {
  late TabController _typeTabCtrl;
  late TabController _statusTabCtrl;
  String _search = '';
  String _shipmentType = 'forward_shipment';

  static const _forwardStatusTabs = [
    (
      'Pending',
      [
        ShipmentStatus.created,
        ShipmentStatus.allocated,
        ShipmentStatus.packed,
        ShipmentStatus.invoiced,
      ],
    ),
    ('Dispatched', [ShipmentStatus.dispatched]),
    ('Delivered', [ShipmentStatus.delivered]),
  ];

  static const _returnStatusTabs = [
    ('All', null),
    ('Return Initiated', [ShipmentStatus.returnInitiated]),
    ('Return Completed', [ShipmentStatus.returnCompleted]),
  ];

  List<(String, List<ShipmentStatus>?)> get _currentStatusTabs =>
      _shipmentType == 'forward_shipment'
          ? _forwardStatusTabs
          : _returnStatusTabs;

  void _onTypeTabChanged() {
    final newType =
        _typeTabCtrl.index == 0 ? 'forward_shipment' : 'reverse_shipment';
    if (_shipmentType != newType) {
      _shipmentType = newType;
      _statusTabCtrl.removeListener(_onStatusTabChanged);
      _statusTabCtrl.dispose();
      _statusTabCtrl = TabController(
        length: _currentStatusTabs.length,
        vsync: this,
      );
      _statusTabCtrl.addListener(_onStatusTabChanged);
      setState(() {});
      ref.read(shipmentListProvider.notifier).load(
            page: 1,
            byShipmentType: newType,
          );
    }
  }

  void _onStatusTabChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _typeTabCtrl = TabController(length: 2, vsync: this);
    _statusTabCtrl =
        TabController(length: _forwardStatusTabs.length, vsync: this);
    _typeTabCtrl.addListener(_onTypeTabChanged);
    _statusTabCtrl.addListener(_onStatusTabChanged);
  }

  @override
  void dispose() {
    _typeTabCtrl.removeListener(_onTypeTabChanged);
    _statusTabCtrl.removeListener(_onStatusTabChanged);
    _typeTabCtrl.dispose();
    _statusTabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_statusTabCtrl.length != _currentStatusTabs.length) {
      _statusTabCtrl.removeListener(_onStatusTabChanged);
      _statusTabCtrl.dispose();
      _statusTabCtrl = TabController(
        length: _currentStatusTabs.length,
        vsync: this,
      );
      _statusTabCtrl.addListener(_onStatusTabChanged);
    }

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
                // Type Tabs (Forward / Return)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: TabBar(
                      controller: _typeTabCtrl,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Forward'),
                        Tab(text: 'Return'),
                      ],
                    ),
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    style: AppTextStyles.bodyMedium,
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: 'Search by shipment number...',
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
                // Status Tabs
                TabBar(
                  controller: _statusTabCtrl,
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
                  tabs: _currentStatusTabs.map((t) => Tab(text: t.$1)).toList(),
                ),
              ],
            ),
          ),
          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _statusTabCtrl,
              children: _currentStatusTabs.map((tab) {
                final filtered = allShipments.where((s) {
                  final matchesStatus =
                      tab.$2 == null || tab.$2!.contains(s.status);
                  final q = _search.toLowerCase();
                  final matchesSearch =
                      q.isEmpty ||
                      s.shipmentNumber.toLowerCase().contains(q) ||
                      s.customerName.toLowerCase().contains(q) ||
                      (s.customerId?.toLowerCase().contains(q) ?? false) ||
                      s.orderNumber.toLowerCase().contains(q);
                  return matchesStatus && matchesSearch;
                }).toList();

                if (state.isLoading && filtered.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

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

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification ||
                        notification is ScrollUpdateNotification) {
                      if (notification.metrics.extentAfter < 200) {
                        ref.read(shipmentListProvider.notifier).loadNextPage();
                      }
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.card,
                    onRefresh: () async =>
                        ref.read(shipmentListProvider.notifier).load(
                              page: 1,
                              byShipmentType: _shipmentType,
                            ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length + (state.isMoreLoading ? 1 : 0),
                      itemBuilder: (_, i) {
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ShipmentCard(
                            shipment: filtered[i],
                            onTap: () =>
                                context.push('/shipments/${filtered[i].id}'),
                          ),
                        );
                      },
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
                            'Customer ID: ${o.customer.id}',
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
                                  'customerName': 'Customer ID: ${o.customer.id}',
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
