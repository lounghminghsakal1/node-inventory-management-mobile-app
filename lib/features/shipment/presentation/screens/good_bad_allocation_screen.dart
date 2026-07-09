import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/tracking_type_badge.dart';
import '../../data/models/shipment.dart';
import '../../data/repositories/shipment_repository.dart';
import '../../providers/shipment_provider.dart';

class _ReturnLineItemState {
  final String lineItemId;
  final int productSkuId;
  final String name;
  final String sku;
  final String trackingType; // 'batch', 'serial', 'none'
  final int returnedQuantity;
  int goodQty;
  int badQty;

  late final TextEditingController goodCtrl;
  late final TextEditingController badCtrl;

  List<Map<String, dynamic>> goodBatches;
  List<Map<String, dynamic>> badBatches;
  List<String> goodSerials;
  List<String> badSerials;

  final List<Map<String, dynamic>> availableBatches;
  final List<String> availableSerials;

  _ReturnLineItemState({
    required this.lineItemId,
    required this.productSkuId,
    required this.name,
    required this.sku,
    required this.trackingType,
    required this.returnedQuantity,
    required this.goodQty,
    required this.badQty,
    this.availableBatches = const [],
    this.availableSerials = const [],
  })  : goodBatches = [],
        badBatches = [],
        goodSerials = [],
        badSerials = [] {
    goodCtrl = TextEditingController(text: goodQty.toString());
    badCtrl = TextEditingController(text: badQty.toString());
  }

  void dispose() {
    goodCtrl.dispose();
    badCtrl.dispose();
  }

  int get goodAllocatedSum {
    if (trackingType == 'batch') {
      return goodBatches.fold(0, (sum, item) => sum + (int.tryParse(item['quantity'].toString()) ?? 0));
    } else if (trackingType == 'serial') {
      return goodSerials.length;
    } else {
      return goodQty;
    }
  }

  int get badAllocatedSum {
    if (trackingType == 'batch') {
      return badBatches.fold(0, (sum, item) => sum + (int.tryParse(item['quantity'].toString()) ?? 0));
    } else if (trackingType == 'serial') {
      return badSerials.length;
    } else {
      return badQty;
    }
  }

  bool get isValid {
    if (goodQty + badQty != returnedQuantity) return false;
    if (trackingType == 'batch' || trackingType == 'serial') {
      if (goodQty > 0 && goodAllocatedSum != goodQty) return false;
      if (badQty > 0 && badAllocatedSum != badQty) return false;
    }
    return true;
  }
}

class _BatchDialogRowState {
  String batchCode;
  int quantity;
  final TextEditingController qtyCtrl;

  _BatchDialogRowState({required this.batchCode, required this.quantity})
      : qtyCtrl = TextEditingController(text: quantity > 0 ? quantity.toString() : '');

  void dispose() {
    qtyCtrl.dispose();
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

  @override
  void dispose() {
    final itemsToDispose = _items;
    super.dispose();
    if (itemsToDispose != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        for (final item in itemsToDispose) {
          item.dispose();
        }
      });
    }
  }

  void _initItems(List<Map<String, dynamic>> infoList, Shipment? shipment) {
    if (_items != null) return;
    final list = <_ReturnLineItemState>[];

    for (final item in infoList) {
      final liId = item['shipment_line_item_id']?.toString() ?? '';
      final productSkuId = int.tryParse(item['product_sku_id']?.toString() ?? '0') ?? (item['product_sku_id'] is int ? item['product_sku_id'] as int : 0);
      final skuName = item['sku_name']?.toString() ?? 'Return Item';
      final skuCode = item['sku_code']?.toString() ?? '';
      final rawType = item['tracking_type']?.toString() ?? 'none';

      int returnedQuantity = 0;
      if (shipment != null && shipment.lineItems.isNotEmpty) {
        ShipmentLineItem? matchedLi;
        for (final li in shipment.lineItems) {
          if ((liId.isNotEmpty && li.id == liId) ||
              (productSkuId > 0 && int.tryParse(li.product.id) == productSkuId) ||
              li.product.name == skuName ||
              li.product.sku == skuCode) {
            matchedLi = li;
            break;
          }
        }
        if (matchedLi == null) {
          // Show only line items that are part of this return shipment's details page
          continue;
        }
        returnedQuantity = matchedLi.shippedQty;
      } else {
        returnedQuantity = int.tryParse(item['returned_quantity']?.toString() ?? '0') ??
                           (int.tryParse(item['remaining_quantity']?.toString() ?? '0') ?? 0);
        if (returnedQuantity == 0 && rawType == 'batch' && item['remaining_batch_codes'] is Map) {
          final map = item['remaining_batch_codes'] as Map;
          returnedQuantity = map.values.fold(0, (sum, v) => sum + (int.tryParse(v.toString()) ?? 0));
        } else if (returnedQuantity == 0 && rawType == 'serial' && item['remaining_serials'] is List) {
          returnedQuantity = (item['remaining_serials'] as List).length;
        }
      }

      final availableBatches = <Map<String, dynamic>>[];
      if (item['remaining_batch_codes'] is Map) {
        final map = item['remaining_batch_codes'] as Map;
        map.forEach((k, v) {
          availableBatches.add({
            'batch_code': k.toString(),
            'quantity': int.tryParse(v.toString()) ?? 0,
          });
        });
      } else if (item['allocated_batches'] is List) {
        for (final b in item['allocated_batches'] as List) {
          if (b is Map) availableBatches.add(Map<String, dynamic>.from(b));
        }
      }

      final availableSerials = <String>[];
      if (item['remaining_serials'] is List) {
        for (final s in item['remaining_serials'] as List) {
          availableSerials.add(s.toString());
        }
      } else if (item['allocated_serials'] is List) {
        for (final s in item['allocated_serials'] as List) {
          availableSerials.add(s.toString());
        }
      }

      String trackingType = rawType;
      if (rawType != 'batch' && rawType != 'serial') {
        if (availableBatches.isNotEmpty) {
          trackingType = 'batch';
        } else if (availableSerials.isNotEmpty) {
          trackingType = 'serial';
        } else {
          trackingType = 'none';
        }
      }

      list.add(_ReturnLineItemState(
        lineItemId: liId,
        productSkuId: productSkuId,
        name: skuName,
        sku: skuCode,
        trackingType: trackingType,
        returnedQuantity: returnedQuantity,
        goodQty: returnedQuantity,
        badQty: 0,
        availableBatches: availableBatches,
        availableSerials: availableSerials,
      ));
    }
    _items = list;
  }

  bool get _allValid => _items != null && _items!.isNotEmpty && _items!.every((i) => i.isValid);

  Future<void> _showCompletionModalAndSubmit() async {
    if (!_allValid || _isSubmitting) return;

    bool inventoryReturn = true;
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Complete Return', style: AppTextStyles.headingSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before completing, please select whether returned items should be restored to inventory.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => setModalState(() => inventoryReturn = !inventoryReturn),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: inventoryReturn,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setModalState(() => inventoryReturn = v ?? true),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Restore to Inventory', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                inventoryReturn
                                    ? 'Good qty → Available, Bad qty → Damaged'
                                    : 'No restoration (All qty treated as write-off)',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Return Reason (Optional)',
                    hintText: 'e.g. Customer returned damaged goods',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Complete Return', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;
    await _submit(inventoryReturn: inventoryReturn, reason: reasonController.text.trim());
  }

  Future<void> _submit({required bool inventoryReturn, required String reason}) async {
    if (!_allValid || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final lineItemsPayload = _items!.map((item) {
        final map = <String, dynamic>{
          'product_sku_id': item.productSkuId,
          'good_quality': item.goodQty,
          'bad_quality': item.badQty,
        };

        if (item.trackingType == 'batch') {
          final goodBatchMap = <String, int>{};
          for (final b in item.goodBatches) {
            final code = b['batch_code']?.toString() ?? '';
            final qty = int.tryParse(b['quantity']?.toString() ?? '0') ?? 0;
            if (code.isNotEmpty && qty > 0) goodBatchMap[code] = qty;
          }
          final badBatchMap = <String, int>{};
          for (final b in item.badBatches) {
            final code = b['batch_code']?.toString() ?? '';
            final qty = int.tryParse(b['quantity']?.toString() ?? '0') ?? 0;
            if (code.isNotEmpty && qty > 0) badBatchMap[code] = qty;
          }
          map['good_batch_codes'] = goodBatchMap;
          map['bad_batch_codes'] = badBatchMap;
        } else if (item.trackingType == 'serial') {
          map['good_serials'] = item.goodSerials;
          map['bad_serials'] = item.badSerials;
        }

        return map;
      }).toList();

      final assignPayload = {'shipment_line_items': lineItemsPayload};

      await ref.read(shipmentRepositoryProvider).assignReturnItems(
        shipmentId: widget.shipmentId,
        payload: assignPayload,
      );

      final completePayload = <String, dynamic>{
        'inventory_return': inventoryReturn,
      };
      if (reason.isNotEmpty) {
        completePayload['return_reason'] = reason;
      }

      await ref.read(shipmentRepositoryProvider).returnComplete(
        shipmentId: widget.shipmentId,
        payload: completePayload,
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
    final targetQty = isGood ? item.goodQty : item.badQty;
    final availablePool = item.availableBatches;
    final currentList = isGood ? item.goodBatches : item.badBatches;
    final otherList = isGood ? item.badBatches : item.goodBatches;

    const idKey = 'batch_code';

    List<_BatchDialogRowState> rows = currentList.isEmpty
        ? [
            _BatchDialogRowState(
              batchCode: availablePool.isNotEmpty ? (availablePool.first[idKey]?.toString() ?? '') : '',
              quantity: 0,
            )
          ]
        : currentList.map((e) => _BatchDialogRowState(
              batchCode: e[idKey]?.toString() ?? '',
              quantity: int.tryParse(e['quantity'].toString()) ?? 0,
            )).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            int currentSum = rows.fold(0, (sum, r) => sum + r.quantity);
            final selectedIds = rows.map((r) => r.batchCode).toSet();

            bool anyExceeds = false;

            return AlertDialog(
              title: Text(
                isGood ? 'Select Good Batches' : 'Select Bad Batches',
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
                        final rowId = row.batchCode;

                        final poolItem = availablePool.where(
                          (p) => (p[idKey]?.toString() ?? '') == rowId,
                        ).firstOrNull ?? <String, dynamic>{'quantity': 0};
                        final batchTotal = int.tryParse(poolItem['quantity'].toString()) ?? 0;
                        final otherItem = otherList.where(
                          (eb) => (eb[idKey]?.toString() ?? '') == rowId,
                        ).firstOrNull;
                        final otherAlloc = int.tryParse((otherItem?['quantity'] ?? 0).toString()) ?? 0;
                        final maxAllowedForBatch = (batchTotal - otherAlloc).clamp(0, batchTotal);
                        final isExceeding = row.quantity > maxAllowedForBatch;
                        if (isExceeding) {
                          anyExceeds = true;
                        }

                        final availableOptions = availablePool.where((poolItem) {
                          final pId = poolItem[idKey]?.toString() ?? '';
                          return pId == rowId || !selectedIds.contains(pId);
                        }).toList();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: rowId.isEmpty && availableOptions.isNotEmpty ? availableOptions.first[idKey]?.toString() : (rowId.isNotEmpty ? rowId : null),
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Select Batch',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      items: availableOptions.map((opt) {
                                        final optId = opt[idKey]?.toString() ?? '';
                                        final optTotal = int.tryParse(opt['quantity'].toString()) ?? 0;
                                        final optOtherItem = otherList.where(
                                          (eb) => (eb[idKey]?.toString() ?? '') == optId,
                                        ).firstOrNull;
                                        final optOther = int.tryParse((optOtherItem?['quantity'] ?? 0).toString()) ?? 0;
                                        final optMax = (optTotal - optOther).clamp(0, optTotal);
                                        return DropdownMenuItem(
                                          value: optId,
                                          child: Text(
                                            '$optId (Avail: $optMax${optOther > 0 ? " / Total: $optTotal" : ""})',
                                            style: AppTextStyles.bodySmall,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null && val != row.batchCode) {
                                          setDialogState(() {
                                            row.batchCode = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      key: ValueKey('row_qty_$idx'),
                                      controller: row.qtyCtrl,
                                      keyboardType: TextInputType.number,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: isExceeding ? AppColors.error : AppColors.textPrimary,
                                        fontWeight: isExceeding ? FontWeight.w700 : FontWeight.normal,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Qty',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        enabledBorder: isExceeding ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error, width: 1.5)) : null,
                                        focusedBorder: isExceeding ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error, width: 2)) : null,
                                      ),
                                      onChanged: (val) {
                                        setDialogState(() {
                                          row.quantity = int.tryParse(val) ?? 0;
                                        });
                                      },
                                    ),
                                  ),
                                  if (rows.length > 1) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                      onPressed: () {
                                        final oldRow = row;
                                        setDialogState(() {
                                          rows.removeAt(idx);
                                        });
                                        Future.delayed(const Duration(milliseconds: 300), () {
                                          oldRow.dispose();
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              if (otherAlloc > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 2),
                                  child: Text(
                                    'Selected in ${isGood ? "Bad Qty" : "Good Qty"}: $otherAlloc / $batchTotal (Max available: $maxAllowedForBatch)',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              if (isExceeding)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 2),
                                  child: Text(
                                    otherAlloc > 0
                                        ? 'Exceeds max available ($maxAllowedForBatch). ($otherAlloc allocated to ${isGood ? "Bad" : "Good"})'
                                        : 'Cannot exceed batch total ($batchTotal)',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      if (selectedIds.length < availablePool.length)
                        TextButton.icon(
                          onPressed: () {
                            final nextOpt = availablePool.where(
                              (p) => !selectedIds.contains(p[idKey]?.toString()),
                            ).firstOrNull ?? <String, dynamic>{idKey: ''};
                            final nextId = nextOpt[idKey]?.toString() ?? '';
                            if (nextId.isNotEmpty) {
                              setDialogState(() {
                                rows.add(_BatchDialogRowState(batchCode: nextId, quantity: 0));
                              });
                            }
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add another batch'),
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
                              color: currentSum == targetQty && !anyExceeds ? AppColors.success : AppColors.error,
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
                  onPressed: !anyExceeds && currentSum == targetQty && rows.every((r) => r.quantity > 0 && r.batchCode.isNotEmpty)
                      ? () {
                          final mapList = rows.map((r) => <String, dynamic>{idKey: r.batchCode, 'quantity': r.quantity}).toList();
                          Navigator.pop(ctx);
                          setState(() {
                            if (isGood) {
                              item.goodBatches = mapList;
                            } else {
                              item.badBatches = mapList;
                            }
                          });
                        }
                      : null,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        for (final r in rows) {
          r.dispose();
        }
      });
    });
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
                          final resultList = currentSet.toList();
                          Navigator.pop(ctx);
                          setState(() {
                            if (isGood) {
                              item.goodSerials = resultList;
                            } else {
                              item.badSerials = resultList;
                            }
                          });
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
    final infoAsync = ref.watch(returnRemainingProvider(widget.shipmentId));
    final shipmentAsync = ref.watch(shipmentByIdProvider(widget.shipmentId));
    final shipment = widget.shipment ?? shipmentAsync.valueOrNull;

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
                  onPressed: () => ref.invalidate(returnRemainingProvider(widget.shipmentId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (infoList) {
          if (widget.shipment == null && shipmentAsync.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          _initItems(infoList, shipment);
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
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text('SKU Code: ${item.sku}', style: AppTextStyles.caption),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                    SizedBox(height: 8,),
                                    TrackingTypeBadge(trackingType: item.trackingType),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Returned Qty: ${item.returnedQuantity}',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Good Qty Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      key: ValueKey('good_${item.lineItemId}'),
                                      controller: item.goodCtrl,
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
                                        final newBad = (item.returnedQuantity - g).clamp(0, item.returnedQuantity);
                                        setState(() {
                                          item.goodQty = g;
                                          item.badQty = newBad;
                                          if (item.badCtrl.text != newBad.toString()) {
                                            item.badCtrl.text = newBad.toString();
                                          }
                                        });
                                      },
                                    ),
                                    if (item.trackingType != 'none' && item.goodQty > 0) ...[
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
                                      key: ValueKey('bad_${item.lineItemId}'),
                                      controller: item.badCtrl,
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
                                        final newGood = (item.returnedQuantity - b).clamp(0, item.returnedQuantity);
                                        setState(() {
                                          item.badQty = b;
                                          item.goodQty = newGood;
                                          if (item.goodCtrl.text != newGood.toString()) {
                                            item.goodCtrl.text = newGood.toString();
                                          }
                                        });
                                      },
                                    ),
                                    if (item.trackingType != 'none' && item.badQty > 0) ...[
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
                              item.goodQty + item.badQty != item.returnedQuantity
                                  ? '* Good + Bad quantity must equal Returned Quantity (${item.returnedQuantity})'
                                  : '* Please select exact batch/serial quantities for Good and Bad items.',
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
                    onPressed: _allValid && !_isSubmitting ? _showCompletionModalAndSubmit : null,
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
