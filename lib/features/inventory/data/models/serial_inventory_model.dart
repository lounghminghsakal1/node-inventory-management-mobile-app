import 'batch_inventory_model.dart';

class SerialCurrentTransactionModel {
  final int id;
  final String transactionReferenceType;
  final String transactionType;
  final int? transactionReferenceId;

  const SerialCurrentTransactionModel({
    required this.id,
    required this.transactionReferenceType,
    required this.transactionType,
    this.transactionReferenceId,
  });

  factory SerialCurrentTransactionModel.fromJson(Map<String, dynamic> json) {
    return SerialCurrentTransactionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      transactionReferenceType: json['transaction_reference_type']?.toString() ?? 'N/A',
      transactionType: json['transaction_type']?.toString() ?? 'N/A',
      transactionReferenceId: int.tryParse(json['transaction_reference_id']?.toString() ?? ''),
    );
  }
}

class SerialInventoryModel {
  final int id;
  final String skuItemNumber;
  final String status;
  final InventoryNodeModel? currentNode;
  final InventoryProductSkuModel? productSku;
  final SerialCurrentTransactionModel? currentTransaction;
  final List<Map<String, dynamic>> trackers;

  const SerialInventoryModel({
    required this.id,
    required this.skuItemNumber,
    required this.status,
    this.currentNode,
    this.productSku,
    this.currentTransaction,
    this.trackers = const [],
  });

  factory SerialInventoryModel.fromJson(Map<String, dynamic> json) {
    final trackersList = (json['sku_item_trackers'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    return SerialInventoryModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      skuItemNumber: json['sku_item_number']?.toString() ?? 'N/A',
      status: json['status']?.toString() ?? 'unknown',
      currentNode: json['current_node'] is Map<String, dynamic> ? InventoryNodeModel.fromJson(json['current_node']) : null,
      productSku: json['product_sku'] is Map<String, dynamic> ? InventoryProductSkuModel.fromJson(json['product_sku']) : null,
      currentTransaction: json['current_inventory_transaction'] is Map<String, dynamic>
          ? SerialCurrentTransactionModel.fromJson(json['current_inventory_transaction'])
          : null,
      trackers: trackersList,
    );
  }
}

class SerialInventoryListResponse {
  final List<SerialInventoryModel> skuItems;
  final InventoryMetaModel meta;

  const SerialInventoryListResponse({
    required this.skuItems,
    required this.meta,
  });

  factory SerialInventoryListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['sku_items'] as List?)?.map((e) => SerialInventoryModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    final metaObj = json['meta'] is Map<String, dynamic>
        ? InventoryMetaModel.fromJson(json['meta'])
        : const InventoryMetaModel(currentPage: 1, totalPages: 1, totalCount: 0);
    return SerialInventoryListResponse(skuItems: list, meta: metaObj);
  }
}
