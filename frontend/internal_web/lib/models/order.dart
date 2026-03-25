enum OrderStatus { pending, preparing, ready, completed, cancelled }
enum OrderItemStatus { pending, preparing, ready, served }
enum OrderType { dineIn, preOrder }

class OrderItemModel {
  final String id;
  final String orderId;
  final String menuItemId;
  final String menuItemName; // Added for UI convenience
  final String? variantName;
  final int qty;
  final String? note;
  final OrderItemStatus status;
  final String tableNumber; // Added for KDS context
  final DateTime createdAt;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.menuItemName,
    this.variantName,
    required this.qty,
    this.note,
    required this.status,
    required this.tableNumber,
    required this.createdAt,
  });

  OrderItemModel copyWith({
    String? id,
    String? orderId,
    String? menuItemId,
    String? menuItemName,
    String? variantName,
    int? qty,
    String? note,
    OrderItemStatus? status,
    String? tableNumber,
    DateTime? createdAt,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      variantName: variantName ?? this.variantName,
      qty: qty ?? this.qty,
      note: note ?? this.note,
      status: status ?? this.status,
      tableNumber: tableNumber ?? this.tableNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['order_item_id'] ?? json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      menuItemId: json['menu_item_id'] ?? '',
      menuItemName: json['menu_item_name'] ?? 'Unknown Item',
      variantName: json['variant_name'],
      qty: json['qty'] ?? 1,
      note: json['note'],
      status: OrderItemStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status']?.toString().toUpperCase() ?? 'PENDING'),
        orElse: () => OrderItemStatus.pending,
      ),
      tableNumber: json['table_number']?.toString() ?? json['table_id']?.toString() ?? '?',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }
}
