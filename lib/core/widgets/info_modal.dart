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
      title: 'How to Process a Shipment',
      description: 'Follow these steps to process a shipment from start to finish. Some items are tracked by Batch (group) or Serial (one by one).',
      items: const [
        InfoModalItem(
          title: 'Step 1: Created',
          titleColor: AppColors.primary,
          content: 'What you do: Click "Manage Allocations" to pick items from your stock.\n'
              '• Not enough stock? You must add more stock (GRN) first.\n'
              '• How to pick: The app might pick for you. If not, pick the items yourself.',
        ),
        InfoModalItem(
          title: 'Step 2: Allocated',
          titleColor: AppColors.warning,
          content: 'What you do: Check if the picked items are correct. If yes, click to pack them. Warning: Once you pack, you cannot change the items.',
        ),
        InfoModalItem(
          title: 'Step 3: Packed',
          titleColor: AppColors.secondary,
          content: 'What you do: The items are in boxes. Now click "Create Invoice" to make a bill. Then, you are ready to send them.',
        ),
        InfoModalItem(
          title: 'Step 4: Dispatched',
          titleColor: Colors.cyan,
          content: 'What you do: Add photos of the boxes. Type the driver details and take one photo of the truck. Then, mark it as sent.',
        ),
        InfoModalItem(
          title: 'Step 5: Delivered',
          titleColor: AppColors.success,
          content: 'What you do: Take one last photo to prove the items reached the customer.',
        ),
      ],
    );
  }

  static void showGrnLifecycle(BuildContext context) {
    show(
      context,
      title: 'How to Receive Items (GRN)',
      description: 'Follow these simple steps to receive your items:',
      items: const [
        InfoModalItem(
          title: 'Step 1: Created (Inwarding)',
          titleColor: AppColors.primary,
          content: 'What you need to do:\n1. Open the boxes you received.\n2. Count all the items inside.\n3. Type that exact number into the app.\n4. Click save.',
        ),
        InfoModalItem(
          title: 'Step 2: QC Pending (Quality Check)',
          titleColor: AppColors.warning,
          content: 'What you need to do:\n1. Look closely at the items you received.\n2. How many are in good condition? Type that number in "Accepted".\n3. How many are broken or bad? Type that number in "Rejected".\n4. Add photos if something is broken.\n5. Click save.',
        ),
        InfoModalItem(
          title: 'Step 3: Completed',
          titleColor: AppColors.success,
          content: 'What happens now:\nGreat job! You are all done. The good items have been safely added to your inventory.',
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
