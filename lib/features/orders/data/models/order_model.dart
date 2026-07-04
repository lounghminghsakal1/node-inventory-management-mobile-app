// ── Shared sub-models ─────────────────────────────────────────────────────────
class OrderCustomer {
  final int id;
  final String name;
  final String code;

  const OrderCustomer({
    required this.id,
    required this.name,
    required this.code,
  });

  factory OrderCustomer.fromJson(Map<String, dynamic> j) => OrderCustomer(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        code: j['code'] as String? ?? '',
      );
}

class OrderShipmentRef {
  final int id;
  final String shipmentNumber;
  final String status;

  const OrderShipmentRef({
    required this.id,
    required this.shipmentNumber,
    required this.status,
  });

  factory OrderShipmentRef.fromJson(Map<String, dynamic> j) => OrderShipmentRef(
        id: (j['id'] as num).toInt(),
        shipmentNumber: j['shipment_number'] as String? ?? '',
        status: j['status'] as String? ?? '',
      );
}

// ── Order list summary ────────────────────────────────────────────────────────
class OrderSummary {
  final int id;
  final String orderNumber;
  final String status;
  final String confirmedAt;
  final OrderCustomer customer;
  final List<OrderShipmentRef> shipments;

  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.confirmedAt,
    required this.customer,
    required this.shipments,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
        id: (j['id'] as num).toInt(),
        orderNumber: j['order_number'] as String? ?? '',
        status: j['status'] as String? ?? '',
        confirmedAt: j['confirmed_at'] as String? ?? '',
        customer:
            OrderCustomer.fromJson(j['customer'] as Map<String, dynamic>),
        shipments: (j['shipments'] as List<dynamic>? ?? [])
            .map((s) =>
                OrderShipmentRef.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

// ── Order detail models ───────────────────────────────────────────────────────
class ProductSku {
  final int id;
  final String skuName;
  final String displayName;
  final String skuCode;

  const ProductSku({
    required this.id,
    required this.skuName,
    required this.displayName,
    required this.skuCode,
  });

  factory ProductSku.fromJson(Map<String, dynamic> j) => ProductSku(
        id: (j['id'] as num).toInt(),
        skuName: j['sku_name'] as String? ?? '',
        displayName: j['display_name'] as String? ?? '',
        skuCode: j['sku_code'] as String? ?? '',
      );
}

class OrderLineItem {
  final int id;
  final int quantity;
  final ProductSku productSku;

  const OrderLineItem({
    required this.id,
    required this.quantity,
    required this.productSku,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> j) => OrderLineItem(
        id: (j['id'] as num).toInt(),
        quantity: (j['quantity'] as num).toInt(),
        productSku:
            ProductSku.fromJson(j['product_sku'] as Map<String, dynamic>),
      );
}

class DeliveryInfo {
  final bool handleWithCare;

  const DeliveryInfo({required this.handleWithCare});

  factory DeliveryInfo.fromJson(Map<String, dynamic> j) =>
      DeliveryInfo(handleWithCare: j['handle_with_care'] as bool? ?? false);
}

class DelivererDetails {
  final String driverName;
  final String vehicleNumber;
  final String driverMobileNumber;

  const DelivererDetails({
    required this.driverName,
    required this.vehicleNumber,
    required this.driverMobileNumber,
  });

  bool get isEmpty =>
      driverName.isEmpty &&
      vehicleNumber.isEmpty &&
      driverMobileNumber.isEmpty;

  factory DelivererDetails.fromJson(Map<String, dynamic> j) => DelivererDetails(
        driverName: j['driver_name'] as String? ?? '',
        vehicleNumber: j['vehicle_number'] as String? ?? '',
        driverMobileNumber: j['driver_mobile_number'] as String? ?? '',
      );
}

class InfoForLabour {
  final int floorNumber;
  final bool permittedByOwner;
  final bool groundFloorIncluded;

  const InfoForLabour({
    required this.floorNumber,
    required this.permittedByOwner,
    required this.groundFloorIncluded,
  });

  factory InfoForLabour.fromJson(Map<String, dynamic> j) => InfoForLabour(
        floorNumber: (j['floor_number'] as num?)?.toInt() ?? 0,
        permittedByOwner: j['permitted_by_owner'] as bool? ?? false,
        groundFloorIncluded: j['ground_floor_included'] as bool? ?? false,
      );
}

class OrderCart {
  final int id;
  final String cartNumber;

  const OrderCart({required this.id, required this.cartNumber});

  factory OrderCart.fromJson(Map<String, dynamic> j) => OrderCart(
        id: (j['id'] as num).toInt(),
        cartNumber: j['cart_number'] as String? ?? '',
      );
}

// ── Full order detail ─────────────────────────────────────────────────────────
class OrderDetail {
  final int id;
  final String orderNumber;
  final String status;
  final String confirmedAt;
  final String placedAt;
  final OrderCustomer customer;
  final List<OrderShipmentRef> shipments;
  final List<OrderLineItem> orderLineItems;
  final String shippingAddress;
  final String billingAddress;
  final String deliveryPartnerFee;
  final String labourFee;
  final String? deliveryType;
  final OrderCart cart;
  final DeliveryInfo deliveryInfo;
  final DelivererDetails delivererDetails;
  final InfoForLabour infoForLabour;
  final String? cancellationReason;

  const OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.confirmedAt,
    required this.placedAt,
    required this.customer,
    required this.shipments,
    required this.orderLineItems,
    required this.shippingAddress,
    required this.billingAddress,
    required this.deliveryPartnerFee,
    required this.labourFee,
    this.deliveryType,
    required this.cart,
    required this.deliveryInfo,
    required this.delivererDetails,
    required this.infoForLabour,
    this.cancellationReason,
  });
}
