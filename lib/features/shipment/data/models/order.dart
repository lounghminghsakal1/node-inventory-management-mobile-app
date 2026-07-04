// ── Tracking Type ─────────────────────────────────────────────────────────────
enum TrackingType { batch, serial, untracked }

extension TrackingTypeX on TrackingType {
  String get label {
    switch (this) {
      case TrackingType.batch:
        return 'Batch';
      case TrackingType.serial:
        return 'Serial';
      case TrackingType.untracked:
        return 'Untracked';
    }
  }
}

// ── Product ───────────────────────────────────────────────────────────────────
class Product {
  final String id;
  final String name;
  final String sku;
  final TrackingType trackingType;
  final int nodeStock;
  final String unit;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.trackingType,
    required this.nodeStock,
    this.unit = 'pcs',
  });
}

// ── Dummy products ────────────────────────────────────────────────────────────
const List<Product> dummyProducts = [
  Product(
    id: 'prod_a',
    name: 'Premium Wireless Headphones',
    sku: 'SKU-A001',
    trackingType: TrackingType.batch,
    nodeStock: 40,
  ),
  Product(
    id: 'prod_b',
    name: 'Smart Watch Series 5',
    sku: 'SKU-B002',
    trackingType: TrackingType.serial,
    nodeStock: 85,
  ),
  Product(
    id: 'prod_c',
    name: 'USB-C Hub 7-in-1',
    sku: 'SKU-C003',
    trackingType: TrackingType.untracked,
    nodeStock: 30,
  ),
  Product(
    id: 'prod_d',
    name: 'Mechanical Keyboard RGB',
    sku: 'SKU-D004',
    trackingType: TrackingType.batch,
    nodeStock: 15,
  ),
  Product(
    id: 'prod_e',
    name: 'Laptop Stand Aluminium',
    sku: 'SKU-E005',
    trackingType: TrackingType.untracked,
    nodeStock: 100,
  ),
  Product(
    id: 'prod_ply_1',
    name: 'Commercial Plywood MR Grade 6mm 8x4',
    sku: '10010010000100000',
    trackingType: TrackingType.batch,
    nodeStock: 150,
  ),
  Product(
    id: 'prod_ply_2',
    name: 'Commercial Plywood BWR Grade 6mm 8x4',
    sku: '10010010001100000',
    trackingType: TrackingType.serial,
    nodeStock: 200,
  ),
  Product(
    id: 'prod_ply_3',
    name: 'Commercial Plywood BWR Grade 9mm 7x4',
    sku: '10010010001100001',
    trackingType: TrackingType.batch,
    nodeStock: 50,
  ),
];

// ── Order Line Item ───────────────────────────────────────────────────────────
class OrderLineItem {
  final String id;
  final Product product;
  final int orderedQty;

  const OrderLineItem({
    required this.id,
    required this.product,
    required this.orderedQty,
  });
}

// ── Order (confirmed, no shipment yet) ───────────────────────────────────────
class Order {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerId;
  final DateTime orderDate;
  final List<OrderLineItem> lineItems;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerId,
    required this.orderDate,
    required this.lineItems,
  });

  int get totalItems => lineItems.length;
  int get totalQty => lineItems.fold(0, (s, i) => s + i.orderedQty);
}

// ── Dummy orders ──────────────────────────────────────────────────────────────
final List<Order> dummyOrders = [
  Order(
    id: '263',
    orderNumber: 'EFP-O-10263',
    customerName: 'SaiFlaerhomes',
    customerId: 'cust_9',
    orderDate: DateTime.now().subtract(const Duration(hours: 1)),
    lineItems: [
      OrderLineItem(id: 'li_263_1', product: dummyProducts[5], orderedQty: 20),
      OrderLineItem(id: 'li_263_2', product: dummyProducts[6], orderedQty: 30),
      OrderLineItem(id: 'li_263_3', product: dummyProducts[7], orderedQty: 1),
    ],
  ),
  Order(
    id: '262',
    orderNumber: 'EFP-O-10262',
    customerName: 'SaiFlaerhomes',
    customerId: 'cust_9',
    orderDate: DateTime.now().subtract(const Duration(hours: 2)),
    lineItems: [
      OrderLineItem(id: 'li_262_1', product: dummyProducts[5], orderedQty: 15),
      OrderLineItem(id: 'li_262_2', product: dummyProducts[6], orderedQty: 25),
    ],
  ),
  Order(
    id: '261',
    orderNumber: 'EFP-O-10261',
    customerName: 'SaiFlaerhomes',
    customerId: 'cust_9',
    orderDate: DateTime.now().subtract(const Duration(hours: 3)),
    lineItems: [
      OrderLineItem(id: 'li_261_1', product: dummyProducts[5], orderedQty: 10),
      OrderLineItem(id: 'li_261_2', product: dummyProducts[7], orderedQty: 5),
    ],
  ),
  Order(
    id: '260',
    orderNumber: 'EFP-O-10260',
    customerName: 'Dinesh',
    customerId: 'cust_3',
    orderDate: DateTime.now().subtract(const Duration(hours: 4)),
    lineItems: [
      OrderLineItem(id: 'li_260_1', product: dummyProducts[5], orderedQty: 12),
    ],
  ),
  Order(
    id: '258',
    orderNumber: 'EFP-O-10258',
    customerName: 'Dinesh',
    customerId: 'cust_3',
    orderDate: DateTime.now().subtract(const Duration(hours: 5)),
    lineItems: [
      OrderLineItem(id: 'li_258_1', product: dummyProducts[6], orderedQty: 18),
    ],
  ),
  Order(
    id: 'ord_201',
    orderNumber: 'ORD-2024-201',
    customerName: 'Acme Corporation',
    customerId: 'cust_01',
    orderDate: DateTime.now().subtract(const Duration(hours: 6)),
    lineItems: [
      OrderLineItem(id: 'li_1', product: dummyProducts[0], orderedQty: 10),
      OrderLineItem(id: 'li_2', product: dummyProducts[1], orderedQty: 20),
      OrderLineItem(id: 'li_3', product: dummyProducts[2], orderedQty: 10),
    ],
  ),
  Order(
    id: 'ord_202',
    orderNumber: 'ORD-2024-202',
    customerName: 'TechMart India',
    customerId: 'cust_02',
    orderDate: DateTime.now().subtract(const Duration(hours: 7)),
    lineItems: [
      OrderLineItem(id: 'li_4', product: dummyProducts[3], orderedQty: 10),
      OrderLineItem(id: 'li_5', product: dummyProducts[4], orderedQty: 40),
    ],
  ),
  Order(
    id: 'ord_203',
    orderNumber: 'ORD-2024-203',
    customerName: 'RetailHub Pvt Ltd',
    customerId: 'cust_03',
    orderDate: DateTime.now().subtract(const Duration(hours: 8)),
    lineItems: [
      OrderLineItem(id: 'li_6', product: dummyProducts[0], orderedQty: 5),
      OrderLineItem(id: 'li_7', product: dummyProducts[2], orderedQty: 15),
    ],
  ),
];
