class Modifier {
  final String id;
  final String name;
  final double extraPrice;
  final bool isRequired;

  Modifier({
    required this.id,
    required this.name,
    this.extraPrice = 0.0,
    this.isRequired = false,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: json['id'] as String,
      name: json['name'] as String,
      extraPrice: (json['extra_price'] ?? 0.0).toDouble(),
      isRequired: json['is_required'] ?? false,
    );
  }
}

class Variant {
  final String id;
  final String name;
  final double extraPrice;

  Variant({
    required this.id,
    required this.name,
    this.extraPrice = 0.0,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'] as String,
      name: json['name'] as String,
      extraPrice: (json['extra_price'] ?? 0.0).toDouble(),
    );
  }
}

class MenuItem {
  final String id;
  final String categoryId;
  final String name;
  final double basePrice;
  final String? imageUrl;
  final bool isAvailable;
  final String kdsZone;
  final List<Variant> variants;
  final List<Modifier> modifiers;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.basePrice,
    this.imageUrl,
    this.isAvailable = true,
    this.kdsZone = 'kitchen',
    this.variants = const [],
    this.modifiers = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      basePrice: (json['base_price'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] ?? true,
      kdsZone: json['kds_zone'] ?? 'kitchen',
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => Variant.fromJson(e))
              .toList() ??
          [],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e))
              .toList() ??
          [],
    );
  }
}
