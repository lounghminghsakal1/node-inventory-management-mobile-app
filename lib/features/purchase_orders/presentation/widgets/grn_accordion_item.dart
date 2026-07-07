import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/purchase_order_model.dart';
import '../../providers/purchase_order_provider.dart';

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
  PoSkuItemModel? _selectedPoItem;
  final _receivedQtyController = TextEditingController();
  List<GrnBatchModel> _tempBatches = [];
  List<String> _tempSerials = [];

  // QC state (for 'qc_pending' status)
  final Map<int, GrnLineItemModel> _qcModifiedItems = {};
  bool _qcSubmitted = false;

  @override
  void dispose() {
    _receivedQtyController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GrnAccordionItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.grn.id != widget.grn.id || oldWidget.grn.status != widget.grn.status) {
      _qcModifiedItems.clear();
      _qcSubmitted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grn = widget.grn;
    final statusLower = grn.status.toLowerCase();

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
                          'Received: ${grn.receivedDate ?? "N/A"} • Items: ${grn.lineItems.length}',
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
              child: _buildExpandedBody(statusLower),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedBody(String statusLower) {
    if (statusLower == 'created') {
      return _buildCreatedStatusView();
    } else if (statusLower == 'qc_pending' || statusLower == 'waiting_for_approval') {
      return _buildQcPendingStatusView();
    } else {
      return _buildCompletedStatusView();
    }
  }

  // ===========================================================================
  // 1. CREATED STATUS VIEW (No Price Fields, Inwarding with Batch/Serial Modals)
  // ===========================================================================
  Widget _buildCreatedStatusView() {
    final grn = widget.grn;
    final asyncSkuItems = ref.watch(poSkuItemsProvider(grn.purchaseOrderId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "GRN Status: CREATED. Select line items that came to node, enter received quantities (up to remaining units), and attach batches/serials. All price fields are hidden.",
                  style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Inwarding Form
        Text("Inward Line Items", style: AppTextStyles.headingMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: asyncSkuItems.when(
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
                  Text("Select Purchase Order Line Item", style: AppTextStyles.labelMedium),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<PoSkuItemModel>(
                    value: _selectedPoItem,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    hint: const Text("Choose SKU line item to inward"),
                    items: skuItems.map((poLi) {
                      final isFulfilled = poLi.fullyFulfilled || poLi.remainingQuantity <= 0;
                      return DropdownMenuItem<PoSkuItemModel>(
                        value: isFulfilled ? null : poLi,
                        enabled: !isFulfilled,
                        child: Text(
                          "${poLi.skuName} (Rem: ${poLi.remainingQuantity} / Total: ${poLi.totalUnits} • ${poLi.selectionType} • ${poLi.trackingType.toUpperCase()})${isFulfilled ? ' - FULFILLED' : ''}",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isFulfilled ? AppColors.textMuted : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedPoItem = val;
                        _receivedQtyController.text = val?.remainingQuantity.toString() ?? '';
                        _tempBatches.clear();
                        _tempSerials.clear();
                      });
                    },
                  ),
                  if (_selectedPoItem != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: "Received Qty (Max: ${_selectedPoItem!.remainingQuantity})",
                            controller: _receivedQtyController,
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (_selectedPoItem!.trackingType == 'batch')
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.layers_outlined, size: 18),
                            label: Text("Add Batches (${_tempBatches.length})"),
                            onPressed: _openBatchModal,
                          )
                        else if (_selectedPoItem!.trackingType == 'serial')
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.qr_code_scanner_outlined, size: 18),
                            label: Text("Add Serials (${_tempSerials.length})"),
                            onPressed: _openSerialModal,
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text("Untracked Item",
                                style: AppTextStyles.labelMedium.copyWith(color: AppColors.success)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: "Add Item to GRN",
                        icon: Icons.add_circle_outline,
                        height: 46,
                        onPressed: _addItemToGrn,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
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
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(li.skuName, style: AppTextStyles.labelMedium),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(child: Text("SKU: ${li.skuCode}", style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(li.trackingType.toUpperCase(),
                                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          if (li.receivedBatches.isNotEmpty || li.receivedSerials.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _showDetailsPopup(li, isAccepted: true, isReceivedOnly: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.visibility_outlined, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      li.trackingType == 'batch'
                                          ? "View Batches (${li.receivedBatches.length})"
                                          : "View Serials (${li.receivedSerials.length})",
                                      style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${li.receivedQuantity} units",
                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _editGrnItem(li),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _removeGrnItem(li),
                            ),
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
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: "Proceed to QC",
            icon: Icons.arrow_forward_rounded,
            onPressed: grn.lineItems.isEmpty ? null : _proceedToQc,
          ),
        ),
      ],
    );
  }

  void _openBatchModal() {
    final qtyVal = int.tryParse(_receivedQtyController.text) ?? 0;
    if (qtyVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid Received Qty first"), backgroundColor: AppColors.error),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _BatchInputModal(
        targetQty: qtyVal,
        initialBatches: _tempBatches,
        onSave: (batches) {
          setState(() {
            _tempBatches = batches;
          });
        },
      ),
    );
  }

  void _openSerialModal() {
    final qtyVal = int.tryParse(_receivedQtyController.text) ?? 0;
    if (qtyVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid Received Qty first"), backgroundColor: AppColors.error),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _SerialInputModal(
        targetQty: qtyVal,
        initialSerials: _tempSerials,
        onSave: (serials) {
          setState(() {
            _tempSerials = serials;
          });
        },
      ),
    );
  }

  void _addItemToGrn() {
    final qtyVal = int.tryParse(_receivedQtyController.text) ?? 0;
    if (qtyVal <= 0 || qtyVal > (_selectedPoItem!.remainingQuantity)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Quantity must be between 1 and ${_selectedPoItem!.remainingQuantity}"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedPoItem!.trackingType == 'batch') {
      final totalBatchQty = _tempBatches.fold<int>(0, (sum, b) => sum + b.quantity);
      if (totalBatchQty != qtyVal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Total batch quantity ($totalBatchQty) must equal received quantity ($qtyVal)"),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } else if (_selectedPoItem!.trackingType == 'serial') {
      if (_tempSerials.length != qtyVal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Total serials count (${_tempSerials.length}) must equal received quantity ($qtyVal)"),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final newItem = GrnLineItemModel(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      productSkuId: _selectedPoItem!.productSkuId,
      skuName: _selectedPoItem!.skuName,
      skuCode: _selectedPoItem!.skuCode,
      trackingType: _selectedPoItem!.trackingType,
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
      receivedBatches: _tempBatches,
      receivedSerials: _tempSerials,
      acceptedBatches: [],
      acceptedSerials: [],
      rejectedBatches: [],
      rejectedSerials: [],
    );

    final updatedList = List<GrnLineItemModel>.from(widget.grn.lineItems)..add(newItem);
    ref.read(grnControllerProvider.notifier).updateGrnLineItems(widget.grn.id, widget.grn.purchaseOrderId, updatedList);

    setState(() {
      _selectedPoItem = null;
      _receivedQtyController.clear();
      _tempBatches.clear();
      _tempSerials.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Item added to GRN"), backgroundColor: AppColors.success),
    );
  }

  void _editGrnItem(GrnLineItemModel li) {
    final asyncSkuItems = ref.read(poSkuItemsProvider(widget.grn.purchaseOrderId));
    asyncSkuItems.whenData((skuItems) {
      final skuItem = skuItems.firstWhere(
        (p) => p.productSkuId == li.productSkuId,
        orElse: () => skuItems.first,
      );
      setState(() {
        _selectedPoItem = skuItem;
        _receivedQtyController.text = li.receivedQuantity.toString();
        _tempBatches = List.from(li.receivedBatches);
        _tempSerials = List.from(li.receivedSerials);
      });
      _removeGrnItem(li);
    });
  }

  void _removeGrnItem(GrnLineItemModel li) {
    final updatedList = widget.grn.lineItems.where((item) => item.id != li.id).toList();
    ref.read(grnControllerProvider.notifier).updateGrnLineItems(widget.grn.id, widget.grn.purchaseOrderId, updatedList);
  }

  void _proceedToQc() {
    ref.read(grnControllerProvider.notifier).updateStatus(widget.grn.id, widget.grn.purchaseOrderId, 'qc_pending');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("GRN transitioned to QC Pending! Details refreshed."), backgroundColor: AppColors.success),
    );
  }

  // ===========================================================================
  // 2. QC PENDING STATUS VIEW (No Price Fields, Dynamic Action Buttons)
  // ===========================================================================
  Widget _buildQcPendingStatusView() {
    final grn = widget.grn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment_late_outlined, color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "GRN Status: QC PENDING. Perform QC inspections by clicking the action button on each product row. Rejection reasons are mandatory when any bad quantity is recorded.",
                  style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Quality Check Items", style: AppTextStyles.headingMedium),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              icon: const Icon(Icons.fact_check_outlined, size: 16),
              label: const Text("QC Check"),
              onPressed: () {
                if (grn.lineItems.isNotEmpty) {
                  _openQcModal(_qcModifiedItems[grn.lineItems.first.id] ?? grn.lineItems.first);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                            const SizedBox(height: 4),
                            Text("SKU: ${activeItem.skuCode} • Type: ${activeItem.trackingType.toUpperCase()}",
                                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isModified ? AppColors.success : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(isModified ? Icons.check_circle_outline : Icons.fact_check_outlined, size: 16),
                        label: Text(isModified ? "Confirmed ($buttonLabel)" : buttonLabel),
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

        // Submit QC & Complete GRN CTAs
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: "Submit QC",
                icon: Icons.done_all,
                isOutlined: true,
                onPressed: _submitQc,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppButton(
                label: "Complete GRN",
                icon: Icons.check_circle,
                onPressed: _qcSubmitted ? _completeGrn : null,
              ),
            ),
          ],
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
        builder: (ctx) => _QcBatchModal(
          item: item,
          onSave: (updatedItem) => _handleQcItemSave(updatedItem),
        ),
      );
    } else if (item.trackingType == 'serial') {
      showDialog(
        context: context,
        builder: (ctx) => _QcSerialModal(
          item: item,
          onSave: (updatedItem) => _handleQcItemSave(updatedItem),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => _QcUntrackedModal(
          item: item,
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

  void _submitQc() {
    final allItems = widget.grn.lineItems.map((li) => _qcModifiedItems[li.id] ?? li).toList();
    ref.read(grnControllerProvider.notifier).submitQc(widget.grn.id, widget.grn.purchaseOrderId, allItems);
    setState(() {
      _qcSubmitted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Quality Check submitted successfully! You can now Complete GRN."), backgroundColor: AppColors.success),
    );
  }

  void _completeGrn() {
    ref.read(grnControllerProvider.notifier).updateStatus(widget.grn.id, widget.grn.purchaseOrderId, 'completed');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("GRN marked as COMPLETED!"), backgroundColor: AppColors.success),
    );
  }

  // ===========================================================================
  // 3. COMPLETED STATUS VIEW (Read-Only Summary Without Price Fields)
  // ===========================================================================
  Widget _buildCompletedStatusView() {
    final grn = widget.grn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "GRN Status: ${grn.status.toUpperCase()}. Quality inspection complete and line items accepted into inventory.",
                  style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Invoice Metadata
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _qcStatCol("Invoice No", grn.vendorInvoiceNo ?? "N/A", AppColors.textPrimary),
              _qcStatCol("Invoice Date", grn.vendorInvoiceDate ?? "N/A", AppColors.textPrimary),
              _qcStatCol("Received Date", grn.receivedDate ?? "N/A", AppColors.textPrimary),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Line Items Summary Without Prices
        Text("Inwarded Line Items (${grn.lineItems.length})", style: AppTextStyles.headingMedium),
        const SizedBox(height: 10),
        Column(
          children: grn.lineItems.map((li) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(li.trackingType.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                    padding: const EdgeInsets.all(12),
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
                        Text(
                          "SKU: ${li.skuCode} • Type: ${li.trackingType.toUpperCase()} • Total: $count",
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
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
                          Text("Recorded Quantity:", style: AppTextStyles.bodyMedium),
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
// MODALS FOR INWARDING (Batches & Serials with 4 Fields, Add Row & Click-to-Edit)
// =============================================================================

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
    final isValid = currentSum == widget.targetQty;

    return AlertDialog(
      title: Text("Add Batches (Target Qty: ${widget.targetQty})", style: AppTextStyles.headingMedium),
      content: SizedBox(
        width: 650,
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
                  padding: const EdgeInsets.all(12),
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
                              onChanged: (val) => _batches[idx] = batch.copyWith(batchCode: val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: batch.quantity > 0 ? batch.quantity.toString() : '',
                              decoration: const InputDecoration(labelText: "Quantity *"),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => _batches[idx] = batch.copyWith(quantity: int.tryParse(val) ?? 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
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
                                decoration: const InputDecoration(labelText: "Manufactured Date", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(batch.manufactureDate ?? "Select Date", style: AppTextStyles.caption),
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, idx, false),
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: "Expiry Date", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(batch.expiryDate ?? "Select Date", style: AppTextStyles.caption),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: isValid
              ? () {
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
  final List<String> initialSerials;
  final Function(List<String>) onSave;

  const _SerialInputModal({required this.targetQty, required this.initialSerials, required this.onSave});

  @override
  ConsumerState<_SerialInputModal> createState() => _SerialInputModalState();
}

class _SerialInputModalState extends ConsumerState<_SerialInputModal> {
  late List<String> _serials;
  final _manualController = TextEditingController();
  final _bulkController = TextEditingController();
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
    _manualController.dispose();
    _bulkController.dispose();
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

    final isValid = await ref.read(grnControllerProvider.notifier).validateSerial(s);
    
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

  void _simulateBarcodeScan() {
    if (_serials.length >= widget.targetQty) return;
    final scanned = "SER-${DateTime.now().millisecondsSinceEpoch % 1000000}";
    setState(() => _serials.add(scanned));
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _serials.length == widget.targetQty;

    return AlertDialog(
      title: Text("Add Serials (Target: ${widget.targetQty})", style: AppTextStyles.headingMedium),
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
                  _tabBtn("Bulk Upload", 1),
                  _tabBtn("Barcode Scan", 2),
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
                      const Icon(Icons.qr_code_scanner, size: 48, color: AppColors.primary),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text("Simulate Barcode Scan"),
                        onPressed: _simulateBarcodeScan,
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: isValid
              ? () {
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
  late List<int> _goodQtys;
  late List<int> _badQtys;

  @override
  void initState() {
    super.initState();
    _goodQtys = widget.item.receivedBatches.map((b) => b.quantity).toList();
    _badQtys = widget.item.receivedBatches.map((b) => 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    final batches = widget.item.receivedBatches;

    return AlertDialog(
      title: Text("QC Check: Confirm Batches (${widget.item.skuName})", style: AppTextStyles.headingMedium),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter Good Qty or Bad Qty for each batch. Both values auto-calculate dynamically based on Received Qty.",
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ...batches.asMap().entries.map((entry) {
                final idx = entry.key;
                final b = entry.value;
                final good = _goodQtys[idx];
                final bad = _badQtys[idx];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
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
                          key: ValueKey("good_${idx}_$good"),
                          initialValue: good.toString(),
                          decoration: const InputDecoration(labelText: "Good Qty"),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final v = int.tryParse(val) ?? 0;
                            if (v >= 0 && v <= b.quantity) {
                              setState(() {
                                _goodQtys[idx] = v;
                                _badQtys[idx] = b.quantity - v;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey("bad_${idx}_$bad"),
                          initialValue: bad.toString(),
                          decoration: const InputDecoration(labelText: "Bad Qty"),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final v = int.tryParse(val) ?? 0;
                            if (v >= 0 && v <= b.quantity) {
                              setState(() {
                                _badQtys[idx] = v;
                                _goodQtys[idx] = b.quantity - v;
                              });
                            }
                          },
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
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () {
            int totGood = 0;
            int totBad = 0;
            List<GrnBatchModel> accBatches = [];
            List<GrnBatchModel> rejBatches = [];

            for (int i = 0; i < batches.length; i++) {
              final b = batches[i];
              final good = _goodQtys[i];
              final bad = _badQtys[i];
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

            widget.onSave(updated);
            Navigator.pop(context);
          },
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
      title: Text("QC Check: Confirm Serial (${widget.item.skuName})", style: AppTextStyles.headingMedium),
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

            widget.onSave(updated);
            Navigator.pop(context);
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
  late int _accepted;

  @override
  void initState() {
    super.initState();
    _accepted = widget.item.receivedQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.item.receivedQuantity;
    final rej = rec - _accepted;

    return AlertDialog(
      title: Text("QC Check: Confirm Qty (${widget.item.skuName})", style: AppTextStyles.headingMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Enter Good Qty (Accepted) out of Received ($rec units).",
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _accepted.toString(),
            decoration: const InputDecoration(labelText: "Good Qty (Accepted)"),
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final v = int.tryParse(val) ?? 0;
              if (v >= 0 && v <= rec) {
                setState(() => _accepted = v);
              }
            },
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
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () {
            final updated = widget.item.copyWith(
              acceptedQuantity: _accepted,
              rejectedQuantity: rej,
              acceptedAmount: '0.0', // No prices
              rejectedAmount: '0.0',
              finalAmount: 0.0,
            );
            widget.onSave(updated);
            Navigator.pop(context);
          },
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
  String? _selectedReason;
  final _customController = TextEditingController();

  final List<String> _commonReasons = [
    "Damaged during transit",
    "Quality grade mismatch",
    "Expired or near expiry date",
    "Packaging damaged / broken seal",
    "Incorrect specification / dimensions",
    "Other (specify below)",
  ];

  @override
  Widget build(BuildContext context) {
    final isOther = _selectedReason == "Other (specify below)";
    final isValid = _selectedReason != null && (!isOther || _customController.text.trim().isNotEmpty);

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
            Text("You have recorded 1 or more units as Bad Qty (Rejected) for this product. Please provide a mandatory reason for rejection.",
                style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ..._commonReasons.map((r) {
              return RadioListTile<String>(
                title: Text(r, style: AppTextStyles.bodyMedium),
                value: r,
                groupValue: _selectedReason,
                activeColor: AppColors.error,
                onChanged: (val) => setState(() => _selectedReason = val),
              );
            }),
            if (isOther) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customController,
                decoration: const InputDecoration(labelText: "Specify Reason *", hintText: "Enter exact issue"),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
          onPressed: isValid
              ? () {
                  final reason = isOther ? _customController.text.trim() : _selectedReason!;
                  widget.onSave(reason);
                  Navigator.pop(context);
                }
              : null,
          child: const Text("Save Reason & Continue"),
        ),
      ],
    );
  }
}
