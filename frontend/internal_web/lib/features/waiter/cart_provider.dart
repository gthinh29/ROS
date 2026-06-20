// ignore_for_file: use_null_aware_elements
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/models/cart_item.dart';
import 'package:shared/core/api_client.dart';

class SelectedTableNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setTableId(String? id) {
    state = id;
  }
}

final selectedTableIdProvider = NotifierProvider<SelectedTableNotifier, String?>(SelectedTableNotifier.new);

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  void addItem(CartItem item) {
    state = [...state, item];
  }

  void removeItem(int index) {
    state = [...state]..removeAt(index);
  }

  void updateQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;
    final newState = [...state];
    newState[index].quantity = newQuantity;
    state = newState;
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0, (sum, item) => sum + item.totalPrice);
  }

  Future<bool> submitOrder() async {
    final tableId = ref.read(selectedTableIdProvider);
    if (state.isEmpty) return false;

    // Build the request matching OrderCreate schema
    final type = tableId != null ? 'DINE_IN' : 'TAKEAWAY';
    
    final itemsPayload = state.map((item) {
      return {
        'menu_item_id': item.menuItem.id,
        'variant_id': item.selectedVariant?.id,
        'qty': item.quantity,
        'note': item.note,
        'modifier_ids': item.selectedModifiers.map((m) => m.id).toList(),
      };
    }).toList();

    final payload = {
      if (tableId != null) 'table_id': tableId,
      'type': type,
      'items': itemsPayload,
    };

    try {
      await apiClient.post('/orders', data: payload);
      clearCart();
      return true;
    } catch (e) {
      debugPrint('Order Submit Error: \$e');
      return false;
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);
