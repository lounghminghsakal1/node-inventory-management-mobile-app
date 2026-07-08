import 'order.dart';

// ── Allocation Availability Models ────────────────────────────────────────────
class LineItemAvailabilityModel {
  final String shipmentLineItemId;
  final String productSkuId;
  final String? skuName;
  final String? skuCode;
  final String trackingType;
  final int requiredQuantity;
  final int availableQuantity;

  const LineItemAvailabilityModel({
    required this.shipmentLineItemId,
    required this.productSkuId,
    this.skuName,
    this.skuCode,
    required this.trackingType,
    required this.requiredQuantity,
    required this.availableQuantity,
  });

  factory LineItemAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return LineItemAvailabilityModel(
      shipmentLineItemId: json['shipment_line_item_id']?.toString() ?? '',
      productSkuId: json['product_sku_id']?.toString() ?? '',
      skuName: json['sku_name']?.toString(),
      skuCode: json['sku_code']?.toString(),
      trackingType: json['tracking_type']?.toString() ?? '',
      requiredQuantity:
          int.tryParse(json['required_quantity']?.toString() ?? '0') ?? 0,
      availableQuantity:
          int.tryParse(json['available_quantity']?.toString() ?? '0') ?? 0,
    );
  }
}

class BatchAvailabilityModel {
  final String? id;
  final String batchCode;
  final String? manufactureDate;
  final String? expiryDate;
  final int availableQuantity;
  final int totalQuantity;
  final int blockedQuantity;

  const BatchAvailabilityModel({
    this.id,
    required this.batchCode,
    this.manufactureDate,
    this.expiryDate,
    required this.availableQuantity,
    required this.totalQuantity,
    required this.blockedQuantity,
  });

  factory BatchAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return BatchAvailabilityModel(
      id: json['id']?.toString(),
      batchCode: json['batch_code']?.toString() ?? '',
      manufactureDate: json['manufacturing_date']?.toString() ?? json['manufacture_date']?.toString(),
      expiryDate: json['expiry_date']?.toString(),
      availableQuantity: int.tryParse(json['available_quantity']?.toString() ?? '0') ?? 0,
      totalQuantity: int.tryParse(json['total_quantity']?.toString() ?? '0') ?? 0,
      blockedQuantity: int.tryParse(json['blocked_quantity']?.toString() ?? '0') ?? 0,
    );
  }
}

class UntrackedAvailabilityModel {
  final String untrackedNumber;
  final int availableQuantity;
  final int totalQuantity;
  final int blockedQuantity;

  const UntrackedAvailabilityModel({
    required this.untrackedNumber,
    required this.availableQuantity,
    required this.totalQuantity,
    required this.blockedQuantity,
  });

  factory UntrackedAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return UntrackedAvailabilityModel(
      untrackedNumber: json['untracked_number']?.toString() ?? '',
      availableQuantity: int.tryParse(json['available_quantity']?.toString() ?? '0') ?? 0,
      totalQuantity: int.tryParse(json['total_quantity']?.toString() ?? '0') ?? 0,
      blockedQuantity: int.tryParse(json['blocked_quantity']?.toString() ?? '0') ?? 0,
    );
  }
}

class SerialAvailabilityModel {
  final String? id;
  final String serialNumber;
  final String? status;

  const SerialAvailabilityModel({
    this.id,
    required this.serialNumber,
    this.status,
  });

  factory SerialAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return SerialAvailabilityModel(
      id: json['id']?.toString(),
      serialNumber: json['serial_number']?.toString() ?? '',
      status: json['status']?.toString(),
    );
  }
}

// ── Batch Allocation ──────────────────────────────────────────────────────────
class BatchAllocation {
  final String batchCode;
  final int qty;

  const BatchAllocation({required this.batchCode, required this.qty});
}

// ── Untracked Allocation ──────────────────────────────────────────────────────
class UntrackedAllocation {
  final String untrackedNumber;
  final int qty;

  const UntrackedAllocation({required this.untrackedNumber, required this.qty});
}

// ── Shipment Line Item ────────────────────────────────────────────────────────
class ShipmentLineItem {
  final String id;
  final Product product;
  final int shippedQty;
  final List<BatchAllocation>? _batchAllocations;
  final List<UntrackedAllocation>? _untrackedAllocations;
  final List<String>? _serialNumbers;
  final bool isAllocated;
  final String allocationType; // 'lifo', 'fifo', 'manual'
  final int? goodQty;
  final int? badQty;
  final Map<String, dynamic> meta;

  List<BatchAllocation> get batchAllocations => _batchAllocations ?? const [];
  List<UntrackedAllocation> get untrackedAllocations => _untrackedAllocations ?? const [];
  List<String> get serialNumbers => _serialNumbers ?? const [];

  List<BatchAllocation> get goodBatches {
    final list = (meta['good_batches'] is List) ? (meta['good_batches'] as List) : [];
    return list.whereType<Map>().map((b) {
      final bMap = Map<String, dynamic>.from(b);
      return BatchAllocation(
        batchCode: bMap['batch_code']?.toString() ?? '',
        qty: int.tryParse(bMap['quantity']?.toString() ?? '0') ?? 0,
      );
    }).toList();
  }

  List<BatchAllocation> get badBatches {
    final list = (meta['bad_batches'] is List) ? (meta['bad_batches'] as List) : [];
    return list.whereType<Map>().map((b) {
      final bMap = Map<String, dynamic>.from(b);
      return BatchAllocation(
        batchCode: bMap['batch_code']?.toString() ?? '',
        qty: int.tryParse(bMap['quantity']?.toString() ?? '0') ?? 0,
      );
    }).toList();
  }

  List<String> get goodSerials {
    final list = (meta['good_serials'] is List) ? (meta['good_serials'] as List) : [];
    return list.map((s) => s.toString()).toList();
  }

  List<String> get badSerials {
    final list = (meta['bad_serials'] is List) ? (meta['bad_serials'] as List) : [];
    return list.map((s) => s.toString()).toList();
  }

  List<UntrackedAllocation> get goodUntracked {
    final list = (meta['good_untracked'] is List) ? (meta['good_untracked'] as List) : [];
    return list.whereType<Map>().map((u) {
      final uMap = Map<String, dynamic>.from(u);
      return UntrackedAllocation(
        untrackedNumber: uMap['untracked_number']?.toString() ?? '',
        qty: int.tryParse(uMap['quantity']?.toString() ?? '0') ?? 0,
      );
    }).toList();
  }

  List<UntrackedAllocation> get badUntracked {
    final list = (meta['bad_untracked'] is List) ? (meta['bad_untracked'] as List) : [];
    return list.whereType<Map>().map((u) {
      final uMap = Map<String, dynamic>.from(u);
      return UntrackedAllocation(
        untrackedNumber: uMap['untracked_number']?.toString() ?? '',
        qty: int.tryParse(uMap['quantity']?.toString() ?? '0') ?? 0,
      );
    }).toList();
  }

  const ShipmentLineItem({
    required this.id,
    required this.product,
    required this.shippedQty,
    List<BatchAllocation>? batchAllocations = const [],
    List<UntrackedAllocation>? untrackedAllocations = const [],
    List<String>? serialNumbers = const [],
    this.isAllocated = false,
    this.allocationType = 'fifo',
    this.goodQty,
    this.badQty,
    this.meta = const {},
  })  : _batchAllocations = batchAllocations,
        _untrackedAllocations = untrackedAllocations,
        _serialNumbers = serialNumbers;

  factory ShipmentLineItem.fromJson(
      Map<String, dynamic> json, bool shipmentAllocated) {
    final skuMap = json['product_sku'] as Map<String, dynamic>? ?? {};
    final trackingTypeStr = json['tracking_type']?.toString().toLowerCase() ??
        skuMap['tracking_type']?.toString().toLowerCase() ??
        'untracked';
    TrackingType tt = TrackingType.untracked;
    if (trackingTypeStr == 'batch') tt = TrackingType.batch;
    if (trackingTypeStr == 'serial') tt = TrackingType.serial;

    final metaMap = json['meta'] as Map<String, dynamic>? ?? {};
    final selectionType = json['selection_type']?.toString().toLowerCase() ??
        metaMap['selection_type']?.toString().toLowerCase() ??
        skuMap['selection_type']?.toString().toLowerCase() ??
        'fifo';

    List<BatchAllocation> batchAllocations = [];
    if (json['batch_codes'] is Map) {
      final bMap = json['batch_codes'] as Map;
      bMap.forEach((k, v) {
        batchAllocations.add(BatchAllocation(
          batchCode: k.toString(),
          qty: int.tryParse(v.toString()) ?? 0,
        ));
      });
    } else if (metaMap['allocated_batches'] is List) {
      final batchesList = metaMap['allocated_batches'] as List;
      batchAllocations = batchesList.whereType<Map>().map((b) {
        final bMap = Map<String, dynamic>.from(b);
        return BatchAllocation(
          batchCode: bMap['batch_code']?.toString() ?? '',
          qty: int.tryParse(bMap['quantity']?.toString() ?? '0') ?? 0,
        );
      }).toList();
    }

    List<UntrackedAllocation> untrackedAllocations = [];
    if (json['untracked_codes'] is Map) {
      final uMap = json['untracked_codes'] as Map;
      uMap.forEach((k, v) {
        untrackedAllocations.add(UntrackedAllocation(
          untrackedNumber: k.toString(),
          qty: int.tryParse(v.toString()) ?? 0,
        ));
      });
    } else if (metaMap['allocated_untracked'] is List) {
      final untrackedList = metaMap['allocated_untracked'] as List;
      untrackedAllocations = untrackedList.whereType<Map>().map((u) {
        final uMap = Map<String, dynamic>.from(u);
        return UntrackedAllocation(
          untrackedNumber: uMap['untracked_number']?.toString() ?? '',
          qty: int.tryParse(uMap['quantity']?.toString() ?? '0') ?? 0,
        );
      }).toList();
    }

    List<String> serialNumbers = [];
    if (json['serial'] is List) {
      serialNumbers = (json['serial'] as List).map((s) => s.toString()).toList();
    } else if (metaMap['allocated_serials'] is List) {
      serialNumbers = (metaMap['allocated_serials'] as List).map((s) => s.toString()).toList();
    }

    final isAlloc = shipmentAllocated ||
        batchAllocations.isNotEmpty ||
        untrackedAllocations.isNotEmpty ||
        serialNumbers.isNotEmpty ||
        json['selection_type'] != null ||
        metaMap['selection_type'] != null;

    final product = Product(
      id: json['product_sku_id']?.toString() ?? skuMap['id']?.toString() ?? '',
      name: json['sku_name']?.toString() ??
          skuMap['display_name']?.toString() ??
          skuMap['sku_name']?.toString() ??
          'Product Item',
      sku: json['sku_code']?.toString() ?? skuMap['sku_code']?.toString() ?? '',
      trackingType: tt,
      nodeStock: 1000,
      unit: 'pcs',
    );

    return ShipmentLineItem(
      id: json['id']?.toString() ?? '',
      product: product,
      shippedQty: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      batchAllocations: batchAllocations,
      untrackedAllocations: untrackedAllocations,
      serialNumbers: serialNumbers,
      isAllocated: isAlloc,
      allocationType: selectionType,
      goodQty: json['good_quantity'] != null ? int.tryParse(json['good_quantity'].toString()) : null,
      badQty: json['bad_quality_quantity'] != null ? int.tryParse(json['bad_quality_quantity'].toString()) : null,
      meta: metaMap,
    );
  }

  ShipmentLineItem copyWith({
    int? shippedQty,
    List<BatchAllocation>? batchAllocations,
    List<UntrackedAllocation>? untrackedAllocations,
    List<String>? serialNumbers,
    bool? isAllocated,
    String? allocationType,
    int? goodQty,
    int? badQty,
    Map<String, dynamic>? meta,
  }) {
    return ShipmentLineItem(
      id: id,
      product: product,
      shippedQty: shippedQty ?? this.shippedQty,
      batchAllocations: batchAllocations ?? this.batchAllocations,
      untrackedAllocations: untrackedAllocations ?? this.untrackedAllocations,
      serialNumbers: serialNumbers ?? this.serialNumbers,
      isAllocated: isAllocated ?? this.isAllocated,
      allocationType: allocationType ?? this.allocationType,
      goodQty: goodQty ?? this.goodQty,
      badQty: badQty ?? this.badQty,
      meta: meta ?? this.meta,
    );
  }
}

// ── Driver Details ────────────────────────────────────────────────────────────
class DriverDetails {
  final String name;
  final String phone;
  final String vehicleNumber;
  final String? distance;
  final String? courierName;
  final String? trackingId;
  final String? dispatchedBy;
  final Map<String, dynamic>? additionalDetails;

  const DriverDetails({
    required this.name,
    required this.phone,
    required this.vehicleNumber,
    this.distance,
    this.courierName,
    this.trackingId,
    this.dispatchedBy,
    this.additionalDetails,
  });
}

// ── Delivery Details ──────────────────────────────────────────────────────────
class DeliveryDetails {
  final String? receivedBy;
  final String? deliveryOtp;
  final String? deliveryNote;

  const DeliveryDetails({
    this.receivedBy,
    this.deliveryOtp,
    this.deliveryNote,
  });
}

// ── Shipment Status ───────────────────────────────────────────────────────────
enum ShipmentStatus {
  created,
  allocated,
  packed,
  invoiced,
  dispatched,
  delivered,
  cancelled,
  returnInitiated,
  returnCompleted,
}

extension ShipmentStatusX on ShipmentStatus {
  String get value {
    switch (this) {
      case ShipmentStatus.created:
        return 'created';
      case ShipmentStatus.allocated:
        return 'allocated';
      case ShipmentStatus.packed:
        return 'packed';
      case ShipmentStatus.invoiced:
        return 'invoiced';
      case ShipmentStatus.dispatched:
        return 'dispatched';
      case ShipmentStatus.delivered:
        return 'delivered';
      case ShipmentStatus.cancelled:
        return 'cancelled';
      case ShipmentStatus.returnInitiated:
        return 'return_initiated';
      case ShipmentStatus.returnCompleted:
        return 'return_completed';
    }
  }

  String get label {
    switch (this) {
      case ShipmentStatus.created:
        return 'Created';
      case ShipmentStatus.allocated:
        return 'Allocated';
      case ShipmentStatus.packed:
        return 'Packed';
      case ShipmentStatus.invoiced:
        return 'Invoiced';
      case ShipmentStatus.dispatched:
        return 'Dispatched';
      case ShipmentStatus.delivered:
        return 'Delivered';
      case ShipmentStatus.cancelled:
        return 'Cancelled';
      case ShipmentStatus.returnInitiated:
        return 'Return Initiated';
      case ShipmentStatus.returnCompleted:
        return 'Return Completed';
    }
  }

  ShipmentStatus? get nextStatus {
    switch (this) {
      case ShipmentStatus.created:
        return ShipmentStatus.allocated;
      case ShipmentStatus.allocated:
        return ShipmentStatus.packed;
      case ShipmentStatus.packed:
        return ShipmentStatus.invoiced;
      case ShipmentStatus.invoiced:
        return ShipmentStatus.dispatched;
      case ShipmentStatus.dispatched:
        return ShipmentStatus.delivered;
      default:
        return null;
    }
  }
}


// ── Shipment ──────────────────────────────────────────────────────────────────
class Shipment {
  final String id;
  final String shipmentNumber;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final ShipmentStatus status;
  final List<ShipmentLineItem>? _lineItems;
  final DateTime createdAt;
  final DriverDetails? driverDetails;
  final DeliveryDetails? deliveryDetails;
  final String? nodeId;
  final String? billingAddress;
  final String? shippingAddress;
  final String? deliveryType;
  final String? customerPhone;
  final String? nodeName;
  final bool fullyAllocated;
  final String? customerId;
  final String? shipmentType;
  final String? parentShipmentNumber;
  final int? reviewRating;
  final String? customerCode;
  final int? lineItemsCount;
  final String? labourFee;
  final String? driverFee;

  List<ShipmentLineItem> get lineItems => _lineItems ?? const [];

  const Shipment({
    required this.id,
    required this.shipmentNumber,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    List<ShipmentLineItem>? lineItems = const [],
    required this.createdAt,
    this.driverDetails,
    this.deliveryDetails,
    this.nodeId,
    this.billingAddress,
    this.shippingAddress,
    this.deliveryType,
    this.customerPhone,
    this.nodeName,
    this.fullyAllocated = false,
    this.customerId,
    this.shipmentType,
    this.parentShipmentNumber,
    this.reviewRating,
    this.customerCode,
    this.lineItemsCount,
    this.labourFee,
    this.driverFee,
  }) : _lineItems = lineItems;

  int get totalItems => lineItemsCount ?? lineItems.length;
  int get totalQty => lineItems.fold(0, (s, i) => s + i.shippedQty);

  Shipment copyWith({
    ShipmentStatus? status,
    List<ShipmentLineItem>? lineItems,
    DriverDetails? driverDetails,
    DeliveryDetails? deliveryDetails,
    bool? fullyAllocated,
    String? customerId,
    String? shipmentType,
    String? parentShipmentNumber,
    int? reviewRating,
    String? customerCode,
    int? lineItemsCount,
    String? labourFee,
    String? driverFee,
  }) {
    return Shipment(
      id: id,
      shipmentNumber: shipmentNumber,
      orderId: orderId,
      orderNumber: orderNumber,
      customerName: customerName,
      status: status ?? this.status,
      lineItems: lineItems ?? _lineItems,
      createdAt: createdAt,
      driverDetails: driverDetails ?? this.driverDetails,
      deliveryDetails: deliveryDetails ?? this.deliveryDetails,
      nodeId: nodeId,
      billingAddress: billingAddress,
      shippingAddress: shippingAddress,
      deliveryType: deliveryType,
      customerPhone: customerPhone,
      nodeName: nodeName,
      fullyAllocated: fullyAllocated ?? this.fullyAllocated,
      customerId: customerId ?? this.customerId,
      shipmentType: shipmentType ?? this.shipmentType,
      parentShipmentNumber: parentShipmentNumber ?? this.parentShipmentNumber,
      reviewRating: reviewRating ?? this.reviewRating,
      customerCode: customerCode ?? this.customerCode,
      lineItemsCount: lineItemsCount ?? this.lineItemsCount,
      labourFee: labourFee ?? this.labourFee,
      driverFee: driverFee ?? this.driverFee,
    );
  }

  factory Shipment.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase() ?? 'created';
    final fullyAllocated = json['fully_allocated'] == true || json['is_fully_allocated'] == true;

    ShipmentStatus statusEnum = ShipmentStatus.created;
    if (statusStr == 'allocated' ||
        (statusStr == 'created' && fullyAllocated)) {
      statusEnum = ShipmentStatus.allocated;
    } else if (statusStr == 'packed') {
      statusEnum = ShipmentStatus.packed;
    } else if (statusStr == 'invoiced') {
      statusEnum = ShipmentStatus.invoiced;
    } else if (statusStr == 'dispatched') {
      statusEnum = ShipmentStatus.dispatched;
    } else if (statusStr == 'delivered') {
      statusEnum = ShipmentStatus.delivered;
    } else if (statusStr == 'cancelled') {
      statusEnum = ShipmentStatus.cancelled;
    } else if (statusStr == 'return_initiated') {
      statusEnum = ShipmentStatus.returnInitiated;
    } else if (statusStr == 'return_completed') {
      statusEnum = ShipmentStatus.returnCompleted;
    }

    final orderMap = json['order'] as Map<String, dynamic>? ?? {};
    final customerMap = json['customer'] as Map<String, dynamic>? ?? {};
    final nodeMap = json['node'] as Map<String, dynamic>? ?? {};

    final customerIdStr = customerMap['id']?.toString() ?? '1';
    final shipmentTypeStr = json['shipment_type']?.toString();
    String? parentNumber;
    if (json['parent_shipment'] is Map) {
      parentNumber = (json['parent_shipment'] as Map)['shipment_number']?.toString();
    }
    int? rating;
    if (json['review'] is Map) {
      rating = int.tryParse((json['review'] as Map)['overall_rating']?.toString() ?? '');
    }

    final lineItemsList = (json['line_items'] is List)
        ? (json['line_items'] as List)
        : ((json['shipment_line_items'] is List)
            ? (json['shipment_line_items'] as List)
            : []);
    final items = lineItemsList
        .whereType<Map>()
        .map((item) => ShipmentLineItem.fromJson(
            Map<String, dynamic>.from(item), fullyAllocated))
        .toList();

    DriverDetails? parsedDriver;
    final metaMap = json['meta'] as Map<String, dynamic>?;
    final dispatchSource = (json['dispatch_details'] is Map)
        ? (json['dispatch_details'] as Map)
        : ((json['shipment_dispatch_details'] is Map)
            ? (json['shipment_dispatch_details'] as Map)
            : ((metaMap != null && metaMap['dispatch_details'] is Map)
                ? (metaMap['dispatch_details'] as Map)
                : null));

    if (dispatchSource != null) {
      final dispatchMap = Map<String, dynamic>.from(dispatchSource);
      final name = dispatchMap['driver_name']?.toString() ??
          dispatchMap['courier_name']?.toString() ??
          (dispatchMap['transporter_name']?.toString().isNotEmpty == true
              ? dispatchMap['transporter_name']?.toString() ?? ''
              : '');
      final phone = dispatchMap['driver_number']?.toString() ??
          dispatchMap['driver_mobile_number']?.toString() ??
          dispatchMap['dispatched_by']?.toString() ??
          '';
      final vehicle = dispatchMap['vehicle_number']?.toString() ??
          dispatchMap['tracking_id']?.toString() ??
          '';
      final distance = dispatchMap['transport_distance']?.toString() ?? dispatchMap['distance']?.toString();

      final additional = <String, dynamic>{};
      dispatchMap.forEach((k, v) {
        if (![
          'driver_name',
          'transporter_name',
          'driver_number',
          'driver_mobile_number',
          'vehicle_number',
          'transport_distance',
          'distance',
          'images',
          'transporter_id',
          'courier_name',
          'tracking_id',
          'dispatched_by',
        ].contains(k) && v != null && v.toString().trim().isNotEmpty && v is! Map && v is! List) {
          final cleanKey = k.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
          additional[cleanKey] = v;
        }
      });

      if (name.isNotEmpty ||
          phone.isNotEmpty ||
          vehicle.isNotEmpty ||
          distance != null ||
          additional.isNotEmpty) {
        parsedDriver = DriverDetails(
          name: name,
          phone: phone,
          vehicleNumber: vehicle,
          distance: distance,
          courierName: dispatchMap['courier_name']?.toString(),
          trackingId: dispatchMap['tracking_id']?.toString(),
          dispatchedBy: dispatchMap['dispatched_by']?.toString(),
          additionalDetails: additional.isEmpty ? null : additional,
        );
      }
    }

    if (parsedDriver == null && json['deliverer_details'] is Map) {
      final delivMap =
          json['deliverer_details'] as Map<String, dynamic>;
      final name = delivMap['driver_name']?.toString() ?? '';
      final phone = delivMap['driver_mobile_number']?.toString() ??
          delivMap['driver_number']?.toString() ??
          '';
      final vehicle = delivMap['vehicle_number']?.toString() ?? '';
      if (name.isNotEmpty || phone.isNotEmpty || vehicle.isNotEmpty) {
        parsedDriver = DriverDetails(
          name: name,
          phone: phone,
          vehicleNumber: vehicle,
        );
      }
    }

    DeliveryDetails? parsedDelivery;
    final delivSource = (json['shipment_delivery_details'] is Map)
        ? (json['shipment_delivery_details'] as Map)
        : ((json['delivery_details'] is Map)
            ? (json['delivery_details'] as Map)
            : ((metaMap != null && metaMap['delivery_details'] is Map)
                ? (metaMap['delivery_details'] as Map)
                : null));

    if (delivSource != null) {
      final dMap = Map<String, dynamic>.from(delivSource);
      parsedDelivery = DeliveryDetails(
        receivedBy: dMap['received_by']?.toString(),
        deliveryOtp: dMap['delivery_otp']?.toString(),
        deliveryNote: dMap['delivery_note']?.toString(),
      );
    }

    final labourFeeStr = json['labour_fee']?.toString() ?? metaMap?['labour_fee']?.toString();
    final driverFeeStr = json['driver_fee']?.toString() ?? metaMap?['driver_fee']?.toString();

    final orderIdStr = orderMap['id']?.toString() ?? json['order_id']?.toString() ?? '';
    final orderNumStr = orderMap['order_number']?.toString() ?? json['order_number']?.toString() ?? '';
    final customerNameStr = customerMap['name']?.toString() ?? json['customer_name']?.toString() ?? 'Unknown Customer';
    final customerCodeStr = customerMap['code']?.toString() ?? json['customer_code']?.toString() ?? customerIdStr;
    final lineItemsCountVal = int.tryParse(json['line_items_count']?.toString() ?? '') ?? (items.isNotEmpty ? items.length : null);

    return Shipment(
      id: json['id']?.toString() ?? '',
      shipmentNumber: json['shipment_number']?.toString() ?? '',
      orderId: orderIdStr,
      orderNumber: orderNumStr,
      customerName: customerNameStr,
      customerPhone: json['customer_mobile']?.toString() ?? customerMap['mobile_number']?.toString(),
      status: statusEnum,
      fullyAllocated: fullyAllocated,
      lineItems: items,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      nodeId: nodeMap['id']?.toString(),
      nodeName: json['node_name']?.toString() ?? nodeMap['name']?.toString(),
      billingAddress: json['billing_address']?.toString(),
      shippingAddress: json['shipping_address']?.toString(),
      deliveryType: json['delivery_type']?.toString(),
      driverDetails: parsedDriver,
      deliveryDetails: parsedDelivery,
      customerId: customerIdStr,
      shipmentType: shipmentTypeStr,
      parentShipmentNumber: parentNumber,
      reviewRating: rating,
      customerCode: customerCodeStr,
      lineItemsCount: lineItemsCountVal,
      labourFee: labourFeeStr,
      driverFee: driverFeeStr,
    );
  }
}

// ── Dummy serial numbers ──────────────────────────────────────────────────────
const List<String> dummySerialNumbers = [];
