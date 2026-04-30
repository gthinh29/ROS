import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/models/cart_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

// ── Active Orders State ────────────────────────────────────────────────────────

class ActiveOrdersNotifier extends StateNotifier<List<String>> {
  ActiveOrdersNotifier() : super([]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('active_order_ids');
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded.cast<String>();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> addOrder(String orderId) async {
    if (!state.contains(orderId)) {
      state = [...state, orderId];
      _saveToPrefs();
    }
  }

  Future<void> removeOrder(String orderId) async {
    state = state.where((id) => id != orderId).toList();
    _saveToPrefs();
  }
  
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_order_ids', jsonEncode(state));
    } catch (e) {
      // ignore
    }
  }
}

final activeOrdersProvider =
    StateNotifierProvider<ActiveOrdersNotifier, List<String>>(
  (ref) => ActiveOrdersNotifier(),
);
