class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.nodeops.example.com/v1';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String nodes = '/auth/nodes';

  // Home / Dashboard
  static const String dashboard = '/dashboard/stats';
  static const String recentActivity = '/dashboard/activity';

  // Orders
  static const String confirmedOrders = '/orders?status=confirmed';
  static String orderDetail(String id) => '/orders/$id';

  // Shipments
  static const String shipments = '/shipments';
  static String shipmentDetail(String id) => '/shipments/$id';
  static String shipmentAllocate(String id) => '/shipments/$id/allocate';
  static String shipmentAutoAllocate(String id) => '/shipments/$id/auto-allocate';
  static String shipmentInvoice(String id) => '/shipments/$id/invoice';
  static String shipmentDispatch(String id) => '/shipments/$id/dispatch';
  static String shipmentDeliver(String id) => '/shipments/$id/deliver';
  static String shipmentReturnInitiate(String id) => '/shipments/$id/return/initiate';
  static String shipmentReturnComplete(String id) => '/shipments/$id/return/complete';

  // Inventory
  static String productStock(String productId, String nodeId) =>
      '/inventory/stock?product=$productId&node=$nodeId';

  // GRN
  static const String grn = '/grn';
  static String grnDetail(String id) => '/grn/$id';

  // Audit
  static const String audit = '/audit';

  // Returns
  static const String returns = '/returns';

  // Adjustment
  static const String adjustment = '/adjustment';
}
