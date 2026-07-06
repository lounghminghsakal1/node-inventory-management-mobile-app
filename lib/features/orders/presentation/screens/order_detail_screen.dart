import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  Color _statusColor(String s) => switch (s) {
        'confirmed' => AppColors.success,
        'partially_delivered' => AppColors.warning,
        'delivered' => AppColors.accentGreen,
        'cancelled' => AppColors.error,
        _ => AppColors.textMuted,
      };

  String _statusLabel(String s) => s
      .split('_')
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  Color _shipmentStatusColor(String s) => switch (s) {
        'created' => AppColors.primary,
        'allocated' || 'invoiced' => AppColors.secondary,
        'dispatched' => const Color(0xFF00B4D8),
        'delivered' => AppColors.success,
        'return_initiated' || 'return_in_transit' => AppColors.warning,
        'return_completed' => AppColors.accentGreen,
        'cancelled' => AppColors.error,
        _ => AppColors.textMuted,
      };

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NodeOpsAppBar(showBack: true, title: 'Order Details'),
      bottomNavigationBar: asyncDetail.maybeWhen(
        data: (order) {
          if (order.status == 'confirmed' ||
              order.status == 'partially_delivered') {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: SafeArea(
                top: false,
                child: AppButton(
                  label: 'Create Shipment',
                  icon: Icons.add_box_outlined,
                  onPressed: () => context.push(
                      '/shipments/create?orderId=${order.id}&orderNumber=${order.orderNumber}&customerName=${order.customer.name}'),
                ),
              ),
            );
          }
          return null;
        },
        orElse: () => null,
      ),
      body: asyncDetail.when(
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
              Text('Failed to load order details',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Order Header Card ───────────────────────────────────────
              _buildHeaderCard(order),
              const SizedBox(height: 20),

              // ── 2. Shipments Section ───────────────────────────────────────
              _buildSectionTitle(
                'Shipments',
                count: order.shipments.length,
                icon: Icons.local_shipping_rounded,
              ),
              const SizedBox(height: 10),
              if (order.shipments.isEmpty)
                _buildEmptyBox('No shipments created yet for this order.')
              else
                ...order.shipments.map((s) => _buildShipmentCard(context, s)),
              const SizedBox(height: 20),

              // ── 3. Line Items Section (No Prices!) ─────────────────────────
              _buildSectionTitle(
                'Order Items',
                count: order.orderLineItems.length,
                icon: Icons.inventory_2_rounded,
              ),
              const SizedBox(height: 10),
              if (order.orderLineItems.isEmpty)
                _buildEmptyBox('No items found in this order.')
              else
                ...order.orderLineItems.map((item) => _buildLineItemCard(item)),
              const SizedBox(height: 20),

              // ── 4. Locations (Addresses) ───────────────────────────────────
              _buildSectionTitle('Locations', icon: Icons.location_on_rounded),
              const SizedBox(height: 10),
              _buildLocationsCard(order),
              const SizedBox(height: 20),

              // ── 5. Delivery & Labour Info ──────────────────────────────────
              _buildSectionTitle('Delivery & Labour Details',
                  icon: Icons.engineering_rounded),
              const SizedBox(height: 10),
              _buildDeliveryLabourCard(order),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {int? count, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.headingMedium),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHeaderCard(OrderDetail order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusPill(
                label: _statusLabel(order.status),
                color: _statusColor(order.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),
          // Customer info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customer.name,
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    Text(
                      'Customer Code: ${order.customer.code}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Timestamps
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildTimeRow(
                    'Placed At', _formatDate(order.placedAt), Icons.event),
                const SizedBox(height: 6),
                _buildTimeRow('Confirmed At', _formatDate(order.confirmedAt),
                    Icons.check_circle_outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text('$label:',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildShipmentCard(BuildContext context, OrderShipmentRef s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push('/shipments/${s.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _shipmentStatusColor(s.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_shipping_rounded,
                      size: 20, color: _shipmentStatusColor(s.status)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.shipmentNumber,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to view shipment flow & details',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: _statusLabel(s.status),
                  color: _shipmentStatusColor(s.status),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineItemCard(OrderLineItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.category_outlined,
                size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productSku.displayName.isNotEmpty
                      ? item.productSku.displayName
                      : item.productSku.skuName,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${item.productSku.skuCode}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item.quantity} Qty',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsCard(OrderDetail order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _buildAddressRow(
            'Shipping Address',
            order.shippingAddress,
            Icons.local_shipping_outlined,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.cardBorder),
          ),
          _buildAddressRow(
            'Billing Address',
            order.billingAddress,
            Icons.receipt_long_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String label, String address, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                address.isNotEmpty ? address : 'No address provided',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryLabourCard(OrderDetail order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fees
          Row(
            children: [
              Expanded(
                child: _buildFeeBox('Delivery Partner Fee',
                    '₹${order.deliveryPartnerFee}', Icons.delivery_dining),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeeBox('Labour Fee', '₹${order.labourFee}',
                    Icons.groups_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),

          // Delivery Info
          Text('Delivery Info', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          _buildDetailRow('Handle With Care',
              order.deliveryInfo.handleWithCare ? 'Yes' : 'No'),
          const SizedBox(height: 14),

          // Deliverer Details
          Text('Deliverer Details', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          if (order.delivererDetails.isEmpty)
            Text('No driver assigned yet',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted))
          else ...[
            if (order.delivererDetails.driverName.isNotEmpty)
              _buildDetailRow('Driver Name', order.delivererDetails.driverName),
            if (order.delivererDetails.vehicleNumber.isNotEmpty)
              _buildDetailRow(
                  'Vehicle Number', order.delivererDetails.vehicleNumber),
            if (order.delivererDetails.driverMobileNumber.isNotEmpty)
              _buildDetailRow(
                  'Mobile', order.delivererDetails.driverMobileNumber),
          ],
          const SizedBox(height: 14),

          // Labour Info
          Text('Labour Information', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          _buildDetailRow(
              'Floor Number', order.infoForLabour.floorNumber.toString()),
          _buildDetailRow('Permitted By Owner',
              order.infoForLabour.permittedByOwner ? 'Yes' : 'No'),
          _buildDetailRow('Ground Floor Included',
              order.infoForLabour.groundFloorIncluded ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildFeeBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          Text(value,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
