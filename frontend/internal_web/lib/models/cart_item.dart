import 'menu.dart';

class CartItem {
  final MenuItem menuItem;
  final Variant? selectedVariant;
  final List<Modifier> selectedModifiers;
  int quantity;
  final String? note;

  CartItem({
    required this.menuItem,
    this.selectedVariant,
    this.selectedModifiers = const [],
    this.quantity = 1,
    this.note,
  });

  double get totalPrice {
    double total = menuItem.basePrice;
    if (selectedVariant != null) {
      total += selectedVariant!.extraPrice;
    }
    for (final mod in selectedModifiers) {
      total += mod.extraPrice;
    }
    return total * quantity;
  }
}
