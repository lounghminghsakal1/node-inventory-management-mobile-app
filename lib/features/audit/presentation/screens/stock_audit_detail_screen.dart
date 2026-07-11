import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

import '../../data/models/stock_audit.dart';
import '../../providers/stock_audit_provider.dart';

// ── Main Screen ───────────────────────────────────────────────────────────────

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
          onPressed: () => Navigator.pop(context),
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
                  onInitiate: () => _initiate(audit),
                  onSendForReview: _sendForReview,
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          SliverFillRemaining(
            child: _buildLineItemsBody(audit, lineItemsState),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsBody(
    StockAuditDetail audit,
    AuditLineItemsState lineItemsState,
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
        // ── Summary bar ────────────────────────────────────────────────────
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

        // ── Full-width SKU list ─────────────────────────────────────────────
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
                          audit.status == StockAuditStatus.initiatedAuditing;
                      return _SkuLineItemCard(
                        item: item,
                        canEdit: canEdit,
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

// ── Audit Header ──────────────────────────────────────────────────────────────

class _AuditHeader extends StatelessWidget {
  final StockAuditDetail audit;
  final bool isActionLoading;
  final VoidCallback onInitiate;
  final VoidCallback onSendForReview;

  const _AuditHeader({
    required this.audit,
    required this.isActionLoading,
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
              // Show the Initiate button for the entire "assigned" status,
              // not just when canInitiate is true — tapping it outside the
              // scheduled date now surfaces an error snackbar (handled in
              // _StockAuditDetailScreenState._initiate) instead of hiding
              // the button/list entirely.
              else if (audit.status == StockAuditStatus.assigned)
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
              else if (audit.status == StockAuditStatus.initiatedAuditing)
                ElevatedButton.icon(
                  onPressed: onSendForReview,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send for Approval'),
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

// ── SKU Line Item Card ─────────────────────────────────────────────────────────
// Full-width expandable card shown in the main list. Shows qty data inline and
// embeds the appropriate count panel directly beneath.

class _SkuLineItemCard extends StatelessWidget {
  final AuditLineItem item;
  final bool canEdit;
  final String auditId;
  final StockAuditStatus auditStatus;
  final Future<void> Function(AuditLineItem) onSaved;

  const _SkuLineItemCard({
    required this.item,
    required this.canEdit,
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
              // Status icon
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: hasCounts
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 18,
                      )
                    : const Icon(
                        Icons.radio_button_unchecked_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
              ),
              const SizedBox(width: 10),
              // Name + inputs/chips
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
                    // Inline inputs/chips depending on tracking type
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
            value != null ? '$value' : '—',
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

// ── Untracked ─────────────────────────────────────────────────────────────

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
  late final TextEditingController _missingCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _goodCtrl = TextEditingController(
      text: widget.item.countedQty?.toString() ?? '',
    );
    _damagedCtrl = TextEditingController(
      text: widget.item.damagedQty?.toString() ?? '',
    );
    _missingCtrl = TextEditingController(
      text: widget.item.missingQty?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(_UntrackedInlineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item != oldWidget.item) {
      _goodCtrl.text = widget.item.countedQty?.toString() ?? '';
      _damagedCtrl.text = widget.item.damagedQty?.toString() ?? '';
      _missingCtrl.text = widget.item.missingQty?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _goodCtrl.dispose();
    _damagedCtrl.dispose();
    _missingCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final good = int.tryParse(_goodCtrl.text) ?? 0;
    final damaged = int.tryParse(_damagedCtrl.text) ?? 0;
    final missing = int.tryParse(_missingCtrl.text) ?? 0;

    setState(() => _isSaving = true);
    try {
      final updated = await ref.read(stockAuditRepositoryProvider).countSku(
        widget.auditId,
        widget.item.skuId,
        {'counted_qty': good, 'damaged_qty': damaged, 'missing_qty': missing},
      );
      await widget.onSaved(updated);
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
            const SizedBox(width: 8),
            Expanded(
              child: _CountField(
                label: 'Missing',
                ctrl: _missingCtrl,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
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
      ],
    );
  }
}

// ── Tracked (Batch / Serial) Inline display ─────────────────────────────

class _TrackedInlineEditor extends ConsumerWidget {
  final AuditLineItem item;
  final String auditId;
  final bool canEdit;
  final StockAuditStatus auditStatus;
  final Future<void> Function(AuditLineItem) onSaved;
  const _TrackedInlineEditor({
    required this.item,
    required this.auditId,
    required this.canEdit,
    required this.auditStatus,
    required this.onSaved,
  });

  Future<void> _openBatchModal(BuildContext context, WidgetRef ref) async {
    final updated = await showDialog<AuditLineItem>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _BatchCountModal(auditId: auditId, item: item, canEdit: canEdit),
    );
    if (updated != null) onSaved(updated);
  }

  Future<void> _openSerialModal(BuildContext context, WidgetRef ref) async {
    final updated = await showDialog<AuditLineItem>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _SerialCountModal(auditId: auditId, item: item, canEdit: canEdit),
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
        if (auditStatus != StockAuditStatus.assigned) ...[
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

// ── Batch Count Modal ─────────────────────────────────────────────────────────

class _BatchEntry {
  final AuditBatch batch;
  final TextEditingController goodCtrl;
  final TextEditingController damagedCtrl;
  final TextEditingController missingCtrl;

  _BatchEntry(this.batch)
    : goodCtrl = TextEditingController(),
      damagedCtrl = TextEditingController(),
      missingCtrl = TextEditingController();

  void dispose() {
    goodCtrl.dispose();
    damagedCtrl.dispose();
    missingCtrl.dispose();
  }
}

class _BatchCountModal extends ConsumerStatefulWidget {
  final String auditId;
  final AuditLineItem item;
  final bool canEdit;
  const _BatchCountModal({
    required this.auditId,
    required this.item,
    required this.canEdit,
  });

  @override
  ConsumerState<_BatchCountModal> createState() => _BatchCountModalState();
}

class _BatchCountModalState extends ConsumerState<_BatchCountModal> {
  List<_BatchEntry>? _entries;
  bool _isSaving = false;

  void _initEntries(List<AuditBatch> batches) {
    if (_entries != null) return;

    final metaBatches = widget.item.meta?['batches'] as List<dynamic>? ?? [];
    _entries = batches.map((b) {
      final entry = _BatchEntry(b);
      final metaBatch = metaBatches
          .where((m) => m['batch_id']?.toString() == b.id.toString())
          .firstOrNull;
      if (metaBatch != null) {
        entry.goodCtrl.text = metaBatch['counted_qty']?.toString() ?? '';
        entry.damagedCtrl.text = metaBatch['damaged_qty']?.toString() ?? '';
        entry.missingCtrl.text = metaBatch['missing_qty']?.toString() ?? '';
      }
      return entry;
    }).toList();
  }

  @override
  void dispose() {
    _entries?.forEach((e) => e.dispose());
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_entries == null) return;

    int totalGood = 0;
    int totalDamaged = 0;
    int totalMissing = 0;

    final batchList = _entries!.map((e) {
      final good = int.tryParse(e.goodCtrl.text) ?? 0;
      final damaged = int.tryParse(e.damagedCtrl.text) ?? 0;
      final missing = int.tryParse(e.missingCtrl.text) ?? 0;

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
      if (mounted) Navigator.pop(context, updated);
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
                'Enter good, damaged and missing qty for each batch',
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
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.batch.batchCode,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Sys: ${entry.batch.systemQty}',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
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
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _CountField(
                                        label: 'Missing',
                                        ctrl: entry.missingCtrl,
                                        color: AppColors.error,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
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
                        : const Text('Confirm & Save'),
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

// ── Serial Count Modal ────────────────────────────────────────────────────────

class _SerialCountModal extends ConsumerStatefulWidget {
  final String auditId;
  final AuditLineItem item;
  final bool canEdit;
  const _SerialCountModal({
    required this.auditId,
    required this.item,
    required this.canEdit,
  });

  @override
  ConsumerState<_SerialCountModal> createState() => _SerialCountModalState();
}

class _SerialCountModalState extends ConsumerState<_SerialCountModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<String>? _good;
  Set<String>? _damaged;
  Set<String>? _missing;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _initSets(List<AuditSerial> serials) {
    if (_good != null) return;

    final damagedList =
        widget.item.meta?['damaged_serials'] as List<dynamic>? ?? [];
    final missingList =
        widget.item.meta?['missing_serials'] as List<dynamic>? ?? [];

    _damaged = damagedList.map((e) => e.toString()).toSet();
    _missing = missingList.map((e) => e.toString()).toSet();

    if (widget.item.isCounted) {
      _good = serials
          .map((s) => s.serialNumber)
          .where((sn) => !_damaged!.contains(sn) && !_missing!.contains(sn))
          .toSet();
    } else {
      _good = {};
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_good == null) return;

    setState(() => _isSaving = true);
    try {
      final updated = await ref
          .read(stockAuditRepositoryProvider)
          .countSku(widget.auditId, widget.item.skuId, {
            'counted_qty': _good!.length,
            'damaged_qty': _damaged!.length,
            'missing_qty': _missing!.length,
            'damaged_serials': _damaged!.toList(),
            'missing_serials': _missing!.toList(),
          });
      if (mounted) Navigator.pop(context, updated);
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
    final serialsAsync = ref.watch(
      auditSkuSerialsProvider((
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
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.checklist_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Select Serials',
                    style: AppTextStyles.headingMedium,
                  ),
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
                        'No serials found',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                      ),
                    );
                  }
                  _initSets(serials);
                  return Column(
                    children: [
                      // Summary chips
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        count: _missing!.length,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Good (${_good!.length})'),
                    Tab(text: 'Damaged (${_damaged!.length})'),
                    Tab(text: 'Missing (${_missing!.length})'),
                  ],
                ),
                const Divider(height: 1),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Good Tab
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: serials.length,
                        itemBuilder: (_, i) {
                          final s = serials[i];
                          final isGood = _good!.contains(s.serialNumber);
                          final blocked =
                              _damaged!.contains(s.serialNumber) ||
                              _missing!.contains(s.serialNumber);
                          return CheckboxListTile(
                            value: isGood,
                            activeColor: AppColors.success,
                            enabled: widget.canEdit && !blocked,
                            title: Text(
                              s.serialNumber,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isGood
                                    ? AppColors.success
                                    : blocked
                                    ? AppColors.textMuted
                                    : null,
                                fontWeight: isGood
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: blocked
                                ? Text(
                                    _damaged!.contains(s.serialNumber)
                                        ? 'Selected as Damaged'
                                        : 'Selected as Missing',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  )
                                : null,
                            onChanged: blocked
                                ? null
                                : (val) {
                                    setState(() {
                                      if (val == true)
                                        _good!.add(s.serialNumber);
                                      else
                                        _good!.remove(s.serialNumber);
                                    });
                                  },
                          );
                        },
                      ),
                      // Damaged Tab
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: serials.length,
                        itemBuilder: (_, i) {
                          final s = serials[i];
                          final isDamaged = _damaged!.contains(s.serialNumber);
                          final blocked =
                              _good!.contains(s.serialNumber) ||
                              _missing!.contains(s.serialNumber);
                          return CheckboxListTile(
                            value: isDamaged,
                            activeColor: AppColors.warning,
                            enabled: widget.canEdit && !blocked,
                            title: Text(
                              s.serialNumber,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _good!.contains(s.serialNumber)
                                    ? AppColors.success
                                    : isDamaged
                                    ? AppColors.warning
                                    : blocked
                                    ? AppColors.textMuted
                                    : null,
                                fontWeight:
                                    (_good!.contains(s.serialNumber) ||
                                        isDamaged)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: blocked
                                ? Text(
                                    _good!.contains(s.serialNumber)
                                        ? 'Selected as Good'
                                        : 'Selected as Missing',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  )
                                : null,
                            onChanged: blocked
                                ? null
                                : (val) {
                                    setState(() {
                                      if (val == true)
                                        _damaged!.add(s.serialNumber);
                                      else
                                        _damaged!.remove(s.serialNumber);
                                    });
                                  },
                          );
                        },
                      ),
                      // Missing Tab
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: serials.length,
                        itemBuilder: (_, i) {
                          final s = serials[i];
                          final isMissing = _missing!.contains(s.serialNumber);
                          final blocked =
                              _good!.contains(s.serialNumber) ||
                              _damaged!.contains(s.serialNumber);
                          return CheckboxListTile(
                            value: isMissing,
                            activeColor: AppColors.error,
                            enabled: widget.canEdit && !blocked,
                            title: Text(
                              s.serialNumber,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _good!.contains(s.serialNumber)
                                    ? AppColors.success
                                    : _damaged!.contains(s.serialNumber)
                                    ? AppColors.warning
                                    : isMissing
                                    ? AppColors.error
                                    : blocked
                                    ? AppColors.textMuted
                                    : null,
                                fontWeight:
                                    (_good!.contains(s.serialNumber) ||
                                        _damaged!.contains(s.serialNumber) ||
                                        isMissing)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: blocked
                                ? Text(
                                    _good!.contains(s.serialNumber)
                                        ? 'Selected as Good'
                                        : 'Selected as Damaged',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  )
                                : null,
                            onChanged: blocked
                                ? null
                                : (val) {
                                    setState(() {
                                      if (val == true)
                                        _missing!.add(s.serialNumber);
                                      else
                                        _missing!.remove(s.serialNumber);
                                    });
                                  },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.cardBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _confirm,
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
                  ),
                ),
                    ],
                  );
                },
              ),
            ),
          ],
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

// ── Shared: Read-only qty display ─────────────────────────────────────────────

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

// ── Shared Helpers ────────────────────────────────────────────────────────────

class _CountField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final Color? color;
  final void Function(String)? onChanged;
  final bool readOnly;

  const _CountField({
    required this.label,
    required this.ctrl,
    this.color,
    this.onChanged,
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
          onChanged: onChanged,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
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
