import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/tracking_type_badge.dart';
import '../../../home/providers/home_provider.dart';
import '../../data/models/purchase_order_model.dart';
import '../../providers/purchase_order_provider.dart';
import 'package:node_management_app/core/utils/snackbar_utils.dart';

class GrnAccordionItem extends ConsumerStatefulWidget {
  final GrnModel grn;
  final PurchaseOrderModel? po;
  final bool isExpanded;
  final VoidCallback onToggle;

  const GrnAccordionItem({
    super.key,
    required this.grn,
    this.po,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  ConsumerState<GrnAccordionItem> createState() => _GrnAccordionItemState();
}

class _GrnAccordionItemState extends ConsumerState<GrnAccordionItem> {
  // Inwarding form state (for 'created' status)
  final Map<int, TextEditingController> _skuQtyControllers = {};
  final Map<int, List<GrnBatchModel>> _skuBatches = {};
  final Map<int, List<String>> _skuSerials = {};
  List<int?> _inwardBlocks = [null];

  // QC state (for 'qc_pending' status)
  final Map<int, GrnLineItemModel> _qcModifiedItems = {};
  String? _loadingAction;
  bool _showAddLineItemsBlock = false;

  @override
  void dispose() {
    for (final c in _skuQtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GrnAccordionItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.grn.id != widget.grn.id || oldWidget.grn.status != widget.grn.status) {
      _qcModifiedItems.clear();
      _inwardBlocks = [null];
      _showAddLineItemsBlock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grn = widget.grn;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isExpanded ? AppColors.primary : AppColors.cardBorder,
          width: widget.isExpanded ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_turned_in_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(grn.grnNumber, style: AppTextStyles.labelLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Received: ${grn.receivedDate ?? "N/A"}', //• Items: ${grn.lineItems.length}
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: grn.status),
                  const SizedBox(width: 8),
                  Icon(
                    widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (widget.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ref.watch(grnDetailProvider(widget.grn.id)).when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _buildExpandedBody(widget.grn), // fallback
                data: (detailedGrn) => _buildExpandedBody(detailedGrn),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedBody(GrnModel grn) {
    final statusLower = grn.status.toLowerCase();
    if (statusLower == 'created') {
      return _buildCreatedStatusView(grn);
    } else if (statusLower == 'qc_pending' || statusLower == 'waiting_for_approval') {
      return _buildQcPendingStatusView(grn);
    } else {
      return _buildCompletedStatusView(grn);
    }
  }

  // ===========================================================================
  // 1. CREATED STATUS VIEW (No Price Fields, Inwarding with Batch/Serial Modals)
  // ===========================================================================
  Widget _buildCreatedStatusView(GrnModel grn) {
    final asyncSkuItems = ref.watch(poSkuItemsProvider(grn.purchaseOrderId));
    final splash = ref.watch(splashDataProvider).valueOrNull;
    final canUpdateGrn = splash?.hasPermission('GoodsReceivedNote', 'update') ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        _buildInvoiceMetadataCard(grn),

        // Inwarding Form
        Text("Inward Line Items", style: AppTextStyles.headingMedium),
        const SizedBox(height: 12),
        asyncSkuItems.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text("Failed to load PO SKU items: $e",
                style: AppTextStyles.caption.copyWith(color: AppColors.error)),
          ),
          data: (skuItems) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final unfulfilledSkus = skuItems.where((item) {
                      return !item.fullyFulfilled && item.remainingQuantity > 0;
                    }).toList();

                    final shouldHideInputBlockByDefault = widget.grn.status.toLowerCase() == 'created' &&
                        widget.grn.lineItems.isNotEmpty &&
                        !_showAddLineItemsBlock;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!canUpdateGrn)
                          const SizedBox.shrink()
                        else if (unfulfilledSkus.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: AppColors.success),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "All line items in this purchase order have been fully inwarded.",
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (shouldHideInputBlockByDefault)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            width: double.infinity,
                            child: AppButton(
                              label: "Add Line Items",
                              icon: Icons.add_circle_outline,
                              height: 48,
                              onPressed: () {
                                setState(() {
                                  _showAddLineItemsBlock = true;
                                  if (_inwardBlocks.isEmpty) {
                                    _inwardBlocks = [null];
                                  }
                                });
                              },
                            ),
                          )
                        else ...[
                          for (int i = 0; i < _inwardBlocks.length; i++)
                            Builder(
                              builder: (context) {
                                final selectedSkuId = _inwardBlocks[i];
                                final poLi = selectedSkuId == null
                                    ? null
                                    : unfulfilledSkus.where((item) => item.productSkuId == selectedSkuId).firstOrNull;

                                final currentlySelectedIds = _inwardBlocks
                                    .where((id) => id != null && id != selectedSkuId)
                                    .toSet();
                                final availableSkusForBlock = unfulfilledSkus
                                    .where((sku) => !currentlySelectedIds.contains(sku.productSkuId))
                                    .toList();

                                final controller = poLi == null
                                    ? null
                                    : _skuQtyControllers.putIfAbsent(poLi.productSkuId, () => TextEditingController());
                                final batches = poLi == null
                                    ? <GrnBatchModel>[]
                                    : _skuBatches.putIfAbsent(poLi.productSkuId, () => []);
                                final serials = poLi == null
                                    ? <String>[]
                                    : _skuSerials.putIfAbsent(poLi.productSkuId, () => []);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedSkuId != null ? AppColors.primary.withValues(alpha: 0.3) : AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField<int>(
                                              initialValue: selectedSkuId,
                                              isExpanded: true,
                                              icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                                              decoration: InputDecoration(
                                                labelText: "Select SKU to Inward",
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                                ),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                filled: true,
                                                fillColor: AppColors.surface,
                                              ),
                                              items: availableSkusForBlock.map((sku) {
                                                return DropdownMenuItem<int>(
                                                  value: sku.productSkuId,
                                                  child: Text(
                                                    "${sku.skuName} (${sku.skuCode})",
                                                    style: AppTextStyles.bodyMedium,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (newVal) {
                                                setState(() {
                                                  if (selectedSkuId != null && selectedSkuId != newVal) {
                                                    _skuQtyControllers.remove(selectedSkuId)?.dispose();
                                                    _skuBatches.remove(selectedSkuId);
                                                    _skuSerials.remove(selectedSkuId);
                                                  }
                                                  _inwardBlocks[i] = newVal;
                                                });
                                              },
                                            ),
                                          ),
                                          if (_inwardBlocks.length > 1) ...[
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                              tooltip: "Remove this block",
                                              onPressed: () {
                                                setState(() {
                                                  final removedId = _inwardBlocks.removeAt(i);
                                                  if (removedId != null) {
                                                    _skuQtyControllers.remove(removedId)?.dispose();
                                                    _skuBatches.remove(removedId);
                                                    _skuSerials.remove(removedId);
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (poLi != null && controller != null) ...[
                                        const SizedBox(height: 14),
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 12,
                                          runSpacing: 8,
                                          children: [
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Text("SKU: ${poLi.skuCode}", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                                                TrackingTypeBadge(trackingType: poLi.trackingType),
                                                if (poLi.selectionType.isNotEmpty)
                                                  Text("• ${poLi.selectionType}", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "Remaining Qty: ${poLi.remainingQuantity} / Total: ${poLi.totalUnits}",
                                                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Builder(
                                          builder: (context) {
                                            final enteredQty = int.tryParse(controller.text) ?? 0;
                                            final isQtyExceeded = enteredQty > poLi.remainingQuantity;
                                            final isBatchesAdded = batches.isNotEmpty && batches.fold<int>(0, (s, b) => s + b.quantity) == enteredQty && enteredQty > 0;
                                            final isSerialsAdded = serials.isNotEmpty && serials.length == enteredQty && enteredQty > 0;

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    final isNarrow = constraints.maxWidth < 460;
                                                    final textFieldWidget = AppTextField(
                                                      label: "Received Qty (Max: ${poLi.remainingQuantity})",
                                                      controller: controller,
                                                      keyboardType: TextInputType.number,
                                                      onChanged: (val) {
                                                        final newQty = int.tryParse(val) ?? 0;
                                                        if (poLi.trackingType == 'batch') {
                                                          final currentBatchSum = batches.fold<int>(0, (s, b) => s + b.quantity);
                                                          if (newQty != currentBatchSum) {
                                                            batches.clear();
                                                          }
                                                        } else if (poLi.trackingType == 'serial') {
                                                          if (newQty != serials.length) {
                                                            serials.clear();
                                                          }
                                                        }
                                                        setState(() {});
                                                      },
                                                    );

                                                    final actionContainer = Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          if (poLi.trackingType == 'batch')
                                                            Expanded(
                                                              child: ElevatedButton.icon(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: isBatchesAdded ? AppColors.success : AppColors.getTrackingTextColor('batch'),
                                                                  foregroundColor: Colors.white,
                                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                ),
                                                                icon: Icon(isBatchesAdded ? Icons.check_circle_outline : Icons.layers_outlined, size: 18),
                                                                label: Text(
                                                                  isBatchesAdded ? "Batches Added (${batches.length})" : "Add Batches (${batches.length})",
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                                onPressed: () => _openBatchModalForSku(poLi),
                                                              ),
                                                            )
                                                          else if (poLi.trackingType == 'serial')
                                                            Expanded(
                                                              child: ElevatedButton.icon(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: isSerialsAdded ? AppColors.success : AppColors.getTrackingTextColor('serial'),
                                                                  foregroundColor: Colors.white,
                                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                ),
                                                                icon: Icon(isSerialsAdded ? Icons.check_circle_outline : Icons.qr_code_scanner_outlined, size: 18),
                                                                label: Text(
                                                                  isSerialsAdded ? "Serials Added (${serials.length})" : "Add Serials (${serials.length})",
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                                onPressed: () => _openSerialModalForSku(poLi),
                                                              ),
                                                            )
                                                          else
                                                            const Expanded(
                                                              child: Center(
                                                                child: TrackingTypeBadge(trackingType: 'untracked'),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    );

                                                    if (isNarrow) {
                                                      return Column(
                                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                                        children: [
                                                          textFieldWidget,
                                                          const SizedBox(height: 12),
                                                          actionContainer,
                                                        ],
                                                      );
                                                    }
                                                    return Row(
                                                      children: [
                                                        Expanded(
                                                          flex: 2,
                                                          child: textFieldWidget,
                                                        ),
                                                        const SizedBox(width: 16),
                                                        Expanded(
                                                          flex: 3,
                                                          child: actionContainer,
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                                if (isQtyExceeded) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    "Received quantity ($enteredQty) cannot exceed remaining quantity (${poLi.remainingQuantity}).",
                                                    style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),

                          if (unfulfilledSkus.length > _inwardBlocks.length) ...[
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                label: "Add One More Line Item",
                                icon: Icons.add,
                                height: 44,
                                isOutlined: true,
                                onPressed: () {
                                  setState(() {
                                    _inwardBlocks.add(null);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ] else
                            const SizedBox(height: 16),

                          Builder(
                            builder: (context) {
                              final hasExceededQty = unfulfilledSkus.any((poLi) {
                                if (!_inwardBlocks.contains(poLi.productSkuId)) return false;
                                final q = int.tryParse(_skuQtyControllers[poLi.productSkuId]?.text ?? '0') ?? 0;
                                return q > poLi.remainingQuantity;
                              });
                              final hasAnySelection = _inwardBlocks.any((id) => id != null);
                              return SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  label: "Add Line Items to GRN",
                                  icon: Icons.add_circle_outline,
                                  height: 48,
                                  isLoading: _loadingAction == 'add',
                                  onPressed: (!hasAnySelection || hasExceededQty || _loadingAction != null) ? null : () => _addItemsToGrn(skuItems),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Added Line Items List (No Price Fields!)
        Text("Inwarded Items (${grn.lineItems.length})", style: AppTextStyles.headingMedium),
        const SizedBox(height: 12),
        if (grn.lineItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text("No items inwarded yet. Add items above.",
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
            ),
          )
        else
          Column(
            children: grn.lineItems.map((li) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text(li.skuName, style: AppTextStyles.labelMedium)),
                        Text("${li.receivedQuantity} units",
                            style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary),),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text("SKU: ${li.skuCode}", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                        TrackingTypeBadge(trackingType: li.trackingType),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (li.trackingType == 'batch' || li.trackingType == 'serial')
                          InkWell(
                            onTap: () => _showInwardedItemDetailsModal(li, isEditing: false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.getTrackingBgColor(li.trackingType),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.getTrackingTextColor(li.trackingType).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_outlined, size: 16, color: AppColors.getTrackingTextColor(li.trackingType)),
                                  const SizedBox(width: 6),
                                  Text(
                                    li.trackingType == 'batch'
                                        ? "View Batches (${li.receivedBatches.length})"
                                        : "View Serials (${li.receivedSerials.length})",
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.getTrackingTextColor(li.trackingType),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          if (canUpdateGrn) ...[
                            if (_loadingAction == 'update_${li.id}' || _loadingAction == 'delete_${li.id}')
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              )
                            else ...[
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                tooltip: "Edit",
                                onPressed: _loadingAction != null ? null : () => _showInwardedItemDetailsModal(li, isEditing: true),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                  tooltip: "Remove Line Item",
                                  onPressed: _loadingAction != null ? null : () => _confirmDeleteLineItem(li),
                                ),
                            ],
                          ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 24),

        // Proceed to QC Button
        if (canUpdateGrn)
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: "Proceed to QC",
              icon: Icons.arrow_forward_rounded,
              isLoading: _loadingAction == 'proceed_qc',
              onPressed: (grn.lineItems.isEmpty || _loadingAction != null) ? null : _proceedToQc,
            ),
          ),
      ],
    );
  }

  void _openBatchModalForSku(PoSkuItemModel poLi) {
    final controller = _skuQtyControllers.putIfAbsent(poLi.productSkuId, () => TextEditingController());
    final qtyVal = int.tryParse(controller.text) ?? 0;
    if (qtyVal <= 0 || qtyVal > poLi.remainingQuantity) {
      showTopErrorSnackBar(context, "Please enter Received Qty between 1 and ${poLi.remainingQuantity} first");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BatchInputModal(
        targetQty: qtyVal,
        initialBatches: _skuBatches[poLi.productSkuId] ?? [],
        onSave: (batches) {
          setState(() {
            _skuBatches[poLi.productSkuId] = batches;
          });
        },
      ),
    );
  }

  void _openSerialModalForSku(PoSkuItemModel poLi) {
    final controller = _skuQtyControllers.putIfAbsent(poLi.productSkuId, () => TextEditingController());
    final qtyVal = int.tryParse(controller.text) ?? 0;
    if (qtyVal <= 0 || qtyVal > poLi.remainingQuantity) {
      showTopErrorSnackBar(context, "Please enter Received Qty between 1 and ${poLi.remainingQuantity} first");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SerialInputModal(
        targetQty: qtyVal,
        productSkuId: poLi.productSkuId,
        initialSerials: _skuSerials[poLi.productSkuId] ?? [],
        onSave: (serials) {
          setState(() {
            _skuSerials[poLi.productSkuId] = serials;
          });
        },
      ),
    );
  }

  // Edit is now handled entirely inside the _InwardedItemDetailsModal popup.

  Future<void> _addItemsToGrn(List<PoSkuItemModel> allSkuItems) async {
    List<GrnLineItemModel> payloadItems = [];

    for (final poLi in allSkuItems) {
      if (!_inwardBlocks.contains(poLi.productSkuId)) continue;
      if (poLi.remainingQuantity <= 0 || poLi.fullyFulfilled) continue;
      final controller = _skuQtyControllers[poLi.productSkuId];
      final qtyVal = int.tryParse(controller?.text ?? '') ?? 0;
      if (qtyVal <= 0) continue;

      if (qtyVal > poLi.remainingQuantity) {
        showTopErrorSnackBar(context, "Received Qty for ${poLi.skuName} cannot exceed ${poLi.remainingQuantity}");
        return;
      }

      final batches = _skuBatches[poLi.productSkuId] ?? [];
      final serials = _skuSerials[poLi.productSkuId] ?? [];

      if (poLi.trackingType == 'batch') {
        final totalBatchQty = batches.fold<int>(0, (sum, b) => sum + b.quantity);
        if (totalBatchQty != qtyVal) {
          showTopErrorSnackBar(context, "Total batch quantity ($totalBatchQty) does not match received qty ($qtyVal)");
          return;
        }
        if (batches.any((b) => b.batchCode.trim().isEmpty)) {
          showTopErrorSnackBar(context, "All batches for '${poLi.skuName}' must have a valid Batch Code");
          return;
        }
      } else if (poLi.trackingType == 'serial') {
        if (serials.length != qtyVal) {
          showTopErrorSnackBar(context, "Total serials count (${serials.length}) does not match received qty ($qtyVal)");
          return;
        }
      }

      payloadItems.add(GrnLineItemModel(
        id: DateTime.now().millisecondsSinceEpoch % 100000 + poLi.productSkuId,
        productSkuId: poLi.productSkuId,
        skuName: poLi.skuName,
        skuCode: poLi.skuCode,
        trackingType: poLi.trackingType,
        receivedQuantity: qtyVal,
        acceptedQuantity: 0,
        rejectedQuantity: 0,
        unitPrice: '0.0', // No price fields stored or shown
        receivedAmount: '0.0',
        acceptedAmount: '0.0',
        rejectedAmount: '0.0',
        taxableAmount: '0.0',
        taxAmount: '0.0',
        cgstAmount: '0.0',
        sgstAmount: '0.0',
        igstAmount: '0.0',
        finalAmount: 0.0,
        receivedBatches: batches,
        receivedSerials: serials,
        acceptedBatches: [],
        acceptedSerials: [],
        rejectedBatches: [],
        rejectedSerials: [],
      ));
    }

    if (payloadItems.isEmpty) {
      showTopErrorSnackBar(context, "Please enter Received Qty > 0 for at least one item");
      return;
    }

    final currentLineItems = ref.read(grnDetailProvider(widget.grn.id)).value?.lineItems ?? widget.grn.lineItems;
    final Map<int, GrnLineItemModel> combinedMap = {};
    for (final item in currentLineItems) {
      combinedMap[item.productSkuId] = item;
    }
    for (final newItem in payloadItems) {
      combinedMap[newItem.productSkuId] = newItem;
    }
    final updatedList = combinedMap.values.toList();

    setState(() => _loadingAction = 'add');
    try {
      await ref.read(grnControllerProvider.notifier).updateGrnLineItems(widget.grn.id, widget.grn.purchaseOrderId, updatedList);
      if (!mounted) return;
      setState(() {
        _showAddLineItemsBlock = false;
        for (final c in _skuQtyControllers.values) {
          c.clear();
        }
        _skuBatches.clear();
        _skuSerials.clear();
        _inwardBlocks = [null];
      });
      ref.invalidate(grnDetailProvider(widget.grn.id));
      await ref.read(grnDetailProvider(widget.grn.id).future);
      if (!mounted) return;
      ref.invalidate(poSkuItemsProvider(widget.grn.purchaseOrderId));
      showTopSuccessSnackBar(context, "Line items added to GRN successfully");
    } catch (e) {
      if (!mounted) return;
      String errMsg = e.toString().replaceAll('Exception: ', '');
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && (data['message'] != null || data['error'] != null)) {
          errMsg = (data['message'] ?? data['error']).toString();
        }
      }
      showTopErrorSnackBar(context, "Failed to add line items: $errMsg");
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  void _showInwardedItemDetailsModal(GrnLineItemModel li, {required bool isEditing}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _InwardedItemDetailsModal(
        item: li,
        grn: widget.grn,
        initialEditing: isEditing,
        onSave: (updatedItem) => _handleInwardedItemUpdate(updatedItem),
        onDelete: () => _confirmRemoveInwardedItem(li),
      ),
    );
  }

  Future<void> _handleInwardedItemUpdate(GrnLineItemModel updatedLi) async {
    setState(() => _loadingAction = 'update_${updatedLi.id}');
    final currentLineItems = ref.read(grnDetailProvider(widget.grn.id)).value?.lineItems ?? widget.grn.lineItems;
    final updatedList = currentLineItems.map((item) {
      if (item.productSkuId == updatedLi.productSkuId || item.id == updatedLi.id) {
        return updatedLi;
      }
      return item;
    }).toList();

    try {
      await ref.read(grnControllerProvider.notifier).updateGrnLineItems(widget.grn.id, widget.grn.purchaseOrderId, updatedList);
      if (!mounted) return;
      ref.invalidate(grnDetailProvider(widget.grn.id));
      await ref.read(grnDetailProvider(widget.grn.id).future);
      if (!mounted) return;
      ref.invalidate(poSkuItemsProvider(widget.grn.purchaseOrderId));
      showTopSuccessSnackBar(context, "Line item updated successfully");
    } catch (e) {
      if (!mounted) return;
      String errMsg = e.toString().replaceAll('Exception: ', '');
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && (data['message'] != null || data['error'] != null)) {
          errMsg = (data['message'] ?? data['error']).toString();
        }
      }
      showTopErrorSnackBar(context, "Failed to update item: $errMsg");
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  Future<void> _confirmRemoveInwardedItem(GrnLineItemModel li) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Item from GRN"),
        content: Text("Are you sure you want to remove '${li.skuName}' from this GRN? Its received quantity will return to the available PO balance."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _handleInwardedItemDelete(li);
    }
  }

  Future<void> _handleInwardedItemDelete(GrnLineItemModel liToDelete) async {
    setState(() => _loadingAction = 'delete_${liToDelete.id}');
    final currentLineItems = ref.read(grnDetailProvider(widget.grn.id)).value?.lineItems ?? widget.grn.lineItems;
    final updatedList = currentLineItems.where((item) => item.productSkuId != liToDelete.productSkuId && item.id != liToDelete.id).toList();

    try {
      await ref.read(grnControllerProvider.notifier).updateGrnLineItems(widget.grn.id, widget.grn.purchaseOrderId, updatedList);
      if (!mounted) return;
      ref.invalidate(grnDetailProvider(widget.grn.id));
      await ref.read(grnDetailProvider(widget.grn.id).future);
      if (!mounted) return;
      ref.invalidate(poSkuItemsProvider(widget.grn.purchaseOrderId));
      showTopSuccessSnackBar(context, "Line item removed successfully");
    } catch (e) {
      if (!mounted) return;
      String errMsg = e.toString().replaceAll('Exception: ', '');
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && (data['message'] != null || data['error'] != null)) {
          errMsg = (data['message'] ?? data['error']).toString();
        }
      }
      showTopErrorSnackBar(context, "Failed to remove item: $errMsg");
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  Future<void> _proceedToQc() async {
    setState(() => _loadingAction = 'proceed_qc');
    try {
      await ref.read(grnControllerProvider.notifier).updateStatus(widget.grn.id, widget.grn.purchaseOrderId, 'qc_pending');
      if (!mounted) return;
      showTopSuccessSnackBar(context, "GRN transitioned to QC Pending! Details refreshed.");
    } catch (e) {
      if (!mounted) return;
      String errMsg = e.toString().replaceAll('Exception: ', '');
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && (data['message'] != null || data['error'] != null)) {
          errMsg = (data['message'] ?? data['error']).toString();
        }
      }
      showTopErrorSnackBar(context, "Failed to transition status: $errMsg");
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  // ===========================================================================
  // 2. QC PENDING STATUS VIEW (No Price Fields, Dynamic Action Buttons)
  // ===========================================================================
  Widget _buildQcPendingStatusView(GrnModel grn) {
    final splash = ref.watch(splashDataProvider).valueOrNull;
    final canUpdateGrn = splash?.hasPermission('GoodsReceivedNote', 'update') ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        _buildInvoiceMetadataCard(grn),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Quality Check Items", style: AppTextStyles.headingMedium),
          ],
        ),
        const SizedBox(height: 6),
        Column(
          children: grn.lineItems.map((li) {
            final activeItem = _qcModifiedItems[li.id] ?? li;
            final isModified = _qcModifiedItems.containsKey(li.id);

            String buttonLabel = "Confirm Qty";
            if (activeItem.trackingType == 'batch') {
              buttonLabel = "Confirm Batches";
            } else if (activeItem.trackingType == 'serial') {
              buttonLabel = "Confirm Serial";
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isModified ? AppColors.success : AppColors.cardBorder, width: isModified ? 1.5 : 1.0),
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
                            Text(activeItem.skuName, style: AppTextStyles.labelMedium),
                            const SizedBox(height: 1),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("SKU: ${activeItem.skuCode}",
                                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                                Row(
                                  children: [
                                    Text("Type: ", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                                    TrackingTypeBadge(trackingType: activeItem.trackingType),
                                  ],
                                ),
                              ],
                            ),
                            
                          ],
                        ),
                      ),
                      if (canUpdateGrn)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isModified ? AppColors.success : AppColors.getTrackingTextColor(activeItem.trackingType),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: Icon(isModified ? Icons.check_circle_outline : Icons.fact_check_outlined, size: 16),
                          label: Text(isModified ? "Confirmed" : buttonLabel),
                          onPressed: () => _openQcModal(activeItem),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _qcStatCol("Received Qty", "${activeItem.receivedQuantity}", AppColors.textPrimary)),
                      Expanded(child: _qcStatCol("Good Qty (Accepted)", "${activeItem.acceptedQuantity}", AppColors.success)),
                      Expanded(child: _qcStatCol("Bad Qty (Rejected)", "${activeItem.rejectedQuantity}", activeItem.rejectedQuantity > 0 ? AppColors.error : AppColors.textMuted)),
                    ],
                  ),
                  if (activeItem.rejectionReason != null && activeItem.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text("Rejection Reason: ${activeItem.rejectionReason}",
                          style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Submit QC CTA
        if (canUpdateGrn)
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: "Submit QC and Complete GRN",
              icon: Icons.done_all,
              isOutlined: true,
              isLoading: _loadingAction == 'submit_qc',
              onPressed: _loadingAction != null ? null : _submitQc,
            ),
          ),
      ],
    );
  }

  Widget _qcStatCol(String label, String value, Color valColor) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.labelMedium.copyWith(color: valColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  void _openQcModal(GrnLineItemModel item) {
    if (item.trackingType == 'batch') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _QcBatchModal(
          item: _qcModifiedItems[item.id] ?? item,
          onSave: (updatedItem) => _handleQcItemSave(updatedItem),
        ),
      );
    } else if (item.trackingType == 'serial') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _QcSerialModal(
          item: _qcModifiedItems[item.id] ?? item,
          onSave: (updatedItem) => _handleQcItemSave(updatedItem),
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _QcUntrackedModal(
          item: _qcModifiedItems[item.id] ?? item,
          onSave: (updatedItem) => _handleQcItemSave(updatedItem),
        ),
      );
    }
  }

  void _handleQcItemSave(GrnLineItemModel updatedItem) {
    if (updatedItem.rejectedQuantity > 0 && (updatedItem.rejectionReason == null || updatedItem.rejectionReason!.trim().isEmpty)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _RejectionReasonModal(
          onSave: (reason) {
            final itemWithReason = updatedItem.copyWith(rejectionReason: reason);
            setState(() {
              _qcModifiedItems[itemWithReason.id] = itemWithReason;
            });
          },
        ),
      );
    } else {
      setState(() {
        _qcModifiedItems[updatedItem.id] = updatedItem;
      });
    }
  }

  Future<void> _confirmDeleteLineItem(GrnLineItemModel li) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Line Item"),
        content: const Text("Are you sure you want to delete this line item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loadingAction = 'delete_${li.id}');
    try {
      await ref.read(grnControllerProvider.notifier).deleteGrnLineItem(widget.grn.id, widget.grn.purchaseOrderId, li.id);
      if (!mounted) return;
      showTopSuccessSnackBar(context, "Line item deleted successfully");
    } catch (e) {
      if (!mounted) return;
      showTopErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  Future<void> _submitQc() async {
    setState(() => _loadingAction = 'submit_qc');
    final currentLineItems = ref.read(grnDetailProvider(widget.grn.id)).value?.lineItems ?? widget.grn.lineItems;
    final allItems = currentLineItems.map((li) => _qcModifiedItems[li.id] ?? li).toList();
    try {
      await ref.read(grnControllerProvider.notifier).submitQc(widget.grn.id, widget.grn.purchaseOrderId, allItems);
      if (!mounted) return;
      showTopSuccessSnackBar(context, "Quality Check submitted successfully!");
    } catch (e) {
      if (!mounted) return;
      String errMsg = e.toString().replaceAll('Exception: ', '');
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && (data['message'] != null || data['error'] != null)) {
          errMsg = (data['message'] ?? data['error']).toString();
        }
      }
      showTopErrorSnackBar(context, "Failed to submit QC: $errMsg");
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  // ===========================================================================
  // 3. COMPLETED STATUS VIEW (Read-Only Summary Without Price Fields)
  // ===========================================================================
  Widget _buildCompletedStatusView(GrnModel grn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),

        // Invoice Metadata Card
        _buildInvoiceMetadataCard(grn),

        // Line Items Summary Without Prices
        Text("Inwarded Line Items (${grn.lineItems.length})", style: AppTextStyles.headingMedium),
        const SizedBox(height: 10),
        Column(
          children: grn.lineItems.map((li) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          li.skuName,
                          style: AppTextStyles.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TrackingTypeBadge(trackingType: li.trackingType),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCountCard(
                          label: "Accepted",
                          count: li.acceptedQuantity,
                          color: AppColors.success,
                          onTap: li.acceptedQuantity > 0
                              ? () => _showDetailsPopup(li, isAccepted: true)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCountCard(
                          label: "Rejected",
                          count: li.rejectedQuantity,
                          color: li.rejectedQuantity > 0 ? AppColors.error : AppColors.textMuted,
                          onTap: li.rejectedQuantity > 0
                              ? () => _showDetailsPopup(li, isAccepted: false)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCountCard({
    required String label,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Text(count.toString(), style: AppTextStyles.labelMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new_rounded, size: 14, color: color),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceMetadataCard(GrnModel grn) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetadataRow("Invoice No", grn.vendorInvoiceNo ?? "N/A"),
          const SizedBox(height: 8),
          _buildMetadataRow("Invoice Date", grn.vendorInvoiceDate ?? "N/A"),
          const SizedBox(height: 8),
          _buildMetadataRow("Received Date", grn.receivedDate ?? "N/A"),
          if (grn.remarks != null && grn.remarks!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text("Remarks: ", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                Expanded(child: Text(grn.remarks!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  void _showDetailsPopup(GrnLineItemModel li, {required bool isAccepted, bool isReceivedOnly = false}) {
    final String title;
    final int count;
    final List<dynamic> batches;
    final List<dynamic> serials;

    if (isReceivedOnly) {
      title = "Received Details";
      count = li.receivedQuantity;
      batches = li.receivedBatches;
      serials = li.receivedSerials;
    } else {
      title = isAccepted ? "Accepted Details (Good)" : "Rejected Details (Bad)";
      count = isAccepted ? li.acceptedQuantity : li.rejectedQuantity;
      batches = isAccepted ? li.acceptedBatches : li.rejectedBatches;
      serials = isAccepted ? li.acceptedSerials : li.rejectedSerials;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: isAccepted ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(li.skuName, style: AppTextStyles.labelMedium),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text("SKU: ${li.skuCode}", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 6),
                            TrackingTypeBadge(trackingType: li.trackingType),
                            const SizedBox(width: 6),
                            Text("• Total: $count", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!isAccepted && li.rejectionReason != null && li.rejectionReason!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        "Rejection Reason: ${li.rejectionReason}",
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (li.trackingType == 'batch') ...[
                    Text("Batch Breakdown (${batches.length})", style: AppTextStyles.labelMedium),
                    const SizedBox(height: 8),
                    if (batches.isEmpty)
                      Text("No specific batches recorded.", style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted))
                    else
                      ...batches.map((b) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Batch: ${b.batchCode}", style: AppTextStyles.labelMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Mfg: ${b.manufactureDate ?? 'N/A'} | Exp: ${b.expiryDate ?? 'N/A'}",
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: (isAccepted ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Qty: ${b.quantity}",
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: isAccepted ? AppColors.success : AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  ] else if (li.trackingType == 'serial') ...[
                    Text("Serial Numbers (${serials.length})", style: AppTextStyles.labelMedium),
                    const SizedBox(height: 8),
                    if (serials.isEmpty)
                      Text("No specific serials recorded.", style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted))
                    else
                      ...serials.asMap().entries.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_rounded, size: 18, color: isAccepted ? AppColors.success : AppColors.error),
                            const SizedBox(width: 10),
                            Text("${e.key + 1}.", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.value, style: AppTextStyles.bodyMedium)),
                          ],
                        ),
                      )),
                  ] else ...[
                    Text("Untracked Item Details", style: AppTextStyles.labelMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text("Recorded Quantity:", style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$count units",
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isAccepted ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// MODALS FOR INWARDED ITEM DETAILS & EDITING
// =============================================================================

class _InwardedItemDetailsModal extends ConsumerStatefulWidget {
  final GrnLineItemModel item;
  final GrnModel grn;
  final bool initialEditing;
  final Function(GrnLineItemModel) onSave;
  final VoidCallback? onDelete;

  const _InwardedItemDetailsModal({
    required this.item,
    required this.grn,
    required this.initialEditing,
    required this.onSave,
    this.onDelete,
  });

  @override
  ConsumerState<_InwardedItemDetailsModal> createState() => _InwardedItemDetailsModalState();
}

class _InwardedItemDetailsModalState extends ConsumerState<_InwardedItemDetailsModal> {
  late bool _isEditing;
  late TextEditingController _qtyController;
  late List<GrnBatchModel> _batches;
  late List<String> _serials;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialEditing;
    _qtyController = TextEditingController(text: widget.item.receivedQuantity.toString());
    _batches = List.from(widget.item.receivedBatches);
    _serials = List.from(widget.item.receivedSerials);
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    _qtyController.dispose();
    super.dispose();
  }

  void _openBatchEditModal() {
    final targetQty = int.tryParse(_qtyController.text) ?? 0;
    if (targetQty <= 0) {
      setState(() => _errorMessage = "Please enter a valid Received Quantity greater than 0 first.");
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BatchInputModal(
        targetQty: targetQty,
        initialBatches: _batches,
        onSave: (newBatches) {
          setState(() {
            _batches = newBatches;
            _errorMessage = null;
          });
        },
      ),
    );
  }

  void _openSerialEditModal() {
    final targetQty = int.tryParse(_qtyController.text) ?? 0;
    if (targetQty <= 0) {
      setState(() => _errorMessage = "Please enter a valid Received Quantity greater than 0 first.");
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SerialInputModal(
        targetQty: targetQty,
        productSkuId: widget.item.productSkuId,
        initialSerials: _serials,
        onSave: (newSerials) {
          setState(() {
            _serials = newSerials;
            _errorMessage = null;
          });
        },
      ),
    );
  }

  void _validateAndSave() {
    setState(() => _errorMessage = null);
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      setState(() => _errorMessage = "Received Quantity must be greater than 0");
      return;
    }

    final poSkuList = ref.read(poSkuItemsProvider(widget.grn.purchaseOrderId)).value ?? [];
    for (final p in poSkuList) {
      if (p.id == widget.item.productSkuId || p.skuCode == widget.item.skuCode) {
        final maxAllowed = widget.item.receivedQuantity + p.remainingQuantity;
        if (qty > maxAllowed) {
          setState(() => _errorMessage = "Received Quantity ($qty) cannot exceed maximum allowed ($maxAllowed units, including current quantity + remaining PO units).");
          return;
        }
        break;
      }
    }

    if (widget.item.trackingType == 'batch') {
      if (_batches.isEmpty) {
        setState(() => _errorMessage = "Please configure at least one batch for this item.");
        return;
      }
      final totalBatchQty = _batches.fold<int>(0, (sum, b) => sum + b.quantity);
      if (totalBatchQty != qty) {
        setState(() => _errorMessage = "Total batch quantity ($totalBatchQty) must equal Received Quantity ($qty). Please change batches.");
        return;
      }
      for (final b in _batches) {
        if (b.batchCode.trim().isEmpty) {
          setState(() => _errorMessage = "Batch code cannot be empty.");
          return;
        }
      }
    } else if (widget.item.trackingType == 'serial') {
      if (_serials.length != qty) {
        setState(() => _errorMessage = "Number of serials (${_serials.length}) must equal Received Quantity ($qty). Please change serials.");
        return;
      }
      for (final s in _serials) {
        if (s.trim().isEmpty) {
          setState(() => _errorMessage = "Serial numbers cannot be empty.");
          return;
        }
      }
    }

    final updated = widget.item.copyWith(
      receivedQuantity: qty,
      receivedBatches: _batches,
      receivedSerials: _serials,
    );
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context);
    widget.onSave(updated);
  }

  Widget _buildViewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Received Quantity", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            Text("${widget.item.receivedQuantity} units", style: AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.item.trackingType == 'batch') ...[
          Text("Batches (${_batches.length}):", style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_batches.isEmpty)
            Text("No batches entered.", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _batches.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final b = _batches[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Batch: ${b.batchCode}", style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                          if (b.expiryDate != null && b.expiryDate!.isNotEmpty)
                            Text("Expiry: ${b.expiryDate}", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                          if ((b.manufactureDate ?? b.manufacturedDate) != null && (b.manufactureDate ?? b.manufacturedDate)!.isNotEmpty)
                            Text("Mfg: ${b.manufactureDate ?? b.manufacturedDate}", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                      Text("${b.quantity} units", style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
        ] else if (widget.item.trackingType == 'serial') ...[
          Text("Serial Numbers (${_serials.length}):", style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_serials.isEmpty)
            Text("No serial numbers entered.", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted))
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _serials.asMap().entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text("${entry.key + 1}. ${entry.value}", style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
            ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text("Untracked Item (Only quantity required)", style: AppTextStyles.caption.copyWith(color: AppColors.success)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: "Received Quantity",
          hint: "Enter units received",
          controller: _qtyController,
          keyboardType: TextInputType.number,
          onChanged: (val) => setState(() {}),
        ),
        const SizedBox(height: 16),
        if (widget.item.trackingType == 'batch') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text("Batches Configured (${_batches.length}):", style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _openBatchEditModal,
                icon: const Icon(Icons.layers_outlined, size: 16),
                label: Text(_batches.isEmpty ? "Add Batches" : "Change Batches"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_batches.isEmpty)
            Text("No batches configured yet. Click above to add.", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _batches.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final b = _batches[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Batch: ${b.batchCode}${b.expiryDate != null && b.expiryDate!.isNotEmpty ? ' (Exp: ${b.expiryDate})' : ''}", style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                      Text("${b.quantity} units", style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
        ] else if (widget.item.trackingType == 'serial') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text("Serials Entered (${_serials.length}):", style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _openSerialEditModal,
                icon: const Icon(Icons.qr_code_outlined, size: 16),
                label: Text(_serials.isEmpty ? "Add Serials" : "Change Serials"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_serials.isEmpty)
            Text("No serial numbers configured yet. Click above to add.", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted))
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _serials.asMap().entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text("${entry.key + 1}. ${entry.value}", style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
            ),
        ] else ...[
          Text("Untracked item: only received quantity is needed above.", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.9;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      child: Container(
        width: maxWidth > 600 ? 600 : maxWidth,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? "Edit Line Item" : "Inwarded Item Details",
                        style: AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.item.skuName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text("SKU: ${widget.item.skuCode}", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                const SizedBox(width: 6),
                TrackingTypeBadge(trackingType: widget.item.trackingType),
              ],
            ),
            const Divider(height: 24, color: AppColors.cardBorder),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: AppTextStyles.caption.copyWith(color: AppColors.error))),
                  ],
                ),
              ),
            ],
            Flexible(
              child: SingleChildScrollView(
                child: _isEditing ? _buildEditContent() : _buildViewContent(),
              ),
            ),
            const Divider(height: 32, color: AppColors.cardBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox.shrink(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isEditing) ...[
                      TextButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.pop(context);
                        },
                        child: const Text("Close"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          setState(() => _isEditing = true);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text("Edit"),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (widget.initialEditing) {
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              _isEditing = false;
                              _errorMessage = null;
                              _qtyController.text = widget.item.receivedQuantity.toString();
                              _batches = List.from(widget.item.receivedBatches);
                              _serials = List.from(widget.item.receivedSerials);
                            });
                          }
                        },
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _validateAndSave,
                        child: const Text("Save & Update"),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchInputModal extends StatefulWidget {
  final int targetQty;
  final List<GrnBatchModel> initialBatches;
  final Function(List<GrnBatchModel>) onSave;

  const _BatchInputModal({required this.targetQty, required this.initialBatches, required this.onSave});

  @override
  State<_BatchInputModal> createState() => _BatchInputModalState();
}

class _BatchInputModalState extends State<_BatchInputModal> {
  late List<GrnBatchModel> _batches;

  @override
  void initState() {
    super.initState();
    _batches = List.from(widget.initialBatches);
    if (_batches.isEmpty) {
      _batches.add(const GrnBatchModel(quantity: 0, batchCode: '', manufactureDate: '', expiryDate: ''));
    }
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, int index, bool isMfg) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        final b = _batches[index];
        if (isMfg) {
          _batches[index] = b.copyWith(manufactureDate: formatted);
        } else {
          _batches[index] = b.copyWith(expiryDate: formatted);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSum = _batches.fold<int>(0, (sum, b) => sum + b.quantity);
    final isValid = currentSum == widget.targetQty && _batches.every((b) => b.batchCode.trim().isNotEmpty);

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text("Add Batches (Target Qty: ${widget.targetQty})", style: AppTextStyles.headingMedium)),
          const SizedBox(width: 8),
          const TrackingTypeBadge(trackingType: 'batch'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Total entered: $currentSum / ${widget.targetQty}",
                  style: AppTextStyles.labelMedium.copyWith(
                      color: isValid ? AppColors.success : AppColors.error)),
              const SizedBox(height: 16),
              ..._batches.asMap().entries.map((entry) {
                final idx = entry.key;
                final batch = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: batch.batchCode,
                              decoration: const InputDecoration(labelText: "Batch Code *", hintText: "e.g., BH-1"),
                              onChanged: (val) => _batches[idx] = _batches[idx].copyWith(batchCode: val),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: TextFormField(
                              initialValue: batch.quantity > 0 ? batch.quantity.toString() : '',
                              decoration: const InputDecoration(labelText: "Qty *", ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => setState(() => _batches[idx] = _batches[idx].copyWith(quantity: int.tryParse(val) ?? 0)),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () => setState(() => _batches.removeAt(idx)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, idx, true),
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: "Mfg. Date *", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(batch.manufactureDate ?? "Select", style: AppTextStyles.caption),
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, idx, false),
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: "Exp. Date", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(batch.expiryDate ?? "Select", style: AppTextStyles.caption),
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Add One More Row"),
                onPressed: () => setState(() => _batches.add(const GrnBatchModel(quantity: 0, batchCode: '', manufactureDate: '', expiryDate: ''))),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: isValid
              ? () {
                  FocusScope.of(context).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                  widget.onSave(_batches);
                  Navigator.pop(context);
                }
              : null,
          child: const Text("Save Batches"),
        ),
      ],
    );
  }
}

class _SerialInputModal extends ConsumerStatefulWidget {
  final int targetQty;
  final int productSkuId;
  final List<String> initialSerials;
  final Function(List<String>) onSave;

  const _SerialInputModal({required this.targetQty, required this.productSkuId, required this.initialSerials, required this.onSave});

  @override
  ConsumerState<_SerialInputModal> createState() => _SerialInputModalState();
}

class _SerialInputModalState extends ConsumerState<_SerialInputModal> {
  late List<String> _serials;
  final _manualController = TextEditingController();
  final _bulkController = TextEditingController();
  
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  int _selectedTab = 0; // 0: Manual, 1: Bulk, 2: Barcode
  String? _warningMsg;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _serials = List.from(widget.initialSerials);
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    _manualController.dispose();
    _bulkController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _addManualSerial() async {
    final s = _manualController.text.trim();
    if (s.isEmpty) return;
    if (_serials.contains(s)) {
      setState(() => _warningMsg = "Serial '$s' already added in this list.");
      return;
    }

    setState(() {
      _isValidating = true;
      _warningMsg = null;
    });

    final isValid = await ref.read(grnControllerProvider.notifier).validateSerial(s, widget.productSkuId);
    
    if (!mounted) return;
    setState(() {
      _isValidating = false;
    });

    if (!isValid) {
      setState(() => _warningMsg = "Serial '$s' already exists in inventory or is invalid!");
      return;
    }
    setState(() {
      _serials.add(s);
      _manualController.clear();
      _warningMsg = null;
    });
  }

  void _processBulkSerials() {
    final text = _bulkController.text;
    final parsed = text.split(RegExp(r'[,\\n\\r]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    setState(() {
      for (final p in parsed) {
        if (!_serials.contains(p) && _serials.length < widget.targetQty) {
          _serials.add(p);
        }
      }
      _bulkController.clear();
    });
  }

  Future<void> _handleBarcodeDetect(BarcodeCapture capture) async {
    if (_serials.length >= widget.targetQty) return;
    
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final s = barcode.rawValue?.trim();
      if (s != null && s.isNotEmpty && !_serials.contains(s)) {
        if (mounted) {
          setState(() {
            _isValidating = true;
            _warningMsg = null;
          });
        }
        
        final isValid = await ref.read(grnControllerProvider.notifier).validateSerial(s, widget.productSkuId);
        
        if (!mounted) return;
        setState(() {
          _isValidating = false;
        });

        if (!isValid) {
          setState(() => _warningMsg = "Serial '$s' already exists in inventory or is invalid!");
        } else {
          HapticFeedback.lightImpact();
          showTopSuccessSnackBar(context, "Detected: $s");
          setState(() {
            _serials.add(s);
            _warningMsg = null;
          });
        }
        
        // Return after processing the first valid one in this capture
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _serials.length == widget.targetQty;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text("Add Serials (Target: ${widget.targetQty})", style: AppTextStyles.headingMedium)),
          const SizedBox(width: 8),
          const TrackingTypeBadge(trackingType: 'serial'),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Total entered: ${_serials.length} / ${widget.targetQty} (Click any chip below to edit & resubmit)",
                  style: AppTextStyles.labelMedium.copyWith(
                      color: isValid ? AppColors.success : AppColors.error)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _tabBtn("Manual Input", 0),
                  _tabBtn("Barcode Scan", 1),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedTab == 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualController,
                        decoration: const InputDecoration(labelText: "Enter Serial Number", hintText: "e.g., SERR-1001"),
                        onSubmitted: (_) => _addManualSerial(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isValidating ? null : _addManualSerial,
                      child: _isValidating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Add"),
                    ),
                  ],
                ),
              ] else if (_selectedTab == 1) ...[
                TextField(
                  controller: _bulkController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Paste comma or newline separated serials",
                    hintText: "SERR-1, SERR-2\\nSERR-3",
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _processBulkSerials, child: const Text("Process Bulk Serials")),
              ] else ...[
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: MobileScanner(
                          controller: _scannerController,
                          onDetect: _handleBarcodeDetect,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Point the camera at a barcode to scan.",
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
              if (_warningMsg != null) ...[
                const SizedBox(height: 10),
                Text(_warningMsg!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              Text("Added Serials (Click chip to edit):", style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _serials.map((s) {
                  return InputChip(
                    label: Text(s, style: AppTextStyles.caption),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _serials.remove(s)),
                    onPressed: () {
                      setState(() {
                        _serials.remove(s);
                        _manualController.text = s;
                        _selectedTab = 0;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: isValid
              ? () {
                  FocusScope.of(context).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                  widget.onSave(_serials);
                  Navigator.pop(context);
                }
              : null,
          child: const Text("Save Serials"),
        ),
      ],
    );
  }

  Widget _tabBtn(String label, int index) {
    final isSel = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: AppTextStyles.caption.copyWith(color: isSel ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}

// =============================================================================
// MODALS FOR QC CHECK (Two-Way Auto-Calc, Default Checked, Mandatory Reason)
// =============================================================================

class _QcBatchModal extends StatefulWidget {
  final GrnLineItemModel item;
  final Function(GrnLineItemModel) onSave;

  const _QcBatchModal({required this.item, required this.onSave});

  @override
  State<_QcBatchModal> createState() => _QcBatchModalState();
}

class _QcBatchModalState extends State<_QcBatchModal> {
  late List<TextEditingController> _goodControllers;
  late List<TextEditingController> _badControllers;

  @override
  void initState() {
    super.initState();
    _goodControllers = widget.item.receivedBatches.map((b) => TextEditingController(text: b.quantity.toString())).toList();
    _badControllers = widget.item.receivedBatches.map((b) => TextEditingController(text: "0")).toList();
  }

  @override
  void dispose() {
    for (final c in _goodControllers) {
      c.dispose();
    }
    for (final c in _badControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batches = widget.item.receivedBatches;

    final isAllValid = batches.asMap().entries.every((e) {
      final idx = e.key;
      final b = e.value;
      final good = int.tryParse(_goodControllers[idx].text) ?? -1;
      final bad = int.tryParse(_badControllers[idx].text) ?? -1;
      return good >= 0 && bad >= 0 && (good + bad) == b.quantity;
    });

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text("QC Check: Confirm Batches (${widget.item.skuName})", style: AppTextStyles.headingMedium)),
          const SizedBox(width: 8),
          const TrackingTypeBadge(trackingType: 'batch'),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter Good Qty or Bad Qty for each batch. Total (Good + Bad) must equal Received Qty.",
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ...batches.asMap().entries.map((entry) {
                final idx = entry.key;
                final b = entry.value;
                final good = int.tryParse(_goodControllers[idx].text) ?? 0;
                final bad = int.tryParse(_badControllers[idx].text) ?? 0;
                final isValid = (good + bad) == b.quantity && good >= 0 && bad >= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: isValid ? null : Border.all(color: AppColors.error),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Batch: ${b.batchCode}", style: AppTextStyles.labelMedium),
                                Text("Received Qty: ${b.quantity}", style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _goodControllers[idx],
                              decoration: const InputDecoration(labelText: "Good Qty"),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _badControllers[idx],
                              decoration: const InputDecoration(labelText: "Bad Qty"),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      if (!isValid)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "Error: Good ($good) + Bad ($bad) must equal Received (${b.quantity})",
                            style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isAllValid ? AppColors.primary : AppColors.textMuted,
            foregroundColor: Colors.white,
          ),
          onPressed: isAllValid ? () {
            int totGood = 0;
            int totBad = 0;
            List<GrnBatchModel> accBatches = [];
            List<GrnBatchModel> rejBatches = [];

            for (int i = 0; i < batches.length; i++) {
              final b = batches[i];
              final good = int.tryParse(_goodControllers[i].text) ?? 0;
              final bad = int.tryParse(_badControllers[i].text) ?? 0;
              totGood += good;
              totBad += bad;
              if (good > 0) accBatches.add(b.copyWith(quantity: good));
              if (bad > 0) rejBatches.add(b.copyWith(quantity: bad));
            }

            final updated = widget.item.copyWith(
              acceptedQuantity: totGood,
              rejectedQuantity: totBad,
              acceptedAmount: '0.0', // No prices
              rejectedAmount: '0.0',
              finalAmount: 0.0,
              acceptedBatches: accBatches,
              rejectedBatches: rejBatches,
            );

            Navigator.pop(context);
            widget.onSave(updated);
          } : null,
          child: const Text("Confirm Batches"),
        ),
      ],
    );
  }
}

class _QcSerialModal extends StatefulWidget {
  final GrnLineItemModel item;
  final Function(GrnLineItemModel) onSave;

  const _QcSerialModal({required this.item, required this.onSave});

  @override
  State<_QcSerialModal> createState() => _QcSerialModalState();
}

class _QcSerialModalState extends State<_QcSerialModal> {
  late Set<String> _acceptedSerials;

  @override
  void initState() {
    super.initState();
    // Checkboxes checked by default (meaning all are good qty)
    _acceptedSerials = Set.from(widget.item.receivedSerials);
  }

  @override
  Widget build(BuildContext context) {
    final serials = widget.item.receivedSerials;
    final totGood = _acceptedSerials.length;
    final totBad = serials.length - totGood;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text("QC Check: Confirm Serial (${widget.item.skuName})", style: AppTextStyles.headingMedium)),
          const SizedBox(width: 8),
          const TrackingTypeBadge(trackingType: 'serial'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("All serial numbers are checked by default (Good Qty). Uncheck any serials that failed inspection (Bad Qty).",
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Good Qty: $totGood", style: AppTextStyles.labelMedium.copyWith(color: AppColors.success)),
                  Text("Bad Qty: $totBad", style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
                ],
              ),
              const SizedBox(height: 12),
              ...serials.map((s) {
                final isGood = _acceptedSerials.contains(s);
                return CheckboxListTile(
                  title: Text(s, style: AppTextStyles.bodyMedium),
                  subtitle: Text(isGood ? "Status: Good Qty" : "Status: Bad Qty (Rejected)",
                      style: AppTextStyles.caption.copyWith(color: isGood ? AppColors.success : AppColors.error)),
                  value: isGood,
                  activeColor: AppColors.success,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _acceptedSerials.add(s);
                      } else {
                        _acceptedSerials.remove(s);
                      }
                    });
                  },
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () {
            final accList = _acceptedSerials.toList();
            final rejList = serials.where((s) => !_acceptedSerials.contains(s)).toList();

            final updated = widget.item.copyWith(
              acceptedQuantity: totGood,
              rejectedQuantity: totBad,
              acceptedAmount: '0.0', // No prices
              rejectedAmount: '0.0',
              finalAmount: 0.0,
              acceptedSerials: accList,
              rejectedSerials: rejList,
            );

            Navigator.pop(context);
            widget.onSave(updated);
          },
          child: const Text("Confirm Serial"),
        ),
      ],
    );
  }
}

class _QcUntrackedModal extends StatefulWidget {
  final GrnLineItemModel item;
  final Function(GrnLineItemModel) onSave;

  const _QcUntrackedModal({required this.item, required this.onSave});

  @override
  State<_QcUntrackedModal> createState() => _QcUntrackedModalState();
}

class _QcUntrackedModalState extends State<_QcUntrackedModal> {
  late TextEditingController _acceptedController;

  @override
  void initState() {
    super.initState();
    _acceptedController = TextEditingController(text: widget.item.receivedQuantity.toString());
  }

  @override
  void dispose() {
    _acceptedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.item.receivedQuantity;
    final acceptedVal = int.tryParse(_acceptedController.text) ?? -1;
    final isValid = acceptedVal >= 0 && acceptedVal <= rec;
    final rej = isValid ? rec - acceptedVal : 0;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text("QC Check: Confirm Qty (${widget.item.skuName})", style: AppTextStyles.headingMedium)),
          const SizedBox(width: 8),
          const TrackingTypeBadge(trackingType: 'untracked'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Enter Good Qty (Accepted) out of Received ($rec units).",
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _acceptedController,
            decoration: const InputDecoration(labelText: "Good Qty (Accepted)"),
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() {}),
          ),
          if (!isValid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Error: Good Qty must be between 0 and $rec",
                style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Bad Qty (Rejected):", style: AppTextStyles.labelMedium),
              Text("$rej units", style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isValid ? AppColors.primary : AppColors.textMuted,
            foregroundColor: Colors.white,
          ),
          onPressed: isValid ? () {
            final updated = widget.item.copyWith(
              acceptedQuantity: acceptedVal,
              rejectedQuantity: rej,
              acceptedAmount: '0.0', // No prices
              rejectedAmount: '0.0',
              finalAmount: 0.0,
            );
            Navigator.pop(context);
            widget.onSave(updated);
          } : null,
          child: const Text("Confirm Qty"),
        ),
      ],
    );
  }
}

class _RejectionReasonModal extends StatefulWidget {
  final Function(String) onSave;

  const _RejectionReasonModal({required this.onSave});

  @override
  State<_RejectionReasonModal> createState() => _RejectionReasonModalState();
}

class _RejectionReasonModalState extends State<_RejectionReasonModal> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _reasonController.text.trim().isNotEmpty;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 8),
          Text("Mandatory Rejection Reason", style: AppTextStyles.headingMedium),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("You have recorded 1 or more units as Bad Qty (Rejected) for this product. Please enter the reason for rejection.",
                style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: "Rejection Reason *",
                hintText: "Enter exact issue (e.g. Damaged during transit, quality mismatch)",
              ),
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isValid ? AppColors.error : AppColors.textMuted,
            foregroundColor: Colors.white,
          ),
          onPressed: isValid
              ? () {
                  widget.onSave(_reasonController.text.trim());
                  Navigator.pop(context);
                }
              : null,
          child: const Text("Save Reason & Continue"),
        ),
      ],
    );
  }
}
