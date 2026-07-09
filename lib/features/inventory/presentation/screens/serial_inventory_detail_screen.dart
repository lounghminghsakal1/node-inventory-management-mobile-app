import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../providers/inventory_provider.dart';

class SerialInventoryDetailScreen extends ConsumerWidget {
  final String serialItemId;

  const SerialInventoryDetailScreen({super.key, required this.serialItemId});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_stock':
      case 'instock':
        return AppColors.success;
      case 'dispatched':
      case 'delivered':
        return AppColors.info;
      case 'in_transit':
      case 'intransit':
      case 'allocated':
        return AppColors.warning;
      case 'damaged':
      case 'missing':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(serialInventoryDetailProvider(serialItemId));

    return Scaffold(
      appBar: const NodeOpsAppBar(title: "Serial Item Detail", hideLogoutButton: true,),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text("Failed to load serial item", style: AppTextStyles.headingMedium),
              const SizedBox(height: 6),
              Text(err.toString().replaceAll('Exception: ', ''),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(serialInventoryDetailProvider(serialItemId)),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
        data: (item) {
          final statusColor = _getStatusColor(item.status);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(serialInventoryDetailProvider(serialItemId));
            },
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Top Summary Card ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 24, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                item.skuItemNumber,
                                style: AppTextStyles.headingLarge.copyWith(fontSize: 18, color: AppColors.primary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              item.status.replaceAll('_', ' ').toUpperCase(),
                              style: AppTextStyles.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(color: AppColors.cardBorder.withValues(alpha: 0.6), height: 1),
                      const SizedBox(height: 14),

                      Text(
                        item.productSku?.skuName ?? 'Unknown SKU',
                        style: AppTextStyles.headingMedium.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "SKU Code: ${item.productSku?.skuCode ?? 'N/A'}",
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),

                      if (item.currentNode != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text("Current Node: ", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                            Text(item.currentNode!.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Current Transaction Section ───────────────────────────────
                if (item.currentTransaction != null) ...[
                  Text("Current Inventory Transaction", style: AppTextStyles.headingMedium),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Ref: ${item.currentTransaction!.transactionReferenceType}",
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Type: ${item.currentTransaction!.transactionType}",
                                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Trackers History ──────────────────────────────────────────
                Row(
                  children: [
                    Text("Tracker History", style: AppTextStyles.headingMedium),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${item.trackers.length}",
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (item.trackers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.timeline_rounded, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text("No tracker history found", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  )
                else
                  ...item.trackers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final trk = entry.value;
                    final isLast = idx == item.trackers.length - 1;

                    return _TrackerItemCard(tracker: trk, isLast: isLast);
                  }),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrackerItemCard extends StatelessWidget {
  final Map<String, dynamic> tracker;
  final bool isLast;

  const _TrackerItemCard({required this.tracker, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final status = tracker['status']?.toString() ?? tracker['tracker_type']?.toString() ?? 'Activity';
    final dateStr = tracker['created_at']?.toString() ?? tracker['timestamp']?.toString() ?? '';
    final nodeName = tracker['node'] is Map ? (tracker['node']['name']?.toString() ?? '') : (tracker['node_name']?.toString() ?? '');

    // Filter out internal keys when displaying metadata
    final metaEntries = tracker.entries.where((e) {
      final k = e.key;
      return k != 'id' && k != 'status' && k != 'created_at' && k != 'timestamp' && k != 'node' && k != 'node_name' && e.value != null;
    }).toList();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.cardBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Content Box
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
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
                      Expanded(
                        child: Text(
                          status.replaceAll('_', ' ').toUpperCase(),
                          style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                        ),
                    ],
                  ),
                  if (nodeName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(nodeName, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],

                  if (metaEntries.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Divider(color: AppColors.cardBorder.withValues(alpha: 0.5), height: 1),
                    const SizedBox(height: 8),
                    ...metaEntries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${e.key.replaceAll('_', ' ')}: ", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                            Expanded(
                              child: Text("${e.value}", style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
