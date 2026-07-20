import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:node_management_app/core/utils/helper_functions.dart';
import 'package:node_management_app/core/utils/snackbar_utils.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/dashboard_stats.dart';
import '../../providers/home_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _navigateWithPermission(
    BuildContext context,
    WidgetRef ref,
    String route,
    String featureName,
    String module,
  ) {
    final splash = ref.read(splashDataProvider).valueOrNull;
    if (splash == null) return;

    bool hasAccess = false;
    if (module == 'Inventory') {
      hasAccess =
          splash.hasPermission('NodeInventory', 'read') ||
          splash.hasPermission('BatchInventory', 'read') ||
          splash.hasPermission('SkuItem', 'read');
    } else {
      hasAccess = splash.hasPermission(module, 'read');
    }

    if (hasAccess) {
      context.go(route);
    } else {
      showTopErrorSnackBar(
        context,
        'You are not authorised to see $featureName',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splashAsync = ref.watch(splashDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          final splashFuture = ref.refresh(splashDataProvider.future);
          final statsFuture = ref.refresh(nodeStatsProvider.future);
          await Future.wait([splashFuture, statsFuture]);
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionLabel('Overview'),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                        onPressed: () {
                          ref.refresh(splashDataProvider.future);
                          ref.refresh(nodeStatsProvider.future);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildOverviewSection(context, ref),
                  const SizedBox(height: 24),

                  // ── Stock Audits Section (From Splash API) ────────────────
                  splashAsync.maybeWhen(
                    data: (splash) {
                      if (splash.stockAudits.isEmpty)
                        return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionLabel('Pending Stock Audits'),
                              TextButton(
                                onPressed: () => _navigateWithPermission(
                                  context,
                                  ref,
                                  '/audit',
                                  'Stock Audit',
                                  'StockAudit',
                                ),
                                child: Text(
                                  'View All',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...splash.stockAudits.map(
                            (audit) =>
                                _buildStockAuditCard(context, ref, audit),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),

                  // ── Node Stats ─────────────────────────────────────────────
                  _buildNodeStatsSection(context, ref),
                  const SizedBox(height: 28),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, WidgetRef ref) {
    final splashAsync = ref.watch(splashDataProvider);
    final statsAsync = ref.watch(nodeStatsProvider);

    if (splashAsync.isLoading || statsAsync.isLoading) {
      return _buildLoadingStatsRow(context, ref);
    }

    if (splashAsync.hasError || statsAsync.hasError) {
      return _buildErrorStatsRow(context, ref, 'Failed to load overview data');
    }

    final splash = splashAsync.value;
    final stats = statsAsync.value;

    if (splash == null || stats == null) {
      return _buildErrorStatsRow(context, ref, 'No data available');
    }

    final pendingShipmentsCount = stats.pendingActions.toPack + 
        stats.pendingActions.toDispatch + 
        stats.pendingActions.unallocated;
    
    final returnsCount = stats.pendingActions.returnsPending;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Pending\nShipments',
            value: pendingShipmentsCount.toString(),
            icon: Icons.local_shipping_outlined,
            gradient: AppColors.primaryGradient,
            onTap: () => _navigateWithPermission(
              context,
              ref,
              '/shipments',
              'Shipments',
              'Shipment',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Return\nInitiated',
            value: returnsCount.toString(),
            icon: Icons.assignment_return_outlined,
            gradient: AppColors.warningGradient,
            onTap: () => _navigateWithPermission(
              context,
              ref,
              '/shipments?type=return&tab=initiated',
              'Shipments',
              'Shipment',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Stock\nAudits',
            value: '${splash.stockAudits.length}',
            icon: Icons.fact_check_outlined,
            gradient: AppColors.cyanGradient,
            onTap: () => _navigateWithPermission(
              context,
              ref,
              '/audit',
              'Stock Audit',
              'StockAudit',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingStatsRow(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Pending\nShipments',
            value: '...',
            icon: Icons.local_shipping_outlined,
            gradient: AppColors.primaryGradient,
            onTap: () => _navigateWithPermission(
              context,
              ref,
              '/shipments',
              'Shipments',
              'Shipment',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Return\nInitiated',
            value: '...',
            icon: Icons.assignment_return_outlined,
            gradient: AppColors.warningGradient,
            onTap: () => _navigateWithPermission(
              context,
              ref,
              '/shipments?type=return&tab=initiated',
              'Shipments',
              'Shipment',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Stock\nAudits',
            value: '...',
            icon: Icons.fact_check_outlined,
            gradient: AppColors.cyanGradient,
            onTap: () => _navigateWithPermission(
              context,
              ref,
              '/audit',
              'Stock Audit',
              'StockAudit',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorStatsRow(
    BuildContext context,
    WidgetRef ref,
    String error,
  ) {
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
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
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

  Widget _buildStockAuditCard(
    BuildContext context,
    WidgetRef ref,
    StockAudit audit,
  ) {
    final isSpot = audit.auditType.toLowerCase() == 'spot';
    final typeBadgeColor = isSpot
        ? AppColors.warning
        : const Color.fromARGB(255, 2, 30, 189);
    bool showStatus = true ? true : false;

    Color statusBadgeColor;
    String statusLabel = audit.status.label.toUpperCase();
    switch (audit.status) {
      case StockAuditStatus.assigned:
        statusBadgeColor = AppColors.primary;
        break;
      case StockAuditStatus.initiatedAuditing:
        statusBadgeColor = AppColors.warning;
        statusLabel = 'PENDING';
        break;
      case StockAuditStatus.sentForReview:
        statusBadgeColor = AppColors.secondary;
        break;
      case StockAuditStatus.approved:
        statusBadgeColor = AppColors.success;
        break;
      case StockAuditStatus.rejected:
        statusBadgeColor = AppColors.error;
        break;
      default:
        statusBadgeColor = AppColors.textMuted;
    }

    // Determine if scheduled date is today
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isToday = audit.scheduledDate == todayStr;

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
          onTap: () => _navigateWithPermission(
            context,
            ref,
            '/audit/${audit.id}',
            'Stock Audit',
            'StockAudit',
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusBadgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSpot
                        ? Icons.flash_on_rounded
                        : Icons.calendar_today_rounded,
                    color: statusBadgeColor,
                    size: 24,
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
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                          if (showStatus) _TypeBadge(
                              label: statusLabel,
                              color: statusBadgeColor,
                              size: 11,
                            ),
                          if (showStatus) const SizedBox(width: 6),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "Audit Type: ",
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          _TypeBadge(
                            label: audit.auditType.toUpperCase(),
                            color: typeBadgeColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          Text(
                            'Audit Date: ${HelperFunctions.formatDate(DateTime.parse(audit.scheduledDate), hasTime: false)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (isToday)
                            _TypeBadge(
                              label: 'TODAY',
                              color: AppColors.success,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeStatsSection(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(nodeStatsProvider);

    return statsAsync.when(
      data: (stats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPendingActionsSection(context, ref, stats),
          const SizedBox(height: 24),
          _buildTodaySummarySection(context, ref, stats),
        ],
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, _) => _buildErrorStatsRow(context, ref, err.toString()),
    );
  }

  Widget _buildPendingActionsSection(
    BuildContext context,
    WidgetRef ref,
    NodeStats stats,
  ) {
    final pending = stats.pendingActions;
    final totalPending = pending.unallocated +
        pending.toPack +
        pending.toDispatch +
        pending.returnsPending +
        pending.grnQcPending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _buildSectionLabel('Pending Actions')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: totalPending > 0
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  totalPending > 0 ? '$totalPending open' : 'All clear',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: totalPending > 0 ? AppColors.error : AppColors.success,
                    letterSpacing: 0,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionTile(
                'Unallocated',
                pending.unallocated,
                Icons.warning_amber_rounded,
                AppColors.warning,
                onTap: () => _navigateWithPermission(context, ref, '/shipments?filter=unallocated', 'Shipments', 'Shipment'),
              ),
              const SizedBox(width: 12),
              _buildActionTile(
                'To Pack',
                pending.toPack,
                Icons.inventory_2_outlined,
                AppColors.primary,
                onTap: () => _navigateWithPermission(context, ref, '/shipments?filter=to_pack', 'Shipments', 'Shipment'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionTile(
                'To Dispatch',
                pending.toDispatch,
                Icons.local_shipping_outlined,
                AppColors.secondary,
                onTap: () => _navigateWithPermission(context, ref, '/shipments?filter=to_dispatch', 'Shipments', 'Shipment'),
              ),
              const SizedBox(width: 12),
              _buildActionTile(
                'Returns Pending',
                pending.returnsPending,
                Icons.keyboard_return_rounded,
                AppColors.error,
                onTap: () => _navigateWithPermission(context, ref, '/shipments?type=return&tab=initiated', 'Shipments', 'Shipment'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionFullTile(
            'GRN QC Pending',
            pending.grnQcPending,
            Icons.fact_check_outlined,
            AppColors.accent,
            onTap: () => _navigateWithPermission(context, ref, '/purchase-orders', 'PurchaseOrder', 'PurchaseOrder'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummarySection(
    BuildContext context,
    WidgetRef ref,
    NodeStats stats,
  ) {
    final today = stats.todaySummary;
    final todayLabel = HelperFunctions.formatDate(DateTime.now(), hasTime: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _buildSectionLabel("Today's Summary")),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.15)),
                ),
                child: Text(
                  todayLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionTile(
                'Dispatched Today',
                today.dispatchedToday,
                Icons.check_circle_outline,
                AppColors.success,
                showAlert: false,
              ),
              const SizedBox(width: 12),
              _buildActionTile(
                'Returns Completed',
                today.returnsCompletedToday,
                Icons.assignment_return_outlined,
                AppColors.accent,
                showAlert: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionTile(
                'GRNs Completed',
                today.grnsCompletedToday,
                Icons.receipt_long_rounded,
                Colors.cyan.shade700,
                showAlert: false,
              ),
              const SizedBox(width: 12),
              _buildActionTile(
                'Items Received',
                today.itemsReceivedToday,
                Icons.move_to_inbox_rounded,
                AppColors.primary,
                showAlert: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    int value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
    bool showAlert = true,
  }) {
    final hasValue = value > 0;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          if (showAlert && hasValue)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.card, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (onTap != null)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                          size: 18,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    value.toString(),
                    style: AppTextStyles.headingXL.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: hasValue ? AppColors.textPrimary : AppColors.textDisabled,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionFullTile(
    String title,
    int value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
    bool showAlert = true,
  }) {
    final hasValue = value > 0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    if (showAlert && hasValue)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.card, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  value.toString(),
                  style: AppTextStyles.headingXL.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: hasValue ? AppColors.textPrimary : AppColors.textDisabled,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ],
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
      style: AppTextStyles.headingMedium.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double size;
  const _TypeBadge({required this.label, required this.color, this.size = 9});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: size,
        ),
      ),
    );
  }
}
