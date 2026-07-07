import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => dotenv.isInitialized
      ? (dotenv.env['BASE_URL'] ?? 'http://192.168.0.118:3000/node_app/mobile/v1')
      : 'http://192.168.0.118:3000/node_app/mobile/v1';

  // Auth
  static const String login = '/auth/login';
  static const String sendOtp = '/users/send_otp';
  static const String verifyOtp = '/users/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String nodes = '/auth/nodes';

  // Home / Dashboard
  static const String dashboard = '/dashboard/stats';
  static const String recentActivity = '/dashboard/activity';

  // Orders
  static const String orders = '/orders';
  static const String confirmedOrders = '/orders?status=confirmed';
  static String orderDetail(String id) => '/orders/$id';

  // Shipments
  static const String shipments = '/shipments';
  static String shippableLineItems(String nodeId, String orderId) =>
      '/shipments/shippable_line_items?node_id=$nodeId&order_id=$orderId';
  static String shipmentDetail(String id) => '/shipments/$id';
  static String updateAllocationType(String shipmentId) => '/shipments/$shipmentId/allocation_type';
  static String shipmentAllocate(String id) => '/shipments/$id/allocate';
  static String shipmentAutoAllocate(String id) => '/shipments/$id/auto-allocate';
  static String shipmentPack(String id) => '/shipments/$id/pack';
  static String shipmentInvoice(String id) => '/shipments/$id/invoice';
  static String shipmentDispatch(String id) => '/shipments/$id/dispatch';
  static String shipmentMarkDispatched(String id) => '/shipments/$id/mark_dispatched';
  static String shipmentDeliver(String id) => '/shipments/$id/deliver';
  static String shipmentReturnInitiate(String id) => '/shipments/$id/return/initiate';
  static String shipmentReturnComplete(String id) => '/shipments/$id/return/complete';
  static String batchAvailability(String nodeId, String skuId) =>
      '/allocations/batch_availability?node_id=$nodeId&product_sku_id=$skuId';
  static String untrackedAvailability(String nodeId, String skuId) =>
      '/allocations/untracked_availability?node_id=$nodeId&product_sku_id=$skuId';
  static String serialAvailability(String nodeId, String skuId) =>
      '/allocations/serial_availability?node_id=$nodeId&product_sku_id=$skuId';
  static String assignShipmentAllocations(String shipmentId) =>
      '/allocations/assign_shipment_allocations?shipment_id=$shipmentId';

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
