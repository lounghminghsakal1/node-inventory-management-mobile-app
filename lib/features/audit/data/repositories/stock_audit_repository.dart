import 'package:dio/dio.dart' show Dio, DioException;
import '../../../../core/network/api_endpoints.dart';
import '../models/stock_audit.dart';

class StockAuditRepository {
  final Dio _dio;

  StockAuditRepository(this._dio);

  // ── Helpers ──────────────────────────────────────────────────────────────────

  dynamic _dataOf(Map<String, dynamic> resp) {
    if (resp['status'] == 'failure') {
      final msg = resp['message']?.toString() ?? 'Request failed';
      throw Exception(msg);
    }
    return resp['data'];
  }

  // ── APIs ─────────────────────────────────────────────────────────────────────

  Future<StockAuditDetail> getStockAuditDetail(String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.stockAuditDetail(id));
      final data = _dataOf(resp.data as Map<String, dynamic>);
      return StockAuditDetail.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message'] ?? e.message)
          : e.message;
      throw Exception(msg);
    }
  }

  Future<StockAuditDetail> initiateAudit(String id) async {
    try {
      final resp = await _dio.patch(ApiEndpoints.initiateStockAudit(id));
      final data = _dataOf(resp.data as Map<String, dynamic>);
      return StockAuditDetail.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message'] ?? e.message)
          : e.message;
      throw Exception(msg);
    }
  }

  Future<({List<AuditLineItem> items, int currentPage, int totalPages, int totalCount})>
      getLineItems(String auditId, {int page = 1}) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.stockAuditLineItems(auditId),
        queryParameters: {'page': page},
      );
      final data = _dataOf(resp.data as Map<String, dynamic>);
      final dataMap = Map<String, dynamic>.from(data as Map);
      final rawItems = (dataMap['line_items'] as List?) ?? [];
      final items = rawItems
          .whereType<Map>()
          .map((m) => AuditLineItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      final meta = dataMap['meta'] as Map? ?? {};
      return (
        items: items,
        currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
        totalPages: (meta['total_pages'] as num?)?.toInt() ?? 1,
        totalCount: (meta['total_count'] as num?)?.toInt() ?? items.length,
      );
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message'] ?? e.message)
          : e.message;
      throw Exception(msg);
    }
  }

  Future<List<AuditBatch>> getBatchesForSku(String auditId, String skuId) async {
    try {
      final resp = await _dio.get(ApiEndpoints.stockAuditSkuBatches(auditId, skuId));
      final data = _dataOf(resp.data as Map<String, dynamic>);
      final dataMap = Map<String, dynamic>.from(data as Map);
      final raw = (dataMap['batches'] as List?) ?? [];
      return raw
          .whereType<Map>()
          .map((m) => AuditBatch.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message'] ?? e.message)
          : e.message;
      throw Exception(msg);
    }
  }

  Future<List<AuditSerial>> getSerialsForSku(String auditId, String skuId) async {
    try {
      final resp = await _dio.get(ApiEndpoints.stockAuditSkuSerials(auditId, skuId));
      final data = _dataOf(resp.data as Map<String, dynamic>);
      final dataMap = Map<String, dynamic>.from(data as Map);
      final raw = (dataMap['serials'] as List?) ?? [];
      return raw
          .whereType<Map>()
          .map((m) => AuditSerial.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message'] ?? e.message)
          : e.message;
      throw Exception(msg);
    }
  }

  Future<AuditLineItem> countSku(
    String auditId,
    String skuId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.patch(
        ApiEndpoints.stockAuditCountSku(auditId, skuId),
        data: payload,
      );
      final data = _dataOf(resp.data as Map<String, dynamic>);
      return AuditLineItem.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message'] ?? e.message)
          : e.message;
      throw Exception(msg);
    }
  }

  Future<StockAuditDetail> sendForReview(String id) async {
    try {
      final resp = await _dio.patch(ApiEndpoints.sendStockAuditForReview(id));
      final data = _dataOf(resp.data as Map<String, dynamic>);
      return StockAuditDetail.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message'] ?? e.message)
          : e.message;
      throw Exception(msg);
    }
  }
}
