class BOMItem {
  final String id;
  final String menuItemId;
  final String? variantId;
  final String ingredientId;
  final double qtyRequired;

  BOMItem({
    required this.id,
    required this.menuItemId,
    this.variantId,
    required this.ingredientId,
    required this.qtyRequired,
  });

  factory BOMItem.fromJson(Map<String, dynamic> json) {
    return BOMItem(
      id: json['id'] as String,
      menuItemId: json['menu_item_id'] as String,
      variantId: json['variant_id'] as String?,
      ingredientId: json['ingredient_id'] as String,
      qtyRequired: (json['qty_required'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_item_id': menuItemId,
      'variant_id': variantId,
      'ingredient_id': ingredientId,
      'qty_required': qtyRequired,
    };
  }
}
