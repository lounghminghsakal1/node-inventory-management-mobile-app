class NodeInventoryModel {
  final int id;
  final int productSkuId;
  final String skuName;
  final String skuCode;
  final String trackingType;
  final int totalQuantity;
  final int availableQuantity;
  final int blockedQuantity;
  final int inTransitQuantity;
  final int damagedQuantity;
  final int missingQuantity;

  const NodeInventoryModel({
    required this.id,
    required this.productSkuId,
    required this.skuName,
    required this.skuCode,
    required this.trackingType,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.blockedQuantity,
    required this.inTransitQuantity,
    required this.damagedQuantity,
    required this.missingQuantity,
  });

  factory NodeInventoryModel.fromJson(Map<String, dynamic> json) {
    final productSku = json['product_sku'] is Map ? json['product_sku'] as Map : null;
    return NodeInventoryModel(
      id: json['id'] ?? 0,
      productSkuId: json['product_sku_id'] ?? 0,
      skuName: (productSku?['sku_name'] ?? json['sku_name'] ?? '').toString(),
      skuCode: (productSku?['sku_code'] ?? json['sku_code'] ?? '').toString(),
      trackingType: (json['tracking_type'] ?? 'untracked').toString(),
      totalQuantity: json['total_quantity'] ?? 0,
      availableQuantity: json['available_quantity'] ?? 0,
      blockedQuantity: json['blocked_quantity'] ?? 0,
      inTransitQuantity: json['in_transit_quantity'] ?? 0,
      damagedQuantity: json['damaged_quantity'] ?? 0,
      missingQuantity: json['missing_quantity'] ?? 0,
    );
  }
}

class InventoryTransactionDetailsModel {
  final String transactionType;
  final String referenceNumber;
  final int id;
  final String completedDate;
  final bool isDirectGrn;

  const InventoryTransactionDetailsModel({
    required this.transactionType,
    required this.referenceNumber,
    required this.id,
    required this.completedDate,
    this.isDirectGrn = false,
  });

  factory InventoryTransactionDetailsModel.fromJson(Map<String, dynamic> json) {
    return InventoryTransactionDetailsModel(
      transactionType: json['transaction_type']?.toString() ?? '',
      referenceNumber: (json['grn_number'] ??
              json['shipment_number'] ??
              json['order_number'] ??
              json['reference_number'] ??
              json['invoice_code'] ??
              '')
          .toString(),
      id: int.tryParse(json['id']?.toString() ?? '0') ?? (json['id'] is int ? json['id'] : 0),
      completedDate: json['completed_date']?.toString() ?? '',
      isDirectGrn: json['is_direct_grn'] == true || json['is_direct_grn'] == 'true',
    );
  }
}

class TransactionPartyDetailsModel {
  final String name;
  final String code;
  final int id;

  const TransactionPartyDetailsModel({
    required this.name,
    required this.code,
    required this.id,
  });

  factory TransactionPartyDetailsModel.fromJson(Map<String, dynamic> json) {
    return TransactionPartyDetailsModel(
      name: (json['vendor_name'] ?? json['node_name'] ?? json['customer_name'] ?? json['name'] ?? '').toString(),
      code: (json['vendor_code'] ?? json['customer_code'] ?? json['node_code'] ?? json['code'] ?? '').toString(),
      id: int.tryParse(json['id']?.toString() ?? '0') ?? (json['id'] is int ? json['id'] : 0),
    );
  }
}

class NodeInventoryTransactionModel {
  final int id;
  final String transactionType;
  final int quantity;
  final int prevQuantity;
  final int newQuantity;
  final String transactionReferenceType;
  final int transactionReferenceId;
  final String createdAt;
  final String adjustmentType;
  final InventoryTransactionDetailsModel? details;
  final TransactionPartyDetailsModel? sourceDetails;
  final TransactionPartyDetailsModel? destinationDetails;

  const NodeInventoryTransactionModel({
    required this.id,
    required this.transactionType,
    required this.quantity,
    required this.prevQuantity,
    required this.newQuantity,
    required this.transactionReferenceType,
    required this.transactionReferenceId,
    required this.createdAt,
    this.adjustmentType = '',
    this.details,
    this.sourceDetails,
    this.destinationDetails,
  });

  factory NodeInventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    final detailsMap = json['inventory_transaction_details'] is Map ? json['inventory_transaction_details'] as Map<String, dynamic> : null;
    final details = detailsMap != null ? InventoryTransactionDetailsModel.fromJson(detailsMap) : null;

    final sourceMap = json['source_details'] is Map ? json['source_details'] as Map<String, dynamic> : null;
    final source = sourceMap != null ? TransactionPartyDetailsModel.fromJson(sourceMap) : null;

    final destMap = json['destination_details'] is Map ? json['destination_details'] as Map<String, dynamic> : null;
    final dest = destMap != null ? TransactionPartyDetailsModel.fromJson(destMap) : null;

    final txType = details?.transactionType.isNotEmpty == true
        ? details!.transactionType
        : (json['transaction_type']?.toString() ?? '');

    final refId = details?.id ?? (int.tryParse(json['transaction_reference_id']?.toString() ?? '0') ?? 0);
    final refType = details?.referenceNumber.isNotEmpty == true
        ? details!.referenceNumber
        : (json['transaction_reference_type']?.toString() ?? '');

    return NodeInventoryTransactionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? (json['id'] is int ? json['id'] : 0),
      transactionType: txType,
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? (json['quantity'] is int ? json['quantity'] : 0),
      prevQuantity: int.tryParse(json['prev_quantity']?.toString() ?? '0') ?? (json['prev_quantity'] is int ? json['prev_quantity'] : 0),
      newQuantity: int.tryParse(json['new_quantity']?.toString() ?? '0') ?? (json['new_quantity'] is int ? json['new_quantity'] : 0),
      transactionReferenceType: refType,
      transactionReferenceId: refId,
      createdAt: json['created_at']?.toString() ?? '',
      adjustmentType: json['adjustment_type']?.toString() ?? '',
      details: details,
      sourceDetails: source,
      destinationDetails: dest,
    );
  }
}

class NodeInventoryListResponse {
  final List<NodeInventoryModel> inventories;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  const NodeInventoryListResponse({
    required this.inventories,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  factory NodeInventoryListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['node_inventories'] as List?)
            ?.map((e) => NodeInventoryModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return NodeInventoryListResponse(
      inventories: list,
      currentPage: meta['current_page'] ?? 1,
      totalPages: meta['total_pages'] ?? 1,
      totalCount: meta['total_count'] ?? list.length,
    );
  }
}

class NodeInventoryTransactionsResponse {
  final NodeInventoryModel? nodeInventory;
  final List<NodeInventoryTransactionModel> transactions;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  const NodeInventoryTransactionsResponse({
    this.nodeInventory,
    required this.transactions,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  factory NodeInventoryTransactionsResponse.fromJson(Map<String, dynamic> json) {
    final invMap = json['node_inventory'] as Map<String, dynamic>?;
    final inv = invMap != null ? NodeInventoryModel.fromJson(invMap) : null;
    final list = (json['transactions'] as List?)
            ?.map((e) => NodeInventoryTransactionModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return NodeInventoryTransactionsResponse(
      nodeInventory: inv,
      transactions: list,
      currentPage: meta['current_page'] ?? 1,
      totalPages: meta['total_pages'] ?? 1,
      totalCount: meta['total_count'] ?? list.length,
    );
  }
}
