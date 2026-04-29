import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/models/cart_item.dart';

// ── Cart state — dùng typed CartItem giống Internal Web ──────────────────────

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem newItem) {
    // Nếu cùng món + variant + modifiers, tăng quantity
    final idx = state.indexWhere((c) =>
        c.menuItem.id == newItem.menuItem.id &&
        c.selectedVariant?.id == newItem.selectedVariant?.id &&
        _modifierKey(c) == _modifierKey(newItem));

    if (idx != -1) {
      final updated = List<CartItem>.from(state);
      updated[idx].quantity += newItem.quantity;
      state = updated;
    } else {
      state = [...state, newItem];
    }
  }

  void updateQty(int index, int qty) {
    final updated = List<CartItem>.from(state);
    if (qty <= 0) {
      updated.removeAt(index);
    } else {
      updated[index].quantity = qty;
    }
    state = updated;
  }

  void removeItem(int index) {
    final updated = List<CartItem>.from(state);
    updated.removeAt(index);
    state = updated;
  }

  void clear() => state = [];

  double get totalAmount =>
      state.fold(0.0, (sum, item) => sum + item.totalPrice);

  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);

  String _modifierKey(CartItem item) =>
      (item.selectedModifiers.map((m) => m.id).toList()..sort()).join(',');
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);
