import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/models/cart_item.dart';
import 'package:shared/models/menu.dart';
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

// ── Pre-order cho đặt bàn trước ────────────────────────────────────────────

class PreOrderItem {
  final MenuItem menuItem;
  final Variant? variant;
  int qty;

  PreOrderItem({required this.menuItem, this.variant, this.qty = 1});

  double get unitPrice => menuItem.basePrice + (variant?.extraPrice ?? 0);
  double get totalPrice => unitPrice * qty;

  String get _key => '${menuItem.id}::${variant?.id ?? ''}';

  Map<String, dynamic> toApiJson() => {
        'menu_item_id': menuItem.id,
        if (variant != null) 'variant_id': variant!.id,
        'qty': qty,
        'modifier_ids': const <String>[],
      };
}

class PreOrderNotifier extends StateNotifier<List<PreOrderItem>> {
  PreOrderNotifier() : super([]);

  void add(MenuItem item, {Variant? variant, int qty = 1}) {
    final key = '${item.id}::${variant?.id ?? ''}';
    final idx = state.indexWhere((p) => p._key == key);
    if (idx != -1) {
      final updated = List<PreOrderItem>.from(state);
      updated[idx].qty += qty;
      state = updated;
    } else {
      state = [...state, PreOrderItem(menuItem: item, variant: variant, qty: qty)];
    }
  }

  void updateQty(int index, int qty) {
    final updated = List<PreOrderItem>.from(state);
    if (qty <= 0) {
      updated.removeAt(index);
    } else {
      updated[index].qty = qty;
    }
    state = updated;
  }

  void remove(int index) {
    final updated = List<PreOrderItem>.from(state);
    updated.removeAt(index);
    state = updated;
  }

  void clear() => state = [];

  double get totalAmount => state.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get totalQty => state.fold(0, (sum, item) => sum + item.qty);
}

final preOrderProvider =
    StateNotifierProvider<PreOrderNotifier, List<PreOrderItem>>(
  (ref) => PreOrderNotifier(),
);

// ── Saved contact info (auto-fill Tên + SĐT) ──────────────────────────────────

class SavedContact {
  static const _keyName = 'saved_customer_name';
  static const _keyPhone = 'saved_customer_phone';

  static Future<({String name, String phone})> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (
        name: prefs.getString(_keyName) ?? '',
        phone: prefs.getString(_keyPhone) ?? '',
      );
    } catch (_) {
      return (name: '', phone: '');
    }
  }

  static Future<void> save({required String name, required String phone}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyName, name);
      await prefs.setString(_keyPhone, phone);
    } catch (_) {
      // ignore
    }
  }
}
