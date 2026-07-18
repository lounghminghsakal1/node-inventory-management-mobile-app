import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class InfoModal extends StatelessWidget {
  final String title;
  final List<InfoModalItem> items;
  final String? description;

  const InfoModal({
    Key? key,
    required this.title,
    required this.items,
    this.description,
  }) : super(key: key);

  static void show(BuildContext context, {
    required String title,
    required List<InfoModalItem> items,
    String? description,
  }) {
    showDialog(
      context: context,
      builder: (context) => InfoModal(
        title: title,
        items: items,
        description: description,
      ),
    );
  }

  static void showShipmentLifecycle(BuildContext context) {
    show(
      context,
      title: 'Shipment Lifecycle & Tracking',
      description: 'These shows all line items of the shipment with quantity to be shipped. Each line item has a tracking type:\n'
          '• Batch: Product quantities are grouped together under a single unit.\n'
          '• Serial: Each product is treated as a separate, individually tracked item.\n'
          '• Untracked: Items requiring no specific tracking.',
      items: const [
        InfoModalItem(
          title: 'State - Created',
          titleColor: AppColors.primary,
          content: 'Now the shipment is in the created state. Next, allocations should be made by clicking "Manage Allocations".\n\n'
              '• If blocked: There is no inventory. You must do a GRN or contact admin.\n'
              '• Assigning: For manual allocation, you must choose a batch and enter the quantity. For LIFO/FIFO, no manual allocation is needed.',
        ),
        InfoModalItem(
          title: 'State - Allocated',
          titleColor: AppColors.warning,
          content: 'Once quantities are allocated for all line items, the shipment status becomes allocated. You can still edit the allocations you made. Next, proceed to packing. Note: Once proceeded to packing, you cannot edit the allocations.',
        ),
        InfoModalItem(
          title: 'State - Packed',
          titleColor: AppColors.secondary,
          content: 'Allocations are locked. To create an invoice, click on "Create Invoice", then proceed to dispatch.',
        ),
        InfoModalItem(
          title: 'State - Dispatched',
          titleColor: Colors.cyan,
          content: 'For dispatch, you must upload photos at the line item level (if required). You must also enter driver-related fields and upload one media file to mark as dispatched.',
        ),
        InfoModalItem(
          title: 'State - Delivered',
          titleColor: AppColors.success,
          content: 'To mark as delivered, you must upload one media file.',
        ),
      ],
    );
  }

  static void showGrnLifecycle(BuildContext context) {
    show(
      context,
      title: 'Goods Receipt Note (GRN) Lifecycle',
      description: 'A GRN is used to record the delivery of items against a Purchase Order. A single PO can have multiple GRNs until all items are fully received.',
      items: const [
        InfoModalItem(
          title: 'State - Created',
          titleColor: AppColors.primary,
          content: 'The GRN is initiated upon goods arrival. At this stage, you must receive the physical items and log their quantities. You can continue receiving items until the quantities match the vendor invoice.',
        ),
        InfoModalItem(
          title: 'State - QC Pending',
          titleColor: AppColors.warning,
          content: 'The received items are awaiting Quality Control. You must verify accepted and rejected quantities for each line item. If required by warehouse configuration, you must also upload photos of the items.',
        ),
        InfoModalItem(
          title: 'State - Completed',
          titleColor: AppColors.success,
          content: 'The GRN process is finished. The accepted goods are now added to your warehouse inventory and are available for allocation.',
        ),
      ],
    );
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
        padding: const EdgeInsets.all(24.0),
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
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (description != null) ...[
              Text(
                description!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
            ],
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.title != null) ...[
                            Text(
                              item.title!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: item.titleColor ?? Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            item.content,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoModalItem {
  final String? title;
  final String content;
  final Color? titleColor;

  const InfoModalItem({
    this.title,
    required this.content,
    this.titleColor,
  });
}
