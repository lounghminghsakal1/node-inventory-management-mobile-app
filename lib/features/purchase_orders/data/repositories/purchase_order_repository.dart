import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrderRepository {
  final Dio _dio;

  PurchaseOrderRepository(this._dio);

  Future<List<PurchaseOrderModel>> getPurchaseOrders({
    String? byVendorName,
    int? byVendorId,
    String? byPoNumber,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{
      if (byVendorName != null && byVendorName.isNotEmpty)
        'by_vendor_name': byVendorName,
      'by_vendor_id': ?byVendorId,
      if (byPoNumber != null && byPoNumber.isNotEmpty)
        'by_po_number': byPoNumber,
      if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
      'page': page,
    };
    final res = await _dio.get(
      ApiEndpoints.purchaseOrders,
      queryParameters: queryParams,
    );
    final data = res.data['data'] as Map<String, dynamic>? ?? {};
    final list = data['purchase_orders'] as List? ?? [];
    return list
        .map((e) => PurchaseOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<
    ({
      List<PurchaseOrderModel> purchaseOrders,
      int currentPage,
      int totalPages,
      int totalCount,
    })
  >
  getPurchaseOrdersApi({
    String? byVendorName,
    int? byVendorId,
    String? byPoNumber,
    String? byStatus,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{
      if (byVendorName != null && byVendorName.isNotEmpty)
        'by_vendor_name': byVendorName,
      'by_vendor_id': ?byVendorId,
      if (byPoNumber != null && byPoNumber.isNotEmpty)
        'by_po_number': byPoNumber,
      if (byStatus != null && byStatus.isNotEmpty) 'by_status': byStatus,
      if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
      'page': page,
    };
    final res = await _dio.get(
      ApiEndpoints.purchaseOrders,
      queryParameters: queryParams,
    );
    final dataMap = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : <String, dynamic>{};
    final data = dataMap['data'] as Map<String, dynamic>? ?? {};
    final list = (data['purchase_orders'] as List? ?? [])
        .map((e) => PurchaseOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta =
        (data['pagination'] as Map<String, dynamic>?) ??
        (data['meta'] as Map<String, dynamic>?) ??
        (dataMap['pagination'] as Map<String, dynamic>?) ??
        (dataMap['meta'] as Map<String, dynamic>?) ??
        {};
    final currentPage = (meta['current_page'] as num?)?.toInt() ?? page;
    final totalPages =
        (meta['total_pages'] as num?)?.toInt() ??
        (list.length >= 10 ? page + 1 : page);
    final totalCount = (meta['total_count'] as num?)?.toInt() ?? list.length;

    return (
      purchaseOrders: list,
      currentPage: currentPage,
      totalPages: totalPages,
      totalCount: totalCount,
    );
  }

  Future<PurchaseOrderModel> getPurchaseOrderById(int id) async {
    final res = await _dio.get(ApiEndpoints.purchaseOrderDetail(id.toString()));
    final data = res.data['data'] as Map<String, dynamic>;
    return PurchaseOrderModel.fromJson(data);
  }

  Future<List<GrnModel>> getGrnsForPo(int poId) async {
    final res = await _dio.get(
      ApiEndpoints.goodsReceivedNotes,
      queryParameters: {'by_po_id': poId},
    );
    final data = res.data['data'] as Map<String, dynamic>? ?? {};
    final list = data['goods_received_notes'] as List? ?? [];
    return list
        .map((e) => GrnModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GrnModel> getGrnDetail(int grnId) async {
    final res = await _dio.get(ApiEndpoints.grnDetail(grnId.toString()));
    final data = res.data['data'] as Map<String, dynamic>;
    return GrnModel.fromJson(data);
  }

  Future<String> uploadGrnDocument(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'vendor_invoice_file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });
    final res = await _dio.post(
      ApiEndpoints.uploadGrnDocument,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    final data = res.data['data'] as Map<String, dynamic>;
    return data['s3_url'] as String;
  }

  Future<GrnModel> createGrn({
    required int poId,
    required String vendorInvoiceDate,
    required String vendorInvoiceNo,
    required String receivedDate,
    List<String>? vendorInvoiceS3Urls,
    String remarks = '',
  }) async {
    final body = {
      'purchase_order_id': poId,
      'received_date': receivedDate,
      'vendor_invoice': vendorInvoiceNo,
      'vendor_invoice_date': vendorInvoiceDate,
      if (remarks.isNotEmpty) 'remarks': remarks,
      if (vendorInvoiceS3Urls != null && vendorInvoiceS3Urls.isNotEmpty)
        'grn_invoice_s3_link': vendorInvoiceS3Urls,
    };
    final res = await _dio.post(ApiEndpoints.createGrn, data: body);
    final data = res.data['data'] as Map<String, dynamic>;
    final newId = data['id'] as int? ?? 0;
    if (newId > 0) {
      try {
        return await getGrnDetail(newId);
      } catch (_) {}
    }
    return GrnModel.fromJson(data);
  }

  Future<GrnModel> updateGrnLineItems(
    int grnId,
    List<GrnLineItemModel> newLineItems,
  ) async {
    final body = {
      "grn_line_items": newLineItems.map((li) {
        return {
          "product_sku_id": li.productSkuId,
          "received_quantity": li.receivedQuantity,
          "new_batches": li.receivedBatches
              .map(
                (b) => {
                  "batch_code": b.batchCode,
                  "quantity": b.quantity,
                  if (b.expiryDate != null && b.expiryDate!.isNotEmpty)
                    "expiry_date": b.expiryDate,
                  if ((b.manufactureDate ?? b.manufacturedDate) != null &&
                      (b.manufactureDate ?? b.manufacturedDate)!.isNotEmpty)
                    "manufacturing_date":
                        b.manufactureDate ?? b.manufacturedDate,
                },
              )
              .toList(),
          "serial": li.receivedSerials,
          if (li.photoUrls.isNotEmpty) "photo_urls": li.photoUrls,
        };
      }).toList(),
    };
    final res = await _dio.post(
      ApiEndpoints.saveGrnLineItems(grnId.toString()),
      data: body,
    );
    if (res.data is Map<String, dynamic>) {
      final status = res.data['status']?.toString().toLowerCase();
      if (status != null && status != 'success' && status != 'ok') {
        throw Exception(
          res.data['message'] ??
              res.data['error'] ??
              'Failed to update GRN line items',
        );
      }
    }
    return await getGrnDetail(grnId);
  }

  Future<void> uploadGrnLineItemPhotos(
    int grnId,
    List<Map<String, dynamic>> items,
  ) async {
    final body = {"grn_line_items": items};
    print("kkfv d f $body");
    final res = await _dio.patch(
      ApiEndpoints.uploadGrnLineItemsPhotos(grnId.toString()),
      data: body,
    );
    if (res.data is Map<String, dynamic>) {
      final status = res.data['status']?.toString().toLowerCase();
      if (status != null && status != 'success' && status != 'ok') {
        throw Exception(
          res.data['message'] ?? res.data['error'] ?? 'Failed to upload photos',
        );
      }
    }
  }

  Future<GrnModel> updateGrnStatus(int grnId, String newStatus) async {
    Response? res;
    if (newStatus == 'qc_pending') {
      res = await _dio.put(ApiEndpoints.initiateQc(grnId.toString()));
    }
    if (res != null && res.data is Map<String, dynamic>) {
      final status = res.data['status']?.toString().toLowerCase();
      if (status != null && status != 'success' && status != 'ok') {
        throw Exception(
          res.data['message'] ?? res.data['error'] ?? 'Failed to update status',
        );
      }
    }
    return await getGrnDetail(grnId);
  }

  Future<GrnModel> submitGrnQc(
    int grnId,
    List<GrnLineItemModel> qcLineItems,
  ) async {
    final body = {
      "grn_line_items": qcLineItems.map((li) {
        final acceptedBatchesMap = <String, int>{};
        for (final b in li.acceptedBatches) {
          if (b.batchCode.isNotEmpty && b.quantity > 0) {
            acceptedBatchesMap[b.batchCode] = b.quantity;
          }
        }
        final rejectedBatchesMap = <String, int>{};
        for (final b in li.rejectedBatches) {
          if (b.batchCode.isNotEmpty && b.quantity > 0) {
            rejectedBatchesMap[b.batchCode] = b.quantity;
          }
        }
        return {
          "goods_received_note_id": grnId,
          "product_sku_id": li.productSkuId,
          "accepted_quantity": li.acceptedQuantity,
          "rejected_quantity": li.rejectedQuantity,
          if (li.rejectionReason != null && li.rejectionReason!.isNotEmpty)
            "rejection_reason": li.rejectionReason,
          "accepted_batch_codes": acceptedBatchesMap,
          "rejected_batch_codes": rejectedBatchesMap,
          "accepted_serials": li.acceptedSerials,
          "rejected_serials": li.rejectedSerials,
        };
      }).toList(),
    };
    final res = await _dio.post(
      ApiEndpoints.saveQcLineItems(grnId.toString()),
      data: body,
    );
    if (res.data is Map<String, dynamic>) {
      final status = res.data['status']?.toString().toLowerCase();
      if (status != null && status != 'success' && status != 'ok') {
        throw Exception(
          res.data['message'] ?? res.data['error'] ?? 'Failed to submit QC',
        );
      }
    }
    return await getGrnDetail(grnId);
  }

  Future<void> deleteGrnLineItem(int grnId, int grnLineItemId) async {
    final res = await _dio.delete(
      ApiEndpoints.deleteGrnLineItem(
        grnId.toString(),
        grnLineItemId.toString(),
      ),
    );
    if (res.data is Map<String, dynamic>) {
      final status = res.data['status']?.toString().toLowerCase();
      if (status != null && status != 'success' && status != 'ok') {
        throw Exception(
          res.data['message'] ??
              res.data['error'] ??
              'Failed to delete GRN line item',
        );
      }
    }
  }

  Future<List<PoSkuItemModel>> getPurchaseOrderSkuItems(
    int poId, [
    int? grnId,
  ]) async {
    final res = await _dio.get(
      ApiEndpoints.poReceivingSummary(poId.toString(), grnId?.toString()),
    );
    final data = res.data['data'] as Map<String, dynamic>? ?? {};
    final list = data['line_items'] as List? ?? [];
    return list
        .map((e) => PoSkuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> validateSerial(
    String serialNumber, [
    int productSkuId = 0,
  ]) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.verifySerial(serialNumber, productSkuId.toString()),
      );
      if (res.data['status'] == 'success') {
        final data = res.data['data'] as Map<String, dynamic>? ?? {};
        return data['valid'] == true || res.data['message'] != null;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkSerialExists(
    String serialNumber, [
    int productSkuId = 0,
  ]) async {
    return !await validateSerial(serialNumber, productSkuId);
  }
}
