class InventoryNodeModel {
  final int id;
  final String name;

  const InventoryNodeModel({
    required this.id,
    required this.name,
  });

  factory InventoryNodeModel.fromJson(Map<String, dynamic> json) {
    return InventoryNodeModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Unknown Node',
    );
  }
}

class InventoryProductSkuModel {
  final int id;
  final String skuName;
  final String skuCode;

  const InventoryProductSkuModel({
    required this.id,
    required this.skuName,
    required this.skuCode,
  });

  factory InventoryProductSkuModel.fromJson(Map<String, dynamic> json) {
    return InventoryProductSkuModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      skuName: json['sku_name']?.toString() ?? 'Unknown SKU',
      skuCode: json['sku_code']?.toString() ?? 'N/A',
    );
  }
}

class InventoryBatchModel {
  final int id;
  final String batchCode;
  final String? manufacturingDate;
  final String? expiryDate;

  const InventoryBatchModel({
    required this.id,
    required this.batchCode,
    this.manufacturingDate,
    this.expiryDate,
  });

  factory InventoryBatchModel.fromJson(Map<String, dynamic> json) {
    return InventoryBatchModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      batchCode: json['batch_code']?.toString() ?? 'N/A',
      manufacturingDate: json['manufacturing_date']?.toString(),
      expiryDate: json['expiry_date']?.toString(),
    );
  }
}

class InventoryMetaModel {
  final int currentPage;
  final int totalPages;
  final int totalCount;

  const InventoryMetaModel({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  factory InventoryMetaModel.fromJson(Map<String, dynamic> json) {
    return InventoryMetaModel(
      currentPage: int.tryParse(json['current_page']?.toString() ?? '1') ?? 1,
      totalPages: int.tryParse(json['total_pages']?.toString() ?? '1') ?? 1,
      totalCount: int.tryParse(json['total_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class BatchInventoryModel {
  final int id;
  final int totalQuantity;
  final int availableQuantity;
  final int blockedQuantity;
  final int inTransitQuantity;
  final int damagedQuantity;
  final int missingQuantity;
  final InventoryNodeModel? node;
  final InventoryProductSkuModel? productSku;
  final InventoryBatchModel? batch;

  const BatchInventoryModel({
    required this.id,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.blockedQuantity,
    required this.inTransitQuantity,
    required this.damagedQuantity,
    required this.missingQuantity,
    this.node,
    this.productSku,
    this.batch,
  });

  factory BatchInventoryModel.fromJson(Map<String, dynamic> json) {
    return BatchInventoryModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      totalQuantity: int.tryParse(json['total_quantity']?.toString() ?? '0') ?? 0,
      availableQuantity: int.tryParse(json['available_quantity']?.toString() ?? '0') ?? 0,
      blockedQuantity: int.tryParse(json['blocked_quantity']?.toString() ?? '0') ?? 0,
      inTransitQuantity: int.tryParse(json['in_transit_quantity']?.toString() ?? '0') ?? 0,
      damagedQuantity: int.tryParse(json['damaged_quantity']?.toString() ?? '0') ?? 0,
      missingQuantity: int.tryParse(json['missing_quantity']?.toString() ?? '0') ?? 0,
      node: json['node'] is Map<String, dynamic> ? InventoryNodeModel.fromJson(json['node']) : null,
      productSku: json['product_sku'] is Map<String, dynamic> ? InventoryProductSkuModel.fromJson(json['product_sku']) : null,
      batch: json['batch'] is Map<String, dynamic> ? InventoryBatchModel.fromJson(json['batch']) : null,
    );
  }
}

class BatchInventoryTransactionModel {
  final int id;
  final String adjustmentType;
  final int quantity;
  final Map<String, dynamic> transactionDetails;
  final Map<String, dynamic>? sourceDetails;
  final Map<String, dynamic>? destinationDetails;

  const BatchInventoryTransactionModel({
    required this.id,
    required this.adjustmentType,
    required this.quantity,
    required this.transactionDetails,
    this.sourceDetails,
    this.destinationDetails,
  });

  factory BatchInventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    return BatchInventoryTransactionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      adjustmentType: json['adjustment_type']?.toString() ?? 'N/A',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      transactionDetails: json['inventory_transaction_details'] is Map<String, dynamic>
          ? (json['inventory_transaction_details'] as Map<String, dynamic>)
          : {},
      sourceDetails: json['source_details'] is Map<String, dynamic> ? (json['source_details'] as Map<String, dynamic>) : null,
      destinationDetails: json['destination_details'] is Map<String, dynamic> ? (json['destination_details'] as Map<String, dynamic>) : null,
    );
  }
}

class BatchInventoryListResponse {
  final List<BatchInventoryModel> batchInventories;
  final InventoryMetaModel meta;

  const BatchInventoryListResponse({
    required this.batchInventories,
    required this.meta,
  });

  factory BatchInventoryListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['batch_inventories'] as List?)?.map((e) => BatchInventoryModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    final metaObj = json['meta'] is Map<String, dynamic>
        ? InventoryMetaModel.fromJson(json['meta'])
        : const InventoryMetaModel(currentPage: 1, totalPages: 1, totalCount: 0);
    return BatchInventoryListResponse(batchInventories: list, meta: metaObj);
  }
}

class BatchInventoryTransactionsResponse {
  final Map<String, dynamic> batchInventorySummary;
  final List<BatchInventoryTransactionModel> transactions;
  final InventoryMetaModel meta;

  const BatchInventoryTransactionsResponse({
    required this.batchInventorySummary,
    required this.transactions,
    required this.meta,
  });

  factory BatchInventoryTransactionsResponse.fromJson(Map<String, dynamic> json) {
    final summary = json['batch_inventory'] is Map<String, dynamic> ? (json['batch_inventory'] as Map<String, dynamic>) : <String, dynamic>{};
    final list = (json['transactions'] as List?)?.map((e) => BatchInventoryTransactionModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    final metaObj = json['meta'] is Map<String, dynamic>
        ? InventoryMetaModel.fromJson(json['meta'])
        : const InventoryMetaModel(currentPage: 1, totalPages: 1, totalCount: 0);
    return BatchInventoryTransactionsResponse(
      batchInventorySummary: summary,
      transactions: list,
      meta: metaObj,
    );
  }
}
