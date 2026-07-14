class DashboardStats {
  final int pendingShipments;
  final int pendingGRNs;
  final int lowStockAlerts;
  final int totalShipmentsToday;
  final int deliveredToday;
  final int pendingReturns;

  const DashboardStats({
    required this.pendingShipments,
    required this.pendingGRNs,
    required this.lowStockAlerts,
    required this.totalShipmentsToday,
    required this.deliveredToday,
    required this.pendingReturns,
  });

  static const DashboardStats dummy = DashboardStats(
    pendingShipments: 12,
    pendingGRNs: 5,
    lowStockAlerts: 3,
    totalShipmentsToday: 24,
    deliveredToday: 9,
    pendingReturns: 2,
  );
}

// -- Splash / Dashboard API models --------------------------------------------

class StockAudit {
  final int id;
  final String stockAuditNumber;
  final String auditType;
  final String scheduledDate;

  const StockAudit({
    required this.id,
    required this.stockAuditNumber,
    required this.auditType,
    required this.scheduledDate,
  });

  factory StockAudit.fromJson(Map<String, dynamic> json) => StockAudit(
        id: json['id'] ?? 0,
        stockAuditNumber: json['stock_audit_number'] ?? '',
        auditType: json['audit_type'] ?? '',
        scheduledDate: json['scheduled_date'] ?? '',
      );
}

class SplashData {
  final int nodeAdminId;
  final String nodeAdminName;
  final String nodeAdminEmail;
  final int nodeId;
  final String nodeName;
  final String nodeType;
  final int pendingForwardShipmentsCount;
  final int returnInitiatedShipmentsCount;
  final List<StockAudit> stockAudits;
  final Map<String, Map<String, bool>> permissions;

  const SplashData({
    required this.nodeAdminId,
    required this.nodeAdminName,
    required this.nodeAdminEmail,
    required this.nodeId,
    required this.nodeName,
    required this.nodeType,
    this.pendingForwardShipmentsCount = 0,
    this.returnInitiatedShipmentsCount = 0,
    this.stockAudits = const [],
    this.permissions = const {},
  });

  bool hasPermission(String feature, String action) {
    return permissions[feature]?[action] ?? false;
  }

  factory SplashData.fromJson(Map<String, dynamic> json) {
    final admin = json['node_admin'] as Map<String, dynamic>? ?? {};
    final node = admin['node'] as Map<String, dynamic>? ?? {};
    final audits = (json['stock_audits'] as List?)
            ?.map((e) => StockAudit.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
        
    final Map<String, Map<String, bool>> parsedPermissions = {};
    if (json['permissions'] is Map) {
      final perms = json['permissions'] as Map;
      for (final key in perms.keys) {
        if (perms[key] is Map) {
          final actions = perms[key] as Map;
          parsedPermissions[key.toString()] = actions.map((k, v) => MapEntry(k.toString(), v == true));
        }
      }
    }
        
    return SplashData(
      nodeAdminId: admin['id'] ?? 0,
      nodeAdminName: admin['name'] ?? '',
      nodeAdminEmail: admin['email'] ?? '',
      nodeId: node['id'] ?? 0,
      nodeName: node['name'] ?? '',
      nodeType: node['node_type'] ?? '',
      pendingForwardShipmentsCount:
          json['pending_forward_shipments_count'] ?? 0,
      returnInitiatedShipmentsCount:
          json['return_initiated_shipments_count'] ?? 0,
      stockAudits: audits,
      permissions: parsedPermissions,
    );
  }

  static SplashData get empty => const SplashData(
        nodeAdminId: 0,
        nodeAdminName: '',
        nodeAdminEmail: '',
        nodeId: 0,
        nodeName: '',
        nodeType: '',
      );
}

// -- Activity feed (static / placeholder) -------------------------------------

class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final String timeAgo;
  final ActivityType type;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.type,
  });
}

enum ActivityType { shipment, grn, return_, adjustment, audit }

const List<ActivityItem> dummyActivity = [
  ActivityItem(
    id: '1',
    title: 'SH-2024-089 Dispatched',
    subtitle: 'Delivered to Acme Corp - 3 items',
    timeAgo: '12 min ago',
    type: ActivityType.shipment,
  ),
  ActivityItem(
    id: '2',
    title: 'GRN-2024-045 Completed',
    subtitle: 'PO-1023 inwarded - 150 units',
    timeAgo: '1 hr ago',
    type: ActivityType.grn,
  ),
  ActivityItem(
    id: '3',
    title: 'Return SH-2024-071 Initiated',
    subtitle: 'TechMart - 2 good, 1 damaged',
    timeAgo: '3 hrs ago',
    type: ActivityType.return_,
  ),
  ActivityItem(
    id: '4',
    title: 'Inventory Adjustment',
    subtitle: 'Product SKU-441 adjusted +5 units',
    timeAgo: '5 hrs ago',
    type: ActivityType.adjustment,
  ),
  ActivityItem(
    id: '5',
    title: 'SH-2024-086 Created',
    subtitle: 'RetailHub - 4 items, allocation pending',
    timeAgo: '6 hrs ago',
    type: ActivityType.shipment,
  ),
];
