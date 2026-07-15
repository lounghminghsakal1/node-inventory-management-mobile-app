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
import "../../../../core/widgets/back_to_home_scope.dart";

class ShipmentListScreen extends ConsumerStatefulWidget {
  const ShipmentListScreen({super.key});

  @override
  ConsumerState<ShipmentListScreen> createState() => _ShipmentListScreenState();
}

class _ShipmentListScreenState extends ConsumerState<ShipmentListScreen>
    with TickerProviderStateMixin {
  late TabController _typeTabCtrl;
  late TabController _statusTabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
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
    ('Return Initiated', [ShipmentStatus.returnInitiated]),
    ('Return Completed', [ShipmentStatus.returnCompleted]),
  ];

  List<(String, List<ShipmentStatus>?)> get _currentStatusTabs =>
      _shipmentType == 'forward_shipment'
      ? _forwardStatusTabs
      : _returnStatusTabs;

  void _onTypeTabChanged() {
    final newType = _typeTabCtrl.index == 0
        ? 'forward_shipment'
        : 'reverse_shipment';
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
      ref
          .read(shipmentListProvider.notifier)
          .load(page: 1, byShipmentType: newType);
    }
  }

  void _onStatusTabChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _typeTabCtrl = TabController(length: 2, vsync: this);
    _statusTabCtrl = TabController(
      length: _forwardStatusTabs.length,
      vsync: this,
    );
    _typeTabCtrl.addListener(_onTypeTabChanged);
    _statusTabCtrl.addListener(_onStatusTabChanged);
  }

  @override
  void dispose() {
    _typeTabCtrl.removeListener(_onTypeTabChanged);
    _statusTabCtrl.removeListener(_onStatusTabChanged);
    _typeTabCtrl.dispose();
    _statusTabCtrl.dispose();
    _searchCtrl.dispose();
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

    return BackToHomeScope(
      child: Scaffold(
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
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: AppTextStyles.bodyMedium,
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              hintText: 'Search by shipment number...',
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
                            onSubmitted: (v) {
                              ref
                                  .read(shipmentListProvider.notifier)
                                  .updateFilters(
                                    byShipmentNumber: v.trim().isEmpty
                                        ? null
                                        : v.trim(),
                                    byStatus: state.byStatus,
                                    byOrderNumber: state.byOrderNumber,
                                    fromDate: state.fromDate,
                                    toDate: state.toDate,
                                  );
                            },
                            onChanged: (v) => setState(
                              () => _search = v,
                            ), // Keep local search for text
                          ),
                        ),
                        const SizedBox(width: 12),
                        Builder(
                          builder: (ctx) {
                            final hasFilters =
                                state.byOrderNumber != null ||
                                state.fromDate != null ||
                                state.toDate != null ||
                                state.bySkuName != null ||
                                state.bySkuCode != null;
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
                                  builder: (ctx) => _ShipmentFilterSheet(
                                    initialOrderNum: state.byOrderNumber,
                                    initialSkuName: state.bySkuName,
                                    initialSkuCode: state.bySkuCode,
                                    initialFromDate: state.fromDate,
                                    initialToDate: state.toDate,
                                    onApply:
                                        (
                                          orderNum,
                                          skuName,
                                          skuCode,
                                          fromDate,
                                          toDate,
                                        ) {
                                          ref
                                              .read(
                                                shipmentListProvider.notifier,
                                              )
                                              .updateFilters(
                                                byOrderNumber: orderNum,
                                                byShipmentNumber:
                                                    state.byShipmentNumber,
                                                bySkuName: skuName,
                                                bySkuCode: skuCode,
                                                fromDate: fromDate,
                                                toDate: toDate,
                                              );
                                        },
                                    onReset: () {
                                      _searchCtrl.clear();
                                      setState(() => _search = '');
                                      ref
                                          .read(shipmentListProvider.notifier)
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
                    tabs: _currentStatusTabs
                        .map((t) => Tab(text: t.$1))
                        .toList(),
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

                  if (state.isLoading && !state.isMoreLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
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
                          ref
                              .read(shipmentListProvider.notifier)
                              .loadNextPage();
                        }
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.card,
                      onRefresh: () async => ref
                          .read(shipmentListProvider.notifier)
                          .load(page: 1, byShipmentType: _shipmentType),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            filtered.length + (state.isMoreLoading ? 1 : 0),
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
                                  'customerName':
                                      'Customer ID: ${o.customer.id}',
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

class _ShipmentFilterSheet extends StatefulWidget {
  final String? initialOrderNum;
  final String? initialSkuName;
  final String? initialSkuCode;
  final String? initialFromDate;
  final String? initialToDate;
  final Function(
    String? orderNum,
    String? skuName,
    String? skuCode,
    String? fromDate,
    String? toDate,
  )
  onApply;
  final VoidCallback onReset;

  const _ShipmentFilterSheet({
    required this.initialOrderNum,
    required this.initialSkuName,
    required this.initialSkuCode,
    required this.initialFromDate,
    required this.initialToDate,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_ShipmentFilterSheet> createState() => _ShipmentFilterSheetState();
}

class _ShipmentFilterSheetState extends State<_ShipmentFilterSheet> {
  late TextEditingController _orderCtrl;
  late TextEditingController _skuNameCtrl;
  late TextEditingController _skuCodeCtrl;
  late TextEditingController _fromCtrl;
  late TextEditingController _toCtrl;

  @override
  void initState() {
    super.initState();
    _orderCtrl = TextEditingController(text: widget.initialOrderNum ?? '');
    _skuNameCtrl = TextEditingController(text: widget.initialSkuName ?? '');
    _skuCodeCtrl = TextEditingController(text: widget.initialSkuCode ?? '');
    _fromCtrl = TextEditingController(text: widget.initialFromDate ?? '');
    _toCtrl = TextEditingController(text: widget.initialToDate ?? '');
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _skuNameCtrl.dispose();
    _skuCodeCtrl.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Filter Shipments", style: AppTextStyles.headingLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text("Order Number", style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _orderCtrl,
            decoration: InputDecoration(
              hintText: "Enter exact order number...",
              hintStyle: AppTextStyles.bodySmall,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
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
          ),
          const SizedBox(height: 12),
          Text("SKU Name", style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _skuNameCtrl,
            decoration: InputDecoration(
              hintText: "Enter SKU name...",
              hintStyle: AppTextStyles.bodySmall,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
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
          ),
          const SizedBox(height: 12),
          Text("SKU Code", style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _skuCodeCtrl,
            decoration: InputDecoration(
              hintText: "Enter SKU code...",
              hintStyle: AppTextStyles.bodySmall,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
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
          ),
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
                        suffixIcon: const Icon(Icons.calendar_today, size: 16),
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
                        suffixIcon: const Icon(Icons.calendar_today, size: 16),
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
                    _orderCtrl.clear();
                    _skuNameCtrl.clear();
                    _skuCodeCtrl.clear();
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
                      _orderCtrl.text.isEmpty ? null : _orderCtrl.text,
                      _skuNameCtrl.text.isEmpty ? null : _skuNameCtrl.text,
                      _skuCodeCtrl.text.isEmpty ? null : _skuCodeCtrl.text,
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
    );
  }
}
