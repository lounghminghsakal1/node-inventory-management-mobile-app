import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../data/models/shipment.dart';
import '../../data/models/order.dart';
import '../../data/repositories/shipment_repository.dart';
import '../../providers/shipment_provider.dart';

class _ReturnLineItemState {
  final String lineItemId;
  final String name;
  final String sku;
  final String trackingType; // 'batch', 'serial', 'untracked'
  final int totalQty;
  int goodQty;
  int badQty;

  List<Map<String, dynamic>> goodBatches;
  List<Map<String, dynamic>> badBatches;
  List<String> goodSerials;
  List<String> badSerials;
  List<Map<String, dynamic>> goodUntracked;
  List<Map<String, dynamic>> badUntracked;

  final List<Map<String, dynamic>> availableBatches;
  final List<String> availableSerials;
  final List<Map<String, dynamic>> availableUntracked;

  _ReturnLineItemState({
    required this.lineItemId,
    required this.name,
    required this.sku,
    required this.trackingType,
    required this.totalQty,
    required this.goodQty,
    required this.badQty,
    this.goodBatches = const [],
    this.badBatches = const [],
    this.goodSerials = const [],
    this.badSerials = const [],
    this.goodUntracked = const [],
    this.badUntracked = const [],
    this.availableBatches = const [],
    this.availableSerials = const [],
    this.availableUntracked = const [],
  });

  int get goodAllocatedSum {
    if (trackingType == 'batch') {
      return goodBatches.fold(0, (sum, item) => sum + (int.tryParse(item['quantity'].toString()) ?? 0));
    } else if (trackingType == 'serial') {
      return goodSerials.length;
    } else {
      return goodUntracked.fold(0, (sum, item) => sum + (int.tryParse(item['quantity'].toString()) ?? 0));
    }
  }

  int get badAllocatedSum {
    if (trackingType == 'batch') {
      return badBatches.fold(0, (sum, item) => sum + (int.tryParse(item['quantity'].toString()) ?? 0));
    } else if (trackingType == 'serial') {
      return badSerials.length;
    } else {
      return badUntracked.fold(0, (sum, item) => sum + (int.tryParse(item['quantity'].toString()) ?? 0));
    }
  }

  bool get isValid {
    if (goodQty + badQty != totalQty) return false;
    if (goodQty > 0 && goodAllocatedSum != goodQty) return false;
    if (badQty > 0 && badAllocatedSum != badQty) return false;
    return true;
  }
}

class GoodBadAllocationScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  final Shipment? shipment;

  const GoodBadAllocationScreen({
    super.key,
    required this.shipmentId,
    this.shipment,
  });

  @override
  ConsumerState<GoodBadAllocationScreen> createState() => _GoodBadAllocationScreenState();
}

class _GoodBadAllocationScreenState extends ConsumerState<GoodBadAllocationScreen> {
  List<_ReturnLineItemState>? _items;
  bool _isSubmitting = false;

  void _initItems(List<Map<String, dynamic>> infoList) {
    if (_items != null) return;
    final list = <_ReturnLineItemState>[];

    for (final item in infoList) {
      final liId = item['shipment_line_item_id']?.toString() ?? '';
      final totalQty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      
      final batchesList = (item['allocated_batches'] is List) ? (item['allocated_batches'] as List) : [];
      final availableBatches = batchesList.whereType<Map>().map((b) => Map<String, dynamic>.from(b)).toList();

      final serialsList = (item['allocated_serials'] is List) ? (item['allocated_serials'] as List) : [];
      final availableSerials = serialsList.map((s) => s.toString()).toList();

      final untrackedList = (item['allocated_untracked'] is List) ? (item['allocated_untracked'] as List) : [];
      final availableUntracked = untrackedList.whereType<Map>().map((u) => Map<String, dynamic>.from(u)).toList();

      String trackingType = 'untracked';
      if (availableBatches.isNotEmpty) trackingType = 'batch';
      if (availableSerials.isNotEmpty) trackingType = 'serial';

      String name = 'Return Item';
      String sku = 'SKU-$liId';
      if (widget.shipment != null) {
        final match = widget.shipment!.lineItems.firstWhere(
          (li) => li.id.toString() == liId,
          orElse: () => ShipmentLineItem(
            id: liId,
            product: Product(id: '', name: 'Return Item', sku: 'SKU', trackingType: TrackingType.untracked, nodeStock: 0),
            shippedQty: totalQty,
          ),
        );
        name = match.product.name;
        sku = match.product.sku;
        if (match.product.trackingType == TrackingType.batch) trackingType = 'batch';
        if (match.product.trackingType == TrackingType.serial) trackingType = 'serial';
        if (match.product.trackingType == TrackingType.untracked) trackingType = 'untracked';
      }

      list.add(_ReturnLineItemState(
        lineItemId: liId,
        name: name,
        sku: sku,
        trackingType: trackingType,
        totalQty: totalQty,
        goodQty: totalQty,
        badQty: 0,
        availableBatches: availableBatches,
        availableSerials: availableSerials,
        availableUntracked: availableUntracked,
      ));
    }
    _items = list;
  }

  bool get _allValid => _items != null && _items!.isNotEmpty && _items!.every((i) => i.isValid);

  Future<void> _submit() async {
    if (!_allValid || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final lineItemsPayload = _items!.map((item) {
        final gMap = <String, dynamic>{};
        final bMap = <String, dynamic>{};

        if (item.trackingType == 'batch') {
          gMap['batch'] = item.goodBatches.map((b) => {
            'batch_code': b['batch_code'],
            'quantity': b['quantity'],
          }).toList();
          bMap['batch'] = item.badBatches.map((b) => {
            'batch_code': b['batch_code'],
            'quantity': b['quantity'],
          }).toList();
        } else if (item.trackingType == 'serial') {
          gMap['serial'] = item.goodSerials;
          bMap['serial'] = item.badSerials;
        } else {
          gMap['untracked'] = item.goodUntracked.map((u) => {
            'untracked_number': u['untracked_number'],
            'quantity': u['quantity'],
          }).toList();
          bMap['untracked'] = item.badUntracked.map((u) => {
            'untracked_number': u['untracked_number'],
            'quantity': u['quantity'],
          }).toList();
        }

        return {
          'shipment_line_item_id': int.tryParse(item.lineItemId) ?? item.lineItemId,
          'good_quantity': item.goodQty,
          'bad_quality_quantity': item.badQty,
          'good': gMap,
          'bad': bMap,
        };
      }).toList();

      final payload = {'line_items': lineItemsPayload};

      await ref.read(shipmentRepositoryProvider).completeReturn(
        shipmentId: widget.shipmentId,
        payload: payload,
      );

      ref.invalidate(shipmentByIdProvider(widget.shipmentId));
      ref.invalidate(shipmentListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return completed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/shipments');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showBatchOrUntrackedDialog(_ReturnLineItemState item, bool isGood) {
    final isBatch = item.trackingType == 'batch';
    final targetQty = isGood ? item.goodQty : item.badQty;
    final availablePool = isBatch ? item.availableBatches : item.availableUntracked;
    final currentList = isGood
        ? (isBatch ? item.goodBatches : item.goodUntracked)
        : (isBatch ? item.badBatches : item.badUntracked);

    final idKey = isBatch ? 'batch_code' : 'untracked_number';

    List<Map<String, dynamic>> rows = currentList.isEmpty
        ? [ {idKey: availablePool.isNotEmpty ? availablePool.first[idKey] : '', 'quantity': targetQty} ]
        : currentList.map((e) => Map<String, dynamic>.from(e)).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            int currentSum = rows.fold(0, (sum, r) => sum + (int.tryParse(r['quantity'].toString()) ?? 0));
            final selectedIds = rows.map((r) => r[idKey]?.toString() ?? '').toSet();

            return AlertDialog(
              title: Text(
                isGood ? 'Select Good ${isBatch ? "Batches" : "Untracked"}' : 'Select Bad ${isBatch ? "Batches" : "Untracked"}',
                style: AppTextStyles.headingSmall,
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Quantity: $targetQty',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ...rows.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final row = entry.value;
                        final rowId = row[idKey]?.toString() ?? '';

                        final availableOptions = availablePool.where((poolItem) {
                          final pId = poolItem[idKey]?.toString() ?? '';
                          return pId == rowId || !selectedIds.contains(pId);
                        }).toList();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: rowId.isEmpty && availableOptions.isNotEmpty ? availableOptions.first[idKey]?.toString() : rowId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(labelText: 'Select Item', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  items: availableOptions.map((opt) {
                                    final optId = opt[idKey]?.toString() ?? '';
                                    return DropdownMenuItem(value: optId, child: Text(optId, style: AppTextStyles.bodySmall));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => row[idKey] = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  initialValue: row['quantity']?.toString() ?? '0',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Qty', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      row['quantity'] = int.tryParse(val) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              if (rows.length > 1) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                  onPressed: () {
                                    setDialogState(() => rows.removeAt(idx));
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      if (selectedIds.length < availablePool.length)
                        TextButton.icon(
                          onPressed: () {
                            final nextOpt = availablePool.firstWhere(
                              (p) => !selectedIds.contains(p[idKey]?.toString()),
                              orElse: () => {idKey: ''},
                            );
                            if ((nextOpt[idKey]?.toString() ?? '').isNotEmpty) {
                              setDialogState(() {
                                int rem = targetQty - currentSum;
                                rows.add({idKey: nextOpt[idKey], 'quantity': rem > 0 ? rem : 1});
                              });
                            }
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add another row'),
                        ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Entered:', style: AppTextStyles.bodySmall),
                          Text(
                            '$currentSum / $targetQty',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: currentSum == targetQty ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: currentSum == targetQty && rows.every((r) => (int.tryParse(r['quantity'].toString()) ?? 0) > 0)
                      ? () {
                          setState(() {
                            if (isGood) {
                              if (isBatch) item.goodBatches = rows; else item.goodUntracked = rows;
                            } else {
                              if (isBatch) item.badBatches = rows; else item.badUntracked = rows;
                            }
                          });
                          Navigator.pop(ctx);
                        }
                      : null,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSerialDialog(_ReturnLineItemState item, bool isGood) {
    final targetQty = isGood ? item.goodQty : item.badQty;
    final currentSet = (isGood ? item.goodSerials : item.badSerials).toSet();
    final otherSet = (isGood ? item.badSerials : item.goodSerials).toSet();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isGood ? 'Select Good Serials' : 'Select Bad Serials',
                style: AppTextStyles.headingSmall,
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target Quantity: $targetQty', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ...item.availableSerials.map((sn) {
                        final inOther = otherSet.contains(sn);
                        final isChecked = currentSet.contains(sn);

                        return CheckboxListTile(
                          title: Text(sn, style: AppTextStyles.bodySmall.copyWith(color: inOther ? AppColors.textDisabled : null)),
                          subtitle: inOther ? Text('Selected in ${isGood ? "Bad" : "Good"}', style: AppTextStyles.caption.copyWith(color: AppColors.error)) : null,
                          value: isChecked,
                          enabled: !inOther,
                          onChanged: inOther ? null : (val) {
                            setDialogState(() {
                              if (val == true) {
                                if (currentSet.length < targetQty) currentSet.add(sn);
                              } else {
                                currentSet.remove(sn);
                              }
                            });
                          },
                        );
                      }),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Selected:', style: AppTextStyles.bodySmall),
                          Text(
                            '${currentSet.length} / $targetQty',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: currentSet.length == targetQty ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: currentSet.length == targetQty
                      ? () {
                          setState(() {
                            if (isGood) item.goodSerials = currentSet.toList(); else item.badSerials = currentSet.toList();
                          });
                          Navigator.pop(ctx);
                        }
                      : null,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(returnAllocationInfoProvider(widget.shipmentId));

    return Scaffold(
      appBar: const NodeOpsAppBar(
        showBack: true,
        title: 'Return Allocation',
      ),
      body: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load return allocation info', style: AppTextStyles.headingSmall),
                const SizedBox(height: 8),
                Text(err.toString(), style: AppTextStyles.caption, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(returnAllocationInfoProvider(widget.shipmentId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (infoList) {
          _initItems(infoList);
          if (_items == null || _items!.isEmpty) {
            return const Center(child: Text('No return items found.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items!.length,
                  itemBuilder: (context, index) {
                    final item = _items![index];
                    final isGoodValid = item.goodQty == 0 || item.goodAllocatedSum == item.goodQty;
                    final isBadValid = item.badQty == 0 || item.badAllocatedSum == item.badQty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: AppTextStyles.headingSmall),
                                    Text('${item.sku} · ${item.trackingType.toUpperCase()}', style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Total: ${item.totalQty}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Good Qty Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      initialValue: item.goodQty.toString(),
                                      keyboardType: TextInputType.number,
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                                      decoration: InputDecoration(
                                        labelText: 'Good Qty',
                                        labelStyle: const TextStyle(color: AppColors.success),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.success, width: 1.5)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.success, width: 2)),
                                      ),
                                      onChanged: (val) {
                                        final g = int.tryParse(val) ?? 0;
                                        setState(() {
                                          item.goodQty = g;
                                          item.badQty = (item.totalQty - g).clamp(0, item.totalQty);
                                        });
                                      },
                                    ),
                                    if (item.goodQty > 0) ...[
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => item.trackingType == 'serial' ? _showSerialDialog(item, true) : _showBatchOrUntrackedDialog(item, true),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                          child: Row(
                                            children: [
                                              Icon(isGoodValid ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 16, color: isGoodValid ? AppColors.success : AppColors.primary),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Select ${item.trackingType} (${item.goodAllocatedSum}/${item.goodQty})',
                                                  style: AppTextStyles.caption.copyWith(
                                                    color: isGoodValid ? AppColors.success : AppColors.primary,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Bad Qty Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      key: ValueKey('bad_${item.lineItemId}_${item.badQty}'),
                                      initialValue: item.badQty.toString(),
                                      keyboardType: TextInputType.number,
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
                                      decoration: InputDecoration(
                                        labelText: 'Bad Qty',
                                        labelStyle: const TextStyle(color: AppColors.error),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 2)),
                                      ),
                                      onChanged: (val) {
                                        final b = int.tryParse(val) ?? 0;
                                        setState(() {
                                          item.badQty = b;
                                          item.goodQty = (item.totalQty - b).clamp(0, item.totalQty);
                                        });
                                      },
                                    ),
                                    if (item.badQty > 0) ...[
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => item.trackingType == 'serial' ? _showSerialDialog(item, false) : _showBatchOrUntrackedDialog(item, false),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                          child: Row(
                                            children: [
                                              Icon(isBadValid ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 16, color: isBadValid ? AppColors.success : AppColors.error),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Select ${item.trackingType} (${item.badAllocatedSum}/${item.badQty})',
                                                  style: AppTextStyles.caption.copyWith(
                                                    color: isBadValid ? AppColors.success : AppColors.error,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (!item.isValid) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.goodQty + item.badQty != item.totalQty
                                  ? '* Good + Bad quantity must equal Total Quantity (${item.totalQty})'
                                  : '* Please select exact batch/serial/untracked quantities for Good and Bad items.',
                              style: AppTextStyles.caption.copyWith(color: AppColors.error, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _allValid && !_isSubmitting ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Return Complete'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
