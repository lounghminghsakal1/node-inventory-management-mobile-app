import 'package:dio/dio.dart' show Dio, DioException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/shipment.dart';
import '../models/order.dart';
import '../models/shippable_line_item.dart';

// ── Repository (dummy + real API) ─────────────────────────────────────────────
class ShipmentRepository {
  final Dio _dio;
  // Mutable in-memory store
  final List<Shipment> _shipments = _buildDummyShipments();

  ShipmentRepository(this._dio);

  List<Shipment> getAll() => List.unmodifiable(_shipments);

  Future<List<ShippableLineItem>> getShippableLineItems({
    required int nodeId,
    required int orderId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.shippableLineItems(nodeId.toString(), orderId.toString()),
      );

      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }

      if (response.data is Map<String, dynamic>) {
        final dataList = response.data['data'] as List<dynamic>? ?? [];
        return dataList
            .map((item) => ShippableLineItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw const ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> createShipmentApi({
    required int orderId,
    required int nodeId,
    required List<Map<String, dynamic>> lineItems,
  }) async {
    final payload = {
      "shipment": {
        "order_id": orderId,
        "node_id": nodeId,
        "shipment_type": "forward_shipment",
        "line_items": lineItems,
      }
    };

    try {
      final response = await _dio.post(
        ApiEndpoints.shipments,
        data: payload,
      );

      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  List<Order> getConfirmedOrders() => dummyOrders;

  Shipment? getById(String id) {
    try {
      return _shipments.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Shipment> getShipmentById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.shipmentDetail(id));

      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }

      if (response.data is Map<String, dynamic>) {
        final dataMap = response.data['data'];
        if (dataMap is Map<String, dynamic>) {
          return Shipment.fromJson(dataMap);
        }
      }
      throw const ApiException('Invalid response format from server');
    } on DioException catch (e) {
      // Fallback to local memory if offline/testing
      final local = getById(id);
      if (local != null) return local;
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      final local = getById(id);
      if (local != null) return local;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> updateAllocationTypeApi({
    required String shipmentId,
    required String allocationType,
  }) async {
    final dummyUrl = ApiEndpoints.updateAllocationType(shipmentId);
    try {
      await _dio.patch(
        dummyUrl,
        data: {
          "selection_type": allocationType,
        },
      );
    } catch (e) {
      // Dummy URL: ignore error so UI flow continues smoothly
      print('Dummy API call to $dummyUrl: $e');
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

  Future<List<BatchAvailabilityModel>> getBatchAvailability({
    required int nodeId,
    required String skuId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.batchAvailability(nodeId.toString(), skuId),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      if (response.data is Map<String, dynamic>) {
        final dataList = response.data['data'] as List<dynamic>? ?? [];
        return dataList
            .map((e) => BatchAvailabilityModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw const ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<UntrackedAvailabilityModel>> getUntrackedAvailability({
    required int nodeId,
    required String skuId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.untrackedAvailability(nodeId.toString(), skuId),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      if (response.data is Map<String, dynamic>) {
        final dataList = response.data['data'] as List<dynamic>? ?? [];
        return dataList
            .map((e) => UntrackedAvailabilityModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw const ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<SerialAvailabilityModel>> getSerialAvailability({
    required int nodeId,
    required String skuId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.serialAvailability(nodeId.toString(), skuId),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      if (response.data is Map<String, dynamic>) {
        final dataList = response.data['data'] as List<dynamic>? ?? [];
        return dataList
            .map((e) => SerialAvailabilityModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw const ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> assignShipmentAllocations({
    required String shipmentId,
    required Map<String, Iterable<Map<String, dynamic>>> payload,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.assignShipmentAllocations(shipmentId),
        data: payload,
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> generateInvoice({required String shipmentId}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.shipmentInvoice(shipmentId),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> markDispatched({
    required String shipmentId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.shipmentMarkDispatched(shipmentId),
        data: payload,
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> markDelivered({
    required String shipmentId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.shipmentDeliver(shipmentId),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      final idx = _shipments.indexWhere((s) => s.id == shipmentId);
      if (idx != -1) {
        _shipments[idx] = _shipments[idx].copyWith(status: ShipmentStatus.delivered);
      }
    } on DioException catch (e) {
      final idx = _shipments.indexWhere((s) => s.id == shipmentId);
      if (idx != -1) {
        _shipments[idx] = _shipments[idx].copyWith(status: ShipmentStatus.delivered);
        return;
      }
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      final idx = _shipments.indexWhere((s) => s.id == shipmentId);
      if (idx != -1) {
        _shipments[idx] = _shipments[idx].copyWith(status: ShipmentStatus.delivered);
        return;
      }
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
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
final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ShipmentRepository(dio);
});
