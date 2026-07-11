import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../features/audit/data/models/stock_audit.dart';
import '../../../../features/audit/providers/stock_audit_provider.dart';

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen>
    with TickerProviderStateMixin {
  bool _showTodayOnTop = false;
  late TabController _statusTabCtrl;

  final _statusValues = const [
    'initiated_auditing',
    'assigned',
    'sent_for_review',
    null,
  ];

  @override
  void initState() {
    super.initState();
    _statusTabCtrl = TabController(length: 4, vsync: this);
    _statusTabCtrl.addListener(_onStatusTabChanged);
  }

  @override
  void dispose() {
    _statusTabCtrl.removeListener(_onStatusTabChanged);
    _statusTabCtrl.dispose();
    super.dispose();
  }

  void _onStatusTabChanged() {
    if (_statusTabCtrl.indexIsChanging) return;

    final statusValue = _statusValues[_statusTabCtrl.index];
    final state = ref.read(stockAuditsProvider);
    if (state.filterStatus != statusValue) {
      ref
          .read(stockAuditsProvider.notifier)
          .setFilters(auditType: state.filterAuditType, status: statusValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockAuditsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Toggles & Filters ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Show today's audits on top",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Switch(
                  value: _showTodayOnTop,
                  onChanged: (val) {
                    setState(() {
                      _showTodayOnTop = val;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),

          TabBar(
            controller: _statusTabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: AppColors.cardBorder,
            labelStyle: AppTextStyles.labelSmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Assigned'),
              Tab(text: 'Sent for Review'),
              Tab(text: 'All'),
            ],
          ),
          
          // ── Content ────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _statusTabCtrl,
              children: [
                _buildTabContent(state, 'initiated_auditing'),
                _buildTabContent(state, 'assigned'),
                _buildTabContent(state, 'sent_for_review'),
                _buildTabContent(state, null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(StockAuditsState state, String? tabStatus) {
    if (state.filterStatus != tabStatus) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    Widget content;
    if (state.error != null && state.audits.isEmpty) {
      content = CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildError(ref, state.error!),
          ),
        ],
      );
    } else if (state.isLoading && state.audits.isEmpty) {
      content = CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      );
    } else if (state.audits.isEmpty) {
      content = CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmpty(),
          ),
        ],
      );
    } else {
      List<StockAuditDetail> displayAudits = List.from(state.audits);
      if (_showTodayOnTop) {
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        displayAudits.sort((a, b) {
          final aIsToday = a.scheduledDate == todayStr;
          final bIsToday = b.scheduledDate == todayStr;
          if (aIsToday && !bIsToday) return -1;
          if (!aIsToday && bIsToday) return 1;
          return 0;
        });
      }

      content = NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollEndNotification || n is ScrollUpdateNotification) {
            if (n.metrics.extentAfter < 200) {
              ref.read(stockAuditsProvider.notifier).loadNextPage();
            }
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${state.totalCount} Audit${state.totalCount == 1 ? '' : 's'} Found',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayAudits.length + (state.isMoreLoading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= displayAudits.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _AuditCard(audit: displayAudits[i]);
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(stockAuditsProvider.notifier).load(),
      child: content,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text('No Stock Audits', style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(
              'You have no pending stock audits at this time.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(WidgetRef ref, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text('Failed to load audits', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.read(stockAuditsProvider.notifier).load(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Audit Card ────────────────────────────────────────────────────────────────

class _AuditCard extends StatelessWidget {
  final StockAuditDetail audit;
  const _AuditCard({required this.audit});

  @override
  Widget build(BuildContext context) {
    final isSpot = audit.auditType.toLowerCase() == 'spot';
    final typeBadgeColor = isSpot ? AppColors.warning : const Color(0xFF3F51B5);

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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.cardBorder,
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/audit/${audit.id}'),
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
                          _TypeBadge(
                            label: statusLabel,
                            color: statusBadgeColor,
                          ),
                          const SizedBox(width: 6),
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
                            'Scheduled: ${audit.scheduledDate}',
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
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeBadge({required this.label, required this.color});

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
          fontSize: 9,
        ),
      ),
    );
  }
}
