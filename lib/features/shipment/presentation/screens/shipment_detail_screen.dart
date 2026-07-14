import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:node_management_app/features/home/providers/home_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/tracking_type_badge.dart';
import '../../data/models/shipment.dart';
import '../../data/models/order.dart';
import '../../providers/shipment_provider.dart';
import 'allocation_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/repositories/shipment_repository.dart';
import 'package:node_management_app/core/utils/snackbar_utils.dart';

class _KeyValuePair {
  final keyCtrl = TextEditingController();
  final valCtrl = TextEditingController();
  void dispose() {
    keyCtrl.dispose();
    valCtrl.dispose();
  }
}

class _MediaItem {
  final String url;
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  _MediaItem(this.url);

  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
  }
}

class ShipmentDetailScreen extends ConsumerWidget {
  final String shipmentId;
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncShipment = ref.watch(shipmentByIdProvider(shipmentId));
    final splash = ref.watch(splashDataProvider).valueOrNull;

    return asyncShipment.when(
      skipLoadingOnReload: false,
      skipLoadingOnRefresh: false,
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: const NodeOpsAppBar(
          showBack: true,
          title: 'Loading Shipment...',
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: const NodeOpsAppBar(showBack: true, title: 'Error'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load shipment details',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 4),
              Text(
                e.toString().replaceFirst('Exception: ', ''),
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: () =>
                    ref.invalidate(shipmentByIdProvider(shipmentId)),
              ),
            ],
          ),
        ),
      ),
      data: (shipment) {
        if (shipment == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Shipment')),
            body: const Center(child: Text('Shipment not found')),
          );
        }

        final canEditOrCancel =
            shipment.status == ShipmentStatus.created ||
            shipment.status == ShipmentStatus.allocated;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: NodeOpsAppBar(
            showBack: true,
            title: shipment.shipmentNumber,
            extraActions: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: StatusBadge(
                    status: shipment.status.value,
                    large: true,
                  ),
                ),
              ),
              //   if (canEditOrCancel)
              //     PopupMenuButton<String>(
              //       icon: const Icon(
              //         Icons.more_vert_rounded,
              //         color: AppColors.textSecondary,
              //       ),
              //       color: AppColors.surface,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12),
              //         side: const BorderSide(color: AppColors.cardBorder),
              //       ),
              //       onSelected: (value) async {
              //         if (value == 'edit') {
              //           _showEditModal(context, ref, shipment);
              //         } else if (value == 'cancel') {
              //           final confirm = await _confirmDialog(
              //             context,
              //             'Cancel Shipment',
              //             'Are you sure you want to cancel this shipment?',
              //           );
              //           if (confirm == true && context.mounted) {
              //             await ref
              //                 .read(shipmentListProvider.notifier)
              //                 .updateStatus(
              //                   shipment.id,
              //                   ShipmentStatus.cancelled,
              //                 );
              //             ref.invalidate(shipmentByIdProvider(shipmentId));
              //           }
              //         }
              //       },
              //       itemBuilder: (context) => [
              //         const PopupMenuItem<String>(
              //           value: 'edit',
              //           child: Row(
              //             children: [
              //               Icon(
              //                 Icons.edit_outlined,
              //                 size: 18,
              //                 color: AppColors.textSecondary,
              //               ),
              //               SizedBox(width: 10),
              //               Text('Edit Shipment'),
              //             ],
              //           ),
              //         ),
              //         const PopupMenuItem<String>(
              //           value: 'cancel',
              //           child: Row(
              //             children: [
              //               Icon(
              //                 Icons.cancel_outlined,
              //                 size: 18,
              //                 color: AppColors.error,
              //               ),
              //               SizedBox(width: 10),
              //               Text(
              //                 'Cancel Shipment',
              //                 style: TextStyle(color: AppColors.error),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ],
              //     ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -- Progress Timeline ------------------------------------------
                _ShipmentTimeline(shipment: shipment),
                const SizedBox(height: 24),

                // -- Primary Focus: Line Items ----------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 12,
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
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Line Items (${shipment.lineItems.length})',
                                    style: AppTextStyles.headingSmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      ...shipment.lineItems.map(
                        (li) => _LineItemRow(item: li, shipment: shipment),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // "?"? Order & Invoice Info Card "?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?
                _SectionCard(
                  title: 'Order & Invoice Info',
                  child: Column(
                    children: [
                      _infoTile(
                        Icons.receipt_outlined,
                        'Order Number',
                        shipment.orderNumber,
                      ),
                      _infoTile(
                        Icons.storefront_outlined,
                        'Customer Code / ID',
                        shipment.customerCode ?? shipment.customerId ?? '-',
                      ),
                      _infoTile(
                        Icons.calendar_today_outlined,
                        'Created',
                        _formatDate(shipment.createdAt),
                      ),
                      if (shipment.invoiceCode != null &&
                          shipment.invoiceCode!.isNotEmpty)
                        _infoTile(
                          Icons.receipt_long_outlined,
                          'Invoice Code',
                          shipment.invoiceCode!,
                        ),
                      if (shipment.invoiceDate != null)
                        _infoTile(
                          Icons.event_outlined,
                          'Invoice Date',
                          _formatDate(shipment.invoiceDate!),
                        ),
                      if (shipment.shippedAt != null)
                        _infoTile(
                          Icons.local_shipping_outlined,
                          'Shipped At',
                          _formatDate(shipment.shippedAt!),
                        ),
                      if (shipment.deliveredAt != null)
                        _infoTile(
                          Icons.check_circle_outline_rounded,
                          'Delivered At',
                          _formatDate(shipment.deliveredAt!),
                        ),
                      if (shipment.returnedAt != null)
                        _infoTile(
                          Icons.keyboard_return_rounded,
                          'Returned At',
                          _formatDate(shipment.returnedAt!),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // -- Shipping & Delivery Info (if present) ---------------------
                if ((shipment.shippingAddress != null &&
                        shipment.shippingAddress!.isNotEmpty) ||
                    (shipment.billingAddress != null &&
                        shipment.billingAddress!.isNotEmpty) ||
                    (shipment.deliveryType != null &&
                        shipment.deliveryType!.isNotEmpty)) ...[
                  _SectionCard(
                    title: 'Shipping & Delivery Info',
                    child: Column(
                      children: [
                        if (shipment.deliveryType != null &&
                            shipment.deliveryType!.isNotEmpty)
                          _infoTile(
                            Icons.local_shipping_outlined,
                            'Delivery Type',
                            shipment.deliveryType!,
                          ),
                        if (shipment.shippingAddress != null &&
                            shipment.shippingAddress!.isNotEmpty)
                          _infoTile(
                            Icons.location_on_outlined,
                            'Shipping Address',
                            shipment.shippingAddress!,
                            isMultiline: true,
                          ),
                        if (shipment.billingAddress != null &&
                            shipment.billingAddress!.isNotEmpty)
                          _infoTile(
                            Icons.receipt_long_outlined,
                            'Billing Address',
                            shipment.billingAddress!,
                            isMultiline: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // -- Parent Forward Shipment Info (Reverse Shipments) ----------
                if (shipment.parentShipment != null ||
                    shipment.parentShipmentNumber != null) ...[
                  _SectionCard(
                    title: 'Parent Forward Shipment Info',
                    child: Column(
                      children: [
                        if (shipment.parentShipment?['shipment_number'] !=
                                null ||
                            shipment.parentShipmentNumber != null)
                          _infoTile(
                            Icons.inventory_2_outlined,
                            'Parent Shipment #',
                            '#${shipment.parentShipment?['shipment_number'] ?? shipment.parentShipmentNumber}',
                          ),
                        if (shipment.parentShipment?['shipment_type'] != null)
                          _infoTile(
                            Icons.swap_horiz_rounded,
                            'Parent Type',
                            shipment.parentShipment!['shipment_type']
                                .toString()
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                          ),
                        if (shipment.parentShipment?['status'] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Parent Status',
                                  style: AppTextStyles.bodySmall,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: StatusBadge(
                                      status: shipment.parentShipment!['status']
                                          .toString(),
                                      large: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (shipment.parentShipment?['delivered_at'] != null)
                          _infoTile(
                            Icons.calendar_today_outlined,
                            'Parent Delivered At',
                            _formatDate(
                              DateTime.tryParse(
                                    shipment.parentShipment!['delivered_at']
                                        .toString(),
                                  ) ??
                                  DateTime.now(),
                            ),
                          ),
                        if (shipment.parentShipment?['id'] != null) ...[
                          const SizedBox(height: 12),
                          AppButton(
                            label: 'Open Parent Shipment Details',
                            icon: Icons.open_in_new_rounded,
                            onPressed: () => context.push(
                              '/shipments/${shipment.parentShipment!['id']}',
                            ),
                            gradient: AppColors.greenGradient,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // -- Driver (if dispatched) ------------------------------------
                if (shipment.driverDetails != null) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Driver & Dispatch Details',
                    child: Column(
                      children: [
                        if (shipment.driverDetails!.name.isNotEmpty)
                          _infoTile(
                            Icons.person_outline_rounded,
                            'Driver Name',
                            shipment.driverDetails!.name,
                          ),
                        if (shipment.driverDetails!.phone.isNotEmpty)
                          _infoTile(
                            Icons.phone_outlined,
                            'Phone',
                            shipment.driverDetails!.phone,
                          ),
                        if (shipment.driverDetails!.vehicleNumber.isNotEmpty)
                          _infoTile(
                            Icons.directions_car_outlined,
                            'Vehicle',
                            shipment.driverDetails!.vehicleNumber,
                          ),
                        if (shipment.driverDetails!.distance != null &&
                            shipment.driverDetails!.distance!.isNotEmpty)
                          _infoTile(
                            Icons.add_road_outlined,
                            'Distance',
                            '${shipment.driverDetails!.distance} km',
                          ),
                        if (shipment.driverDetails!.courierName != null &&
                            shipment.driverDetails!.courierName!.isNotEmpty)
                          _infoTile(
                            Icons.local_shipping_outlined,
                            'Courier Name',
                            shipment.driverDetails!.courierName!,
                          ),
                        if (shipment.driverDetails!.trackingId != null &&
                            shipment.driverDetails!.trackingId!.isNotEmpty)
                          _infoTile(
                            Icons.qr_code_outlined,
                            'Tracking ID',
                            shipment.driverDetails!.trackingId!,
                          ),
                        if (shipment.driverDetails!.dispatchedBy != null &&
                            shipment.driverDetails!.dispatchedBy!.isNotEmpty)
                          _infoTile(
                            Icons.badge_outlined,
                            'Dispatched By',
                            shipment.driverDetails!.dispatchedBy!,
                          ),
                        if (shipment.driverDetails!.additionalDetails != null &&
                            shipment
                                .driverDetails!
                                .additionalDetails!
                                .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(color: AppColors.cardBorder),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Additional Details',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...shipment.driverDetails!.additionalDetails!.entries
                              .map((e) {
                                return _infoTile(
                                  Icons.label_outline_rounded,
                                  e.key,
                                  e.value.toString(),
                                );
                              }),
                        ],
                        if (shipment.driverDetails!.images != null &&
                            shipment.driverDetails!.images!.isNotEmpty)
                          _buildImagesGallery(
                            context,
                            shipment.driverDetails!.images!,
                            'Dispatch Images',
                          ),
                      ],
                    ),
                  ),
                ],

                // -- Delivery Details (if delivered) ---------------------------
                if (shipment.deliveryDetails != null) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Delivery Details',
                    child: Column(
                      children: [
                        if (shipment.deliveryDetails!.receivedBy != null &&
                            shipment.deliveryDetails!.receivedBy!.isNotEmpty)
                          _infoTile(
                            Icons.person_pin_outlined,
                            'Received By',
                            shipment.deliveryDetails!.receivedBy!,
                          ),
                        if (shipment.deliveryDetails!.deliveryOtp != null &&
                            shipment.deliveryDetails!.deliveryOtp!.isNotEmpty)
                          _infoTile(
                            Icons.pin_outlined,
                            'Delivery OTP',
                            shipment.deliveryDetails!.deliveryOtp!,
                          ),
                        if (shipment.deliveryDetails!.deliveryNote != null &&
                            shipment.deliveryDetails!.deliveryNote!.isNotEmpty)
                          _infoTile(
                            Icons.note_alt_outlined,
                            'Delivery Note',
                            shipment.deliveryDetails!.deliveryNote!,
                            isMultiline: true,
                          ),
                        if (shipment
                            .deliveryDetails!
                            .additionalDetails
                            .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(color: AppColors.cardBorder),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Additional Details',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...shipment.deliveryDetails!.additionalDetails.entries
                              .map((e) {
                                return _infoTile(
                                  Icons.label_outline_rounded,
                                  e.key,
                                  e.value.toString(),
                                );
                              }),
                        ],
                        if (shipment.deliveryDetails!.images.isNotEmpty)
                          _buildImagesGallery(
                            context,
                            shipment.deliveryDetails!.images,
                            'Delivery Images',
                          ),
                      ],
                    ),
                  ),
                ],

                // -- Fee Details (if present) ----------------------------------
                if ((shipment.labourFee != null &&
                        shipment.labourFee!.isNotEmpty &&
                        shipment.labourFee != '0' &&
                        shipment.labourFee != '0.0') ||
                    (shipment.driverFee != null &&
                        shipment.driverFee!.isNotEmpty &&
                        shipment.driverFee != '0' &&
                        shipment.driverFee != '0.0')) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Fee Details',
                    child: Column(
                      children: [
                        if (shipment.labourFee != null &&
                            shipment.labourFee!.isNotEmpty &&
                            shipment.labourFee != '0' &&
                            shipment.labourFee != '0.0')
                          _infoTile(
                            Icons.payments_outlined,
                            'Labour Fee',
                            '₹${shipment.labourFee}',
                          ),
                        if (shipment.driverFee != null &&
                            shipment.driverFee!.isNotEmpty &&
                            shipment.driverFee != '0' &&
                            shipment.driverFee != '0.0')
                          _infoTile(
                            Icons.payments_outlined,
                            'Driver Fee',
                            '₹${shipment.driverFee}',
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // -- Action Buttons --------------------------------------------
                if(splash!.hasPermission("Shipment", "update")) _ActionButtons(shipment: shipment),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    if (isMultiline) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                value,
                style: AppTextStyles.labelLarge.copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.labelLarge,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesGallery(
    BuildContext context,
    List<ShipmentMedia> images,
    String title,
  ) {
    if (images.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Divider(color: AppColors.cardBorder),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...images.map((img) {
          final displayTitle = img.title.isNotEmpty ? img.title : 'Image';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(
              Icons.image_outlined,
              color: AppColors.textSecondary,
            ),
            title: Text(displayTitle, style: AppTextStyles.bodySmall),
            subtitle: (img.description != null && img.description!.isNotEmpty)
                ? Text(img.description!, style: AppTextStyles.caption)
                : null,
            trailing: IconButton(
              icon: const Icon(
                Icons.remove_red_eye_outlined,
                color: AppColors.primary,
              ),
              onPressed: () => _showImagePopup(context, img, displayTitle),
            ),
          );
        }),
      ],
    );
  }

  void _showImagePopup(BuildContext context, ShipmentMedia img, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.headingSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: img.url.toLowerCase().endsWith('.pdf')
                    ? SizedBox(
                        height: 400,
                        width: double.infinity,
                        child: SfPdfViewer.network(
                          img.url,
                          canShowScrollHead: false,
                          canShowScrollStatus: false,
                        ),
                      )
                    : Image.network(
                        img.url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Unable to preview this file type.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
              ),
              if (img.description != null && img.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(img.description!, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// -- Progress Timeline ---------------------------------------------------------
class _ShipmentTimeline extends StatelessWidget {
  final Shipment shipment;
  const _ShipmentTimeline({required this.shipment});

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
    final status = shipment.status;
    final isReturn =
        shipment.shipmentType == 'reverse_shipment' ||
        status == ShipmentStatus.returnInitiated ||
        status == ShipmentStatus.returnCompleted;
    final stages = isReturn
        ? [
            (
              status != ShipmentStatus.returnCompleted
                  ? 'Return Initiated\n(Current)'
                  : 'Return Initiated\n(Completed)',
              ShipmentStatus.returnInitiated,
              Icons.keyboard_return_rounded,
            ),
            (
              status != ShipmentStatus.returnCompleted
                  ? 'Return Completed\n(Pending)'
                  : 'Return Completed\n(Current)',
              ShipmentStatus.returnCompleted,
              Icons.check_circle_outline_rounded,
            ),
          ]
        : _stages;

    final currentIdx = isReturn
        ? (status == ShipmentStatus.returnCompleted ? 1 : 0)
        : stages.indexWhere((s) => s.$2 == status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(stages.length, (i) {
          final stage = stages[i];
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
                    if (i < stages.length - 1)
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

// -- Line Item Row -------------------------------------------------------------
class _LineItemRow extends ConsumerWidget {
  final ShipmentLineItem item;
  final Shipment shipment;
  const _LineItemRow({required this.item, required this.shipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReturn =
        shipment.shipmentType == 'reverse_shipment' ||
        shipment.status == ShipmentStatus.returnInitiated ||
        shipment.status == ShipmentStatus.returnCompleted;
    final isUntracked = item.product.trackingType == TrackingType.untracked;
    final canEditAllocation =
        !isUntracked &&
        !isReturn &&
        (shipment.status == ShipmentStatus.created ||
            shipment.status == ShipmentStatus.allocated);
    final showViewInventory =
        !isUntracked &&
        !isReturn &&
        (item.isAllocated || canEditAllocation) &&
        shipment.fullyAllocated == true;

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
                    Row(
                      children: [
                        Text(item.product.sku, style: AppTextStyles.caption),
                        const SizedBox(width: 8),
                        TrackingTypeBadge(
                          trackingType: item.product.trackingType.name,
                        ),
                      ],
                    ),
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
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              isUntracked
                  ? const SizedBox.shrink()
                  : Text(
                      'Allocation: ${item.allocationType.toUpperCase()}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
              if (!isReturn)
                Row(
                  children: [
                    Icon(
                      isUntracked ||
                              (item.isAllocated &&
                                  !(shipment.status == ShipmentStatus.created &&
                                      !shipment.fullyAllocated))
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color:
                          isUntracked ||
                              (item.isAllocated &&
                                  !(shipment.status == ShipmentStatus.created &&
                                      !shipment.fullyAllocated))
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUntracked
                          ? 'No allocation needed'
                          : ((shipment.status == ShipmentStatus.created &&
                                    !shipment.fullyAllocated)
                                ? 'Pending'
                                : (item.isAllocated ? 'Allocated' : 'Pending')),
                      style: AppTextStyles.caption.copyWith(
                        color:
                            isUntracked ||
                                (item.isAllocated &&
                                    !(shipment.status ==
                                            ShipmentStatus.created &&
                                        !shipment.fullyAllocated))
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
                label: Text(
                  canEditAllocation
                      ? 'View/Edit Assigned Inventory'
                      : 'View Assigned Inventory',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showAssignedInventoryDialog(
                  context,
                  ref,
                  item,
                  shipment,
                  canEditAllocation,
                ),
              ),
            ),
          ],
          if (item.goodQty != null || item.badQty != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Qty: ${shipment.status == ShipmentStatus.returnCompleted ? item.goodQty : 0}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.goodBatches.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            children: item.goodBatches
                                .map(
                                  (b) => _buildAllocationChip(
                                    'Batch: ${b.batchCode} (${b.qty})',
                                    'batch',
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (item.goodSerials.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            children: item.goodSerials
                                .map(
                                  (s) => _buildAllocationChip(
                                    'Serial: $s',
                                    'serial',
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (item.goodUntracked.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            children: item.goodUntracked
                                .map(
                                  (u) => _buildAllocationChip(
                                    'Untracked: ${u.untrackedNumber} (${u.qty})',
                                    'untracked',
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bad Qty: ${item.badQty ?? 0}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.badBatches.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            children: item.badBatches
                                .map(
                                  (b) => _buildAllocationChip(
                                    'Batch: ${b.batchCode} (${b.qty})',
                                    'batch',
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (item.badSerials.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            children: item.badSerials
                                .map(
                                  (s) => _buildAllocationChip(
                                    'Serial: $s',
                                    'serial',
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (item.badUntracked.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            children: item.badUntracked
                                .map(
                                  (u) => _buildAllocationChip(
                                    'Untracked: ${u.untrackedNumber} (${u.qty})',
                                    'untracked',
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllocationChip(String text, String type) {
    Color bgColor;
    Color textColor;
    switch (type.toLowerCase()) {
      case 'batch':
        bgColor = const Color(0xFFEDE7F6);
        textColor = const Color(0xFF5E35B1);
        break;
      case 'serial':
        bgColor = const Color(0xFFE0F2F1);
        textColor = const Color(0xFF00897B);
        break;
      case 'untracked':
      default:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFB8C00);
        break;
    }
    return Container(
      margin: const EdgeInsets.only(top: 4, right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showAssignedInventoryDialog(
    BuildContext context,
    WidgetRef ref,
    ShipmentLineItem item,
    Shipment shipment,
    bool canEditAllocation,
  ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assigned Inventory',
                      style: AppTextStyles.headingMedium,
                    ),
                    if (canEditAllocation)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Editable',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.product.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (item.product.sku.isNotEmpty) ...[
                      Text(
                        item.product.sku,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    TrackingTypeBadge(
                      trackingType: item.product.trackingType.name,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Text(
                  'Allocation Type: ${item.allocationType.toUpperCase()}',
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 10),
                if (item.product.trackingType == TrackingType.untracked) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Untracked item - no allocation required.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ] else if (item.allocationType == 'lifo' ||
                    item.allocationType == 'fifo') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Auto-allocated ${item.shippedQty} ${item.product.unit} via ${item.allocationType.toUpperCase()} from available node stock.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ] else if (item.product.trackingType == TrackingType.batch) ...[
                  if (item.batchAllocations.isEmpty)
                    Text('No lots assigned yet.', style: AppTextStyles.caption)
                  else
                    Column(
                      children: [
                        ...item.batchAllocations.map((b) {
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
                                Text(
                                  b.batchCode,
                                  style: AppTextStyles.bodySmall,
                                ),
                                Text(
                                  '${b.qty} ${item.product.unit}',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                ] else ...[
                  if (item.serialNumbers.isEmpty)
                    Text(
                      'No serials assigned yet.',
                      style: AppTextStyles.caption,
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.serialNumbers.map((sn) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Text(
                            sn,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canEditAllocation) ...[
                      AppButton(
                        width: 140,
                        height: 40,
                        label: 'Edit Allocation',
                        icon: Icons.edit_outlined,
                        onPressed: () {
                          Navigator.pop(context);
                          _openEditModal(context, ref, item, shipment);
                        },
                      ),
                      const SizedBox(width: 12),
                    ],
                    AppButton(
                      width: 90,
                      height: 40,
                      label: 'Close',
                      isOutlined: canEditAllocation,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditModal(
    BuildContext context,
    WidgetRef ref,
    ShipmentLineItem item,
    Shipment shipment,
  ) {
    final authState = ref.read(authProvider);
    final nodeIdStr =
        shipment.nodeId ?? authState.node?.id ?? authState.user?.nodeId ?? '1';
    final nodeId =
        int.tryParse(nodeIdStr) ??
        int.tryParse(nodeIdStr.replaceAll(RegExp(r'[^0-9]'), '')) ??
        1;

    final isUntracked = item.product.trackingType == TrackingType.untracked;

    if (item.product.trackingType == TrackingType.batch || isUntracked) {
      showDialog(
        context: context,
        builder: (_) => BatchAllocationModal(
          title: isUntracked ? 'Edit Untracked Lots' : 'Edit Batches',
          requiredQty: item.shippedQty,
          unit: item.product.unit,
          nodeId: nodeId,
          shipmentId: shipment.id,
          skuId: item.product.id,
          initialAllocations: isUntracked
              ? item.untrackedAllocations
                    .map((u) => {'code': u.untrackedNumber, 'qty': u.qty})
                    .toList()
              : item.batchAllocations
                    .map((b) => {'code': b.batchCode, 'qty': b.qty})
                    .toList(),
          isUntracked: isUntracked,
          onConfirm: (newAllocations) async {
            await _submitUpdatedAllocation(
              context: context,
              ref: ref,
              shipment: shipment,
              editedItem: item,
              newBatches: !isUntracked
                  ? newAllocations
                        .map(
                          (e) => BatchAllocation(
                            batchCode: e['code'] as String,
                            qty: e['qty'] as int,
                          ),
                        )
                        .toList()
                  : null,
              newUntracked: isUntracked
                  ? newAllocations
                        .map(
                          (e) => UntrackedAllocation(
                            untrackedNumber: e['code'] as String,
                            qty: e['qty'] as int,
                          ),
                        )
                        .toList()
                  : null,
            );
          },
        ),
      );
    } else if (item.product.trackingType == TrackingType.serial) {
      showDialog(
        context: context,
        builder: (_) => SerialAllocationModal(
          requiredQty: item.shippedQty,
          nodeId: nodeId,
          shipmentId: shipment.id,
          skuId: item.product.id,
          initialSerials: item.serialNumbers,
          onConfirm: (newSerials) async {
            await _submitUpdatedAllocation(
              context: context,
              ref: ref,
              shipment: shipment,
              editedItem: item,
              newSerials: newSerials,
            );
          },
        ),
      );
    } else {
      showTopSnackBar(context, 'No manual lots required for this item type.');
    }
  }

  Future<void> _submitUpdatedAllocation({
    required BuildContext context,
    required WidgetRef ref,
    required Shipment shipment,
    required ShipmentLineItem editedItem,
    List<BatchAllocation>? newBatches,
    List<UntrackedAllocation>? newUntracked,
    List<String>? newSerials,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final payload = {
        "shipment_line_items": shipment.lineItems
            .where((li) => li.product.trackingType != TrackingType.untracked)
            .map((li) {
              final skuId = int.tryParse(li.product.id) ?? 0;

              if (li.id == editedItem.id) {
                final map = <String, dynamic>{
                  "product_sku_id": skuId,
                  "selection_type": "manual",
                };
                if (li.product.trackingType == TrackingType.batch) {
                  final batchMap = <String, int>{};
                  for (final b in (newBatches ?? [])) {
                    if (b.qty > 0) batchMap[b.batchCode] = b.qty;
                  }
                  map["batch_codes"] = batchMap;
                } else if (li.product.trackingType == TrackingType.serial) {
                  map["serial"] = newSerials ?? [];
                }
                return map;
              }

              final selType = li.allocationType.toLowerCase();
              if (selType == 'fifo' || selType == 'lifo') {
                return {
                  "product_sku_id": skuId,
                  "selection_type": selType.toUpperCase(),
                };
              }

              final map = <String, dynamic>{
                "product_sku_id": skuId,
                "selection_type": "manual",
              };
              if (li.product.trackingType == TrackingType.batch) {
                final batchMap = <String, int>{};
                for (final b in li.batchAllocations) {
                  if (b.qty > 0) batchMap[b.batchCode] = b.qty;
                }
                map["batch_codes"] = batchMap;
              } else if (li.product.trackingType == TrackingType.serial) {
                map["serial"] = li.serialNumbers;
              }
              return map;
            })
            .toList(),
      };

      await ref
          .read(shipmentRepositoryProvider)
          .assignShipmentAllocations(shipmentId: shipment.id, payload: payload);

      if (context.mounted) {
        Navigator.pop(context); // close loading indicator
        ref.invalidate(shipmentByIdProvider(shipment.id));
        ref.invalidate(shipmentListProvider);
        showTopSuccessSnackBar(context, 'Allocation updated successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loading indicator
        showTopErrorSnackBar(context, 'Failed to update allocation: ${e.toString()}');
      }
    }
  }
}

// -- Action Buttons ------------------------------------------------------------
class _ActionButtons extends ConsumerWidget {
  final Shipment shipment;
  const _ActionButtons({required this.shipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (shipment.status == ShipmentStatus.returnInitiated ||
            (shipment.shipmentType == 'reverse_shipment' &&
                shipment.status != ShipmentStatus.returnCompleted)) ...[
          AppButton(
            label: 'Enter good , bad quantities',
            icon: Icons.assignment_return_outlined,
            onPressed: () async {
              await context.push(
                '/shipments/${shipment.id}/good_bad_allocation',
                extra: shipment,
              );
              ref.invalidate(shipmentByIdProvider(shipment.id));
              ref.invalidate(shipmentListProvider);
            },
          ),
          const SizedBox(height: 12),
        ] else if (shipment.status == ShipmentStatus.created) ...[
          AppButton(
            label: 'Manage Allocations',
            icon: Icons.inventory_2_outlined,
            onPressed: () async {
              await context.push('/shipments/${shipment.id}/allocate');
              ref.invalidate(shipmentByIdProvider(shipment.id));
              ref.invalidate(shipmentListProvider);
            },
          ),
          const SizedBox(height: 12),
        ] else if (shipment.status == ShipmentStatus.allocated) ...[
          AppButton(
            label: 'Proceed to Packing',
            icon: Icons.inventory_2_outlined,
            gradient: AppColors.greenGradient,
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
              try {
                await ref
                    .read(shipmentRepositoryProvider)
                    .packShipment(shipmentId: shipment.id);
                if (context.mounted) {
                  Navigator.pop(context); // close progress dialog
                  ref.invalidate(shipmentByIdProvider(shipment.id));
                  ref.invalidate(shipmentListProvider);
                  showTopSuccessSnackBar(context, 'Shipment packed successfully!');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // close progress dialog
                  showTopErrorSnackBar(context, 'Failed to pack shipment: ${e.toString()}');
                }
              }
            },
          ),
          const SizedBox(height: 12),
        ] else if (shipment.status == ShipmentStatus.packed) ...[
          AppButton(
            label: 'Create Invoice',
            icon: Icons.receipt_long_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
            ),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
              try {
                await ref
                    .read(shipmentRepositoryProvider)
                    .generateInvoice(shipmentId: shipment.id);
                if (context.mounted) {
                  Navigator.pop(context); // close progress dialog
                  ref.invalidate(shipmentByIdProvider(shipment.id));
                  ref.invalidate(shipmentListProvider);
                  showTopSuccessSnackBar(context, 'Invoice generated successfully!');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // close progress dialog
                  showTopErrorSnackBar(context, 'Failed to generate invoice: ${e.toString()}');
                }
              }
            },
          ),
        ] else if (shipment.status == ShipmentStatus.invoiced) ...[
          AppButton(
            label: 'Mark as Dispatched',
            icon: Icons.local_shipping_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
            ),
            onPressed: () async {
              await context.push('/shipments/${shipment.id}/dispatch');
              ref.invalidate(shipmentByIdProvider(shipment.id));
              ref.invalidate(shipmentListProvider);
            },
          ),
        ] else if (shipment.status == ShipmentStatus.dispatched) ...[
          AppButton(
            label: 'Mark as Delivered',
            icon: Icons.check_circle_outline_rounded,
            gradient: AppColors.greenGradient,
            onPressed: () => _showDeliverDialog(context, ref, shipment),
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
                const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'This shipment has been cancelled.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

void _showEditModal(BuildContext context, WidgetRef ref, Shipment shipment) {
  showDialog(
    context: context,
    builder: (_) => _EditShipmentModal(shipment: shipment),
  );
}

Future<bool?> _confirmDialog(BuildContext ctx, String title, String message) {
  return showDialog<bool>(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      title: Text(title, style: AppTextStyles.headingMedium),
      content: Text(message, style: AppTextStyles.bodySmall),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Confirm',
            style: TextStyle(color: AppColors.success),
          ),
        ),
      ],
    ),
  );
}

void _showDeliverDialog(
  BuildContext context,
  WidgetRef ref,
  Shipment shipment,
) {
  showDialog(
    context: context,
    builder: (_) => _DeliverShipmentModal(shipment: shipment),
  );
}

class _DeliverShipmentModal extends ConsumerStatefulWidget {
  final Shipment shipment;
  const _DeliverShipmentModal({required this.shipment});

  @override
  ConsumerState<_DeliverShipmentModal> createState() =>
      _DeliverShipmentModalState();
}

class _DeliverShipmentModalState extends ConsumerState<_DeliverShipmentModal> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final List<_KeyValuePair> _additionalRows = [];
  final List<_MediaItem> _uploadedMedia = [];
  bool _isUploadingMedia = false;

  @override
  void dispose() {
    for (final row in _additionalRows) {
      row.dispose();
    }
    for (final media in _uploadedMedia) {
      media.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _isUploadingMedia = true);
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        final url = await ref
            .read(shipmentRepositoryProvider)
            .uploadMedia(
              shipmentId: widget.shipment.id,
              actionType: 'delivered',
              filePath: filePath,
              fileName: fileName,
            );
        setState(() {
          _uploadedMedia.add(_MediaItem(url));
          _isUploadingMedia = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
        showTopErrorSnackBar(context, 'Media upload failed: ${e.toString()}');
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedMedia.isEmpty) {
      showTopErrorSnackBar(context, 'Please upload at least one media to proceed.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final innerMap = <String, dynamic>{
        "images": _uploadedMedia
            .map(
              (m) => {
                "title": m.titleCtrl.text.trim(),
                if (m.descCtrl.text.trim().isNotEmpty)
                  "description": m.descCtrl.text.trim(),
                "image_url": m.url,
              },
            )
            .toList(),
      };

      for (final row in _additionalRows) {
        final k = row.keyCtrl.text.trim();
        final v = row.valCtrl.text.trim();
        if (k.isNotEmpty && v.isNotEmpty) {
          innerMap[k] = v;
        }
      }

      final payload = <String, dynamic>{"shipment_delivery_details": innerMap};
      await ref
          .read(shipmentListProvider.notifier)
          .markDelivered(widget.shipment.id, payload);

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(shipmentByIdProvider(widget.shipment.id));
        ref.invalidate(shipmentListProvider);
        showTopSuccessSnackBar(context, 'Shipment marked as delivered successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showTopErrorSnackBar(context, 'Failed to mark as delivered: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Mark Shipment Delivered',
                      style: AppTextStyles.headingMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to mark shipment #${widget.shipment.shipmentNumber} as delivered?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Delivery Details',
                          style: AppTextStyles.headingMedium,
                        ),
                        const SizedBox(height: 12),
                        ..._additionalRows.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final row = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Field Label',
                                    hint: 'e.g. Received By',
                                    controller: row.keyCtrl,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AppTextField(
                                    label: 'Field Value',
                                    hint: 'e.g. John Doe',
                                    controller: row.valCtrl,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      row.dispose();
                                      _additionalRows.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _additionalRows.add(_KeyValuePair());
                            });
                          },
                          icon: const Icon(
                            Icons.add_rounded,
                            color: AppColors.primary,
                          ),
                          label: const Text(
                            'Add one more row',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Delivery Media (Required)',
                          style: AppTextStyles.headingMedium,
                        ),
                        const SizedBox(height: 12),
                        ..._uploadedMedia.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final media = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Media ${idx + 1} uploaded successfully!',
                                        style: AppTextStyles.labelMedium,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          media.dispose();
                                          _uploadedMedia.removeAt(idx);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                AppTextField(
                                  label: 'Media Title',
                                  hint: 'e.g. Package delivered image',
                                  controller: media.titleCtrl,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Title is required'
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                AppTextField(
                                  label: 'Media Description (Optional)',
                                  hint: 'e.g. Package placed at door',
                                  controller: media.descCtrl,
                                ),
                              ],
                            ),
                          );
                        }),
                        if (_isUploadingMedia)
                          const Center(child: CircularProgressIndicator())
                        else
                          OutlinedButton.icon(
                            onPressed: _pickAndUploadFile,
                            icon: const Icon(
                              Icons.upload_file,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              _uploadedMedia.isEmpty
                                  ? 'Upload Media (Image/PDF)'
                                  : 'Upload Another Media',
                              style: const TextStyle(color: AppColors.primary),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirm Delivery'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Edit Shipment Modal -------------------------------------------------------
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
            Text(
              'Adjust quantities or remove items before packing.',
              style: AppTextStyles.caption,
            ),
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
                                Text(
                                  item.product.name,
                                  style: AppTextStyles.labelMedium,
                                ),
                                Text(
                                  'Max Stock: ${item.product.nodeStock}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: item.shippedQty > 1
                                    ? () {
                                        setState(() {
                                          _items[idx] = item.copyWith(
                                            shippedQty: item.shippedQty - 1,
                                            isAllocated: false,
                                          );
                                        });
                                      }
                                    : null,
                              ),
                              Text(
                                '${item.shippedQty}',
                                style: AppTextStyles.labelLarge,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed:
                                    item.shippedQty < item.product.nodeStock
                                    ? () {
                                        setState(() {
                                          _items[idx] = item.copyWith(
                                            shippedQty: item.shippedQty + 1,
                                            isAllocated: false,
                                          );
                                        });
                                      }
                                    : null,
                              ),
                              if (_items.length > 1) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
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

// -- Section Card --------------------------------------------------------------
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
          Text(
            title,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
