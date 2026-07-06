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
        id: int.tryParse(j['id'].toString()) ?? 0,
        name: j['name'] as String? ?? '',
        code: j['code'] as String? ?? '',
      );
}

class OrderShipmentRef {
  final int id;
  final String shipmentNumber;
  final String status;
  final String? shipmentType;

  const OrderShipmentRef({
    required this.id,
    required this.shipmentNumber,
    required this.status,
    this.shipmentType,
  });

  factory OrderShipmentRef.fromJson(Map<String, dynamic> j) => OrderShipmentRef(
        id: int.tryParse(j['id'].toString()) ?? 0,
        shipmentNumber: j['shipment_number'] as String? ?? '',
        status: j['status'] as String? ?? '',
        shipmentType: j['shipment_type'] as String?,
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
        id: int.tryParse(j['id'].toString()) ?? 0,
        orderNumber: j['order_number'] as String? ?? '',
        status: j['status'] as String? ?? '',
        confirmedAt: j['confirmed_at'] as String? ?? '',
        customer: j['customer'] is Map<String, dynamic>
            ? OrderCustomer.fromJson(j['customer'] as Map<String, dynamic>)
            : const OrderCustomer(id: 0, name: 'Unknown', code: ''),
        shipments: (j['shipments'] as List<dynamic>? ?? [])
            .map((s) =>
                OrderShipmentRef.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

// ── Pagination Meta & Paginated Orders ────────────────────────────────────────
class OrderMeta {
  final int currentPage;
  final int totalPages;
  final int totalDataCount;

  const OrderMeta({
    required this.currentPage,
    required this.totalPages,
    required this.totalDataCount,
  });

  factory OrderMeta.fromJson(Map<String, dynamic> j) => OrderMeta(
        currentPage: (j['current_page'] as num?)?.toInt() ?? 1,
        totalPages: (j['total_pages'] as num?)?.toInt() ?? 1,
        totalDataCount: (j['total_data_count'] as num?)?.toInt() ?? 0,
      );
}

class PaginatedOrders {
  final List<OrderSummary> orders;
  final OrderMeta meta;

  const PaginatedOrders({
    required this.orders,
    required this.meta,
  });

  factory PaginatedOrders.fromJson(Map<String, dynamic> j) {
    final dataList = j['data'] as List<dynamic>? ?? [];
    final orders = dataList
        .map((o) => OrderSummary.fromJson(o as Map<String, dynamic>))
        .toList();
    final metaMap = j['meta'] is Map<String, dynamic>
        ? j['meta'] as Map<String, dynamic>
        : <String, dynamic>{};
    return PaginatedOrders(
      orders: orders,
      meta: OrderMeta.fromJson(metaMap),
    );
  }
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
  final String? lineItemType;

  const OrderLineItem({
    required this.id,
    required this.quantity,
    required this.productSku,
    this.lineItemType,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> j) => OrderLineItem(
        id: int.tryParse(j['id'].toString()) ?? 0,
        quantity: int.tryParse(j['quantity'].toString()) ?? 0,
        productSku: j['product_sku'] is Map<String, dynamic>
            ? ProductSku.fromJson(j['product_sku'] as Map<String, dynamic>)
            : const ProductSku(id: 0, skuName: '', displayName: '', skuCode: ''),
        lineItemType: j['line_item_type'] as String?,
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

// ── Full order detail ─────────────────────────────────────────────────────────
class OrderDetail {
  final int id;
  final String orderNumber;
  final String status;
  final String? sourceType;
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
  final DeliveryInfo deliveryInfo;
  final DelivererDetails delivererDetails;
  final InfoForLabour infoForLabour;
  final String? cancellationReason;

  const OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.sourceType,
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
    required this.deliveryInfo,
    required this.delivererDetails,
    required this.infoForLabour,
    this.cancellationReason,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> j) {
    return OrderDetail(
      id: int.tryParse(j['id'].toString()) ?? 0,
      orderNumber: j['order_number'] as String? ?? '',
      status: j['status'] as String? ?? '',
      sourceType: j['source_type'] as String?,
      confirmedAt: j['confirmed_at'] as String? ?? '',
      placedAt: j['placed_at'] as String? ?? j['confirmed_at'] as String? ?? '',
      customer: j['customer'] is Map<String, dynamic>
          ? OrderCustomer.fromJson(j['customer'] as Map<String, dynamic>)
          : const OrderCustomer(id: 0, name: 'Unknown', code: ''),
      shipments: (j['shipments'] as List<dynamic>? ?? [])
          .map((s) => OrderShipmentRef.fromJson(s as Map<String, dynamic>))
          .toList(),
      orderLineItems: (j['order_line_items'] as List<dynamic>? ?? [])
          .map((item) => OrderLineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      shippingAddress: j['shipping_address'] as String? ?? '',
      billingAddress: j['billing_address'] as String? ?? '',
      deliveryPartnerFee: j['delivery_partner_fee']?.toString() ?? '0.0',
      labourFee: j['labour_fee']?.toString() ?? '0.0',
      deliveryType: j['delivery_type'] as String?,
      deliveryInfo: j['delivery_info'] is Map<String, dynamic>
          ? DeliveryInfo.fromJson(j['delivery_info'] as Map<String, dynamic>)
          : const DeliveryInfo(handleWithCare: false),
      delivererDetails: j['deliverer_details'] is Map<String, dynamic>
          ? DelivererDetails.fromJson(j['deliverer_details'] as Map<String, dynamic>)
          : const DelivererDetails(driverName: '', vehicleNumber: '', driverMobileNumber: ''),
      infoForLabour: j['info_for_labour'] is Map<String, dynamic>
          ? InfoForLabour.fromJson(j['info_for_labour'] as Map<String, dynamic>)
          : const InfoForLabour(floorNumber: 0, permittedByOwner: false, groundFloorIncluded: false),
      cancellationReason: j['cancellation_reason'] as String?,
    );
  }
}
