// models/inventory.dart
class Ingredient {
  final String id;
  final String name;
  final String unit;
  final double costPerUnit;
  final double stockQty;
  final double alertThreshold;

  Ingredient({
    required this.id, 
    required this.name, 
    required this.unit, 
    this.costPerUnit = 0,
    this.stockQty = 0,
    this.alertThreshold = 0,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      unit: json['unit'],
      costPerUnit: (json['cost_per_unit'] ?? 0.0).toDouble(),
      stockQty: (json['stock_qty'] ?? 0.0).toDouble(),
      alertThreshold: (json['alert_threshold'] ?? 0.0).toDouble(),
    );
  }
}
