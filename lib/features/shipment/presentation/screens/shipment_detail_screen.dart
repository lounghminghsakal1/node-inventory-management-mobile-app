import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/shipment.dart';
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
                    .map((li) => _LineItemRow(item: li))
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
          final isDone = i <= currentIdx;
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
                          color: i <= currentIdx
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 32 : 26,
                      height: isCurrent ? 32 : 26,
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
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          stage.$3,
                          size: isCurrent ? 16 : 13,
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
  const _LineItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
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
                    Text(item.product.sku, style: AppTextStyles.caption),
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
          if (item.batchAllocations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.batchAllocations.map((b) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${b.batchCode}: ${b.qty}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.accent),
                  ),
                );
              }).toList(),
            ),
          ],
          if (item.serialNumbers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${item.serialNumbers.length} serials allocated',
              style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────
class _ActionButtons extends ConsumerWidget {
  final Shipment shipment;
  const _ActionButtons({required this.shipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (shipment.status) {
      case ShipmentStatus.created:
        return Column(
          children: [
            AppButton(
              label: 'Manage Allocations',
              icon: Icons.inventory_2_outlined,
              onPressed: () => context.push('/shipments/${shipment.id}/allocate'),
            ),
          ],
        );

      case ShipmentStatus.allocated:
        return AppButton(
          label: 'Generate Invoice',
          icon: Icons.receipt_long_outlined,
          gradient: const LinearGradient(
            colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
          ),
          onPressed: () async {
            await ref
                .read(shipmentListProvider.notifier)
                .updateStatus(shipment.id, ShipmentStatus.invoiced);
          },
        );

      case ShipmentStatus.invoiced:
        return AppButton(
          label: 'Enter Driver & Dispatch',
          icon: Icons.local_shipping_outlined,
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          ),
          onPressed: () => context.push('/shipments/${shipment.id}/dispatch'),
        );

      case ShipmentStatus.dispatched:
        return AppButton(
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
        );

      case ShipmentStatus.delivered:
        return AppButton(
          label: 'Initiate Return',
          icon: Icons.assignment_return_outlined,
          isOutlined: true,
          isDestructive: true,
          onPressed: () {},
        );

      default:
        return const SizedBox.shrink();
    }
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
