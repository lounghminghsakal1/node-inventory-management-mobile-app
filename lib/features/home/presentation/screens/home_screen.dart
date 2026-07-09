import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/dashboard_stats.dart';
import '../../providers/home_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/recent_activity_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splashAsync = ref.watch(splashDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          return ref.refresh(splashDataProvider.future);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Overview Section ───────────────────────────────────────
                  _buildSectionLabel('Overview'),
                  const SizedBox(height: 12),
                  splashAsync.when(
                    data: (splash) => _buildStatsRow(context, splash),
                    loading: () => _buildLoadingStatsRow(context),
                    error: (err, _) => _buildErrorStatsRow(context, ref, err.toString()),
                  ),
                  const SizedBox(height: 24),

                  // ── Stock Audits Section (From Splash API) ────────────────
                  splashAsync.maybeWhen(
                    data: (splash) {
                      if (splash.stockAudits.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionLabel('Pending Stock Audits'),
                              TextButton(
                                onPressed: () => context.go('/audit'),
                                child: Text(
                                  'View All',
                                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...splash.stockAudits.map((audit) => _buildStockAuditCard(context, audit)),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),

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
                        label: 'Shipments',
                        icon: Icons.local_shipping_rounded,
                        color: AppColors.primary,
                        onTap: () => context.go('/shipments'),
                      ),
                      QuickActionTile(
                        label: 'Purchase Orders',
                        icon: Icons.shopping_bag_rounded,
                        color: AppColors.secondary,
                        onTap: () => context.go('/purchase-orders'),
                      ),
                      QuickActionTile(
                        label: 'Inventory',
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.accentGreen,
                        onTap: () => context.go('/inventory'),
                      ),
                      QuickActionTile(
                        label: 'Audit',
                        icon: Icons.fact_check_rounded,
                        color: AppColors.warning,
                        onTap: () => context.go('/audit'),
                      ),
                      QuickActionTile(
                        label: 'GRN',
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.accent,
                        onTap: () => context.go('/purchase-orders'),
                      ),
                      QuickActionTile(
                        label: 'Refresh',
                        icon: Icons.refresh_rounded,
                        color: AppColors.textSecondary,
                        onTap: () => ref.refresh(splashDataProvider.future),
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
                        child: Text(
                          'See all',
                          style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...dummyActivity.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RecentActivityCard(item: a),
                      )),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildStatsRow(BuildContext context, SplashData splash) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Pending\nShipments',
            value: '${splash.pendingForwardShipmentsCount}',
            icon: Icons.local_shipping_outlined,
            gradient: AppColors.primaryGradient,
            onTap: () => context.go('/shipments'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Return\nInitiated',
            value: '${splash.returnInitiatedShipmentsCount}',
            icon: Icons.assignment_return_outlined,
            gradient: AppColors.warningGradient,
            onTap: () => context.go('/shipments'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Stock\nAudits',
            value: '${splash.stockAudits.length}',
            icon: Icons.fact_check_outlined,
            gradient: AppColors.cyanGradient,
            onTap: () => context.go('/audit'),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Pending\nShipments',
            value: '...',
            icon: Icons.local_shipping_outlined,
            gradient: AppColors.primaryGradient,
            onTap: () => context.go('/shipments'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Return\nInitiated',
            value: '...',
            icon: Icons.assignment_return_outlined,
            gradient: AppColors.warningGradient,
            onTap: () => context.go('/inventory'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Stock\nAudits',
            value: '...',
            icon: Icons.fact_check_outlined,
            gradient: AppColors.cyanGradient,
            onTap: () => context.go('/audit'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorStatsRow(BuildContext context, WidgetRef ref, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Failed to load overview data',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => ref.refresh(splashDataProvider.future),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStockAuditCard(BuildContext context, StockAudit audit) {
    final isSpot = audit.auditType.toLowerCase() == 'spot';
    final badgeColor = isSpot ? AppColors.warning : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/audit'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSpot ? Icons.flash_on_rounded : Icons.calendar_today_rounded,
                    color: badgeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Audit #${audit.stockAuditNumber}',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              audit.auditType.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Scheduled: ${audit.scheduledDate}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary),
    );
  }
}
