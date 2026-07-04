import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/shipment.dart';
import '../../data/models/order.dart';
import '../../providers/shipment_provider.dart';

class ShipmentDetailScreen extends ConsumerWidget {
  final String shipmentId;
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipment = ref.watch(shipmentByIdProvider(shipmentId));

    if (shipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shipment')),
        body: const Center(child: Text('Shipment not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: NodeOpsAppBar(
        showBack: true,
        title: shipment.shipmentNumber,
        extraActions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: StatusBadge(status: shipment.status.value, large: true),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Progress Timeline ──────────────────────────────────────────
            _ShipmentTimeline(status: shipment.status),
            const SizedBox(height: 24),

            // ── Info Card ─────────────────────────────────────────────────
            _SectionCard(
              title: 'Order Info',
              child: Column(
                children: [
                  _infoTile(Icons.receipt_outlined, 'Order Number',
                      shipment.orderNumber),
                  _infoTile(Icons.storefront_outlined, 'Customer',
                      shipment.customerName),
                  _infoTile(Icons.calendar_today_outlined, 'Created',
                      _formatDate(shipment.createdAt)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Line Items ────────────────────────────────────────────────
            _SectionCard(
              title: 'Line Items (${shipment.lineItems.length})',
              child: Column(
                children: shipment.lineItems
                    .map((li) => _LineItemRow(item: li, shipment: shipment))
                    .toList(),
              ),
            ),

            // ── Driver (if dispatched) ────────────────────────────────────
            if (shipment.driverDetails != null) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Driver Details',
                child: Column(children: [
                  _infoTile(Icons.person_outline_rounded, 'Driver Name',
                      shipment.driverDetails!.name),
                  _infoTile(Icons.phone_outlined, 'Phone',
                      shipment.driverDetails!.phone),
                  _infoTile(Icons.directions_car_outlined, 'Vehicle',
                      shipment.driverDetails!.vehicleNumber),
                ]),
              ),
            ],

            // ── Invoice Details (if invoiced, dispatched, or delivered) ───
            if (shipment.status == ShipmentStatus.invoiced ||
                shipment.status == ShipmentStatus.dispatched ||
                shipment.status == ShipmentStatus.delivered) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Invoice Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoice for ${shipment.shipmentNumber} is generated and ready.',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Downloading Invoice PDF...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'https://flaerhomes.com/invoices/${shipment.shipmentNumber}.pdf',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Click to download invoice',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Action Buttons ────────────────────────────────────────────
            _ActionButtons(shipment: shipment),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(value,
              style: AppTextStyles.labelLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Progress Timeline ─────────────────────────────────────────────────────────
class _ShipmentTimeline extends StatelessWidget {
  final ShipmentStatus status;
  const _ShipmentTimeline({required this.status});

  static const _stages = [
    ('Created', ShipmentStatus.created, Icons.add_circle_outline_rounded),
    ('Allocated', ShipmentStatus.allocated, Icons.inventory_outlined),
    ('Packed', ShipmentStatus.packed, Icons.inventory_2_outlined),
    ('Invoiced', ShipmentStatus.invoiced, Icons.receipt_long_outlined),
    ('Dispatched', ShipmentStatus.dispatched, Icons.local_shipping_outlined),
    ('Delivered', ShipmentStatus.delivered, Icons.check_circle_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _stages.indexWhere((s) => s.$2 == status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: List.generate(_stages.length, (i) {
          final stage = _stages[i];
          final isDone = i <= currentIdx && currentIdx != -1;
          final isCurrent = i == currentIdx;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i <= currentIdx && currentIdx != -1
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 30 : 24,
                      height: isCurrent ? 30 : 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? (isCurrent
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.2))
                            : AppColors.card,
                        border: Border.all(
                          color: isDone
                              ? AppColors.primary
                              : AppColors.cardBorder,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          stage.$3,
                          size: isCurrent ? 15 : 12,
                          color: isDone
                              ? (isCurrent ? Colors.white : AppColors.primary)
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (i < _stages.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < currentIdx
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  stage.$1,
                  style: AppTextStyles.caption.copyWith(
                    color: isDone ? AppColors.primary : AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Line Item Row ─────────────────────────────────────────────────────────────
class _LineItemRow extends StatelessWidget {
  final ShipmentLineItem item;
  final Shipment shipment;
  const _LineItemRow({required this.item, required this.shipment});

  @override
  Widget build(BuildContext context) {
    final showViewInventory = item.isAllocated &&
        (shipment.status == ShipmentStatus.allocated ||
          shipment.status == ShipmentStatus.packed ||
            shipment.status == ShipmentStatus.invoiced ||
            shipment.status == ShipmentStatus.dispatched ||
            shipment.status == ShipmentStatus.delivered);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.name, style: AppTextStyles.headingSmall),
                    Text('${item.product.sku} · ${item.product.trackingType.label}', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.shippedQty} ${item.product.unit}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Allocation: ${item.allocationType.toUpperCase()}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              Row(
                children: [
                  Icon(
                    item.isAllocated
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 14,
                    color: item.isAllocated
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.isAllocated ? 'Allocated' : 'Pending',
                    style: AppTextStyles.caption.copyWith(
                      color: item.isAllocated
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (showViewInventory) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View Assigned Inventory', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showAssignedInventoryDialog(context, item),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAssignedInventoryDialog(BuildContext context, ShipmentLineItem item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
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
              Text('Assigned Inventory', style: AppTextStyles.headingMedium),
              const SizedBox(height: 4),
              Text(item.product.name, style: AppTextStyles.caption),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Text('Allocation Type: ${item.allocationType.toUpperCase()}',
                  style: AppTextStyles.labelMedium),
              const SizedBox(height: 10),
              if (item.allocationType == 'lifo' || item.allocationType == 'fifo') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Auto-allocated ${item.shippedQty} ${item.product.unit} via ${item.allocationType.toUpperCase()} from available node stock.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
                  ),
                ),
              ] else if (item.product.trackingType == TrackingType.batch ||
                  item.product.trackingType == TrackingType.untracked) ...[
                if (item.batchAllocations.isEmpty)
                  Text('No lots assigned.', style: AppTextStyles.caption)
                else
                  Column(
                    children: item.batchAllocations.map((b) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(b.batchCode, style: AppTextStyles.bodySmall),
                            Text('${b.qty} ${item.product.unit}',
                                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ] else ...[
                if (item.serialNumbers.isEmpty)
                  Text('No serials assigned.', style: AppTextStyles.caption)
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.serialNumbers.map((sn) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Text(sn, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
              ],
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  width: 120,
                  height: 44,
                  label: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────
class _ActionButtons extends ConsumerWidget {
  final Shipment shipment;
  const _ActionButtons({required this.shipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEditOrCancel = shipment.status == ShipmentStatus.created ||
        shipment.status == ShipmentStatus.allocated;

    return Column(
      children: [
        if (shipment.status == ShipmentStatus.created) ...[
          AppButton(
            label: 'Manage Allocations',
            icon: Icons.inventory_2_outlined,
            onPressed: () => context.push('/shipments/${shipment.id}/allocate'),
          ),
          const SizedBox(height: 12),
        ] else if (shipment.status == ShipmentStatus.allocated) ...[
          AppButton(
            label: 'Proceed to Packing',
            icon: Icons.inventory_2_outlined,
            gradient: AppColors.greenGradient,
            onPressed: () async {
              await ref
                  .read(shipmentListProvider.notifier)
                  .updateStatus(shipment.id, ShipmentStatus.packed);
            },
          ),
          const SizedBox(height: 12),
        ] else if (shipment.status == ShipmentStatus.packed) ...[
          AppButton(
            label: 'Generate Invoice',
            icon: Icons.receipt_long_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
            ),
            onPressed: () async {
              _showInvoiceDownloadDialog(context, shipment);
              await ref
                  .read(shipmentListProvider.notifier)
                  .updateStatus(shipment.id, ShipmentStatus.invoiced);
            },
          ),
        ] else if (shipment.status == ShipmentStatus.invoiced) ...[
          AppButton(
            label: 'Mark as Dispatched',
            icon: Icons.local_shipping_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
            ),
            onPressed: () => context.push('/shipments/${shipment.id}/dispatch'),
          ),
        ] else if (shipment.status == ShipmentStatus.dispatched) ...[
          AppButton(
            label: 'Mark as Delivered',
            icon: Icons.check_circle_outline_rounded,
            gradient: AppColors.greenGradient,
            onPressed: () async {
              final confirm = await _confirmDialog(context, 'Mark Delivered',
                  'Confirm this shipment has been delivered?');
              if (confirm == true && context.mounted) {
                await ref
                    .read(shipmentListProvider.notifier)
                    .updateStatus(shipment.id, ShipmentStatus.delivered);
              }
            },
          ),
        ] else if (shipment.status == ShipmentStatus.delivered) ...[
          AppButton(
            label: 'Return Shipment',
            icon: Icons.assignment_return_outlined,
            isOutlined: true,
            isDestructive: true,
            onPressed: () {},
          ),
        ] else if (shipment.status == ShipmentStatus.cancelled) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Text('This shipment has been cancelled.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ],
            ),
          ),
        ],

        // Edit & Cancel buttons before packing
        if (canEditOrCancel) ...[
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Edit Shipment',
                  icon: Icons.edit_outlined,
                  isOutlined: true,
                  onPressed: () => _showEditModal(context, ref, shipment),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Cancel Shipment',
                  icon: Icons.cancel_outlined,
                  isOutlined: true,
                  isDestructive: true,
                  onPressed: () async {
                    final confirm = await _confirmDialog(context, 'Cancel Shipment',
                        'Are you sure you want to cancel this shipment?');
                    if (confirm == true && context.mounted) {
                      await ref
                          .read(shipmentListProvider.notifier)
                          .updateStatus(shipment.id, ShipmentStatus.cancelled);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showInvoiceDownloadDialog(BuildContext context, Shipment shipment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
            const SizedBox(width: 10),
            Text('Invoice Generated', style: AppTextStyles.headingMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice for ${shipment.shipmentNumber} is ready.', style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading Invoice PDF...')));
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('https://flaerhomes.com/invoices/${shipment.shipmentNumber}.pdf',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primary, decoration: TextDecoration.underline),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading Invoice PDF...')));
            },
            child: const Text('Download PDF', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditModal(BuildContext context, WidgetRef ref, Shipment shipment) {
    showDialog(
      context: context,
      builder: (_) => _EditShipmentModal(shipment: shipment),
    );
  }

  Future<bool?> _confirmDialog(
      BuildContext ctx, String title, String message) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(title,
            style: AppTextStyles.headingMedium),
        content: Text(message, style: AppTextStyles.bodySmall),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm',
                  style: TextStyle(color: AppColors.success))),
        ],
      ),
    );
  }
}

// ── Edit Shipment Modal ───────────────────────────────────────────────────────
class _EditShipmentModal extends ConsumerStatefulWidget {
  final Shipment shipment;
  const _EditShipmentModal({required this.shipment});

  @override
  ConsumerState<_EditShipmentModal> createState() => _EditShipmentModalState();
}

class _EditShipmentModalState extends ConsumerState<_EditShipmentModal> {
  late List<ShipmentLineItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.shipment.lineItems);
  }

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
            Text('Edit Shipment Items', style: AppTextStyles.headingMedium),
            const SizedBox(height: 4),
            Text('Adjust quantities or remove items before packing.',
                style: AppTextStyles.caption),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: _items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name, style: AppTextStyles.labelMedium),
                                Text('Max Stock: ${item.product.nodeStock}', style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.textSecondary),
                                onPressed: item.shippedQty > 1
                                    ? () {
                                        setState(() {
                                          _items[idx] = item.copyWith(shippedQty: item.shippedQty - 1, isAllocated: false);
                                        });
                                      }
                                    : null,
                              ),
                              Text('${item.shippedQty}', style: AppTextStyles.labelLarge),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.textSecondary),
                                onPressed: item.shippedQty < item.product.nodeStock
                                    ? () {
                                        setState(() {
                                          _items[idx] = item.copyWith(shippedQty: item.shippedQty + 1, isAllocated: false);
                                        });
                                      }
                                    : null,
                              ),
                              if (_items.length > 1) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _items.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                AppButton(
                  width: 130,
                  height: 40,
                  label: 'Save Changes',
                  onPressed: () async {
                    await ref
                        .read(shipmentListProvider.notifier)
                        .updateShipmentItems(widget.shipment.id, _items);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
