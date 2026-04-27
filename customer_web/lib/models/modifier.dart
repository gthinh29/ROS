class Modifier {
  final String id;
  final String name;
  final double price;

  Modifier({required this.id, required this.name, required this.price});

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(id: json['id'], name: json['name'], price: json['price']);
  }
}
