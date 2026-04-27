class Variant {
  final String id;
  final String name;
  final double price;

  Variant({required this.id, required this.name, required this.price});

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(id: json['id'], name: json['name'], price: json['price']);
  }
}
