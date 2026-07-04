import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../data/models/order.dart';
import '../../providers/shipment_provider.dart';

class CreateShipmentScreen extends ConsumerStatefulWidget {
  final String? orderId;
  const CreateShipmentScreen({super.key, this.orderId});

  @override
  ConsumerState<CreateShipmentScreen> createState() =>
      _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends ConsumerState<CreateShipmentScreen> {
  Order? _selectedOrder;
  // Map of product id -> qty to ship
  final Map<String, int> _selectedQtys = {};
  // Map of product id -> is selected
  final Map<String, bool> _selectedItems = {};

  int _step = 0; // 0 = select order, 1 = select items

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_selectedOrder == null && mounted) {
          final orders = ref.read(confirmedOrdersProvider);
          try {
            final order = orders.firstWhere(
              (o) =>
                  o.id == widget.orderId ||
                  o.orderNumber == widget.orderId ||
                  o.id == 'ord_${widget.orderId}' ||
                  o.orderNumber.contains(widget.orderId!),
              orElse: () => Order(
                id: widget.orderId!,
                orderNumber: widget.orderId!.startsWith('EFP')
                    ? widget.orderId!
                    : 'EFP-O-10${widget.orderId}',
                customerName: 'SaiFlaerhomes',
                customerId: 'cust_9',
                orderDate: DateTime.now(),
                lineItems: [
                  OrderLineItem(
                      id: 'li_fb_1',
                      product: dummyProducts[5],
                      orderedQty: 20),
                  OrderLineItem(
                      id: 'li_fb_2',
                      product: dummyProducts[6],
                      orderedQty: 30),
                  OrderLineItem(
                      id: 'li_fb_3',
                      product: dummyProducts[7],
                      orderedQty: 1),
                ],
              ),
            );
            setState(() {
              _selectedOrder = order;
              _step = 1;
              _selectedItems.clear();
              _selectedQtys.clear();
              for (final li in order.lineItems) {
                _selectedItems[li.product.id] = true;
                _selectedQtys[li.product.id] = li.orderedQty;
              }
            });
          } catch (_) {}
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shipmentListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: NodeOpsAppBar(
        showBack: true,
        title: _step == 0 ? 'Select Order' : 'Select Items',
        extraActions: _step == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      size: 20, color: AppColors.textSecondary),
                  tooltip: 'Back to orders',
                  onPressed: () => setState(() => _step = 0),
                ),
              ]
            : [],
      ),
      body: _step == 0
          ? _buildOrderList()
          : _buildItemSelector(state.isLoading),
    );
  }

  // ── Step 1: Order selection ─────────────────────────────────────────────────
  Widget _buildOrderList() {
    final orders = ref.read(confirmedOrdersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIndicator(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final order = orders[i];
              final isSelected = _selectedOrder?.id == order.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedOrder = order;
                    _selectedItems.clear();
                    _selectedQtys.clear();
                    // Pre-select all items
                    for (final li in order.lineItems) {
                      _selectedItems[li.product.id] = true;
                      _selectedQtys[li.product.id] = li.orderedQty;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.cardBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(order.orderNumber,
                                style: AppTextStyles.headingMedium),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 20),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.storefront_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 5),
                        Text(order.customerName,
                            style: AppTextStyles.bodySmall),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: order.lineItems.map((li) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${li.product.name.split(' ').first} × ${li.orderedQty}',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primary),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildBottomBar(
          label: 'Next: Select Items',
          enabled: _selectedOrder != null,
          onTap: () => setState(() => _step = 1),
        ),
      ],
    );
  }

  // ── Step 2: Item selection with qty and node stock ─────────────────────────
  Widget _buildItemSelector(bool isLoading) {
    final order = _selectedOrder!;
    final anySelected =
        _selectedItems.values.any((v) => v) &&
        _selectedItems.entries.where((e) => e.value).every(
          (e) => (_selectedQtys[e.key] ?? 0) > 0,
        );

    return Column(
      children: [
        _stepIndicator(),
        // Order header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.receipt_long_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('${order.orderNumber} — ${order.customerName}',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primary)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: order.lineItems.length,
            itemBuilder: (_, i) {
              final li = order.lineItems[i];
              final isChecked = _selectedItems[li.product.id] ?? false;
              final nodeStock = li.product.nodeStock;
              final maxAllowedQty =
                  li.orderedQty < nodeStock ? li.orderedQty : nodeStock;
              final currentQty = (_selectedQtys[li.product.id] ?? li.orderedQty)
                  .clamp(1, maxAllowedQty > 0 ? maxAllowedQty : 1);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isChecked
                      ? AppColors.card
                      : AppColors.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isChecked
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: AppColors.primary,
                          checkColor: Colors.white,
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) {
                            setState(() {
                              _selectedItems[li.product.id] = v ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(li.product.name,
                                  style: AppTextStyles.headingSmall),
                              Text(li.product.sku,
                                  style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        // Tracking type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            li.product.trackingType.label,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Stock + qty row
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        // Node stock
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.warehouse_outlined,
                                    size: 12,
                                    color: nodeStock >= li.orderedQty
                                        ? AppColors.success
                                        : AppColors.warning),
                                const SizedBox(width: 4),
                                Text('Node Stock: ',
                                    style: AppTextStyles.caption),
                                Text(
                                  '$nodeStock ${li.product.unit}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: nodeStock >= li.orderedQty
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ]),
                              Text(
                                'Ordered: ${li.orderedQty} ${li.product.unit} (Max allowed: $maxAllowedQty)',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        // Qty stepper
                        if (isChecked) ...[
                          _QtyStepper(
                            value: currentQty,
                            max: maxAllowedQty,
                            onChanged: (v) => setState(
                                () => _selectedQtys[li.product.id] = v),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildBottomBar(
          label: 'Create Shipment',
          enabled: anySelected && !isLoading,
          isLoading: isLoading,
          onTap: _createShipment,
        ),
      ],
    );
  }

  Future<void> _createShipment() async {
    final order = _selectedOrder!;
    final selected = order.lineItems
        .where((li) => _selectedItems[li.product.id] == true)
        .map((li) => (
              product: li.product,
              qty: _selectedQtys[li.product.id] ?? li.orderedQty,
            ))
        .toList();

    try {
      final shipment = await ref
          .read(shipmentListProvider.notifier)
          .createShipment(order: order, selectedItems: selected);

      if (mounted) {
        context.pushReplacement('/shipments/${shipment.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _stepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          _stepDot(1, _step >= 0, 'Select Order'),
          _stepLine(),
          _stepDot(2, _step >= 1, 'Choose Items'),
          _stepLine(),
          _stepDot(3, false, 'Create'),
        ],
      ),
    );
  }

  Widget _stepDot(int n, bool active, String label) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? AppColors.primary : AppColors.cardBorder,
            ),
          ),
          child: Center(
            child: Text(
              '$n',
              style: TextStyle(
                color: active ? Colors.white : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _stepLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: AppColors.cardBorder,
      ),
    );
  }

  Widget _buildBottomBar({
    required String label,
    required bool enabled,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          label: label,
          onPressed: enabled ? onTap : null,
          isLoading: isLoading,
          icon: Icons.arrow_forward_rounded,
        ),
      ),
    );
  }
}

// ── Qty Stepper ───────────────────────────────────────────────────────────────
class _QtyStepper extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _QtyStepper(
      {required this.value, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove_rounded, value > 1,
              () => onChanged((value - 1).clamp(1, max))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$value',
              style: AppTextStyles.headingMedium
                  .copyWith(color: AppColors.primary),
            ),
          ),
          _btn(Icons.add_rounded, value < max,
              () => onChanged((value + 1).clamp(1, max))),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}
