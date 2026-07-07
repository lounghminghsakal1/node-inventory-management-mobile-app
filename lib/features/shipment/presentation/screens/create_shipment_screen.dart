import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../orders/providers/order_provider.dart';
import '../../data/models/order.dart';
import '../../data/models/shippable_line_item.dart';
import '../../providers/shipment_provider.dart';

class CreateShipmentScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final String? orderNumber;
  final String? customerName;
  const CreateShipmentScreen({
    super.key,
    this.orderId,
    this.orderNumber,
    this.customerName,
  });

  @override
  ConsumerState<CreateShipmentScreen> createState() =>
      _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends ConsumerState<CreateShipmentScreen> {
  Order? _selectedOrder;
  // Map of oliId -> qty to ship
  final Map<int, int> _selectedQtys = {};
  // Map of oliId -> is selected
  final Map<int, bool> _selectedItems = {};

  int _step = 0; // 0 = select order, 1 = select items

  int get _nodeIdInt {
    final authState = ref.read(authProvider);
    final nodeIdStr = authState.node?.id ?? authState.user?.nodeId ?? '1';
    final parsed = int.tryParse(nodeIdStr);
    if (parsed != null) return parsed;
    final digits = nodeIdStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 1;
  }

  int get _orderIdInt {
    if (_selectedOrder == null) return 0;
    final idStr = _selectedOrder!.id;
    final parsed = int.tryParse(idStr);
    if (parsed != null) return parsed;
    final digits = idStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

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
                orderNumber: widget.orderNumber ??
                    (widget.orderId!.startsWith('EFP')
                        ? widget.orderId!
                        : 'EFP-O-10${widget.orderId}'),
                customerName: widget.customerName ?? 'SaiFlaerhomes',
                customerId: 'cust_9',
                orderDate: DateTime.now(),
                lineItems: [],
              ),
            );
            setState(() {
              _selectedOrder = order;
              _step = 1;
              _selectedItems.clear();
              _selectedQtys.clear();
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

  // ── Step 2: Item selection from shippable line items API ───────────────────
  Widget _buildItemSelector(bool isLoading) {
    final order = _selectedOrder!;
    final shippableAsync = ref.watch(
      shippableLineItemsProvider((nodeId: _nodeIdInt, orderId: _orderIdInt)),
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
            Expanded(
              child: Text(
                '${order.orderNumber} — ${order.customerName}',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ]),
        ),
        Expanded(
          child: shippableAsync.when(
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
                  Text('Failed to load shippable items',
                      style: AppTextStyles.headingSmall),
                  const SizedBox(height: 4),
                  Text(e.toString().replaceFirst('Exception: ', ''),
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    onPressed: () => ref.invalidate(
                      shippableLineItemsProvider(
                          (nodeId: _nodeIdInt, orderId: _orderIdInt)),
                    ),
                  ),
                ],
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('No shippable items found',
                          style: AppTextStyles.headingMedium
                              .copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text('All items for this order may already be shipped.',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                );
              }

              final anySelected = items.any((li) {
                final isChecked =
                    _selectedItems[li.oliId] ?? (li.maxShippable > 0);
                final qty = _selectedQtys[li.oliId] ?? li.maxShippable;
                return isChecked && qty > 0 && li.maxShippable > 0;
              });

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.card,
                      onRefresh: () async {
                        ref.invalidate(shippableLineItemsProvider(
                            (nodeId: _nodeIdInt, orderId: _orderIdInt)));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final li = items[i];
                          final isChecked = _selectedItems[li.oliId] ??
                              (li.maxShippable > 0);
                          final currentQty =
                              (_selectedQtys[li.oliId] ?? li.maxShippable)
                                  .clamp(1, li.maxShippable > 0 ? li.maxShippable : 1);

                          return _buildShippableItemCard(li, isChecked, currentQty);
                        },
                      ),
                    ),
                  ),
                  _buildBottomBar(
                    label: 'Create Shipment',
                    enabled: anySelected && !isLoading,
                    isLoading: isLoading,
                    onTap: () => _createShipment(items),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShippableItemCard(
      ShippableLineItem li, bool isChecked, int currentQty) {
    final canShip = li.maxShippable > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: canShip
            ? (isChecked ? AppColors.card : AppColors.card.withValues(alpha: 0.6))
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canShip && isChecked
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.cardBorder,
          width: canShip && isChecked ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: canShip ? isChecked : false,
                activeColor: AppColors.primary,
                checkColor: Colors.white,
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                onChanged: canShip
                    ? (v) {
                        setState(() {
                          _selectedItems[li.oliId] = v ?? false;
                        });
                      }
                    : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(li.skuName, style: AppTextStyles.headingSmall),
                    const SizedBox(height: 2),
                    Text('SKU: ${li.skuCode}', style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (li.lineItemType != null && li.lineItemType!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    li.lineItemType!.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Quantity & Inventory Stats Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _statItem('Ordered', '${li.orderedQuantity}',
                          AppColors.textSecondary),
                    ),
                    Expanded(
                      child: _statItem('Shipped', '${li.shippedQuantity}',
                          AppColors.textSecondary),
                    ),
                    Expanded(
                      child: _statItem(
                        'Remaining',
                        '${li.remainingQuantity}',
                        li.remainingQuantity > 0
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.warehouse_outlined,
                      size: 14,
                      color: li.nodeInventory.availableQuantity >= li.remainingQuantity
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Text('Node Inventory Available: ',
                        style: AppTextStyles.caption),
                    Text(
                      '${li.nodeInventory.availableQuantity}',
                      style: AppTextStyles.caption.copyWith(
                        color: li.nodeInventory.availableQuantity >=
                                li.remainingQuantity
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Stepper & Max shippable row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!canShip)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    li.remainingQuantity == 0
                        ? 'Fully Shipped'
                        : 'Out of Stock at Node',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.warning),
                  ),
                )
              else ...[
                Text(
                  'Max shippable: ${li.maxShippable}',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
                if (isChecked)
                  _QtyStepper(
                    value: currentQty,
                    max: li.maxShippable,
                    onChanged: (v) =>
                        setState(() => _selectedQtys[li.oliId] = v),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _createShipment(List<ShippableLineItem> allItems) async {
    final selectedItemsToShip = <Map<String, dynamic>>[];
    for (final li in allItems) {
      final isChecked = _selectedItems[li.oliId] ?? (li.maxShippable > 0);
      if (isChecked && li.maxShippable > 0) {
        final qty = _selectedQtys[li.oliId] ?? li.maxShippable;
        if (qty > 0) {
          selectedItemsToShip.add({
            "order_line_item_id": li.oliId,
            "quantity": qty,
          });
        }
      }
    }

    if (selectedItemsToShip.isEmpty) return;

    try {
      await ref.read(shipmentListProvider.notifier).createShipmentApi(
            orderId: _orderIdInt,
            nodeId: _nodeIdInt,
            lineItems: selectedItemsToShip,
          );

      // Invalidate providers so UI is refreshed
      ref.invalidate(orderDetailProvider(_orderIdInt));
      ref.invalidate(orderListProvider);
      ref.invalidate(shipmentListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipment created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        if (widget.orderId != null && context.canPop()) {
          context.pop();
        } else {
          context.pushReplacement('/orders/$_orderIdInt');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: AppColors.error,
          ),
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
