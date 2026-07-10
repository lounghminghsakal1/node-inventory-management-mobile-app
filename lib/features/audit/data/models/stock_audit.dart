// ── Stock Audit Models ────────────────────────────────────────────────────────

enum StockAuditStatus {
  draft,
  assigned,
  initiatedAuditing,
  sentForReview,
  rejected,
  approved;

  static StockAuditStatus fromString(String s) {
    switch (s) {
      case 'draft':
        return StockAuditStatus.draft;
      case 'assigned':
        return StockAuditStatus.assigned;
      case 'initiated_auditing':
        return StockAuditStatus.initiatedAuditing;
      case 'sent_for_review':
        return StockAuditStatus.sentForReview;
      case 'rejected':
        return StockAuditStatus.rejected;
      case 'approved':
        return StockAuditStatus.approved;
      default:
        return StockAuditStatus.draft;
    }
  }

  String get label {
    switch (this) {
      case StockAuditStatus.draft:
        return 'Draft';
      case StockAuditStatus.assigned:
        return 'Assigned';
      case StockAuditStatus.initiatedAuditing:
        return 'In Progress';
      case StockAuditStatus.sentForReview:
        return 'Sent for Review';
      case StockAuditStatus.rejected:
        return 'Rejected';
      case StockAuditStatus.approved:
        return 'Approved';
    }
  }
}

class StockAuditDetail {
  final String id;
  final String stockAuditNumber;
  final String auditType;
  final StockAuditStatus status;
  final String scheduledDate;
  final String? initiatedAt;
  final String? notes;
  final String? rejectionReason;
  final int lineItemsCount;

  const StockAuditDetail({
    required this.id,
    required this.stockAuditNumber,
    required this.auditType,
    required this.status,
    required this.scheduledDate,
    this.initiatedAt,
    this.notes,
    this.rejectionReason,
    this.lineItemsCount = 0,
  });

  factory StockAuditDetail.fromJson(Map<String, dynamic> json) {
    return StockAuditDetail(
      id: json['id']?.toString() ?? '',
      stockAuditNumber: json['stock_audit_number']?.toString() ?? '',
      auditType: json['audit_type']?.toString() ?? '',
      status: StockAuditStatus.fromString(json['status']?.toString() ?? ''),
      scheduledDate: json['scheduled_date']?.toString() ?? '',
      initiatedAt: json['initiated_at']?.toString(),
      notes: json['notes']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      lineItemsCount: (json['line_items_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Returns true if the audit can be initiated (assigned + today's date).
  bool get canInitiate {
    if (status != StockAuditStatus.assigned) return false;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return scheduledDate == todayStr;
  }
}

// ── Line Item ─────────────────────────────────────────────────────────────────

class AuditLineItem {
  final String id;
  final String stockAuditId;
  final String skuId;
  final String skuName;
  final String skuCode;
  final String trackingType; // untracked | batch | serial
  final int systemQty;
  final int? countedQty;
  final int? damagedQty;
  final int? missingQty;
  final int? variance;
  final int? nodeAvailableQuantity;
  final int? nodeTotalQuantity;
  final String? notes;
  final Map<String, dynamic>? meta;

  const AuditLineItem({
    required this.id,
    required this.stockAuditId,
    required this.skuId,
    required this.skuName,
    required this.skuCode,
    required this.trackingType,
    required this.systemQty,
    this.countedQty,
    this.damagedQty,
    this.missingQty,
    this.variance,
    this.nodeAvailableQuantity,
    this.nodeTotalQuantity,
    this.notes,
    this.meta,
  });

  bool get isCounted => countedQty != null;

  factory AuditLineItem.fromJson(Map<String, dynamic> json) {
    return AuditLineItem(
      id: json['id']?.toString() ?? '',
      stockAuditId: json['stock_audit_id']?.toString() ?? '',
      skuId: json['product_sku_id']?.toString() ?? '',
      skuName: json['sku_name']?.toString() ?? '',
      skuCode: json['sku_code']?.toString() ?? '',
      trackingType: json['tracking_type']?.toString() ?? 'untracked',
      systemQty: (json['system_qty'] as num?)?.toInt() ?? 0,
      countedQty: (json['counted_qty'] as num?)?.toInt(),
      damagedQty: (json['damaged_qty'] as num?)?.toInt(),
      missingQty: (json['missing_qty'] as num?)?.toInt(),
      variance: (json['variance'] as num?)?.toInt(),
      nodeAvailableQuantity: (json['node_available_quantity'] as num?)?.toInt(),
      nodeTotalQuantity: (json['node_total_quantity'] as num?)?.toInt(),
      notes: json['notes']?.toString(),
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  AuditLineItem copyWith({
    int? countedQty,
    int? damagedQty,
    int? missingQty,
    int? variance,
    Map<String, dynamic>? meta,
  }) {
    return AuditLineItem(
      id: id,
      stockAuditId: stockAuditId,
      skuId: skuId,
      skuName: skuName,
      skuCode: skuCode,
      trackingType: trackingType,
      systemQty: systemQty,
      countedQty: countedQty ?? this.countedQty,
      damagedQty: damagedQty ?? this.damagedQty,
      missingQty: missingQty ?? this.missingQty,
      variance: variance ?? this.variance,
      nodeAvailableQuantity: nodeAvailableQuantity,
      nodeTotalQuantity: nodeTotalQuantity,
      notes: notes,
      meta: meta ?? this.meta,
    );
  }
}

// ── Batch ─────────────────────────────────────────────────────────────────────

class AuditBatch {
  final String id;
  final String batchCode;
  final String? manufacturingDate;
  final String? expiryDate;
  final int systemQty;

  const AuditBatch({
    required this.id,
    required this.batchCode,
    this.manufacturingDate,
    this.expiryDate,
    required this.systemQty,
  });

  factory AuditBatch.fromJson(Map<String, dynamic> json) {
    return AuditBatch(
      id: json['id']?.toString() ?? '',
      batchCode: json['batch_code']?.toString() ?? '',
      manufacturingDate: json['manufacturing_date']?.toString(),
      expiryDate: json['expiry_date']?.toString(),
      systemQty: (json['system_qty'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Serial ────────────────────────────────────────────────────────────────────

class AuditSerial {
  final String id;
  final String serialNumber;
  final String status; // available | damaged

  const AuditSerial({
    required this.id,
    required this.serialNumber,
    required this.status,
  });

  factory AuditSerial.fromJson(Map<String, dynamic> json) {
    return AuditSerial(
      id: json['id']?.toString() ?? '',
      serialNumber: json['serial_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'available',
    );
  }
}
