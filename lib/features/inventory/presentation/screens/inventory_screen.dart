import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:node_management_app/core/widgets/back_to_home_scope.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../widgets/node_inventory_list_view.dart';
import '../widgets/batch_inventory_list_view.dart';
import '../widgets/serial_inventory_list_view.dart';
import '../../../home/providers/home_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
    final splash = ref.watch(splashDataProvider).valueOrNull;
    final showNode = splash?.hasPermission('NodeInventory', 'read') ?? false;
    final showBatch = splash?.hasPermission('BatchInventory', 'read') ?? false;
    final showSerial = splash?.hasPermission('SkuItem', 'read') ?? false;

    final tabs = <Widget>[];
    final views = <Widget>[];

    if (showNode) {
      tabs.add(
        const Tab(
          height: 34,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 15),
              SizedBox(width: 4),
              Flexible(child: Text("Overview", maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      );
      views.add(const NodeInventoryListView());
    }

    if (showBatch) {
      tabs.add(
        const Tab(
          height: 34,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.layers_outlined, size: 15),
              SizedBox(width: 4),
              Flexible(child: Text("Batches", maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      );
      views.add(const BatchInventoryListView());
    }

    if (showSerial) {
      tabs.add(
        const Tab(
          height: 34,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_outlined, size: 15),
              SizedBox(width: 4),
              Flexible(child: Text("Serials", maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      );
      views.add(const SerialInventoryListView());
    }

    if (tabs.isEmpty) {
      return const Center(child: Text('No Inventory Permissions'));
    }

    return BackToHomeScope(
      child: DefaultTabController(
        length: tabs.length,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                isScrollable: false,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(fontSize: 12),
                tabs: tabs,
              ),
            ),
            Expanded(
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: views,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
