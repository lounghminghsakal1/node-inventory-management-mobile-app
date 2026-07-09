class NodeInventoryLedgerModel {
  final int id;
  final int productSkuId;
  final String skuName;
  final String skuCode;
  final int openingQuantity;
  final int closingQuantity;
  final int inwardQuantity;
  final int outwardQuantity;
  final String date;

  const NodeInventoryLedgerModel({
    required this.id,
    required this.productSkuId,
    required this.skuName,
    required this.skuCode,
    required this.openingQuantity,
    required this.closingQuantity,
    required this.inwardQuantity,
    required this.outwardQuantity,
    required this.date,
  });

  factory NodeInventoryLedgerModel.fromJson(Map<String, dynamic> json) {
    return NodeInventoryLedgerModel(
      id: json['id'] ?? 0,
      productSkuId: json['product_sku_id'] ?? 0,
      skuName: json['product_sku']['sku_name'] ?? '',
      skuCode: json['product_sku']['sku_code'] ?? '',
      openingQuantity: json['opening_quantity'] ?? 0,
      closingQuantity: json['closing_quantity'] ?? 0,
      inwardQuantity: json['inward_quantity'] ?? 0,
      outwardQuantity: json['outward_quantity'] ?? 0,
      date: json['date'] ?? '',
    );
  }
}

class NodeInventoryLedgerResponse {
  final List<NodeInventoryLedgerModel> ledger;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  const NodeInventoryLedgerResponse({
    required this.ledger,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  factory NodeInventoryLedgerResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['ledger'] as List?)
            ?.map((e) => NodeInventoryLedgerModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return NodeInventoryLedgerResponse(
      ledger: list,
      currentPage: meta['current_page'] ?? 1,
      totalPages: meta['total_pages'] ?? 1,
      totalCount: meta['total_count'] ?? list.length,
    );
  }
}
