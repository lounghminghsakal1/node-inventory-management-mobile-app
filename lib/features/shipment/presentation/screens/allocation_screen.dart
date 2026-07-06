import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/shipment.dart';
import '../../data/models/order.dart';
import '../../data/repositories/shipment_repository.dart';
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
    final asyncShipment = ref.watch(shipmentByIdProvider(widget.shipmentId));

    return asyncShipment.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: const NodeOpsAppBar(
          showBack: true,
          title: 'Manage Allocations',
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: const NodeOpsAppBar(showBack: true, title: 'Error'),
        body: Center(child: Text('Error loading shipment: $e')),
      ),
      data: (shipment) {
        if (shipment == null) return const Scaffold();

        if (!_initialized) {
          _items = List.from(shipment.lineItems);
          _initialized = true;
        }

        final allAllocated = _items.every((i) => i.isAllocated);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const NodeOpsAppBar(
            showBack: true,
            title: 'Manage Allocations',
          ),
          body: Column(
            children: [
              // Header info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Allocate inventory for each product. Select FIFO, Manual, or LIFO allocation.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_items.where((i) => i.isAllocated).length}/${_items.length} allocated',
                          style: AppTextStyles.bodySmall,
                        ),
                        if (allAllocated)
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Ready to allocate',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SafeArea(
                      top: false,
                      child: AppButton(
                        label: 'Assign Allocations',
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
      },
    );
  }

  Future<void> _confirmAllocation() async {
    setState(() => _isLoading = true);
    try {
      final payload = {
        "line_items": _items.map((item) {
          final sliId = int.tryParse(item.id) ?? 0;
          final selType = item.allocationType.toLowerCase();

          if (selType == 'fifo' || selType == 'lifo') {
            return {"shipment_line_item_id": sliId, "selection_type": selType};
          }

          final map = <String, dynamic>{
            "shipment_line_item_id": sliId,
            "selection_type": "manual",
          };

          if (item.product.trackingType == TrackingType.batch) {
            map["batch_codes"] = item.batchAllocations
                .map((b) => {"batch_code": b.batchCode, "quantity": b.qty})
                .toList();
          } else if (item.product.trackingType == TrackingType.serial) {
            map["serials"] = item.serialNumbers;
          } else if (item.product.trackingType == TrackingType.untracked) {
            map["untracked_numbers"] = item.untrackedAllocations
                .map(
                  (u) => {
                    "untracked_number": u.untrackedNumber,
                    "quantity": u.qty,
                  },
                )
                .toList();
          }
          return map;
        }),
      };

      await ref
          .read(shipmentRepositoryProvider)
          .assignShipmentAllocations(
            shipmentId: widget.shipmentId,
            payload: payload,
          );

      ref.invalidate(shipmentByIdProvider(widget.shipmentId));
      ref.invalidate(shipmentListProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Per-product Allocation Card ───────────────────────────────────────────────
class _AllocationCard extends ConsumerStatefulWidget {
  final ShipmentLineItem item;
  final ValueChanged<ShipmentLineItem> onAllocated;

  const _AllocationCard({
    super.key,
    required this.item,
    required this.onAllocated,
  });

  @override
  ConsumerState<_AllocationCard> createState() => _AllocationCardState();
}

class _AllocationCardState extends ConsumerState<_AllocationCard> {
  late List<BatchAllocation> _batches;
  late List<UntrackedAllocation> _untrackedLots;
  late List<String> _selectedSerials;
  late String _allocationType;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _batches = List.from(widget.item.batchAllocations);
    _untrackedLots = List.from(widget.item.untrackedAllocations);
    _selectedSerials = List.from(widget.item.serialNumbers);
    _allocationType = widget.item.allocationType;

    if (_allocationType == 'lifo' || _allocationType == 'fifo') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!widget.item.isAllocated) {
          _save(isAllocated: true);
        }
      });
    }
  }

  int get _allocatedQty {
    if (_allocationType == 'lifo' || _allocationType == 'fifo') {
      return widget.item.shippedQty;
    }
    switch (widget.item.product.trackingType) {
      case TrackingType.batch:
        return _batches.fold(0, (s, b) => s + b.qty);
      case TrackingType.untracked:
        return _untrackedLots.fold(0, (s, u) => s + u.qty);
      case TrackingType.serial:
        return _selectedSerials.length;
    }
  }

  bool get _isComplete {
    if (_allocationType == 'lifo' || _allocationType == 'fifo') return true;
    return _allocatedQty == widget.item.shippedQty;
  }

  void _save({bool? isAllocated}) {
    final updated = widget.item.copyWith(
      batchAllocations: _batches,
      untrackedAllocations: _untrackedLots,
      serialNumbers: _selectedSerials,
      isAllocated: isAllocated ?? _isComplete,
      allocationType: _allocationType,
    );
    widget.onAllocated(updated);
  }

  void _openBatchModal(BuildContext context, {bool isUntracked = false}) {
    final authState = ref.read(authProvider);
    final nodeIdStr = authState.node?.id ?? authState.user?.nodeId ?? '1';
    final nodeId =
        int.tryParse(nodeIdStr) ??
        int.tryParse(nodeIdStr.replaceAll(RegExp(r'[^0-9]'), '')) ??
        1;

    showDialog(
      context: context,
      builder: (_) => BatchAllocationModal(
        title: isUntracked ? 'Assign Untracked Lots' : 'Assign Batches',
        requiredQty: widget.item.shippedQty,
        unit: widget.item.product.unit,
        nodeId: nodeId,
        skuId: widget.item.product.id,
        initialAllocations: isUntracked
            ? _untrackedLots
                  .map((u) => ({'code': u.untrackedNumber, 'qty': u.qty}))
                  .toList()
            : _batches
                  .map((b) => ({'code': b.batchCode, 'qty': b.qty}))
                  .toList(),
        isUntracked: isUntracked,
        onConfirm: (newAllocations) {
          setState(() {
            if (isUntracked) {
              _untrackedLots = newAllocations
                  .map(
                    (e) => UntrackedAllocation(
                      untrackedNumber: e['code'] as String,
                      qty: e['qty'] as int,
                    ),
                  )
                  .toList();
            } else {
              _batches = newAllocations
                  .map(
                    (e) => BatchAllocation(
                      batchCode: e['code'] as String,
                      qty: e['qty'] as int,
                    ),
                  )
                  .toList();
            }
          });
          _save();
        },
      ),
    );
  }

  void _openSerialModal(BuildContext context) {
    final authState = ref.read(authProvider);
    final nodeIdStr = authState.node?.id ?? authState.user?.nodeId ?? '1';
    final nodeId =
        int.tryParse(nodeIdStr) ??
        int.tryParse(nodeIdStr.replaceAll(RegExp(r'[^0-9]'), '')) ??
        1;

    showDialog(
      context: context,
      builder: (_) => SerialAllocationModal(
        requiredQty: widget.item.shippedQty,
        nodeId: nodeId,
        skuId: widget.item.product.id,
        initialSerials: _selectedSerials,
        onConfirm: (newSerials) {
          setState(() {
            _selectedSerials = newSerials;
          });
          _save();
        },
      ),
    );
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
          color: _isComplete
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.cardBorder,
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
                      child: Icon(
                        Icons.category_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: AppTextStyles.headingSmall,
                        ),
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
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20,
                    )
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Allocation Type Dropdown
                  Row(
                    children: [
                      Text(
                        'Allocation Type: ',
                        style: AppTextStyles.labelMedium,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _allocationType,
                              dropdownColor: AppColors.surface,
                              style: AppTextStyles.bodySmall,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.primary,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'fifo',
                                  child: Text('FIFO (Default)'),
                                ),
                                DropdownMenuItem(
                                  value: 'manual',
                                  child: Text('Manual'),
                                ),
                                DropdownMenuItem(
                                  value: 'lifo',
                                  child: Text('LIFO'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null && val != _allocationType) {
                                  setState(() {
                                    _allocationType = val;
                                  });
                                  if (val == 'manual') {
                                    ref
                                        .read(shipmentRepositoryProvider)
                                        .updateAllocationTypeApi(
                                          shipmentId: widget.item.id,
                                          allocationType: val,
                                        );
                                  }
                                  if (val == 'lifo' || val == 'fifo') {
                                    _save(isAllocated: true);
                                  } else {
                                    _save(isAllocated: _isComplete);
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Content based on allocation type
                  if (_allocationType == 'lifo' ||
                      _allocationType == 'fifo') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Auto-allocated via ${_allocationType.toUpperCase()}. No batch/serial entry required.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Manual allocation UI
                    if (item.product.trackingType == TrackingType.batch) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assigned Batches',
                                  style: AppTextStyles.labelMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_batches.fold(0, (sum, b) => sum + b.qty)} / ${item.shippedQty} ${item.product.unit} assigned',
                                  style: AppTextStyles.caption.copyWith(
                                    color: _isComplete
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontWeight: _isComplete
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            width: 150,
                            height: 44,
                            label: 'Assign Batch',
                            icon: Icons.playlist_add_rounded,
                            onPressed: () => _openBatchModal(context),
                          ),
                        ],
                      ),
                    ] else if (item.product.trackingType ==
                        TrackingType.untracked) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assigned Lots',
                                  style: AppTextStyles.labelMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_untrackedLots.fold(0, (sum, u) => sum + u.qty)} / ${item.shippedQty} ${item.product.unit} assigned',
                                  style: AppTextStyles.caption.copyWith(
                                    color: _isComplete
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontWeight: _isComplete
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            width: 150,
                            height: 44,
                            label: 'Assign Lots',
                            icon: Icons.playlist_add_rounded,
                            onPressed: () =>
                                _openBatchModal(context, isUntracked: true),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assigned Serials',
                                  style: AppTextStyles.labelMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_selectedSerials.length} / ${item.shippedQty} serials assigned',
                                  style: AppTextStyles.caption.copyWith(
                                    color: _isComplete
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontWeight: _isComplete
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            width: 150,
                            height: 44,
                            label: 'Assign Serials',
                            icon: Icons.qr_code_scanner_rounded,
                            onPressed: () => _openSerialModal(context),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvailOption {
  final String code;
  final int availQty;
  final int totalQty;
  _AvailOption({
    required this.code,
    required this.availQty,
    required this.totalQty,
  });
}

// ── Batch & Untracked Allocation Modal ────────────────────────────────────────
class BatchAllocationModal extends ConsumerStatefulWidget {
  final String title;
  final int requiredQty;
  final String unit;
  final int nodeId;
  final String skuId;
  final List<Map<String, dynamic>> initialAllocations;
  final bool isUntracked;
  final ValueChanged<List<Map<String, dynamic>>> onConfirm;

  const BatchAllocationModal({
    super.key,
    required this.title,
    required this.requiredQty,
    required this.unit,
    required this.nodeId,
    required this.skuId,
    required this.initialAllocations,
    required this.isUntracked,
    required this.onConfirm,
  });

  @override
  ConsumerState<BatchAllocationModal> createState() =>
      _BatchAllocationModalState();
}

class _BatchRow {
  String code;
  int qty;
  final TextEditingController qtyCtrl;
  _BatchRow({required this.code, required this.qty})
    : qtyCtrl = TextEditingController(text: qty > 0 ? '$qty' : '');
}

class _BatchAllocationModalState extends ConsumerState<BatchAllocationModal> {
  List<_BatchRow>? _rows;

  @override
  void dispose() {
    if (_rows != null) {
      for (final r in _rows!) {
        r.qtyCtrl.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = widget.isUntracked
        ? ref.watch(
            untrackedAvailabilityProvider((
              nodeId: widget.nodeId,
              skuId: widget.skuId,
            )),
          )
        : ref.watch(
            batchAvailabilityProvider((
              nodeId: widget.nodeId,
              skuId: widget.skuId,
            )),
          );

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: asyncData.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'Error loading availability: $e',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (dataList) {
            final options = widget.isUntracked
                ? (dataList as List<UntrackedAvailabilityModel>)
                      .map(
                        (u) => _AvailOption(
                          code: u.untrackedNumber,
                          availQty: u.availableQuantity,
                          totalQty: u.totalQuantity,
                        ),
                      )
                      .toList()
                : (dataList as List<BatchAvailabilityModel>)
                      .map(
                        (b) => _AvailOption(
                          code: b.batchCode,
                          availQty: b.availableQuantity,
                          totalQty: b.totalQuantity,
                        ),
                      )
                      .toList();

            if (options.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title, style: AppTextStyles.headingMedium),
                  const SizedBox(height: 20),
                  const Text(
                    'No available inventory found for this item.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            if (_rows == null) {
              if (widget.initialAllocations.isNotEmpty &&
                  widget.initialAllocations.any(
                    (b) => (b['code']?.toString() ?? '').isNotEmpty,
                  )) {
                _rows = widget.initialAllocations.map((b) {
                  final code = b['code']?.toString() ?? '';
                  final validCode = options.any((o) => o.code == code)
                      ? code
                      : options.first.code;
                  return _BatchRow(
                    code: validCode,
                    qty: (b['qty'] as int?) ?? 0,
                  );
                }).toList();
              } else {
                final firstOpt = options.first;
                final initialQty = widget.requiredQty <= firstOpt.availQty
                    ? widget.requiredQty
                    : firstOpt.availQty;
                _rows = [_BatchRow(code: firstOpt.code, qty: initialQty)];
              }
            }

            final totalEntered = _rows!.fold(0, (sum, r) => sum + r.qty);
            final allWithinAvail = _rows!.every((r) {
              final opt = options.firstWhere(
                (o) => o.code == r.code,
                orElse: () => _AvailOption(code: '', availQty: 0, totalQty: 0),
              );
              return r.qty > 0 && r.qty <= opt.availQty;
            });
            final isValid =
                totalEntered == widget.requiredQty &&
                allWithinAvail &&
                _rows!.isNotEmpty;

            final unselected = options
                .where((opt) => !_rows!.any((r) => r.code == opt.code))
                .toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppTextStyles.headingMedium),
                const SizedBox(height: 4),
                Text(
                  'Total required: ${widget.requiredQty} ${widget.unit}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _rows!.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final row = entry.value;
                        final rowOptions = options
                            .where(
                              (opt) =>
                                  opt.code == row.code ||
                                  !_rows!.any(
                                    (r) => r != row && r.code == opt.code,
                                  ),
                            )
                            .toList();
                        final currentOpt = options.firstWhere(
                          (o) => o.code == row.code,
                          orElse: () => _AvailOption(
                            code: row.code,
                            availQty: 0,
                            totalQty: 0,
                          ),
                        );
                        final exceedsAvail = row.qty > currentOpt.availQty;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.cardBorder,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value:
                                              rowOptions.any(
                                                (o) => o.code == row.code,
                                              )
                                              ? row.code
                                              : (rowOptions.isNotEmpty
                                                    ? rowOptions.first.code
                                                    : null),
                                          dropdownColor: AppColors.card,
                                          style: AppTextStyles.caption,
                                          isExpanded: true,
                                          itemHeight: 56,
                                          selectedItemBuilder: (context) {
                                            return rowOptions.map((opt) {
                                              return Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  '${opt.code} (Avail: ${opt.availQty})',
                                                  style: AppTextStyles.caption
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList();
                                          },
                                          items: rowOptions.map((opt) {
                                            return DropdownMenuItem<String>(
                                              value: opt.code,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    opt.code,
                                                    style: AppTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                  Text(
                                                    'Total: ${opt.totalQty} | Avail: ${opt.availQty}',
                                                    style: AppTextStyles.caption
                                                        .copyWith(
                                                          color: AppColors
                                                              .textMuted,
                                                          fontSize: 11,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => row.code = val);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: row.qtyCtrl,
                                      style: AppTextStyles.bodySmall,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        labelText: 'Qty',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 10,
                                            ),
                                        filled: true,
                                        fillColor: AppColors.background,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: exceedsAvail
                                                ? AppColors.error
                                                : AppColors.cardBorder,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: exceedsAvail
                                                ? AppColors.error
                                                : AppColors.cardBorder,
                                          ),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          row.qty = int.tryParse(val) ?? 0;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (_rows!.length > 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          row.qtyCtrl.dispose();
                                          _rows!.removeAt(idx);
                                        });
                                      },
                                    ),
                                ],
                              ),
                              if (exceedsAvail)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    left: 4,
                                  ),
                                  child: Text(
                                    'Cannot exceed available quantity (${currentOpt.availQty})',
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add one row'),
                    style: TextButton.styleFrom(
                      foregroundColor: unselected.isNotEmpty
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    onPressed: unselected.isNotEmpty
                        ? () {
                            setState(() {
                              _rows!.add(
                                _BatchRow(code: unselected.first.code, qty: 0),
                              );
                            });
                          }
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total: $totalEntered / ${widget.requiredQty}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isValid ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      width: 100,
                      height: 40,
                      label: 'Confirm',
                      onPressed: isValid
                          ? () {
                              final res = _rows!
                                  .map((r) => {'code': r.code, 'qty': r.qty})
                                  .toList();
                              widget.onConfirm(res);
                              Navigator.pop(context);
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Serial Allocation Modal ───────────────────────────────────────────────────
class SerialAllocationModal extends ConsumerStatefulWidget {
  final int requiredQty;
  final int nodeId;
  final String skuId;
  final List<String> initialSerials;
  final ValueChanged<List<String>> onConfirm;

  const SerialAllocationModal({
    super.key,
    required this.requiredQty,
    required this.nodeId,
    required this.skuId,
    required this.initialSerials,
    required this.onConfirm,
  });

  @override
  ConsumerState<SerialAllocationModal> createState() =>
      _SerialAllocationModalState();
}

class _SerialAllocationModalState extends ConsumerState<SerialAllocationModal> {
  late List<String> _selected;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSerials);
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(
      serialAvailabilityProvider((nodeId: widget.nodeId, skuId: widget.skuId)),
    );

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: asyncData.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'Error loading serials: $e',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (dataList) {
            final allSerials = dataList.map((e) => e.serialNumber).toList();
            final filtered = allSerials
                .where((s) => s.toLowerCase().contains(_search.toLowerCase()))
                .toList();
            final isValid = _selected.length == widget.requiredQty;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assign Serials', style: AppTextStyles.headingMedium),
                const SizedBox(height: 4),
                Text(
                  'Select exactly ${widget.requiredQty} serial numbers',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 14),
                TextField(
                  style: AppTextStyles.bodySmall,
                  decoration: InputDecoration(
                    hintText: 'Search serials...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  onChanged: (val) => setState(() => _search = val),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                if (allSerials.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No available serials found.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: filtered.map((sn) {
                          final isSel = _selected.contains(sn);
                          final canSel =
                              !isSel && _selected.length < widget.requiredQty;

                          return FilterChip(
                            label: Text(
                              sn,
                              style: AppTextStyles.caption.copyWith(
                                color: isSel
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSel,
                            onSelected: (val) {
                              setState(() {
                                if (val && canSel) {
                                  _selected.add(sn);
                                } else if (!val) {
                                  _selected.remove(sn);
                                }
                              });
                            },
                            selectedColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            backgroundColor: AppColors.background,
                            checkmarkColor: AppColors.primary,
                            side: BorderSide(
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Selected: ${_selected.length} / ${widget.requiredQty}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isValid ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      width: 100,
                      height: 40,
                      label: 'Confirm',
                      onPressed: isValid
                          ? () {
                              widget.onConfirm(_selected);
                              Navigator.pop(context);
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
