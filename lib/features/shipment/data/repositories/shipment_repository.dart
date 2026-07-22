import 'package:dio/dio.dart' show Dio, DioException, FormData, MultipartFile;
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
  final List<Shipment> _shipments = [];

  ShipmentRepository(this._dio);

  List<Shipment> getAll() => List.unmodifiable(_shipments);

  Future<({List<Shipment> shipments, int currentPage, int totalPages, int totalCount})> getShipmentsApi({
    int page = 1,
    String? byStatus,
    bool? byFullyAllocated,
    String? byOrderNumber,
    String? byCustomerCode,
    String? byShipmentType,
    String? fromDate,
    String? toDate,
    String? byShipmentNumber,
    String? bySkuName,
    String? bySkuCode,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (byStatus != null && byStatus.isNotEmpty) queryParams['by_status'] = byStatus;
      if (byFullyAllocated != null) queryParams['by_fully_allocated'] = byFullyAllocated;
      if (byOrderNumber != null && byOrderNumber.isNotEmpty) queryParams['by_order_number'] = byOrderNumber;
      if (byCustomerCode != null && byCustomerCode.isNotEmpty) queryParams['by_customer_code'] = byCustomerCode;
      if (byShipmentType != null && byShipmentType.isNotEmpty) queryParams['by_shipment_type'] = byShipmentType;
      if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;
      if (byShipmentNumber != null && byShipmentNumber.isNotEmpty) queryParams['by_shipment_number'] = byShipmentNumber;
      if (bySkuName != null && bySkuName.isNotEmpty) queryParams['by_sku_name'] = bySkuName;
      if (bySkuCode != null && bySkuCode.isNotEmpty) queryParams['by_sku_code'] = bySkuCode;

      final response = await _dio.get(
        ApiEndpoints.shipments,
        queryParameters: queryParams,
      );

      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }

      if (response.data is Map<String, dynamic>) {
        final dataObj = response.data['data'];
        List<dynamic> dataList = [];
        Map<String, dynamic>? metaObj;
        if (dataObj is List) {
          dataList = dataObj;
        } else if (dataObj is Map) {
          if (dataObj['shipments'] is List) {
            dataList = dataObj['shipments'] as List;
          }
          if (dataObj['meta'] is Map) {
            metaObj = Map<String, dynamic>.from(dataObj['meta']);
          }
        }
        final list = dataList
            .whereType<Map>()
            .map((item) => Shipment.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        
        if (page == 1) {
          _shipments.clear();
        }
        _shipments.addAll(list);

        final currentPage = (metaObj?['current_page'] as num?)?.toInt() ?? page;
        final totalPages = (metaObj?['total_pages'] as num?)?.toInt() ?? 1;
        final totalCount = (metaObj?['total_count'] as num?)?.toInt() ?? list.length;

        return (
          shipments: list,
          currentPage: currentPage,
          totalPages: totalPages,
          totalCount: totalCount,
        );
      }
      throw const ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
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

  List<Order> getConfirmedOrders() => [];

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

  Future<List<LineItemAvailabilityModel>> getLineItemsAvailability({
    required String shipmentId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.lineItemsAvailability(shipmentId),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      if (response.data is Map<String, dynamic>) {
        final dataObj = response.data['data'];
        List<dynamic> dataList = [];
        if (dataObj is List) {
          dataList = dataObj;
        } else if (dataObj is Map && dataObj['line_items'] is List) {
          dataList = dataObj['line_items'] as List;
        } else if (response.data['line_items'] is List) {
          dataList = response.data['line_items'] as List;
        }
        return dataList
            .map((e) => LineItemAvailabilityModel.fromJson(e as Map<String, dynamic>))
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

  Future<List<BatchAvailabilityModel>> getBatchAvailability({
    required String shipmentId,
    required String skuId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.batchAvailability(shipmentId, skuId),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      if (response.data is Map<String, dynamic>) {
        final dataObj = response.data['data'];
        List<dynamic> dataList = [];
        if (dataObj is List) {
          dataList = dataObj;
        } else if (dataObj is Map && dataObj['batches'] is List) {
          dataList = dataObj['batches'] as List;
        }
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
    required String shipmentId,
    required String skuId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.untrackedAvailability(shipmentId, skuId),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      if (response.data is Map<String, dynamic>) {
        final dataObj = response.data['data'];
        List<dynamic> dataList = [];
        if (dataObj is List) {
          dataList = dataObj;
        } else if (dataObj is Map && dataObj['untracked'] is List) {
          dataList = dataObj['untracked'] as List;
        }
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
    required String shipmentId,
    required String skuId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.serialAvailability(shipmentId, skuId),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      if (response.data is Map<String, dynamic>) {
        final dataObj = response.data['data'];
        List<dynamic> dataList = [];
        if (dataObj is List) {
          dataList = dataObj;
        } else if (dataObj is Map && dataObj['serials'] is List) {
          dataList = dataObj['serials'] as List;
        }
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
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _dio.put(
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

  Future<void> packShipment({required String shipmentId}) async {
    try {
      final response = await _dio.put(
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
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> generateInvoice({required String shipmentId}) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.shipmentInvoice(shipmentId),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      final idx = _shipments.indexWhere((s) => s.id == shipmentId);
      if (idx != -1) {
        _shipments[idx] = _shipments[idx].copyWith(status: ShipmentStatus.invoiced);
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
      final response = await _dio.put(
        ApiEndpoints.shipmentDispatch(shipmentId),
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

  Future<String> uploadMedia({
    required String shipmentId,
    required String actionType,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'action_type': actionType,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _dio.post(
        ApiEndpoints.shipmentUploadMedia(shipmentId),
        data: formData,
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      if (response.data is Map<String, dynamic>) {
        final dataMap = response.data['data'];
        if (dataMap is Map<String, dynamic> && dataMap.containsKey('s3_url')) {
          return dataMap['s3_url'] as String;
        }
      }
      throw const ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> markDelivered({
    required String shipmentId,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.shipmentDeliver(shipmentId),
        data: payload,
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      final idx = _shipments.indexWhere((s) => s.id == shipmentId);
      if (idx != -1) {
        _shipments[idx] = _shipments[idx].copyWith(status: ShipmentStatus.delivered);
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<Map<String, dynamic>>> getReturnRemaining(String shipmentId) async {
    try {
      final response = await _dio.get(ApiEndpoints.returnRemaining(shipmentId));
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      if (response.data is Map<String, dynamic>) {
        final dataMap = response.data['data'] as Map<String, dynamic>? ?? {};
        final dataList = dataMap['line_items'] as List<dynamic>? ?? [];
        return dataList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw const ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<Map<String, dynamic>>> getReturnAllocationInfo(String shipmentId) async {
    return getReturnRemaining(shipmentId);
  }

  Future<void> assignReturnItems({
    required String shipmentId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.assignReturnItems(shipmentId),
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

  Future<void> returnComplete({
    required String shipmentId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.returnComplete(shipmentId),
        data: payload,
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      _updateLocalReturnCompleted(shipmentId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<SerialAvailabilityModel> verifyScannedSerial({
    required String shipmentId,
    required String skuId,
    required String serialNumber,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.verifySerialAvailability(shipmentId, skuId, serialNumber),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      final responseData = response.data['data'];
      if (responseData == null) {
        throw ApiException("Serial not found");
      }
      return SerialAvailabilityModel.fromJson(responseData);
    } on DioException catch (e) {
      if (e.response != null) {
        // Handle 400, 404 explicitly if they come as standard errors
        if (e.response!.statusCode == 404) {
          throw ApiException("Serial not found in node");
        } else if (e.response!.statusCode == 400) {
          throw ApiException("Bad Request: Serial missing or invalid");
        }
      }
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> completeReturn({
    required String shipmentId,
    required Map<String, dynamic> payload,
  }) async {
    return returnComplete(shipmentId: shipmentId, payload: payload);
  }

  void _updateLocalReturnCompleted(String shipmentId) {
    final idx = _shipments.indexWhere((s) => s.id == shipmentId);
    if (idx == -1) return;
    final s = _shipments[idx];
    _shipments[idx] = s.copyWith(
      status: ShipmentStatus.returnCompleted,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ShipmentRepository(dio);
});
