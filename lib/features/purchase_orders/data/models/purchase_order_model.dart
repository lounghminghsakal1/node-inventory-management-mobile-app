class VendorModel {
  final int id;
  final String firmName;
  final String code;
  final String status;

  const VendorModel({
    required this.id,
    required this.firmName,
    required this.code,
    required this.status,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] ?? 0,
      firmName: json['firm_name'] ?? json['name'] ?? '',
      code: json['code'] ?? '',
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firm_name': firmName,
      'code': code,
      'status': status,
    };
  }
}

class PurchaseOrderLineItemModel {
  final int id;
  final int productSkuId;
  final String skuName;
  final String skuCode;
  final String trackingType; // 'batch', 'serial', 'untracked'
  final int orderedQuantity;
  final String unitPrice;
  final int receivedQuantity;

  const PurchaseOrderLineItemModel({
    required this.id,
    required this.productSkuId,
    required this.skuName,
    required this.skuCode,
    required this.trackingType,
    required this.orderedQuantity,
    required this.unitPrice,
    this.receivedQuantity = 0,
  });

  int get remainingQuantity => orderedQuantity - receivedQuantity;

  factory PurchaseOrderLineItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderLineItemModel(
      id: json['id'] ?? 0,
      productSkuId: json['product_sku_id'] ?? 0,
      skuName: json['sku_name'] ?? '',
      skuCode: json['sku_code'] ?? '',
      trackingType: json['tracking_type'] ?? 'untracked',
      orderedQuantity: json['ordered_quantity'] ?? json['quantity'] ?? 0,
      unitPrice: json['unit_price']?.toString() ?? '0.0',
      receivedQuantity: json['received_quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_sku_id': productSkuId,
      'sku_name': skuName,
      'sku_code': skuCode,
      'tracking_type': trackingType,
      'ordered_quantity': orderedQuantity,
      'unit_price': unitPrice,
      'received_quantity': receivedQuantity,
    };
  }

  PurchaseOrderLineItemModel copyWith({
    int? id,
    int? productSkuId,
    String? skuName,
    String? skuCode,
    String? trackingType,
    int? orderedQuantity,
    String? unitPrice,
    int? receivedQuantity,
  }) {
    return PurchaseOrderLineItemModel(
      id: id ?? this.id,
      productSkuId: productSkuId ?? this.productSkuId,
      skuName: skuName ?? this.skuName,
      skuCode: skuCode ?? this.skuCode,
      trackingType: trackingType ?? this.trackingType,
      orderedQuantity: orderedQuantity ?? this.orderedQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
    );
  }
}

class PoSkuItemModel {
  final int id;
  final int productSkuId;
  final String skuName;
  final String skuCode;
  final int totalUnits;
  final String selectionType; // 'LIFO', 'FIFO'
  final String trackingType; // 'serial', 'batch', 'untracked'
  final int fulfilledQuantity;
  final bool fullyFulfilled;

  const PoSkuItemModel({
    required this.id,
    required this.productSkuId,
    required this.skuName,
    required this.skuCode,
    required this.totalUnits,
    required this.selectionType,
    required this.trackingType,
    required this.fulfilledQuantity,
    required this.fullyFulfilled,
  });

  int get remainingQuantity => totalUnits - fulfilledQuantity;

  factory PoSkuItemModel.fromJson(Map<String, dynamic> json) {
    return PoSkuItemModel(
      id: json['id'] ?? 0,
      productSkuId: json['product_sku_id'] ?? 0,
      skuName: json['sku_name'] ?? '',
      skuCode: json['sku_code'] ?? '',
      totalUnits: json['total_units'] ?? 0,
      selectionType: json['selection_type'] ?? 'FIFO',
      trackingType: json['tracking_type'] ?? 'untracked',
      fulfilledQuantity: json['fulfilled_quantity'] ?? 0,
      fullyFulfilled: json['fully_fulfilled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_sku_id': productSkuId,
      'sku_name': skuName,
      'sku_code': skuCode,
      'total_units': totalUnits,
      'selection_type': selectionType,
      'tracking_type': trackingType,
      'fulfilled_quantity': fulfilledQuantity,
      'fully_fulfilled': fullyFulfilled,
    };
  }
}

class PurchaseOrderModel {
  final int id;
  final String purchaseOrderNumber;
  final String status;
  final String? expiryDate;
  final String? deliveryDate;
  final int totalUnits;
  final VendorModel vendor;
  final List<PurchaseOrderLineItemModel> lineItems;

  const PurchaseOrderModel({
    required this.id,
    required this.purchaseOrderNumber,
    required this.status,
    this.expiryDate,
    this.deliveryDate,
    required this.totalUnits,
    required this.vendor,
    this.lineItems = const [],
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      id: json['id'] ?? 0,
      purchaseOrderNumber: json['purchase_order_number'] ?? '',
      status: json['status'] ?? '',
      expiryDate: json['expiry_date']?.toString(),
      deliveryDate: json['delivery_date']?.toString(),
      totalUnits: json['total_units'] ?? 0,
      vendor: VendorModel.fromJson(json['vendor'] ?? {}),
      lineItems: (json['line_items'] as List?)
              ?.map((e) => PurchaseOrderLineItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class GrnBatchModel {
  final int quantity;
  final String batchCode;
  final String? expiryDate;
  final String? manufactureDate;

  const GrnBatchModel({
    required this.quantity,
    required this.batchCode,
    this.expiryDate,
    this.manufactureDate,
  });

  factory GrnBatchModel.fromJson(Map<String, dynamic> json) {
    return GrnBatchModel(
      quantity: json['quantity'] ?? 0,
      batchCode: json['batch_code'] ?? '',
      expiryDate: json['expiry_date']?.toString(),
      manufactureDate: json['manufacture_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'batch_code': batchCode,
      'expiry_date': expiryDate,
      'manufacture_date': manufactureDate,
    };
  }

  GrnBatchModel copyWith({
    int? quantity,
    String? batchCode,
    String? expiryDate,
    String? manufactureDate,
  }) {
    return GrnBatchModel(
      quantity: quantity ?? this.quantity,
      batchCode: batchCode ?? this.batchCode,
      expiryDate: expiryDate ?? this.expiryDate,
      manufactureDate: manufactureDate ?? this.manufactureDate,
    );
  }
}

class GrnLineItemModel {
  final int id;
  final int productSkuId;
  final String skuName;
  final String skuCode;
  final String trackingType;
  final int receivedQuantity;
  final int acceptedQuantity;
  final int rejectedQuantity;
  final String unitPrice;
  final String receivedAmount;
  final String acceptedAmount;
  final String rejectedAmount;
  final String taxableAmount;
  final String taxAmount;
  final String cgstAmount;
  final String sgstAmount;
  final String igstAmount;
  final double finalAmount;
  final List<GrnBatchModel> receivedBatches;
  final List<String> receivedSerials;
  final List<GrnBatchModel> acceptedBatches;
  final List<String> acceptedSerials;
  final List<GrnBatchModel> rejectedBatches;
  final List<String> rejectedSerials;
  final String? rejectionReason;

  const GrnLineItemModel({
    required this.id,
    required this.productSkuId,
    required this.skuName,
    required this.skuCode,
    required this.trackingType,
    required this.receivedQuantity,
    required this.acceptedQuantity,
    required this.rejectedQuantity,
    this.unitPrice = '1000.0',
    this.receivedAmount = '0.0',
    this.acceptedAmount = '0.0',
    this.rejectedAmount = '0.0',
    this.taxableAmount = '0.0',
    this.taxAmount = '0.0',
    this.cgstAmount = '0.0',
    this.sgstAmount = '0.0',
    this.igstAmount = '0.0',
    this.finalAmount = 0.0,
    required this.receivedBatches,
    required this.receivedSerials,
    required this.acceptedBatches,
    required this.acceptedSerials,
    required this.rejectedBatches,
    required this.rejectedSerials,
    this.rejectionReason,
  });

  factory GrnLineItemModel.fromJson(Map<String, dynamic> json) {
    return GrnLineItemModel(
      id: json['id'] ?? 0,
      productSkuId: json['product_sku_id'] ?? 0,
      skuName: json['sku_name'] ?? '',
      skuCode: json['sku_code'] ?? '',
      trackingType: json['tracking_type'] ?? 'untracked',
      receivedQuantity: json['received_quantity'] ?? 0,
      acceptedQuantity: json['accepted_quantity'] ?? 0,
      rejectedQuantity: json['rejected_quantity'] ?? 0,
      unitPrice: json['unit_price']?.toString() ?? '1000.0',
      receivedAmount: json['received_amount']?.toString() ?? '0.0',
      acceptedAmount: json['accepted_amount']?.toString() ?? '0.0',
      rejectedAmount: json['rejected_amount']?.toString() ?? '0.0',
      taxableAmount: json['taxable_amount']?.toString() ?? '0.0',
      taxAmount: json['tax_amount']?.toString() ?? '0.0',
      cgstAmount: json['cgst_amount']?.toString() ?? '0.0',
      sgstAmount: json['sgst_amount']?.toString() ?? '0.0',
      igstAmount: json['igst_amount']?.toString() ?? '0.0',
      finalAmount: (json['final_amount'] as num?)?.toDouble() ?? 0.0,
      receivedBatches: (json['received_batches'] as List?)
              ?.map((e) => GrnBatchModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      receivedSerials: (json['received_serials'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      acceptedBatches: (json['accepted_batches'] as List?)
              ?.map((e) => GrnBatchModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      acceptedSerials: (json['accepted_serials'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rejectedBatches: (json['rejected_batches'] as List?)
              ?.map((e) => GrnBatchModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rejectedSerials: (json['rejected_serials'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_sku_id': productSkuId,
      'sku_name': skuName,
      'sku_code': skuCode,
      'tracking_type': trackingType,
      'received_quantity': receivedQuantity,
      'accepted_quantity': acceptedQuantity,
      'rejected_quantity': rejectedQuantity,
      'unit_price': unitPrice,
      'received_amount': receivedAmount,
      'accepted_amount': acceptedAmount,
      'rejected_amount': rejectedAmount,
      'taxable_amount': taxableAmount,
      'tax_amount': taxAmount,
      'cgst_amount': cgstAmount,
      'sgst_amount': sgstAmount,
      'igst_amount': igstAmount,
      'final_amount': finalAmount,
      'rejection_reason': rejectionReason,
      'received_batches': receivedBatches.isEmpty ? null : receivedBatches.map((b) => b.toJson()).toList(),
      'received_serials': receivedSerials.isEmpty ? null : receivedSerials,
      'accepted_batches': acceptedBatches.isEmpty ? null : acceptedBatches.map((b) => b.toJson()).toList(),
      'accepted_serials': acceptedSerials.isEmpty ? null : acceptedSerials,
      'rejected_batches': rejectedBatches.isEmpty ? null : rejectedBatches.map((b) => b.toJson()).toList(),
      'rejected_serials': rejectedSerials.isEmpty ? null : rejectedSerials,
    };
  }

  GrnLineItemModel copyWith({
    int? id,
    int? productSkuId,
    String? skuName,
    String? skuCode,
    String? trackingType,
    int? receivedQuantity,
    int? acceptedQuantity,
    int? rejectedQuantity,
    String? unitPrice,
    String? receivedAmount,
    String? acceptedAmount,
    String? rejectedAmount,
    String? taxableAmount,
    String? taxAmount,
    String? cgstAmount,
    String? sgstAmount,
    String? igstAmount,
    double? finalAmount,
    List<GrnBatchModel>? receivedBatches,
    List<String>? receivedSerials,
    List<GrnBatchModel>? acceptedBatches,
    List<String>? acceptedSerials,
    List<GrnBatchModel>? rejectedBatches,
    List<String>? rejectedSerials,
    String? rejectionReason,
  }) {
    return GrnLineItemModel(
      id: id ?? this.id,
      productSkuId: productSkuId ?? this.productSkuId,
      skuName: skuName ?? this.skuName,
      skuCode: skuCode ?? this.skuCode,
      trackingType: trackingType ?? this.trackingType,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      acceptedQuantity: acceptedQuantity ?? this.acceptedQuantity,
      rejectedQuantity: rejectedQuantity ?? this.rejectedQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      acceptedAmount: acceptedAmount ?? this.acceptedAmount,
      rejectedAmount: rejectedAmount ?? this.rejectedAmount,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      receivedBatches: receivedBatches ?? this.receivedBatches,
      receivedSerials: receivedSerials ?? this.receivedSerials,
      acceptedBatches: acceptedBatches ?? this.acceptedBatches,
      acceptedSerials: acceptedSerials ?? this.acceptedSerials,
      rejectedBatches: rejectedBatches ?? this.rejectedBatches,
      rejectedSerials: rejectedSerials ?? this.rejectedSerials,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

class GrnModel {
  final int id;
  final String grnNumber;
  final String status;
  final bool directGrn;
  final String? vendorInvoiceDate;
  final String? vendorInvoiceNo;
  final String? receivedDate;
  final double finalAmount;
  final int totalReceivedQuantity;
  final int totalAcceptedQuantity;
  final int totalRejectedQuantity;
  final String totalReceivedAmount;
  final String totalAcceptedAmount;
  final String totalRejectedAmount;
  final String taxableAmount;
  final String taxAmount;
  final String cgstAmount;
  final String sgstAmount;
  final String igstAmount;
  final String? vendorInvoiceS3Url;
  final int vendorId;
  final String vendorName;
  final String vendorType;
  final int nodeId;
  final String nodeName;
  final int purchaseOrderId;
  final String purchaseOrderNumber;
  final int createdById;
  final String createdByName;
  final String createdByEmail;
  final List<GrnLineItemModel> lineItems;

  const GrnModel({
    required this.id,
    required this.grnNumber,
    required this.status,
    required this.directGrn,
    this.vendorInvoiceDate,
    this.vendorInvoiceNo,
    this.receivedDate,
    this.finalAmount = 0.0,
    required this.totalReceivedQuantity,
    required this.totalAcceptedQuantity,
    required this.totalRejectedQuantity,
    this.totalReceivedAmount = '0.0',
    this.totalAcceptedAmount = '0.0',
    this.totalRejectedAmount = '0.0',
    this.taxableAmount = '0.0',
    this.taxAmount = '0.0',
    this.cgstAmount = '0.0',
    this.sgstAmount = '0.0',
    this.igstAmount = '0.0',
    this.vendorInvoiceS3Url,
    this.vendorId = 23,
    required this.vendorName,
    this.vendorType = 'manufacturer',
    this.nodeId = 8,
    required this.nodeName,
    this.purchaseOrderId = 132,
    required this.purchaseOrderNumber,
    this.createdById = 14,
    required this.createdByName,
    this.createdByEmail = 'lounghminghsakal@flaerhomes.com',
    this.lineItems = const [],
  });

  factory GrnModel.fromJson(Map<String, dynamic> json) {
    final vendorObj = json['vendor'] as Map<String, dynamic>? ?? {};
    final nodeObj = json['node'] as Map<String, dynamic>? ?? {};
    final poObj = json['purchase_order'] as Map<String, dynamic>? ?? {};
    final creatorObj = json['created_by'] as Map<String, dynamic>? ?? {};

    return GrnModel(
      id: json['id'] ?? 0,
      grnNumber: json['grn_number'] ?? '',
      status: json['status'] ?? '',
      directGrn: json['direct_grn'] ?? false,
      vendorInvoiceDate: json['vendor_invoice_date']?.toString(),
      vendorInvoiceNo: json['vendor_invoice_no']?.toString(),
      receivedDate: json['received_date']?.toString(),
      finalAmount: (json['final_amount'] as num?)?.toDouble() ?? 0.0,
      totalReceivedQuantity: json['total_received_quantity'] ?? 0,
      totalAcceptedQuantity: json['total_accepted_quantity'] ?? 0,
      totalRejectedQuantity: json['total_rejected_quantity'] ?? 0,
      totalReceivedAmount: json['total_received_amount']?.toString() ?? '0.0',
      totalAcceptedAmount: json['total_accepted_amount']?.toString() ?? '0.0',
      totalRejectedAmount: json['total_rejected_amount']?.toString() ?? '0.0',
      taxableAmount: json['taxable_amount']?.toString() ?? '0.0',
      taxAmount: json['tax_amount']?.toString() ?? '0.0',
      cgstAmount: json['cgst_amount']?.toString() ?? '0.0',
      sgstAmount: json['sgst_amount']?.toString() ?? '0.0',
      igstAmount: json['igst_amount']?.toString() ?? '0.0',
      vendorInvoiceS3Url: json['vendor_invoice_s3_url']?.toString(),
      vendorId: vendorObj['id'] ?? 23,
      vendorName: vendorObj['name'] ?? vendorObj['firm_name'] ?? '',
      vendorType: vendorObj['vendor_type'] ?? 'manufacturer',
      nodeId: nodeObj['id'] ?? 8,
      nodeName: nodeObj['name'] ?? '',
      purchaseOrderId: poObj['id'] ?? 132,
      purchaseOrderNumber: poObj['purchase_order_number'] ?? '',
      createdById: creatorObj['id'] ?? 14,
      createdByName: creatorObj['name'] ?? '',
      createdByEmail: creatorObj['email'] ?? 'lounghminghsakal@flaerhomes.com',
      lineItems: (json['line_items'] as List?)
              ?.map((e) => GrnLineItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "grn_number": grnNumber,
      "status": status,
      "direct_grn": directGrn,
      "vendor_invoice_date": vendorInvoiceDate,
      "vendor_invoice_no": vendorInvoiceNo,
      "received_date": receivedDate,
      "final_amount": finalAmount,
      "total_received_quantity": totalReceivedQuantity,
      "total_accepted_quantity": totalAcceptedQuantity,
      "total_rejected_quantity": totalRejectedQuantity,
      "total_received_amount": totalReceivedAmount,
      "total_accepted_amount": totalAcceptedAmount,
      "total_rejected_amount": totalRejectedAmount,
      "taxable_amount": taxableAmount,
      "tax_amount": taxAmount,
      "cgst_amount": cgstAmount,
      "sgst_amount": sgstAmount,
      "igst_amount": igstAmount,
      "vendor_invoice_s3_url": vendorInvoiceS3Url,
      "vendor": {
        "id": vendorId,
        "name": vendorName,
        "vendor_type": vendorType
      },
      "node": {
        "id": nodeId,
        "name": nodeName
      },
      "purchase_order": {
        "id": purchaseOrderId,
        "purchase_order_number": purchaseOrderNumber
      },
      "created_by": {
        "id": createdById,
        "name": createdByName,
        "email": createdByEmail
      },
      "line_items": lineItems.map((li) => li.toJson()).toList()
    };
  }

  GrnModel copyWith({
    int? id,
    String? grnNumber,
    String? status,
    bool? directGrn,
    String? vendorInvoiceDate,
    String? vendorInvoiceNo,
    String? receivedDate,
    double? finalAmount,
    int? totalReceivedQuantity,
    int? totalAcceptedQuantity,
    int? totalRejectedQuantity,
    String? totalReceivedAmount,
    String? totalAcceptedAmount,
    String? totalRejectedAmount,
    String? taxableAmount,
    String? taxAmount,
    String? cgstAmount,
    String? sgstAmount,
    String? igstAmount,
    String? vendorInvoiceS3Url,
    int? vendorId,
    String? vendorName,
    String? vendorType,
    int? nodeId,
    String? nodeName,
    int? purchaseOrderId,
    String? purchaseOrderNumber,
    int? createdById,
    String? createdByName,
    String? createdByEmail,
    List<GrnLineItemModel>? lineItems,
  }) {
    return GrnModel(
      id: id ?? this.id,
      grnNumber: grnNumber ?? this.grnNumber,
      status: status ?? this.status,
      directGrn: directGrn ?? this.directGrn,
      vendorInvoiceDate: vendorInvoiceDate ?? this.vendorInvoiceDate,
      vendorInvoiceNo: vendorInvoiceNo ?? this.vendorInvoiceNo,
      receivedDate: receivedDate ?? this.receivedDate,
      finalAmount: finalAmount ?? this.finalAmount,
      totalReceivedQuantity: totalReceivedQuantity ?? this.totalReceivedQuantity,
      totalAcceptedQuantity: totalAcceptedQuantity ?? this.totalAcceptedQuantity,
      totalRejectedQuantity: totalRejectedQuantity ?? this.totalRejectedQuantity,
      totalReceivedAmount: totalReceivedAmount ?? this.totalReceivedAmount,
      totalAcceptedAmount: totalAcceptedAmount ?? this.totalAcceptedAmount,
      totalRejectedAmount: totalRejectedAmount ?? this.totalRejectedAmount,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      vendorInvoiceS3Url: vendorInvoiceS3Url ?? this.vendorInvoiceS3Url,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorType: vendorType ?? this.vendorType,
      nodeId: nodeId ?? this.nodeId,
      nodeName: nodeName ?? this.nodeName,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      lineItems: lineItems ?? this.lineItems,
    );
  }
}
