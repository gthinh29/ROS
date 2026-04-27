class MenuItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final bool isAvailable;
  final List<String> modifiers;
  final String description;

  MenuItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.isAvailable,
    required this.modifiers,
    required this.description,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['is_available'] ?? false,
      modifiers: List<String>.from(json['modifiers'] ?? []),
      description: json['description'] ?? '',
    );
  }
}
