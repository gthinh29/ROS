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
}
