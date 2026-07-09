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
  });

  factory NodeInventoryModel.fromJson(Map<String, dynamic> json) {
    return NodeInventoryModel(
      id: json['id'] ?? 0,
      productSkuId: json['product_sku_id'] ?? 0,
      skuName: json['product_sku']['sku_name'] ?? '',
      skuCode: json['product_sku']['sku_code'] ?? '',
      trackingType: json['tracking_type'] ?? 'untracked',
      totalQuantity: json['total_quantity'] ?? 0,
      availableQuantity: json['available_quantity'] ?? 0,
      blockedQuantity: json['blocked_quantity'] ?? 0,
      inTransitQuantity: json['in_transit_quantity'] ?? 0,
      damagedQuantity: json['damaged_quantity'] ?? 0,
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

  const NodeInventoryTransactionModel({
    required this.id,
    required this.transactionType,
    required this.quantity,
    required this.prevQuantity,
    required this.newQuantity,
    required this.transactionReferenceType,
    required this.transactionReferenceId,
    required this.createdAt,
  });

  factory NodeInventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    return NodeInventoryTransactionModel(
      id: json['id'] ?? 0,
      transactionType: json['transaction_type'] ?? '',
      quantity: json['quantity'] ?? 0,
      prevQuantity: json['prev_quantity'] ?? 0,
      newQuantity: json['new_quantity'] ?? 0,
      transactionReferenceType: json['transaction_reference_type'] ?? '',
      transactionReferenceId: json['transaction_reference_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
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
