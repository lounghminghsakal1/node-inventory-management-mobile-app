import 'order.dart';

// ── Allocation Availability Models ────────────────────────────────────────────
class BatchAvailabilityModel {
  final String batchCode;
  final String? manufactureDate;
  final String? expiryDate;
  final int availableQuantity;
  final int totalQuantity;
  final int blockedQuantity;

  const BatchAvailabilityModel({
    required this.batchCode,
    this.manufactureDate,
    this.expiryDate,
    required this.availableQuantity,
    required this.totalQuantity,
    required this.blockedQuantity,
  });

  factory BatchAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return BatchAvailabilityModel(
      batchCode: json['batch_code']?.toString() ?? '',
      manufactureDate: json['manufacture_date']?.toString(),
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
  final String serialNumber;

  const SerialAvailabilityModel({
    required this.serialNumber,
  });

  factory SerialAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return SerialAvailabilityModel(
      serialNumber: json['serial_number']?.toString() ?? '',
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

  List<BatchAllocation> get batchAllocations => _batchAllocations ?? const [];
  List<UntrackedAllocation> get untrackedAllocations => _untrackedAllocations ?? const [];
  List<String> get serialNumbers => _serialNumbers ?? const [];

  const ShipmentLineItem({
    required this.id,
    required this.product,
    required this.shippedQty,
    List<BatchAllocation>? batchAllocations = const [],
    List<UntrackedAllocation>? untrackedAllocations = const [],
    List<String>? serialNumbers = const [],
    this.isAllocated = false,
    this.allocationType = 'fifo',
  })  : _batchAllocations = batchAllocations,
        _untrackedAllocations = untrackedAllocations,
        _serialNumbers = serialNumbers;

  factory ShipmentLineItem.fromJson(
      Map<String, dynamic> json, bool shipmentAllocated) {
    final skuMap = json['product_sku'] as Map<String, dynamic>? ?? {};
    final trackingTypeStr =
        skuMap['tracking_type']?.toString().toLowerCase() ?? 'untracked';
    TrackingType tt = TrackingType.untracked;
    if (trackingTypeStr == 'batch') tt = TrackingType.batch;
    if (trackingTypeStr == 'serial') tt = TrackingType.serial;

    final metaMap = json['meta'] as Map<String, dynamic>? ?? {};
    final selectionType = metaMap['selection_type']?.toString().toLowerCase() ??
        skuMap['selection_type']?.toString().toLowerCase() ??
        'fifo';

    final batchesList = (metaMap['allocated_batches'] is List) ? (metaMap['allocated_batches'] as List) : [];
    final batchAllocations = batchesList.whereType<Map>().map((b) {
      final bMap = Map<String, dynamic>.from(b);
      return BatchAllocation(
        batchCode: bMap['batch_code']?.toString() ?? '',
        qty: int.tryParse(bMap['quantity']?.toString() ?? '0') ?? 0,
      );
    }).toList();

    final untrackedList =
        (metaMap['allocated_untracked'] is List) ? (metaMap['allocated_untracked'] as List) : [];
    final untrackedAllocations = untrackedList.whereType<Map>().map((u) {
      final uMap = Map<String, dynamic>.from(u);
      return UntrackedAllocation(
        untrackedNumber: uMap['untracked_number']?.toString() ?? '',
        qty: int.tryParse(uMap['quantity']?.toString() ?? '0') ?? 0,
      );
    }).toList();

    final serialsList = (metaMap['allocated_serials'] is List) ? (metaMap['allocated_serials'] as List) : [];
    final serialNumbers = serialsList.map((s) => s.toString()).toList();

    final isAlloc = shipmentAllocated ||
        batchAllocations.isNotEmpty ||
        untrackedAllocations.isNotEmpty ||
        serialNumbers.isNotEmpty ||
        metaMap['selection_type'] != null;

    final product = Product(
      id: skuMap['id']?.toString() ?? '',
      name: skuMap['display_name']?.toString() ??
          skuMap['sku_name']?.toString() ??
          'Product Item',
      sku: skuMap['sku_code']?.toString() ?? '',
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
    );
  }

  ShipmentLineItem copyWith({
    int? shippedQty,
    List<BatchAllocation>? batchAllocations,
    List<UntrackedAllocation>? untrackedAllocations,
    List<String>? serialNumbers,
    bool? isAllocated,
    String? allocationType,
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
    );
  }
}

// ── Driver Details ────────────────────────────────────────────────────────────
class DriverDetails {
  final String name;
  final String phone;
  final String vehicleNumber;
  final String? distance;
  final Map<String, dynamic>? additionalDetails;

  const DriverDetails({
    required this.name,
    required this.phone,
    required this.vehicleNumber,
    this.distance,
    this.additionalDetails,
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

// ── Shipment Invoice ──────────────────────────────────────────────────────────
class ShipmentInvoice {
  final int id;
  final String invoiceType;
  final String invoiceNumber;
  final String invoiceUrl;

  const ShipmentInvoice({
    required this.id,
    required this.invoiceType,
    required this.invoiceNumber,
    required this.invoiceUrl,
  });

  factory ShipmentInvoice.fromJson(Map<String, dynamic> json) {
    return ShipmentInvoice(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      invoiceType: json['invoice_type']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      invoiceUrl: json['invoice_url']?.toString() ?? '',
    );
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
  final String? nodeId;
  final String? billingAddress;
  final String? shippingAddress;
  final String? deliveryType;
  final String? customerPhone;
  final String? nodeName;
  final bool fullyAllocated;
  final List<ShipmentInvoice>? _invoices;
  final String? customerId;
  final String? shipmentType;
  final String? parentShipmentNumber;
  final int? reviewRating;

  List<ShipmentLineItem> get lineItems => _lineItems ?? const [];
  List<ShipmentInvoice> get invoices => _invoices ?? const [];

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
    this.nodeId,
    this.billingAddress,
    this.shippingAddress,
    this.deliveryType,
    this.customerPhone,
    this.nodeName,
    this.fullyAllocated = false,
    List<ShipmentInvoice>? invoices = const [],
    this.customerId,
    this.shipmentType,
    this.parentShipmentNumber,
    this.reviewRating,
  })  : _lineItems = lineItems,
        _invoices = invoices;

  int get totalItems => lineItems.length;
  int get totalQty => lineItems.fold(0, (s, i) => s + i.shippedQty);

  Shipment copyWith({
    ShipmentStatus? status,
    List<ShipmentLineItem>? lineItems,
    DriverDetails? driverDetails,
    bool? fullyAllocated,
    List<ShipmentInvoice>? invoices,
    String? customerId,
    String? shipmentType,
    String? parentShipmentNumber,
    int? reviewRating,
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
      nodeId: nodeId,
      billingAddress: billingAddress,
      shippingAddress: shippingAddress,
      deliveryType: deliveryType,
      customerPhone: customerPhone,
      nodeName: nodeName,
      fullyAllocated: fullyAllocated ?? this.fullyAllocated,
      invoices: invoices ?? _invoices,
      customerId: customerId ?? this.customerId,
      shipmentType: shipmentType ?? this.shipmentType,
      parentShipmentNumber: parentShipmentNumber ?? this.parentShipmentNumber,
      reviewRating: reviewRating ?? this.reviewRating,
    );
  }

  factory Shipment.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase() ?? 'created';
    final fullyAllocated = json['fully_allocated'] == true;

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

    final lineItemsList = (json['line_items'] is List) ? (json['line_items'] as List) : [];
    final items = lineItemsList
        .whereType<Map>()
        .map((item) => ShipmentLineItem.fromJson(
            Map<String, dynamic>.from(item), fullyAllocated))
        .toList();

    final invoicesList = (json['invoices'] is List) ? (json['invoices'] as List) : [];
    final invoices = invoicesList
        .whereType<Map>()
        .map((e) => ShipmentInvoice.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    DriverDetails? parsedDriver;
    final metaMap = json['meta'] as Map<String, dynamic>?;
    if (metaMap != null && metaMap['dispatch_details'] is Map) {
      final dispatchMap =
          metaMap['dispatch_details'] as Map<String, dynamic>;
      final name = dispatchMap['driver_name']?.toString() ?? '';
      final phone = dispatchMap['driver_number']?.toString() ??
          dispatchMap['driver_mobile_number']?.toString() ??
          '';
      final vehicle = dispatchMap['vehicle_number']?.toString() ?? '';
      final distance = dispatchMap['distance']?.toString();

      final additional = <String, dynamic>{};
      dispatchMap.forEach((k, v) {
        if (![
          'driver_name',
          'driver_number',
          'driver_mobile_number',
          'vehicle_number',
          'distance',
        ].contains(k)) {
          additional[k] = v;
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

    return Shipment(
      id: json['id']?.toString() ?? '',
      shipmentNumber: json['shipment_number']?.toString() ?? '',
      orderId: orderMap['id']?.toString() ?? '',
      orderNumber: orderMap['order_number']?.toString() ?? '',
      customerName: customerMap['name']?.toString() ?? 'Unknown Customer',
      customerPhone: customerMap['mobile_number']?.toString(),
      status: statusEnum,
      fullyAllocated: fullyAllocated,
      lineItems: items,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      nodeId: nodeMap['id']?.toString(),
      nodeName: nodeMap['name']?.toString(),
      billingAddress: json['billing_address']?.toString(),
      shippingAddress: json['shipping_address']?.toString(),
      deliveryType: json['delivery_type']?.toString(),
      driverDetails: parsedDriver,
      invoices: invoices,
      customerId: customerIdStr,
      shipmentType: shipmentTypeStr,
      parentShipmentNumber: parentNumber,
      reviewRating: rating,
    );
  }
}

// ── Dummy serial numbers ──────────────────────────────────────────────────────
const List<String> dummySerialNumbers = [
  'SN-B002-001', 'SN-B002-002', 'SN-B002-003', 'SN-B002-004',
  'SN-B002-005', 'SN-B002-006', 'SN-B002-007', 'SN-B002-008',
  'SN-B002-009', 'SN-B002-010', 'SN-B002-011', 'SN-B002-012',
];
