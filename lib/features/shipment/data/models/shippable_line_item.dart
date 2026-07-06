class NodeInventory {
  final int totalQuantity;
  final int availableQuantity;
  final int blockedQuantity;

  const NodeInventory({
    required this.totalQuantity,
    required this.availableQuantity,
    required this.blockedQuantity,
  });

  factory NodeInventory.fromJson(Map<String, dynamic> j) => NodeInventory(
        totalQuantity: (j['total_quantity'] as num?)?.toInt() ?? 0,
        availableQuantity: (j['available_quantity'] as num?)?.toInt() ?? 0,
        blockedQuantity: (j['blocked_quantity'] as num?)?.toInt() ?? 0,
      );
}

class ShippableLineItem {
  final int oliId;
  final int productSkuId;
  final String skuName;
  final String skuCode;
  final String? lineItemType;
  final int orderedQuantity;
  final int shippedQuantity;
  final int remainingQuantity;
  final NodeInventory nodeInventory;

  const ShippableLineItem({
    required this.oliId,
    required this.productSkuId,
    required this.skuName,
    required this.skuCode,
    this.lineItemType,
    required this.orderedQuantity,
    required this.shippedQuantity,
    required this.remainingQuantity,
    required this.nodeInventory,
  });

  int get maxShippable => remainingQuantity < nodeInventory.availableQuantity
      ? remainingQuantity
      : nodeInventory.availableQuantity;

  factory ShippableLineItem.fromJson(Map<String, dynamic> j) =>
      ShippableLineItem(
        oliId: (j['oli_id'] as num?)?.toInt() ?? 0,
        productSkuId: (j['product_sku_id'] as num?)?.toInt() ?? 0,
        skuName: j['sku_name'] as String? ?? '',
        skuCode: j['sku_code'] as String? ?? '',
        lineItemType: j['line_item_type'] as String?,
        orderedQuantity: (j['ordered_quantity'] as num?)?.toInt() ?? 0,
        shippedQuantity: (j['shipped_quantity'] as num?)?.toInt() ?? 0,
        remainingQuantity: (j['remaining_quantity'] as num?)?.toInt() ?? 0,
        nodeInventory: j['node_inventory'] is Map<String, dynamic>
            ? NodeInventory.fromJson(j['node_inventory'] as Map<String, dynamic>)
            : const NodeInventory(totalQuantity: 0, availableQuantity: 0, blockedQuantity: 0),
      );
}
