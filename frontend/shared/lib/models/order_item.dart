class OrderItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String status;

  const OrderItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.status,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
      status: json['status'] ?? 'PENDING',
    );
  }

  // ✅ Thêm copyWith để cập nhật status realtime
  OrderItem copyWith({String? status}) {
    return OrderItem(
      id: id,
      name: name,
      imageUrl: imageUrl,
      price: price,
      quantity: quantity,
      status: status ?? this.status,
    );
  }
}
