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
    subtitle: 'Delivered to Acme Corp — 3 items',
    timeAgo: '12 min ago',
    type: ActivityType.shipment,
  ),
  ActivityItem(
    id: '2',
    title: 'GRN-2024-045 Completed',
    subtitle: 'PO-1023 inwarded — 150 units',
    timeAgo: '1 hr ago',
    type: ActivityType.grn,
  ),
  ActivityItem(
    id: '3',
    title: 'Return SH-2024-071 Initiated',
    subtitle: 'TechMart — 2 good, 1 damaged',
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
    subtitle: 'RetailHub — 4 items, allocation pending',
    timeAgo: '6 hrs ago',
    type: ActivityType.shipment,
  ),
];
