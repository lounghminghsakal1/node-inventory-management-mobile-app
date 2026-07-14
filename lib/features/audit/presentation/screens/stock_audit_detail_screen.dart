import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

import '../../data/models/stock_audit.dart';
import '../../providers/stock_audit_provider.dart';
import '../../utils/audit_draft_service.dart';
import '../../../home/providers/home_provider.dart';

// Main Screen

class StockAuditDetailScreen extends ConsumerStatefulWidget {
  final String auditId;
  const StockAuditDetailScreen({super.key, required this.auditId});

  @override
  ConsumerState<StockAuditDetailScreen> createState() =>
      _StockAuditDetailScreenState();
}

class _StockAuditDetailScreenState
    extends ConsumerState<StockAuditDetailScreen> {
  bool _isActionLoading = false;

  Future<void> _refresh() async {
    ref.invalidate(stockAuditDetailProvider(widget.auditId));
    ref.invalidate(auditLineItemsProvider(widget.auditId));
  }

  Future<void> _initiate(StockAuditDetail audit) async {
    // Guard: only allow initiating on the scheduled date. If tapped outside
    // of that window, show an error instead of hitting the API.
    // if (!audit.canInitiate) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Today is not the scheduled date for this audit.'),
    //       backgroundColor: AppColors.error,
    //     ),
    //   );
    //   return;
    // }

    setState(() => _isActionLoading = true);
    try {
      await ref
          .read(stockAuditRepositoryProvider)
          .initiateAudit(widget.auditId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock audit initiated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        await _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _sendForReview() async {
    setState(() => _isActionLoading = true);
    try {
      await ref
          .read(stockAuditRepositoryProvider)
          .sendForReview(widget.auditId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sent for review successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        await _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _onSkuSaved(AuditLineItem updated) async {
    ref
        .read(auditLineItemsProvider(widget.auditId).notifier)
        .updateItem(updated);
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(stockAuditDetailProvider(widget.auditId));
    final lineItemsState = ref.watch(auditLineItemsProvider(widget.auditId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: detailAsync.maybeWhen(
          data: (a) => a == null
              ? const Text('Stock Audit')
              : Text(
                  'Audit #${a.stockAuditNumber}',
                  style: AppTextStyles.headingMedium,
                ),
          orElse: () => const Text('Stock Audit'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.cardBorder),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(err.toString().replaceFirst('Exception: ', '')),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (audit) {
          if (audit == null) {
            return const Center(child: Text('Audit not found'));
          }
          return _buildBody(context, audit, lineItemsState);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    StockAuditDetail audit,
    AuditLineItemsState lineItemsState,
  ) {
    final splash = ref.watch(splashDataProvider).valueOrNull;
    final canUpdate = splash?.hasPermission('StockAudit', 'update') ?? false;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _AuditHeader(
                  audit: audit,
                  isActionLoading: _isActionLoading,
                  canUpdate: canUpdate,
                  onInitiate: () => _initiate(audit),
                  onSendForReview: _sendForReview,
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          SliverFillRemaining(
            child: _buildLineItemsBody(
              audit,
              lineItemsState,
              canUpdate,
              splash?.hasPermission('StockAudit', 'read') ?? false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsBody(
    StockAuditDetail audit,
    AuditLineItemsState lineItemsState,
    bool canUpdate,
    bool canRead,
  ) {
    if (lineItemsState.error != null && lineItemsState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(lineItemsState.error!.replaceFirst('Exception: ', '')),
            TextButton.icon(
              onPressed: () => ref
                  .read(auditLineItemsProvider(widget.auditId).notifier)
                  .load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final countedCount = lineItemsState.items.where((i) => i.isCounted).length;

    return Column(
      children: [
        // Summary bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                'SKUs (${lineItemsState.totalCount})',
                style: AppTextStyles.labelMedium,
              ),
              const Spacer(),
              Text(
                '$countedCount counted',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: lineItemsState.items.isEmpty && lineItemsState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification &&
                        n.metrics.pixels >= n.metrics.maxScrollExtent - 100) {
                      ref
                          .read(auditLineItemsProvider(widget.auditId).notifier)
                          .loadNextPage();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount:
                        lineItemsState.items.length +
                        (lineItemsState.isMoreLoading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= lineItemsState.items.length) {
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
                      final item = lineItemsState.items[i];
                      final canEdit =
                          audit.status == StockAuditStatus.initiatedAuditing &&
                          canUpdate;
                      return _SkuLineItemCard(
                        item: item,
                        canEdit: canEdit,
                        canRead: canRead,
                        auditId: widget.auditId,
                        auditStatus: audit.status,
                        onSaved: _onSkuSaved,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _AuditHeader extends StatelessWidget {
  final StockAuditDetail audit;
  final bool isActionLoading;
  final bool canUpdate;
  final VoidCallback onInitiate;
  final VoidCallback onSendForReview;

  const _AuditHeader({
    required this.audit,
    required this.isActionLoading,
    required this.canUpdate,
    required this.onInitiate,
    required this.onSendForReview,
  });

  Color get _statusColor {
    switch (audit.status) {
      case StockAuditStatus.assigned:
        return AppColors.primary;
      case StockAuditStatus.initiatedAuditing:
        return AppColors.warning;
      case StockAuditStatus.sentForReview:
        return AppColors.secondary;
      case StockAuditStatus.approved:
        return AppColors.success;
      case StockAuditStatus.rejected:
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _statusColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        audit.status.label.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F51B5).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF3F51B5).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        audit.auditType.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF3F51B5),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isActionLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (audit.status == StockAuditStatus.assigned && canUpdate)
                ElevatedButton.icon(
                  onPressed: onInitiate,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Initiate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else if (audit.status == StockAuditStatus.initiatedAuditing && canUpdate)
                ElevatedButton.icon(
                  onPressed: onSendForReview,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send for Review'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 4,
            children: [
              _HeaderChip(
                icon: Icons.calendar_today_outlined,
                label: 'Scheduled',
                value: audit.scheduledDate,
              ),
              _HeaderChip(
                icon: Icons.inventory_2_outlined,
                label: 'SKUs',
                value: '${audit.lineItemsCount}',
              ),
              if (audit.notes != null && audit.notes!.isNotEmpty)
                _HeaderChip(
                  icon: Icons.notes_outlined,
                  label: 'Notes',
                  value: audit.notes!,
                ),
            ],
          ),
          if (audit.rejectionReason != null &&
              audit.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.error,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Rejection reason: ${audit.rejectionReason}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(icon, size: 13, color: AppColors.textMuted),
            ),
          ),
          TextSpan(
            text: '$label: ',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          TextSpan(
            text: value,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// SKU Line

class _SkuLineItemCard extends StatelessWidget {
  final AuditLineItem item;
  final bool canEdit;
  final bool canRead;
  final String auditId;
  final StockAuditStatus auditStatus;
  final Future<void> Function(AuditLineItem) onSaved;

  const _SkuLineItemCard({
    required this.item,
    required this.canEdit,
    required this.canRead,
    required this.auditId,
    required this.auditStatus,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final hasCounts = item.countedQty != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasCounts)
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 10),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.skuName,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.skuCode,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (item.trackingType == 'untracked')
                      _UntrackedInlineEditor(
                        item: item,
                        auditId: auditId,
                        canEdit: canEdit,
                        onSaved: onSaved,
                      ),
                    if (item.trackingType != 'untracked')
                      _TrackedInlineEditor(
                        item: item,
                        auditId: auditId,
                        canEdit: canEdit,
                        canRead: canRead,
                        auditStatus: auditStatus,
                        onSaved: onSaved,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TrackingBadge(trackingType: item.trackingType),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyChip extends StatelessWidget {
  final String label;
  final int? value;
  final Color color;
  const _QtyChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value != null ? '$value' : '-',
            style: AppTextStyles.caption.copyWith(
              color: value != null ? color : AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _UntrackedInlineEditor extends ConsumerStatefulWidget {
  final AuditLineItem item;
  final String auditId;
  final bool canEdit;
  final Future<void> Function(AuditLineItem) onSaved;
  const _UntrackedInlineEditor({
    required this.item,
    required this.auditId,
    required this.canEdit,
    required this.onSaved,
  });

  @override
  ConsumerState<_UntrackedInlineEditor> createState() =>
      _UntrackedInlineEditorState();
}

class _UntrackedInlineEditorState
    extends ConsumerState<_UntrackedInlineEditor> {
  late final TextEditingController _goodCtrl;
  late final TextEditingController _damagedCtrl;
  bool _isSaving = false;

  bool _isLoadingDraft = true;

  @override
  void initState() {
    super.initState();
    _goodCtrl = TextEditingController();
    _damagedCtrl = TextEditingController();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await AuditDraftService.getDraft(
      widget.auditId,
      widget.item.skuId.toString(),
    );
    if (draft != null) {
      _goodCtrl.text = draft['good']?.toString() ?? '';
      _damagedCtrl.text = draft['damaged']?.toString() ?? '';
    } else {
      _goodCtrl.text = widget.item.countedQty?.toString() ?? '';
      _damagedCtrl.text = widget.item.damagedQty?.toString() ?? '';
    }
    if (mounted) setState(() => _isLoadingDraft = false);
  }

  Future<void> _saveDraft() async {
    final data = {'good': _goodCtrl.text, 'damaged': _damagedCtrl.text};
    await AuditDraftService.saveDraft(
      widget.auditId,
      widget.item.skuId.toString(),
      data,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entered quantity saved as draft'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(_UntrackedInlineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item != oldWidget.item) {
      _isLoadingDraft = true;
      _loadDraft();
    }
  }

  @override
  void dispose() {
    _goodCtrl.dispose();
    _damagedCtrl.dispose();
    super.dispose();
  }

  Future<bool> _showDiscrepancyWarning() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discrepancy Warning'),
            content: const Text(
              'There may be huge variance between you entered quantity with system quantity.\n\n'
              'There may be discrepancies - please recount once more to ensure accuracy.\n\n'
              'Do you want to proceed anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel & Recount'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Proceed'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _save() async {
    final good = int.tryParse(_goodCtrl.text) ?? 0;
    final damaged = int.tryParse(_damagedCtrl.text) ?? 0;

    int missing = widget.item.systemQty - good - damaged;
    if (missing < 0) missing = 0;

    if (good + damaged + missing != widget.item.systemQty) {
      final proceed = await _showDiscrepancyWarning();
      if (!proceed) return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await ref.read(stockAuditRepositoryProvider).countSku(
        widget.auditId,
        widget.item.skuId,
        {'counted_qty': good, 'damaged_qty': damaged, 'missing_qty': missing},
      );
      await AuditDraftService.clearDraft(
        widget.auditId,
        widget.item.skuId.toString(),
      );
      await widget.onSaved(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entered quantity saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canEdit) {
      return _ReadOnlyQtyRow(
        goodQty: widget.item.countedQty ?? 0,
        damagedQty: widget.item.damagedQty ?? 0,
        missingQty: widget.item.missingQty ?? 0,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _CountField(
                label: 'Good',
                ctrl: _goodCtrl,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CountField(
                label: 'Damaged',
                ctrl: _damagedCtrl,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: (_isSaving || _isLoadingDraft) ? null : _saveDraft,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  child: const Text('Save Draft'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: (_isSaving || _isLoadingDraft) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrackedInlineEditor extends ConsumerWidget {
  final AuditLineItem item;
  final String auditId;
  final bool canEdit;
  final bool canRead;
  final StockAuditStatus auditStatus;
  final Future<void> Function(AuditLineItem) onSaved;
  const _TrackedInlineEditor({
    required this.item,
    required this.auditId,
    required this.canEdit,
    required this.canRead,
    required this.auditStatus,
    required this.onSaved,
  });

  Future<void> _openBatchModal(BuildContext context, WidgetRef ref) async {
    final updated = await showDialog<AuditLineItem>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BatchCountModal(
        auditId: auditId,
        item: item,
        canEdit: canEdit,
        auditStatus: auditStatus,
      ),
    );
    if (updated != null) onSaved(updated);
  }

  Future<void> _openSerialModal(BuildContext context, WidgetRef ref) async {
    final updated = await showDialog<AuditLineItem>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SerialCountModal(
        auditId: auditId,
        item: item,
        canEdit: canEdit,
        auditStatus: auditStatus,
      ),
    );
    if (updated != null) onSaved(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QtyChip(
              label: 'Good',
              value: item.countedQty,
              color: AppColors.success,
            ),
            _QtyChip(
              label: 'Damaged',
              value: item.damagedQty,
              color: AppColors.warning,
            ),
            _QtyChip(
              label: 'Missing',
              value: item.missingQty,
              color: AppColors.error,
            ),
          ],
        ),
        if (auditStatus != StockAuditStatus.assigned && (canEdit || canRead)) ...[
          const SizedBox(height: 12),
          if (item.trackingType == 'batch')
            FilledButton.icon(
              onPressed: () => _openBatchModal(context, ref),
              icon: const Icon(Icons.edit_document, size: 16),
              label: Text(
                !canEdit
                    ? 'View Batches'
                    : (item.countedQty == null
                          ? 'Enter Batches'
                          : 'Edit Batches'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                foregroundColor: AppColors.primary,
                elevation: 0,
              ),
            ),
          if (item.trackingType == 'serial')
            FilledButton.icon(
              onPressed: () => _openSerialModal(context, ref),
              icon: const Icon(Icons.qr_code, size: 16),
              label: Text(
                !canEdit
                    ? 'View Serials'
                    : (item.countedQty == null
                          ? 'Enter Serials'
                          : 'Edit Serials'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                foregroundColor: AppColors.primary,
                elevation: 0,
              ),
            ),
        ],
      ],
    );
  }
}

class _BatchEntry {
  final AuditBatch batch;
  final TextEditingController goodCtrl;
  final TextEditingController damagedCtrl;

  _BatchEntry(this.batch)
    : goodCtrl = TextEditingController(),
      damagedCtrl = TextEditingController();

  void dispose() {
    goodCtrl.dispose();
    damagedCtrl.dispose();
  }
}

class _BatchCountModal extends ConsumerStatefulWidget {
  final String auditId;
  final AuditLineItem item;
  final bool canEdit;
  final StockAuditStatus auditStatus;

  const _BatchCountModal({
    required this.auditId,
    required this.item,
    required this.canEdit,
    required this.auditStatus,
  });

  @override
  ConsumerState<_BatchCountModal> createState() => _BatchCountModalState();
}

class _BatchCountModalState extends ConsumerState<_BatchCountModal> {
  List<_BatchEntry>? _entries;
  bool _isSaving = false;

  bool _isLoadingDraft = true;
  Map<String, dynamic>? _draft;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    _draft = await AuditDraftService.getDraft(
      widget.auditId,
      widget.item.skuId.toString(),
    );
    if (mounted) setState(() => _isLoadingDraft = false);
  }

  void _initEntries(List<AuditBatch> batches) {
    if (_entries != null) return;

    final metaBatches = widget.item.meta?['batches'] as List<dynamic>? ?? [];
    _entries = batches.map((b) {
      final entry = _BatchEntry(b);
      final draftBatch = _draft?[b.id.toString()];
      if (draftBatch != null) {
        entry.goodCtrl.text = draftBatch['good']?.toString() ?? '';
        entry.damagedCtrl.text = draftBatch['damaged']?.toString() ?? '';
      } else {
        final metaBatch = metaBatches
            .where((m) => m['batch_id']?.toString() == b.id.toString())
            .firstOrNull;
        if (metaBatch != null) {
          entry.goodCtrl.text = metaBatch['counted_qty']?.toString() ?? '';
          entry.damagedCtrl.text = metaBatch['damaged_qty']?.toString() ?? '';
        }
      }
      return entry;
    }).toList();
  }

  Future<void> _saveDraft() async {
    if (_entries == null) return;
    final Map<String, dynamic> data = {};
    for (var e in _entries!) {
      data[e.batch.id.toString()] = {
        'good': e.goodCtrl.text,
        'damaged': e.damagedCtrl.text,
      };
    }
    await AuditDraftService.saveDraft(
      widget.auditId,
      widget.item.skuId.toString(),
      data,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entered quantities saved as draft'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _entries?.forEach((e) => e.dispose());
    super.dispose();
  }

  Future<bool> _showDiscrepancyWarning() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discrepancy Warning'),
            content: const Text(
              'The totals for one or more batches do not account for all items.\n\n'
              'There may be discrepancies - please recount once more to ensure accuracy.\n\n'
              'Do you want to proceed anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel & Recount'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Proceed'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _confirm() async {
    if (_entries == null) return;

    int totalGood = 0;
    int totalDamaged = 0;
    int totalMissing = 0;
    bool hasDiscrepancy = false;

    final batchList = _entries!.map((e) {
      final good = int.tryParse(e.goodCtrl.text) ?? 0;
      final damaged = int.tryParse(e.damagedCtrl.text) ?? 0;

      int missing = e.batch.systemQty - good - damaged;
      if (missing < 0) missing = 0;

      if (good + damaged + missing != e.batch.systemQty) {
        hasDiscrepancy = true;
      }

      totalGood += good;
      totalDamaged += damaged;
      totalMissing += missing;

      return {
        'batch_id': int.tryParse(e.batch.id) ?? 0,
        'batch_code': e.batch.batchCode,
        'counted_qty': good,
        'damaged_qty': damaged,
        'missing_qty': missing,
      };
    }).toList();

    if (hasDiscrepancy) {
      final proceed = await _showDiscrepancyWarning();
      if (!proceed) return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await ref
          .read(stockAuditRepositoryProvider)
          .countSku(widget.auditId, widget.item.skuId, {
            'counted_qty': totalGood,
            'damaged_qty': totalDamaged,
            'missing_qty': totalMissing,
            'batches': batchList,
          });
      await AuditDraftService.clearDraft(
        widget.auditId,
        widget.item.skuId.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entered quantities saved'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDraft) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [CircularProgressIndicator()],
          ),
        ),
      );
    }

    final batchesAsync = ref.watch(
      auditSkuBatchesProvider((
        auditId: widget.auditId,
        skuId: widget.item.skuId,
      )),
    );

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.canEdit ? 'Enter Batch Quantities' : 'Batch Quantities',
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Enter good and damaged qty for each batch. Missing is calculated automatically.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              batchesAsync.when(
                loading: () => const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    Expanded(child: Center(child: Text('Error: $e'))),
                data: (batches) {
                  if (batches.isEmpty) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          'No batches found',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  }
                  _initEntries(batches);
                  return Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _entries!.map((entry) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.batch.batchCode,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (entry.batch.expiryDate != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Expiry: ${entry.batch.expiryDate}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _CountField(
                                        label: 'Good',
                                        ctrl: entry.goodCtrl,
                                        color: AppColors.success,
                                        readOnly: !widget.canEdit,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _CountField(
                                        label: 'Damaged',
                                        ctrl: entry.damagedCtrl,
                                        color: AppColors.warning,
                                        readOnly: !widget.canEdit,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              if (widget.auditStatus == StockAuditStatus.initiatedAuditing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              await _saveDraft();
                              if (mounted) Navigator.pop(context);
                            },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: const Text('Save Draft'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: (_isSaving || _entries == null)
                          ? null
                          : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm\n & Save'),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
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

// Serial Count Modal

class _SerialCountModal extends ConsumerStatefulWidget {
  final String auditId;
  final AuditLineItem item;
  final bool canEdit;
  final StockAuditStatus auditStatus;
  const _SerialCountModal({
    required this.auditId,
    required this.item,
    required this.canEdit,
    required this.auditStatus,
  });

  @override
  ConsumerState<_SerialCountModal> createState() => _SerialCountModalState();
}

class _SerialCountModalState extends ConsumerState<_SerialCountModal> {
  Set<String>? _good;
  Set<String>? _damaged;
  List<AuditSerial> _expectedSerials = [];
  bool _isSaving = false;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isLoadingDraft = true;
  Map<String, dynamic>? _draft;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    _draft = await AuditDraftService.getDraft(
      widget.auditId,
      widget.item.skuId.toString(),
    );
    if (mounted) setState(() => _isLoadingDraft = false);
  }

  void _initSets(List<AuditSerial> serials) {
    if (_good != null) return;
    _expectedSerials = serials;

    if (_draft != null) {
      _good =
          (_draft!['good'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {};
      _damaged =
          (_draft!['damaged'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {};
    } else {
      final damagedList =
          widget.item.meta?['damaged_serials'] as List<dynamic>? ?? [];
      _damaged = damagedList.map((e) => e.toString()).toSet();

      if (widget.item.isCounted) {
        final goodList =
            widget.item.meta?['good_serials'] as List<dynamic>? ?? [];
        if (goodList.isNotEmpty) {
          _good = goodList.map((e) => e.toString()).toSet();
        } else {
          final missingList =
              widget.item.meta?['missing_serials'] as List<dynamic>? ?? [];
          final missing = missingList.map((e) => e.toString()).toSet();
          _good = serials
              .map((s) => s.serialNumber)
              .where((sn) => !_damaged!.contains(sn) && !missing.contains(sn))
              .toSet();
        }
      } else {
        _good = {};
      }
    }
  }

  Future<void> _saveDraft() async {
    if (_good == null || _damaged == null) return;
    final data = {'good': _good!.toList(), 'damaged': _damaged!.toList()};
    await AuditDraftService.saveDraft(
      widget.auditId,
      widget.item.skuId.toString(),
      data,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entered serials saved as draft'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue ?? '';
    if (code.isEmpty) return;

    HapticFeedback.lightImpact();

    if (_good!.contains(code) || _damaged!.contains(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Serial $code already scanned.'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.textMuted,
        ),
      );
      return;
    }

    final isExpected = _expectedSerials.any((s) => s.serialNumber == code);
    if (!isExpected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Serial "$code" is not expected for this item.'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    _scannerController.stop();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code_rounded, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('Serial Captured'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                code,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Is this item Good or Damaged?'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'damaged'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Damaged'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'good'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Good'),
          ),
        ],
      ),
    );

    if (result == 'good') {
      setState(() => _good!.add(code));
    } else if (result == 'damaged') {
      setState(() => _damaged!.add(code));
    }

    _scannerController.start();
  }

  Future<void> _confirm() async {
    if (_good == null) return;

    final missing = _expectedSerials
        .map((s) => s.serialNumber)
        .where((sn) => !_good!.contains(sn) && !_damaged!.contains(sn))
        .toList();

    setState(() => _isSaving = true);
    try {
      final updated = await ref
          .read(stockAuditRepositoryProvider)
          .countSku(widget.auditId, widget.item.skuId, {
            'counted_qty': _good!.length,
            'damaged_qty': _damaged!.length,
            'missing_qty': missing.length,
            'good_serials': _good!.toList(),
            'damaged_serials': _damaged!.toList(),
            'missing_serials': missing,
          });
      await AuditDraftService.clearDraft(
        widget.auditId,
        widget.item.skuId.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entered serials saved'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDraft) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final serialsAsync = ref.watch(
      auditSkuSerialsProvider((
        auditId: widget.auditId,
        skuId: widget.item.skuId,
      )),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              children: [
                Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text('Scan Serials', style: AppTextStyles.headingMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: serialsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (serials) {
                  if (serials.isEmpty) {
                    return Center(
                      child: Text(
                        'No expected serials found',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  }
                  _initSets(serials);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.canEdit &&
                          widget.auditStatus ==
                              StockAuditStatus.initiatedAuditing)
                        Container(
                          height: 220,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: MobileScanner(
                            controller: _scannerController,
                            onDetect: _onDetect,
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            _SerialStatChip(
                              label: 'Good',
                              count: _good!.length,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            _SerialStatChip(
                              label: 'Damaged',
                              count: _damaged!.length,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            _SerialStatChip(
                              label: 'Missing',
                              count:
                                  serials.length -
                                  _good!.length -
                                  _damaged!.length,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._good!.map(
                                (s) => Chip(
                                  avatar: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  label: Text(
                                    s,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: AppColors.success,
                                  onDeleted: widget.canEdit
                                      ? () => setState(() => _good!.remove(s))
                                      : null,
                                  deleteIconColor: Colors.white,
                                ),
                              ),
                              ..._damaged!.map(
                                (s) => Chip(
                                  avatar: const Icon(
                                    Icons.warning_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  label: Text(
                                    s,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: AppColors.warning,
                                  onDeleted: widget.canEdit
                                      ? () =>
                                            setState(() => _damaged!.remove(s))
                                      : null,
                                  deleteIconColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: widget.auditStatus == StockAuditStatus.initiatedAuditing
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.cardBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    await _saveDraft();
                                    if (mounted) Navigator.pop(context);
                                  },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Save Draft'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (_isSaving || _good == null)
                                ? null
                                : _confirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Confirm & Save'),
                          ),
                        ),
                      ],
                    )
                  : OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _SerialStatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SerialStatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Shared: Read-only qty display

class _ReadOnlyQtyRow extends StatelessWidget {
  final int goodQty;
  final int damagedQty;
  final int missingQty;
  const _ReadOnlyQtyRow({
    required this.goodQty,
    required this.damagedQty,
    required this.missingQty,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyChip(label: 'Good', value: goodQty, color: AppColors.success),
        const SizedBox(width: 8),
        _QtyChip(label: 'Damaged', value: damagedQty, color: AppColors.warning),
        const SizedBox(width: 8),
        _QtyChip(label: 'Missing', value: missingQty, color: AppColors.error),
      ],
    );
  }
}

// Shared Helpers

class _CountField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final Color? color;
  final bool readOnly;

  const _CountField({
    required this.label,
    required this.ctrl,
    this.color,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color ?? AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          readOnly: readOnly,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: color?.withValues(alpha: 0.4) ?? AppColors.cardBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: color?.withValues(alpha: 0.4) ?? AppColors.cardBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: color ?? AppColors.primary,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: color?.withValues(alpha: 0.04) ?? AppColors.background,
          ),
        ),
      ],
    );
  }
}

class _TrackingBadge extends StatelessWidget {
  final String trackingType;
  const _TrackingBadge({required this.trackingType});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (trackingType) {
      case 'batch':
        color = AppColors.secondary;
        break;
      case 'serial':
        color = AppColors.accentGreen;
        break;
      default:
        color = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        trackingType.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
