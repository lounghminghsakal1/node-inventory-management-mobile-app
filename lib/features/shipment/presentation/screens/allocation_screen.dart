import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../data/models/shipment.dart';
import '../../data/models/order.dart';
import '../../providers/shipment_provider.dart';

class AllocationScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const AllocationScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<AllocationScreen> createState() => _AllocationScreenState();
}

class _AllocationScreenState extends ConsumerState<AllocationScreen> {
  late List<ShipmentLineItem> _items;
  bool _initialized = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final shipment = ref.watch(shipmentByIdProvider(widget.shipmentId));
    if (shipment == null) return const Scaffold();

    if (!_initialized) {
      _items = List.from(shipment.lineItems);
      _initialized = true;
    }

    final allAllocated = _items.every((i) => i.isAllocated);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: NodeOpsAppBar(
        showBack: true,
        title: 'Manage Allocations',
        extraActions: [
          TextButton.icon(
            icon: const Icon(Icons.auto_awesome_rounded,
                size: 16, color: AppColors.secondary),
            label: Text('Auto',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.secondary)),
            onPressed: _autoAllocate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                  bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Allocate inventory for each product. All must be allocated before confirming.',
                  style: AppTextStyles.caption,
                ),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                return _AllocationCard(
                  key: ValueKey(item.id),
                  item: item,
                  onAllocated: (updated) {
                    setState(() => _items[i] = updated);
                  },
                );
              },
            ),
          ),
          // Bottom confirm
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Column(
              children: [
                // Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_items.where((i) => i.isAllocated).length}/${_items.length} allocated',
                      style: AppTextStyles.bodySmall,
                    ),
                    if (allAllocated)
                      const Row(children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 16),
                        SizedBox(width: 4),
                        Text('Ready',
                            style: TextStyle(
                                color: AppColors.success, fontSize: 13)),
                      ]),
                  ],
                ),
                const SizedBox(height: 12),
                SafeArea(
                  top: false,
                  child: AppButton(
                    label: 'Confirm Allocation',
                    icon: Icons.check_rounded,
                    isLoading: _isLoading,
                    onPressed: allAllocated ? _confirmAllocation : null,
                    gradient: AppColors.greenGradient,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _autoAllocate() {
    setState(() {
      _items = _items.map((item) {
        switch (item.product.trackingType) {
          case TrackingType.batch:
            return item.copyWith(
              batchAllocations: [
                BatchAllocation(
                    batchCode: 'AUTO-${item.product.sku}-01',
                    qty: item.shippedQty),
              ],
              isAllocated: true,
            );
          case TrackingType.serial:
            return item.copyWith(
              serialNumbers:
                  dummySerialNumbers.take(item.shippedQty).toList(),
              isAllocated: true,
            );
          case TrackingType.untracked:
            return item.copyWith(isAllocated: true);
        }
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.auto_awesome_rounded,
              color: AppColors.secondary, size: 16),
          const SizedBox(width: 8),
          Text('Auto allocation applied',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
        ]),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _confirmAllocation() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(shipmentListProvider.notifier)
          .allocate(widget.shipmentId, _items);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Per-product Allocation Card ───────────────────────────────────────────────
class _AllocationCard extends StatefulWidget {
  final ShipmentLineItem item;
  final ValueChanged<ShipmentLineItem> onAllocated;

  const _AllocationCard({super.key, required this.item, required this.onAllocated});

  @override
  State<_AllocationCard> createState() => _AllocationCardState();
}

class _AllocationCardState extends State<_AllocationCard> {
  late List<BatchAllocation> _batches;
  late List<String> _selectedSerials;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _batches = List.from(widget.item.batchAllocations);
    _selectedSerials = List.from(widget.item.serialNumbers);

    if (_batches.isEmpty &&
        widget.item.product.trackingType == TrackingType.batch) {
      _batches = [BatchAllocation(batchCode: '', qty: widget.item.shippedQty)];
    }
  }

  int get _allocatedQty {
    switch (widget.item.product.trackingType) {
      case TrackingType.batch:
        return _batches.fold(0, (s, b) => s + b.qty);
      case TrackingType.serial:
        return _selectedSerials.length;
      case TrackingType.untracked:
        return widget.item.shippedQty;
    }
  }

  bool get _isComplete => _allocatedQty == widget.item.shippedQty;

  void _save() {
    final updated = widget.item.copyWith(
      batchAllocations:
          widget.item.product.trackingType == TrackingType.batch ? _batches : null,
      serialNumbers:
          widget.item.product.trackingType == TrackingType.serial ? _selectedSerials : null,
      isAllocated: _isComplete,
    );
    widget.onAllocated(updated);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isComplete ? AppColors.success.withValues(alpha: 0.4) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.category_outlined,
                          size: 18, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name,
                            style: AppTextStyles.headingSmall),
                        Text(
                          '${item.product.trackingType.label} · Need: ${item.shippedQty}  Got: $_allocatedQty',
                          style: AppTextStyles.caption.copyWith(
                            color: _isComplete
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isComplete)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20)
                  else
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ),
          ),

          // Body
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _buildAllocationBody(item),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllocationBody(ShipmentLineItem item) {
    switch (item.product.trackingType) {
      case TrackingType.batch:
        return _buildBatchAllocation();
      case TrackingType.serial:
        return _buildSerialAllocation();
      case TrackingType.untracked:
        return _buildUntrackedAllocation();
    }
  }

  // ── Batch ─────────────────────────────────────────────────────────────────
  Widget _buildBatchAllocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Batch Allocations', style: AppTextStyles.labelMedium),
        const SizedBox(height: 10),
        ..._batches.asMap().entries.map((e) {
          final i = e.key;
          final b = e.value;
          final codeCtrl = TextEditingController(text: b.batchCode);
          final qtyCtrl = TextEditingController(text: '${b.qty}');

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: codeCtrl,
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      labelText: 'Batch Code',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: (v) {
                      _batches[i] = BatchAllocation(batchCode: v, qty: _batches[i].qty);
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    style: AppTextStyles.bodySmall,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: (v) {
                      final qty = int.tryParse(v) ?? 0;
                      _batches[i] = BatchAllocation(
                          batchCode: _batches[i].batchCode, qty: qty);
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                if (_batches.length > 1)
                  GestureDetector(
                    onTap: () {
                      setState(() => _batches.removeAt(i));
                      _save();
                    },
                    child: const Icon(Icons.remove_circle_outline_rounded,
                        color: AppColors.error, size: 20),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total: $_allocatedQty / ${widget.item.shippedQty}',
              style: AppTextStyles.labelSmall.copyWith(
                color: _isComplete ? AppColors.success : AppColors.warning,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Batch'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              onPressed: () {
                setState(() =>
                    _batches.add(const BatchAllocation(batchCode: '', qty: 0)));
              },
            ),
          ],
        ),
      ],
    );
  }

  // ── Serial ────────────────────────────────────────────────────────────────
  Widget _buildSerialAllocation() {
    final needed = widget.item.shippedQty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Select Serial Numbers', style: AppTextStyles.labelMedium),
            Text(
              '${_selectedSerials.length}/$needed selected',
              style: AppTextStyles.caption.copyWith(
                color: _isComplete ? AppColors.success : AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dummySerialNumbers.map((sn) {
            final isSelected = _selectedSerials.contains(sn);
            final canSelect =
                !isSelected && _selectedSerials.length < needed;

            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  setState(() => _selectedSerials.remove(sn));
                } else if (canSelect) {
                  setState(() => _selectedSerials.add(sn));
                }
                _save();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  sn,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? AppColors.primary : (canSelect ? AppColors.textPrimary : AppColors.textMuted),
                    fontSize: 11,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Untracked ─────────────────────────────────────────────────────────────
  Widget _buildUntrackedAllocation() {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded,
            color: AppColors.success, size: 20),
        const SizedBox(width: 10),
        Text(
          '${widget.item.shippedQty} units — no tracking required',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
        ),
      ],
    );
  }
}
