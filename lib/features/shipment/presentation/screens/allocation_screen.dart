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
      appBar: const NodeOpsAppBar(
        showBack: true,
        title: 'Manage Allocations',
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
                  'Allocate inventory for each product. Select LIFO, FIFO, or Manual allocation.',
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
  late String _allocationType;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _batches = List.from(widget.item.batchAllocations);
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
      case TrackingType.untracked:
        return _batches.fold(0, (s, b) => s + b.qty);
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
      serialNumbers: _selectedSerials,
      isAllocated: isAllocated ?? _isComplete,
      allocationType: _allocationType,
    );
    widget.onAllocated(updated);
  }

  void _openBatchModal(BuildContext context, {bool isUntracked = false}) {
    showDialog(
      context: context,
      builder: (_) => _BatchAllocationModal(
        title: isUntracked ? 'Assign Untracked Lots' : 'Assign Batches',
        requiredQty: widget.item.shippedQty,
        unit: widget.item.product.unit,
        initialBatches: _batches,
        isUntracked: isUntracked,
        onConfirm: (newBatches) {
          setState(() {
            _batches = newBatches;
          });
          _save();
        },
      ),
    );
  }

  void _openSerialModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _SerialAllocationModal(
        requiredQty: widget.item.shippedQty,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Allocation Type Dropdown
                  Row(
                    children: [
                      Text('Allocation Type: ',
                          style: AppTextStyles.labelMedium),
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
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: AppColors.primary),
                              items: const [
                                DropdownMenuItem(
                                    value: 'lifo', child: Text('LIFO (Default)')),
                                DropdownMenuItem(
                                    value: 'fifo', child: Text('FIFO')),
                                DropdownMenuItem(
                                    value: 'manual', child: Text('Manual')),
                              ],
                              onChanged: (val) {
                                if (val != null && val != _allocationType) {
                                  setState(() {
                                    _allocationType = val;
                                  });
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
                  if (_allocationType == 'lifo' || _allocationType == 'fifo') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 16, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Auto-allocated via ${_allocationType.toUpperCase()}. No batch/serial entry required.',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.secondary),
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
                                Text('Assigned Batches', style: AppTextStyles.labelMedium),
                                const SizedBox(height: 2),
                                Text(
                                  '${_batches.fold(0, (sum, b) => sum + b.qty)} / ${item.shippedQty} ${item.product.unit} assigned',
                                  style: AppTextStyles.caption.copyWith(
                                    color: _isComplete ? AppColors.success : AppColors.warning,
                                    fontWeight: _isComplete ? FontWeight.bold : FontWeight.normal,
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
                    ] else if (item.product.trackingType == TrackingType.untracked) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Assigned Lots', style: AppTextStyles.labelMedium),
                                const SizedBox(height: 2),
                                Text(
                                  '${_batches.fold(0, (sum, b) => sum + b.qty)} / ${item.shippedQty} ${item.product.unit} assigned',
                                  style: AppTextStyles.caption.copyWith(
                                    color: _isComplete ? AppColors.success : AppColors.warning,
                                    fontWeight: _isComplete ? FontWeight.bold : FontWeight.normal,
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
                            onPressed: () => _openBatchModal(context, isUntracked: true),
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
                                Text('Assigned Serials', style: AppTextStyles.labelMedium),
                                const SizedBox(height: 2),
                                Text(
                                  '${_selectedSerials.length} / ${item.shippedQty} serials assigned',
                                  style: AppTextStyles.caption.copyWith(
                                    color: _isComplete ? AppColors.success : AppColors.warning,
                                    fontWeight: _isComplete ? FontWeight.bold : FontWeight.normal,
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

// ── Batch & Untracked Allocation Modal ────────────────────────────────────────
class _BatchAllocationModal extends StatefulWidget {
  final String title;
  final int requiredQty;
  final String unit;
  final List<BatchAllocation> initialBatches;
  final bool isUntracked;
  final ValueChanged<List<BatchAllocation>> onConfirm;

  const _BatchAllocationModal({
    required this.title,
    required this.requiredQty,
    required this.unit,
    required this.initialBatches,
    required this.isUntracked,
    required this.onConfirm,
  });

  @override
  State<_BatchAllocationModal> createState() => _BatchAllocationModalState();
}

class _BatchRow {
  String code;
  int qty;
  final TextEditingController qtyCtrl;
  _BatchRow({required this.code, required this.qty})
      : qtyCtrl = TextEditingController(text: qty > 0 ? '$qty' : '');
}

class _BatchAllocationModalState extends State<_BatchAllocationModal> {
  late List<_BatchRow> _rows;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    if (widget.isUntracked) {
      _options = [
        'UNTRACKED-A (Avail: 150)',
        'UNTRACKED-B (Avail: 100)',
        'UNTRACKED-C (Avail: 80)',
        'UNTRACKED-D (Avail: 200)',
      ];
    } else {
      _options = [
        'B-2024-01 (Avail: 150)',
        'B-2024-02 (Avail: 100)',
        'B-2024-03 (Avail: 80)',
        'B-2024-04 (Avail: 200)',
        'B-2024-05 (Avail: 50)',
      ];
    }

    if (widget.initialBatches.isNotEmpty && widget.initialBatches.any((b) => b.batchCode.isNotEmpty)) {
      _rows = widget.initialBatches
          .map((b) => _BatchRow(code: b.batchCode.isEmpty ? _options.first : b.batchCode, qty: b.qty))
          .toList();
    } else {
      _rows = [_BatchRow(code: _options.first, qty: widget.requiredQty)];
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.qtyCtrl.dispose();
    }
    super.dispose();
  }

  int get _totalEntered => _rows.fold(0, (sum, r) => sum + r.qty);
  bool get _isValid => _totalEntered == widget.requiredQty;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppTextStyles.headingMedium),
            const SizedBox(height: 4),
            Text('Total required: ${widget.requiredQty} ${widget.unit}',
                style: AppTextStyles.caption),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Column(
                  children: _rows.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final row = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _options.contains(row.code) ? row.code : _options.first,
                                  dropdownColor: AppColors.card,
                                  style: AppTextStyles.caption,
                                  isExpanded: true,
                                  items: _options.map((opt) {
                                    return DropdownMenuItem(
                                        value: opt, child: Text(opt));
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
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: AppColors.cardBorder),
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
                          if (_rows.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppColors.error, size: 20),
                              onPressed: () {
                                setState(() {
                                  row.qtyCtrl.dispose();
                                  _rows.removeAt(idx);
                                });
                              },
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
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                onPressed: () {
                  setState(() {
                    _rows.add(_BatchRow(code: _options.first, qty: 0));
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total: $_totalEntered / ${widget.requiredQty}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _isValid ? AppColors.success : AppColors.error,
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
                  onPressed: _isValid
                      ? () {
                          final res = _rows
                              .map((r) => BatchAllocation(
                                  batchCode: r.code, qty: r.qty))
                              .toList();
                          widget.onConfirm(res);
                          Navigator.pop(context);
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Serial Allocation Modal ───────────────────────────────────────────────────
class _SerialAllocationModal extends StatefulWidget {
  final int requiredQty;
  final List<String> initialSerials;
  final ValueChanged<List<String>> onConfirm;

  const _SerialAllocationModal({
    required this.requiredQty,
    required this.initialSerials,
    required this.onConfirm,
  });

  @override
  State<_SerialAllocationModal> createState() => _SerialAllocationModalState();
}

class _SerialAllocationModalState extends State<_SerialAllocationModal> {
  late List<String> _selected;
  late List<String> _allSerials;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSerials);
    _allSerials = List.generate(50, (i) => 'SN-2024-${1001 + i}');
  }

  bool get _isValid => _selected.length == widget.requiredQty;

  @override
  Widget build(BuildContext context) {
    final filtered = _allSerials
        .where((s) => s.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign Serials', style: AppTextStyles.headingMedium),
            const SizedBox(height: 4),
            Text('Select exactly ${widget.requiredQty} serial numbers',
                style: AppTextStyles.caption),
            const SizedBox(height: 14),
            TextField(
              style: AppTextStyles.bodySmall,
              decoration: InputDecoration(
                hintText: 'Search serials...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filtered.map((sn) {
                    final isSel = _selected.contains(sn);
                    final canSel = !isSel && _selected.length < widget.requiredQty;

                    return FilterChip(
                      label: Text(sn, style: AppTextStyles.caption.copyWith(
                        color: isSel ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      )),
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
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      backgroundColor: AppColors.background,
                      checkmarkColor: AppColors.primary,
                      side: BorderSide(
                        color: isSel ? AppColors.primary : AppColors.cardBorder,
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
                      color: _isValid ? AppColors.success : AppColors.error,
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
                  onPressed: _isValid
                      ? () {
                          widget.onConfirm(_selected);
                          Navigator.pop(context);
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
