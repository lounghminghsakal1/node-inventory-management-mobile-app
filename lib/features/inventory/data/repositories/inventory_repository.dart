import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/batch_inventory_model.dart';
import '../models/serial_inventory_model.dart';
import '../models/node_inventory_model.dart';
import '../models/node_inventory_ledger_model.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final dio = ref.read(dioProvider);
  return InventoryRepository(dio);
});

class InventoryRepository {
  final Dio _dio;

  const InventoryRepository(this._dio);

  Future<BatchInventoryListResponse> getBatchInventories({
    String? bySkuName,
    String? bySkuCode,
    String? bySkuId,
    String? byBatchId,
    bool? availableInventory,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (bySkuName != null && bySkuName.trim().isNotEmpty) 'by_sku_name': bySkuName.trim(),
        if (bySkuCode != null && bySkuCode.trim().isNotEmpty) 'by_sku_code': bySkuCode.trim(),
        if (bySkuId != null && bySkuId.trim().isNotEmpty) 'by_sku_id': bySkuId.trim(),
        if (byBatchId != null && byBatchId.trim().isNotEmpty) 'by_batch_id': byBatchId.trim(),
        if (availableInventory != null) 'available_inventory': availableInventory.toString(),
        'page': page,
      };

      final response = await _dio.get(ApiEndpoints.batchInventories, queryParameters: queryParams);
      _checkFailure(response);

      final data = (response.data is Map && response.data['data'] != null)
          ? response.data['data'] as Map<String, dynamic>
          : (response.data as Map<String, dynamic>? ?? {});

      return BatchInventoryListResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<BatchInventoryModel> getBatchInventoryDetail(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.batchInventoryDetail(id));
      _checkFailure(response);

      final data = (response.data is Map && response.data['data'] != null)
          ? response.data['data'] as Map<String, dynamic>
          : (response.data as Map<String, dynamic>? ?? {});

      return BatchInventoryModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<BatchInventoryTransactionsResponse> getBatchInventoryTransactions(String id, {int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.batchInventoryTransactions(id),
        queryParameters: {'page': page},
      );
      _checkFailure(response);

      final data = (response.data is Map && response.data['data'] != null)
          ? response.data['data'] as Map<String, dynamic>
          : (response.data as Map<String, dynamic>? ?? {});

      return BatchInventoryTransactionsResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<SerialInventoryListResponse> getSerialInventories({
    String? bySkuItemNumber,
    String? bySkuName,
    String? bySkuCode,
    String? byStatus,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (bySkuItemNumber != null && bySkuItemNumber.trim().isNotEmpty) 'by_sku_item_number': bySkuItemNumber.trim(),
        if (bySkuName != null && bySkuName.trim().isNotEmpty) 'by_sku_name': bySkuName.trim(),
        if (bySkuCode != null && bySkuCode.trim().isNotEmpty) 'by_sku_code': bySkuCode.trim(),
        if (byStatus != null && byStatus.trim().isNotEmpty && byStatus != 'all') 'by_status': byStatus.trim(),
        'page': page,
      };

      final response = await _dio.get(ApiEndpoints.skuItems, queryParameters: queryParams);
      _checkFailure(response);

      final data = (response.data is Map && response.data['data'] != null)
          ? response.data['data'] as Map<String, dynamic>
          : (response.data as Map<String, dynamic>? ?? {});

      return SerialInventoryListResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<SerialInventoryModel> getSerialInventoryDetail(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.skuItemDetail(id));
      _checkFailure(response);

      final data = (response.data is Map && response.data['data'] != null)
          ? response.data['data'] as Map<String, dynamic>
          : (response.data as Map<String, dynamic>? ?? {});

      return SerialInventoryModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<NodeInventoryListResponse> getNodeInventories({
    String? bySkuId,
    String? bySkuName,
    String? bySkuCode,
    bool? availableInventory,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (bySkuId != null && bySkuId.trim().isNotEmpty) 'by_sku_id': bySkuId.trim(),
        if (bySkuName != null && bySkuName.trim().isNotEmpty) 'by_sku_name': bySkuName.trim(),
        if (bySkuCode != null && bySkuCode.trim().isNotEmpty) 'by_sku_code': bySkuCode.trim(),
        if (availableInventory != null) 'available_inventory': availableInventory.toString(),
        'page': page,
      };

      final response = await _dio.get(ApiEndpoints.nodeInventories, queryParameters: queryParams);
      _checkFailure(response);

      final data = (response.data is Map && response.data['data'] != null)
          ? response.data['data'] as Map<String, dynamic>
          : (response.data as Map<String, dynamic>? ?? {});

      return NodeInventoryListResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<NodeInventoryModel> getNodeInventoryDetail(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.nodeInventoryDetail(id));
      _checkFailure(response);

      final data = (response.data is Map && response.data['data'] != null)
          ? response.data['data'] as Map<String, dynamic>
          : (response.data as Map<String, dynamic>? ?? {});

      return NodeInventoryModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<NodeInventoryTransactionsResponse> getNodeInventoryTransactions(String id, {int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.nodeInventoryTransactions(id),
        queryParameters: {'page': page},
      );
      _checkFailure(response);

      final data = (response.data is Map && response.data['data'] != null)
          ? response.data['data'] as Map<String, dynamic>
          : (response.data as Map<String, dynamic>? ?? {});

      return NodeInventoryTransactionsResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<NodeInventoryLedgerResponse> getNodeInventoryLedger({
    String? bySkuId,
    String? bySkuCode,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (bySkuId != null && bySkuId.trim().isNotEmpty) 'by_sku_id': bySkuId.trim(),
        if (bySkuCode != null && bySkuCode.trim().isNotEmpty) 'by_sku_code': bySkuCode.trim(),
        if (fromDate != null && fromDate.trim().isNotEmpty) 'from_date': fromDate.trim(),
        if (toDate != null && toDate.trim().isNotEmpty) 'to_date': toDate.trim(),
        'page': page,
      };

      final response = await _dio.get(ApiEndpoints.nodeInventoryLedger, queryParameters: queryParams);
      _checkFailure(response);

      final data = (response.data is Map && response.data['data'] != null)
          ? response.data['data'] as Map<String, dynamic>
          : (response.data as Map<String, dynamic>? ?? {});

      return NodeInventoryLedgerResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _checkFailure(Response response) {
    if (response.data is Map) {
      final map = response.data as Map;
      if (map['status'] == 'failure' || map['success'] == false) {
        throw ApiException.fromResponseData(map, response.statusCode);
      }
    }
  }
}
