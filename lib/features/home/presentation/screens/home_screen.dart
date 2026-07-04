import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/dashboard_stats.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/recent_activity_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = DashboardStats.dummy;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Stats Row ──────────────────────────────────────────────
                _buildSectionLabel('Overview'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Pending\nOrders',
                        value: '${stats.pendingShipments}',
                        icon: Icons.shopping_bag_outlined,
                        gradient: AppColors.primaryGradient,
                        onTap: () => context.go('/orders'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Pending\nGRNs',
                        value: '${stats.pendingGRNs}',
                        icon: Icons.inventory_2_outlined,
                        gradient: AppColors.cyanGradient,
                        onTap: () => context.go('/grn'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Low Stock\nAlerts',
                        value: '${stats.lowStockAlerts}',
                        icon: Icons.warning_amber_outlined,
                        gradient: AppColors.warningGradient,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        'Today\'s Shipments',
                        '${stats.totalShipmentsToday}',
                        Icons.today_outlined,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniStat(
                        'Delivered Today',
                        '${stats.deliveredToday}',
                        Icons.check_circle_outline,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniStat(
                        'Pending Returns',
                        '${stats.pendingReturns}',
                        Icons.assignment_return_outlined,
                        AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Quick Actions ──────────────────────────────────────────
                _buildSectionLabel('Quick Actions'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: [
                    QuickActionTile(
                      label: 'Orders',
                      icon: Icons.shopping_bag_rounded,
                      color: AppColors.primary,
                      onTap: () => context.go('/orders'),
                    ),
                    QuickActionTile(
                      label: 'GRN',
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFF00D4FF),
                      onTap: () => context.go('/grn'),
                    ),
                    QuickActionTile(
                      label: 'Audit',
                      icon: Icons.fact_check_rounded,
                      color: AppColors.accentGreen,
                      onTap: () => context.go('/audit'),
                    ),
                    QuickActionTile(
                      label: 'Returns',
                      icon: Icons.assignment_return_rounded,
                      color: AppColors.warning,
                      onTap: () => context.go('/returns'),
                    ),
                    QuickActionTile(
                      label: 'Adjustment',
                      icon: Icons.tune_rounded,
                      color: AppColors.accent,
                      onTap: () => context.go('/adjustment'),
                    ),
                    QuickActionTile(
                      label: 'Profile',
                      icon: Icons.manage_accounts_rounded,
                      color: AppColors.textSecondary,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Recent Activity ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionLabel('Recent Activity'),
                    TextButton(
                      onPressed: () {},
                      child: Text('See all',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...dummyActivity
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RecentActivityCard(item: a),
                        )),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: AppTextStyles.headingMedium
            .copyWith(color: AppColors.textSecondary));
  }

  Widget _buildMiniStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.headingMedium.copyWith(color: color)),
          Text(label,
              style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

