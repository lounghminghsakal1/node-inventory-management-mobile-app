import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';

  static const _tabs = [
    ('All', null),
    ('Confirmed', 'confirmed'),
    ('Partially Delivered', 'partially_delivered'),
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
    final async = ref.watch(orderListProvider);

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
                      hintText: 'Search by order number or customer...',
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

          // ── Content ────────────────────────────────────────────────────────
          Expanded(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Failed to load orders',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(orderListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (orders) => TabBarView(
                controller: _tabCtrl,
                children: _tabs.map((tab) {
                  final filtered = orders.where((o) {
                    final matchStatus =
                        tab.$2 == null || o.status == tab.$2;
                    final q = _search.toLowerCase();
                    final matchSearch = q.isEmpty ||
                        o.orderNumber.toLowerCase().contains(q) ||
                        o.customer.name.toLowerCase().contains(q) ||
                        o.customer.code.toLowerCase().contains(q);
                    return matchStatus && matchSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 56, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text('No orders found',
                              style: AppTextStyles.headingMedium
                                  .copyWith(color: AppColors.textMuted)),
                          if (tab.$2 != null) ...[
                            const SizedBox(height: 8),
                            Text('No ${tab.$1.toLowerCase()} orders',
                                style: AppTextStyles.bodySmall),
                          ],
                        ],
                      ),
                    );
                  }

                  final isLoadingMore = ref.watch(orderListLoadingMoreProvider);
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.card,
                    onRefresh: () async =>
                        ref.invalidate(orderListProvider),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification &&
                            notification.metrics.extentAfter < 200) {
                          ref.read(orderListProvider.notifier).loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == filtered.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OrderCard(
                              order: filtered[i],
                              onTap: () =>
                                  context.push('/orders/${filtered[i].id}'),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final OrderSummary order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  static const int _kPreviewCount = 3;

  Color _statusColor(String s) => switch (s) {
        'confirmed' => AppColors.success,
        'partially_delivered' => AppColors.warning,
        'delivered' => AppColors.accentGreen,
        'cancelled' => AppColors.error,
        _ => AppColors.textMuted,
      };

  String _statusLabel(String s) => s
      .split('_')
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  Color _shipmentStatusColor(String s) => switch (s) {
        'created' => AppColors.primary,
        'allocated' || 'invoiced' => AppColors.secondary,
        'dispatched' => const Color(0xFF00B4D8),
        'delivered' => AppColors.success,
        'return_initiated' || 'return_in_transit' => AppColors.warning,
        'return_completed' => AppColors.accentGreen,
        'cancelled' => AppColors.error,
        _ => AppColors.textMuted,
      };

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year},'
          ' ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final shipments = order.shipments;
    final visibleShipments =
        _expanded ? shipments : shipments.take(_kPreviewCount).toList();
    final hasMore = shipments.length > _kPreviewCount;
    final extraCount = shipments.length - _kPreviewCount;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order number + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          order.orderNumber,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(
                        label: _statusLabel(order.status),
                        color: _statusColor(order.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Customer
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        order.customer.name,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${order.customer.code}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Confirmed date
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(order.confirmedAt),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Shipments section ─────────────────────────────────────────
            if (shipments.isNotEmpty) ...[
              const Divider(height: 1, color: AppColors.cardBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${shipments.length} Shipment${shipments.length == 1 ? '' : 's'}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...visibleShipments.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: GestureDetector(
                            onTap: () => context.push('/shipments/${s.shipmentNumber}'),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                const Icon(Icons.local_shipping_outlined,
                                    size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    s.shipmentNumber,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                _StatusPill(
                                  label: _statusLabel(s.status),
                                  color: _shipmentStatusColor(s.status),
                                  small: true,
                                ),
                              ],
                            ),
                          ),
                        )),
                    if (hasMore)
                      GestureDetector(
                        onTap: () {
                          setState(() => _expanded = !_expanded);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _expanded
                                    ? 'Show less'
                                    : 'View $extraCount more',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                _expanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              const Divider(height: 1, color: AppColors.cardBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Text(
                  'No shipments yet',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Reusable status pill ──────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;

  const _StatusPill({
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 9,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: small ? 9.5 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
