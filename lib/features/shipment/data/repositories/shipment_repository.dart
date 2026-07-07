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

  Future<List<Shipment>> getShipmentsApi({int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.shipments,
        queryParameters: {'page': page},
      );

      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }

      if (response.data is Map<String, dynamic>) {
        final dataList = response.data['data'] as List<dynamic>? ?? [];
        final list = dataList
            .whereType<Map>()
            .map((item) => Shipment.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _shipments.clear();
        _shipments.addAll(list);
        return list;
      }
      throw const ApiException('Invalid response format from server');
    } on DioException catch (e) {
      if (_shipments.isNotEmpty) return _shipments;
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (_shipments.isNotEmpty) return _shipments;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

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
      
      print("jdcdhcdsvsv"+response.data.toString());
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

  Future<void> packShipment({required String shipmentId}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.shipmentPack(shipmentId),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      final idx = _shipments.indexWhere((s) => s.id == shipmentId);
      if (idx != -1) {
        _shipments[idx] = _shipments[idx].copyWith(status: ShipmentStatus.packed);
      }
    } on DioException catch (e) {
      final idx = _shipments.indexWhere((s) => s.id == shipmentId);
      if (idx != -1) {
        _shipments[idx] = _shipments[idx].copyWith(status: ShipmentStatus.packed);
        return;
      }
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      final idx = _shipments.indexWhere((s) => s.id == shipmentId);
      if (idx != -1) {
        _shipments[idx] = _shipments[idx].copyWith(status: ShipmentStatus.packed);
        return;
      }
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
      id: '18',
      shipmentNumber: 'EFP-S-10018',
      orderId: '107',
      orderNumber: 'EFP-O-10107',
      customerName: 'Prince Godwin I',
      customerId: '1',
      status: ShipmentStatus.created,
      shipmentType: 'forward_shipment',
      fullyAllocated: false,
      createdAt: DateTime.parse('2026-07-06T16:23:36.420+05:30'),
    ),
    Shipment(
      id: '17',
      shipmentNumber: 'EFP-S-10017',
      orderId: '107',
      orderNumber: 'EFP-O-10107',
      customerName: 'Prince Godwin I',
      customerId: '1',
      status: ShipmentStatus.delivered,
      shipmentType: 'forward_shipment',
      fullyAllocated: true,
      createdAt: DateTime.parse('2026-07-06T16:23:08.571+05:30'),
    ),
    Shipment(
      id: '16',
      shipmentNumber: 'EFP-S-10016',
      orderId: '105',
      orderNumber: 'EFP-O-10105',
      customerName: 'Prince Godwin I',
      customerId: '1',
      status: ShipmentStatus.returnInitiated,
      shipmentType: 'reverse_shipment',
      parentShipmentNumber: 'EFP-S-10015',
      fullyAllocated: false,
      createdAt: DateTime.parse('2026-07-06T13:42:07.457+05:30'),
    ),
    Shipment(
      id: '15',
      shipmentNumber: 'EFP-S-10015',
      orderId: '105',
      orderNumber: 'EFP-O-10105',
      customerName: 'Prince Godwin I',
      customerId: '1',
      status: ShipmentStatus.delivered,
      shipmentType: 'forward_shipment',
      fullyAllocated: true,
      createdAt: DateTime.parse('2026-07-06T13:41:40.490+05:30'),
    ),
    Shipment(
      id: '14',
      shipmentNumber: 'EFP-S-10014',
      orderId: '104',
      orderNumber: 'EFP-O-10104',
      customerName: 'Prince Godwin I',
      customerId: '1',
      status: ShipmentStatus.delivered,
      shipmentType: 'forward_shipment',
      fullyAllocated: true,
      createdAt: DateTime.parse('2026-07-06T13:38:51.621+05:30'),
    ),
    Shipment(
      id: '13',
      shipmentNumber: 'EFP-S-10013',
      orderId: '103',
      orderNumber: 'EFP-O-10103',
      customerName: 'Prince Godwin I',
      customerId: '1',
      status: ShipmentStatus.packed,
      shipmentType: 'forward_shipment',
      fullyAllocated: true,
      createdAt: DateTime.parse('2026-07-06T13:38:13.432+05:30'),
    ),
    Shipment(
      id: '12',
      shipmentNumber: 'EFP-S-10012',
      orderId: '102',
      orderNumber: 'EFP-O-10102',
      customerName: 'Prince Godwin I',
      customerId: '1',
      status: ShipmentStatus.allocated,
      shipmentType: 'forward_shipment',
      fullyAllocated: true,
      createdAt: DateTime.parse('2026-07-06T13:37:37.388+05:30'),
    ),
    Shipment(
      id: '11',
      shipmentNumber: 'EFP-S-10011',
      orderId: '101',
      orderNumber: 'EFP-O-10101',
      customerName: 'Prince Godwin I',
      customerId: '1',
      status: ShipmentStatus.delivered,
      shipmentType: 'forward_shipment',
      fullyAllocated: true,
      createdAt: DateTime.parse('2026-07-06T13:37:05.146+05:30'),
    ),
    Shipment(
      id: '10',
      shipmentNumber: 'EFP-S-10010',
      orderId: '100',
      orderNumber: 'EFP-O-10100',
      customerName: 'Prince Godwin I',
      customerId: '1',
      status: ShipmentStatus.delivered,
      shipmentType: 'forward_shipment',
      fullyAllocated: true,
      createdAt: DateTime.parse('2026-07-06T13:36:20.301+05:30'),
    ),
    Shipment(
      id: '9',
      shipmentNumber: 'EFP-S-10009',
      orderId: '99',
      orderNumber: 'EFP-O-10099',
      customerName: 'Prince Godwin I',
      customerId: '1',
      status: ShipmentStatus.delivered,
      shipmentType: 'forward_shipment',
      fullyAllocated: true,
      createdAt: DateTime.parse('2026-07-06T13:35:46.398+05:30'),
    ),
    Shipment(
      id: '3',
      shipmentNumber: 'EFP-S-10003',
      orderId: '92',
      orderNumber: 'EFP-O-10092',
      customerName: 'Prince Godwin I',
      customerId: '1',
      status: ShipmentStatus.returnCompleted,
      shipmentType: 'reverse_shipment',
      parentShipmentNumber: 'EFP-S-10002',
      fullyAllocated: false,
      createdAt: DateTime.parse('2026-07-06T13:28:46.069+05:30'),
    ),
    Shipment(
      id: '2',
      shipmentNumber: 'EFP-S-10002',
      orderId: '92',
      orderNumber: 'EFP-O-10092',
      customerName: 'Prince Godwin I',
      customerId: '1',
      status: ShipmentStatus.delivered,
      shipmentType: 'forward_shipment',
      fullyAllocated: true,
      createdAt: DateTime.parse('2026-07-06T13:28:16.892+05:30'),
    ),
  ];
}

// ── Provider ──────────────────────────────────────────────────────────────────
final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ShipmentRepository(dio);
});
