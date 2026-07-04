import 'order.dart';

// ── Batch Allocation ──────────────────────────────────────────────────────────
class BatchAllocation {
  final String batchCode;
  final int qty;

  const BatchAllocation({required this.batchCode, required this.qty});
}

// ── Shipment Line Item ────────────────────────────────────────────────────────
class ShipmentLineItem {
  final String id;
  final Product product;
  final int shippedQty;
  final List<BatchAllocation> batchAllocations;
  final List<String> serialNumbers;
  final bool isAllocated;
  final String allocationType; // 'lifo', 'fifo', 'manual'

  const ShipmentLineItem({
    required this.id,
    required this.product,
    required this.shippedQty,
    this.batchAllocations = const [],
    this.serialNumbers = const [],
    this.isAllocated = false,
    this.allocationType = 'lifo',
  });

  ShipmentLineItem copyWith({
    int? shippedQty,
    List<BatchAllocation>? batchAllocations,
    List<String>? serialNumbers,
    bool? isAllocated,
    String? allocationType,
  }) {
    return ShipmentLineItem(
      id: id,
      product: product,
      shippedQty: shippedQty ?? this.shippedQty,
      batchAllocations: batchAllocations ?? this.batchAllocations,
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

  const DriverDetails({
    required this.name,
    required this.phone,
    required this.vehicleNumber,
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
  final List<ShipmentLineItem> lineItems;
  final DateTime createdAt;
  final DriverDetails? driverDetails;
  final String? nodeId;

  const Shipment({
    required this.id,
    required this.shipmentNumber,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.lineItems,
    required this.createdAt,
    this.driverDetails,
    this.nodeId,
  });

  int get totalItems => lineItems.length;
  int get totalQty => lineItems.fold(0, (s, i) => s + i.shippedQty);

  Shipment copyWith({
    ShipmentStatus? status,
    List<ShipmentLineItem>? lineItems,
    DriverDetails? driverDetails,
  }) {
    return Shipment(
      id: id,
      shipmentNumber: shipmentNumber,
      orderId: orderId,
      orderNumber: orderNumber,
      customerName: customerName,
      status: status ?? this.status,
      lineItems: lineItems ?? this.lineItems,
      createdAt: createdAt,
      driverDetails: driverDetails ?? this.driverDetails,
      nodeId: nodeId,
    );
  }
}

// ── Dummy serial numbers ──────────────────────────────────────────────────────
const List<String> dummySerialNumbers = [
  'SN-B002-001', 'SN-B002-002', 'SN-B002-003', 'SN-B002-004',
  'SN-B002-005', 'SN-B002-006', 'SN-B002-007', 'SN-B002-008',
  'SN-B002-009', 'SN-B002-010', 'SN-B002-011', 'SN-B002-012',
];
