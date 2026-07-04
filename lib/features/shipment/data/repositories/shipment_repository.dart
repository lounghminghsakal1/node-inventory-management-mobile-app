import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shipment.dart';
import '../models/order.dart';

// ── Repository (dummy) ────────────────────────────────────────────────────────
class ShipmentRepository {
  // Mutable in-memory store
  final List<Shipment> _shipments = _buildDummyShipments();

  List<Shipment> getAll() => List.unmodifiable(_shipments);

  List<Order> getConfirmedOrders() => dummyOrders;

  Shipment? getById(String id) {
    try {
      return _shipments.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Shipment> createShipment({
    required Order order,
    required List<({Product product, int qty})> selectedItems,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final lineItems = selectedItems
        .map((item) => ShipmentLineItem(
              id: 'sli_${DateTime.now().millisecondsSinceEpoch}_${item.product.id}',
              product: item.product,
              shippedQty: item.qty,
            ))
        .toList();

    final shipment = Shipment(
      id: 'sh_${DateTime.now().millisecondsSinceEpoch}',
      shipmentNumber: 'SH-2024-${100 + _shipments.length}',
      orderId: order.id,
      orderNumber: order.orderNumber,
      customerName: order.customerName,
      status: ShipmentStatus.created,
      lineItems: lineItems,
      createdAt: DateTime.now(),
    );

    _shipments.insert(0, shipment);
    return shipment;
  }

  Future<Shipment> updateStatus(String id, ShipmentStatus status) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final idx = _shipments.indexWhere((s) => s.id == id);
    if (idx == -1) throw Exception('Shipment not found');
    final updated = _shipments[idx].copyWith(status: status);
    _shipments[idx] = updated;
    return updated;
  }

  Future<Shipment> allocate(
      String id, List<ShipmentLineItem> allocatedItems) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final idx = _shipments.indexWhere((s) => s.id == id);
    if (idx == -1) throw Exception('Shipment not found');
    final updated = _shipments[idx].copyWith(
      status: ShipmentStatus.allocated,
      lineItems: allocatedItems,
    );
    _shipments[idx] = updated;
    return updated;
  }

  Future<Shipment> dispatch(String id, DriverDetails driver) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final idx = _shipments.indexWhere((s) => s.id == id);
    if (idx == -1) throw Exception('Shipment not found');
    final updated = _shipments[idx].copyWith(
      status: ShipmentStatus.dispatched,
      driverDetails: driver,
    );
    _shipments[idx] = updated;
    return updated;
  }

  Future<Shipment> updateShipmentItems(
      String id, List<ShipmentLineItem> items) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final idx = _shipments.indexWhere((s) => s.id == id);
    if (idx == -1) throw Exception('Shipment not found');
    final updated = _shipments[idx].copyWith(lineItems: items);
    _shipments[idx] = updated;
    return updated;
  }
}

List<Shipment> _buildDummyShipments() {
  return [
    Shipment(
      id: 'sh_001',
      shipmentNumber: 'SH-2024-089',
      orderId: 'ord_history_1',
      orderNumber: 'ORD-2024-189',
      customerName: 'Acme Corporation',
      status: ShipmentStatus.dispatched,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      driverDetails: const DriverDetails(
        name: 'Ravi Kumar',
        phone: '9876543210',
        vehicleNumber: 'TN 09 AB 1234',
      ),
      lineItems: [
        ShipmentLineItem(
          id: 'sli_1',
          product: dummyProducts[0],
          shippedQty: 10,
          batchAllocations: [
            BatchAllocation(batchCode: 'B-2024-11', qty: 6),
            BatchAllocation(batchCode: 'B-2024-12', qty: 4),
          ],
          isAllocated: true,
        ),
        ShipmentLineItem(
          id: 'sli_2',
          product: dummyProducts[2],
          shippedQty: 10,
          isAllocated: true,
        ),
      ],
    ),
    Shipment(
      id: 'sh_002',
      shipmentNumber: 'SH-2024-086',
      orderId: 'ord_history_2',
      orderNumber: 'ORD-2024-186',
      customerName: 'RetailHub Pvt Ltd',
      status: ShipmentStatus.created,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      lineItems: [
        ShipmentLineItem(
          id: 'sli_3',
          product: dummyProducts[0],
          shippedQty: 5,
        ),
        ShipmentLineItem(
          id: 'sli_4',
          product: dummyProducts[2],
          shippedQty: 15,
        ),
      ],
    ),
    Shipment(
      id: 'sh_003',
      shipmentNumber: 'SH-2024-082',
      orderId: 'ord_history_3',
      orderNumber: 'ORD-2024-182',
      customerName: 'TechMart India',
      status: ShipmentStatus.allocated,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      lineItems: [
        ShipmentLineItem(
          id: 'sli_5',
          product: dummyProducts[1],
          shippedQty: 8,
          serialNumbers: dummySerialNumbers.sublist(0, 8),
          isAllocated: true,
        ),
      ],
    ),
    Shipment(
      id: 'sh_004',
      shipmentNumber: 'SH-2024-075',
      orderId: 'ord_history_4',
      orderNumber: 'ORD-2024-175',
      customerName: 'GlobalTech Solutions',
      status: ShipmentStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      lineItems: [
        ShipmentLineItem(
          id: 'sli_6',
          product: dummyProducts[3],
          shippedQty: 7,
          isAllocated: true,
        ),
        ShipmentLineItem(
          id: 'sli_7',
          product: dummyProducts[4],
          shippedQty: 20,
          isAllocated: true,
        ),
      ],
    ),
    Shipment(
      id: 'sh_005',
      shipmentNumber: 'SH-2024-068',
      orderId: 'ord_history_5',
      orderNumber: 'ORD-2024-168',
      customerName: 'Sunrise Retail',
      status: ShipmentStatus.invoiced,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      lineItems: [
        ShipmentLineItem(
          id: 'sli_8',
          product: dummyProducts[2],
          shippedQty: 25,
          isAllocated: true,
        ),
      ],
    ),
  ];
}

// ── Provider ──────────────────────────────────────────────────────────────────
final shipmentRepositoryProvider = Provider<ShipmentRepository>(
  (_) => ShipmentRepository(),
);
