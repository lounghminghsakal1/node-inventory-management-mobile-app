import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/order_model.dart';

// ── Dummy order list ──────────────────────────────────────────────────────────
const List<Map<String, dynamic>> _dummyOrderList = [
  {
    'id': 263, 'order_number': 'EFP-O-10263', 'status': 'partially_delivered',
    'confirmed_at': '2026-07-03T16:55:54.595+05:30',
    'customer': {'id': 9, 'name': 'SaiFlaerhomes', 'code': 'EXCUS10009'},
    'shipments': [
      {'id': 390, 'shipment_number': 'EFP-S-10390', 'status': 'delivered'},
      {'id': 391, 'shipment_number': 'EFP-S-10391', 'status': 'return_initiated'},
    ],
  },
  {
    'id': 262, 'order_number': 'EFP-O-10262', 'status': 'confirmed',
    'confirmed_at': '2026-07-03T16:48:17.370+05:30',
    'customer': {'id': 9, 'name': 'SaiFlaerhomes', 'code': 'EXCUS10009'},
    'shipments': [
      {'id': 389, 'shipment_number': 'EFP-S-10389', 'status': 'created'},
    ],
  },
  {
    'id': 261, 'order_number': 'EFP-O-10261', 'status': 'confirmed',
    'confirmed_at': '2026-07-03T16:37:12.111+05:30',
    'customer': {'id': 9, 'name': 'SaiFlaerhomes', 'code': 'EXCUS10009'},
    'shipments': [],
  },
  {
    'id': 260, 'order_number': 'EFP-O-10260', 'status': 'confirmed',
    'confirmed_at': '2026-06-29T13:13:36.494+05:30',
    'customer': {'id': 3, 'name': 'Dinesh', 'code': 'EXCUS10003'},
    'shipments': [],
  },
  {
    'id': 259, 'order_number': 'EFP-O-10259', 'status': 'confirmed',
    'confirmed_at': '2026-06-29T13:11:09.358+05:30',
    'customer': {'id': 3, 'name': 'Dinesh', 'code': 'EXCUS10003'},
    'shipments': [],
  },
  {
    'id': 258, 'order_number': 'EFP-O-10258', 'status': 'confirmed',
    'confirmed_at': '2026-06-29T13:09:59.068+05:30',
    'customer': {'id': 3, 'name': 'Dinesh', 'code': 'EXCUS10003'},
    'shipments': [
      {'id': 388, 'shipment_number': 'EFP-S-10388', 'status': 'created'},
    ],
  },
  {
    'id': 257, 'order_number': 'EFP-O-10257', 'status': 'confirmed',
    'confirmed_at': '2026-06-29T12:55:35.569+05:30',
    'customer': {'id': 3, 'name': 'Dinesh', 'code': 'EXCUS10003'},
    'shipments': [],
  },
  {
    'id': 256, 'order_number': 'EFP-O-10256', 'status': 'confirmed',
    'confirmed_at': '2026-06-29T12:29:42.460+05:30',
    'customer': {'id': 3, 'name': 'Dinesh', 'code': 'EXCUS10003'},
    'shipments': [],
  },
  {
    'id': 255, 'order_number': 'EFP-O-10255', 'status': 'confirmed',
    'confirmed_at': '2026-06-29T12:16:26.936+05:30',
    'customer': {'id': 3, 'name': 'Dinesh', 'code': 'EXCUS10003'},
    'shipments': [],
  },
  {
    'id': 254, 'order_number': 'EFP-O-10254', 'status': 'confirmed',
    'confirmed_at': '2026-06-29T12:11:24.387+05:30',
    'customer': {'id': 3, 'name': 'Dinesh', 'code': 'EXCUS10003'},
    'shipments': [],
  },
  {
    'id': 253, 'order_number': 'EFP-O-10253', 'status': 'confirmed',
    'confirmed_at': '2026-06-29T12:08:48.115+05:30',
    'customer': {'id': 3, 'name': 'Dinesh', 'code': 'EXCUS10003'},
    'shipments': [],
  },
  {
    'id': 252, 'order_number': 'EFP-O-10252', 'status': 'confirmed',
    'confirmed_at': '2026-06-29T12:06:55.424+05:30',
    'customer': {'id': 3, 'name': 'Dinesh', 'code': 'EXCUS10003'},
    'shipments': [],
  },
  {
    'id': 251, 'order_number': 'EFP-O-10251', 'status': 'confirmed',
    'confirmed_at': '2026-06-29T11:32:32.298+05:30',
    'customer': {'id': 7, 'name': 'Prince Godwin I', 'code': 'EXCUS10007'},
    'shipments': [],
  },
  {
    'id': 250, 'order_number': 'EFP-O-10250', 'status': 'partially_delivered',
    'confirmed_at': '2026-06-26T16:35:06.248+05:30',
    'customer': {'id': 7, 'name': 'Prince Godwin I', 'code': 'EXCUS10007'},
    'shipments': [
      {'id': 385, 'shipment_number': 'EFP-S-10385', 'status': 'return_completed'},
      {'id': 386, 'shipment_number': 'EFP-S-10386', 'status': 'delivered'},
      {'id': 384, 'shipment_number': 'EFP-S-10384', 'status': 'delivered'},
      {'id': 387, 'shipment_number': 'EFP-S-10387', 'status': 'return_completed'},
    ],
  },
  {
    'id': 249, 'order_number': 'EFP-O-10249', 'status': 'partially_delivered',
    'confirmed_at': '2026-06-26T13:09:57.315+05:30',
    'customer': {'id': 7, 'name': 'Prince Godwin I', 'code': 'EXCUS10007'},
    'shipments': [
      {'id': 383, 'shipment_number': 'EFP-S-10383', 'status': 'return_completed'},
      {'id': 381, 'shipment_number': 'EFP-S-10381', 'status': 'cancelled'},
      {'id': 371, 'shipment_number': 'EFP-S-10371', 'status': 'delivered'},
      {'id': 372, 'shipment_number': 'EFP-S-10372', 'status': 'return_completed'},
      {'id': 373, 'shipment_number': 'EFP-S-10373', 'status': 'delivered'},
      {'id': 375, 'shipment_number': 'EFP-S-10375', 'status': 'delivered'},
      {'id': 374, 'shipment_number': 'EFP-S-10374', 'status': 'return_completed'},
      {'id': 376, 'shipment_number': 'EFP-S-10376', 'status': 'return_completed'},
      {'id': 377, 'shipment_number': 'EFP-S-10377', 'status': 'delivered'},
      {'id': 380, 'shipment_number': 'EFP-S-10380', 'status': 'cancelled'},
      {'id': 378, 'shipment_number': 'EFP-S-10378', 'status': 'cancelled'},
      {'id': 379, 'shipment_number': 'EFP-S-10379', 'status': 'return_completed'},
      {'id': 382, 'shipment_number': 'EFP-S-10382', 'status': 'delivered'},
    ],
  },
  {
    'id': 248, 'order_number': 'EFP-O-10248', 'status': 'confirmed',
    'confirmed_at': '2026-06-25T18:29:25.878+05:30',
    'customer': {'id': 3, 'name': 'Dinesh', 'code': 'EXCUS10003'},
    'shipments': [],
  },
  {
    'id': 247, 'order_number': 'EFP-O-10247', 'status': 'confirmed',
    'confirmed_at': '2026-06-25T16:41:13.746+05:30',
    'customer': {'id': 3, 'name': 'Dinesh', 'code': 'EXCUS10003'},
    'shipments': [],
  },
  {
    'id': 246, 'order_number': 'EFP-O-10246', 'status': 'confirmed',
    'confirmed_at': '2026-06-25T14:12:05.029+05:30',
    'customer': {'id': 13, 'name': 'Leo', 'code': 'EXCUS10013'},
    'shipments': [],
  },
  {
    'id': 245, 'order_number': 'EFP-O-10245', 'status': 'confirmed',
    'confirmed_at': '2026-06-25T14:08:01.585+05:30',
    'customer': {'id': 13, 'name': 'Leo', 'code': 'EXCUS10013'},
    'shipments': [],
  },
  {
    'id': 244, 'order_number': 'EFP-O-10244', 'status': 'confirmed',
    'confirmed_at': '2026-06-25T14:07:19.415+05:30',
    'customer': {'id': 13, 'name': 'Leo', 'code': 'EXCUS10013'},
    'shipments': [],
  },
];

// ── Dummy line items (shared for all orders in demo) ─────────────────────────
const List<Map<String, dynamic>> _dummyLineItems = [
  {
    'id': 503, 'quantity': 20,
    'product_sku': {
      'id': 1,
      'sku_name': 'Commercial Plywood MR Grade - 6mm 8x4',
      'display_name': 'Commercial Plywood MR Grade 6mm 8x4',
      'sku_code': '10010010000100000',
    },
  },
  {
    'id': 504, 'quantity': 30,
    'product_sku': {
      'id': 6,
      'sku_name': 'Commercial Plywood BWR Grade - 6mm 8x4',
      'display_name': 'Commercial Plywood BWR Grade 6mm 8x4',
      'sku_code': '10010010001100000',
    },
  },
  {
    'id': 505, 'quantity': 1,
    'product_sku': {
      'id': 7,
      'sku_name': 'Commercial Plywood BWR Grade - 9mm 7x4',
      'display_name': 'Commercial Plywood BWR Grade 9mm 7x4',
      'sku_code': '10010010001100001',
    },
  },
];

// ── Providers ─────────────────────────────────────────────────────────────────
final orderListProvider = FutureProvider<List<OrderSummary>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return _dummyOrderList
      .map((j) => OrderSummary.fromJson(j))
      .toList();
});

/// Returns detail for the given order ID.
/// Uses correct header data from the list and shared dummy fields for the rest.
final orderDetailProvider =
    FutureProvider.family<OrderDetail, int>((ref, id) async {
  await Future.delayed(const Duration(milliseconds: 300));

  final orders = await ref.read(orderListProvider.future);
  final summary = orders.firstWhere(
    (o) => o.id == id,
    orElse: () => orders.first,
  );

  final lineItems = _dummyLineItems
      .map((j) => OrderLineItem.fromJson(j))
      .toList();

  return OrderDetail(
    id: summary.id,
    orderNumber: summary.orderNumber,
    status: summary.status,
    confirmedAt: summary.confirmedAt,
    placedAt: summary.confirmedAt,
    customer: summary.customer,
    shipments: summary.shipments,
    orderLineItems: lineItems,
    shippingAddress: 'amma boys hostel, narsinhi, 500032',
    billingAddress: 'amma boys hostel, narsinhi, 500032',
    deliveryPartnerFee: '0.0',
    labourFee: '0.0',
    deliveryType: null,
    cart: const OrderCart(id: 397, cartNumber: 'EFP-C-10397'),
    deliveryInfo: const DeliveryInfo(handleWithCare: false),
    delivererDetails: const DelivererDetails(
      driverName: '',
      vehicleNumber: '',
      driverMobileNumber: '',
    ),
    infoForLabour: const InfoForLabour(
      floorNumber: 0,
      permittedByOwner: false,
      groundFloorIncluded: false,
    ),
    cancellationReason: null,
  );
});
