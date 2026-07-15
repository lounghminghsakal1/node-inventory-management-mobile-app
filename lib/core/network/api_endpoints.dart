import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => dotenv.isInitialized
      ? (dotenv.env['BASE_URL'] ?? 'http://192.168.0.118:3000/node_app/mobile/v1')
      : 'http://192.168.0.118:3000/node_app/mobile/v1';

  // Auth
  static const String login = '/login';
  static const String sendOtp = '/users/send_otp';
  static const String verifyOtp = '/users/login';
  static const String logout = '/logout';
  static const String refreshToken = '/auth/refresh';
  static const String myNodes = '/my_nodes';
  static const String splashScreen = '/splash_screen';

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
  static String shipmentAllocate(String id) => '/shipments/$id/allocate';
  static String shipmentAutoAllocate(String id) => '/shipments/$id/auto-allocate';
  static String shipmentPack(String id) => '/shipments/$id/pack';
  static String shipmentInvoice(String id) => '/shipments/$id/invoice';
  static String shipmentDispatch(String id) => '/shipments/$id/dispatch';
  static String shipmentMarkDispatched(String id) => '/shipments/$id/mark_dispatched';
  static String shipmentDeliver(String id) => '/shipments/$id/deliver';
  static String shipmentReturnInitiate(String id) => '/shipments/$id/return/initiate';
  static String returnRemaining(String id) => '/shipments/$id/return_remaining';
  static String assignReturnItems(String id) => '/shipments/$id/assign_return_items';
  static String returnComplete(String id) => '/shipments/$id/return_complete';
  static String shipmentUploadMedia(String id) => '/shipments/$id/upload_media';
  // Backward compatible aliases
  static String returnAllocationInfo(String id) => '/shipments/$id/return_remaining';
  static String completeReturn(String id) => '/shipments/$id/return_complete';
  static String lineItemsAvailability(String shipmentId) =>
      '/shipments/$shipmentId/line_items_availability';
  static String batchAvailability(String shipmentId, String skuId) =>
      '/shipments/$shipmentId/batch_availability?sku_id=$skuId';
  static String untrackedAvailability(String shipmentId, String skuId) =>
      '/shipments/$shipmentId/untracked_availability?sku_id=$skuId';
  static String serialAvailability(String shipmentId, String skuId) =>
      '/shipments/$shipmentId/serial_availability?sku_id=$skuId';
  static String assignShipmentAllocations(String shipmentId) =>
      '/shipments/$shipmentId/assign_allocations';

  // Inventory
  static String productStock(String productId, String nodeId) =>
      '/inventory/stock?product=$productId&node=$nodeId';
  static const String batchInventories = '/batch_inventories';
  static String batchInventoryDetail(String id) => '/batch_inventories/$id';
  static String batchInventoryTransactions(String id) => '/batch_inventories/$id/transactions';
  static const String skuItems = '/sku_items';
  static String skuItemDetail(String id) => '/sku_items/$id';
  static const String nodeInventories = '/node_inventories';
  static String nodeInventoryDetail(String id) => '/node_inventories/$id';
  static String nodeInventoryTransactions(String id) => '/node_inventories/$id/transactions';
  static const String nodeInventoryLedger = '/node_inventories/ledger';

  // Purchase Orders
  static const String purchaseOrders = '/purchase_orders';
  static String purchaseOrderDetail(String id) => '/purchase_orders/$id';

  // GRN
  static const String grn = '/goods_received_notes';
  static const String goodsReceivedNotes = '/goods_received_notes';
  static String grnDetail(String id) => '/goods_received_notes/$id';
  static const String createGrn = '/goods_received_notes/create_grn';
  static const String uploadGrnDocument = '/goods_received_notes/upload_document';
  static String poReceivingSummary(String poId, [String? grnId]) =>
      '/goods_received_notes/po_receiving_summary?po_id=$poId${grnId != null ? '&grn_id=$grnId' : ''}';
  static String verifySerial(String serialNumber, String skuId) =>
      '/goods_received_notes/verify_serial?serial_number=$serialNumber&product_sku_id=$skuId';
  static String saveGrnLineItems(String grnId) =>
      '/goods_received_notes/$grnId/grn_line_items';
  static String initiateQc(String grnId) =>
      '/goods_received_notes/$grnId/initiate_qc';
  static String saveQcLineItems(String grnId) =>
      '/goods_received_notes/$grnId/qc_line_items';
  static String deleteGrnLineItem(String grnId, String lineItemId) =>
      '/goods_received_notes/$grnId/delete_line_item?grn_line_item_id=$lineItemId';


  // Stock Audits
  static const String stockAudits = '/stock_audits';
  static String stockAuditDetail(String id) => '/stock_audits/$id';
  static String initiateStockAudit(String id) => '/stock_audits/$id/initiate';
  static String stockAuditLineItems(String id) => '/stock_audits/$id/line_items';
  static String stockAuditSkuBatches(String auditId, String skuId) => '/stock_audits/$auditId/skus/$skuId/sku_batches';
  static String stockAuditSkuSerials(String auditId, String skuId) => '/stock_audits/$auditId/skus/$skuId/sku_serials';
  static String stockAuditCountSku(String auditId, String skuId) => '/stock_audits/$auditId/skus/$skuId/count_sku';
  static String sendStockAuditForReview(String id) => '/stock_audits/$id/send_for_review';

  // Returns
  static const String returns = '/returns';

  // Adjustment
  static const String adjustment = '/adjustment';
}
