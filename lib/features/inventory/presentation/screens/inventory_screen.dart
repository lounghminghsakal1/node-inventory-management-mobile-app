import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../widgets/node_inventory_list_view.dart';
import '../widgets/batch_inventory_list_view.dart';
import '../widgets/serial_inventory_list_view.dart';
import '../widgets/node_inventory_ledger_view.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // ── Top Tab Bar ─────────────────────────────────────────────────────
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
              tabs: const [
                Tab(
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
                Tab(
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
                Tab(
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
              ],
            ),
          ),

          // ── Tab Bar View ────────────────────────────────────────────────────
          const Expanded(
            child: TabBarView(
              physics: BouncingScrollPhysics(),
              children: [
                NodeInventoryListView(),
                BatchInventoryListView(),
                SerialInventoryListView(),
                NodeInventoryLedgerView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
