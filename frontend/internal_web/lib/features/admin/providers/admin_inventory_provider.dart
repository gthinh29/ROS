import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/models/inventory.dart';
import 'package:shared/core/api_client.dart';

class InventoryNotifier extends Notifier<AsyncValue<List<Ingredient>>> {
  @override
  AsyncValue<List<Ingredient>> build() {
    _fetchIngredients();
    return const AsyncValue.loading();
  }

  Future<void> _fetchIngredients() async {
    try {
      final res = await apiClient.get('/inventory/ingredients');
      final data = res.data['data'] ?? res.data;
      final items = (data as List).map((e) => Ingredient.fromJson(e)).toList();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createIngredient(Map<String, dynamic> payload) async {
    try {
      await apiClient.post('/inventory/ingredients', data: payload);
      await _fetchIngredients();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateIngredient(String id, Map<String, dynamic> payload) async {
    try {
       await apiClient.patch('/inventory/ingredients/$id', data: payload);
       await _fetchIngredients();
       return true;
    } catch (_) {
       return false;
    }
  }

  Future<bool> deleteIngredient(String id) async {
     try {
       await apiClient.delete('/inventory/ingredients/$id');
       await _fetchIngredients();
       return true;
     } catch (_) {
       return false;
     }
  }
}

final adminInventoryProvider = NotifierProvider<InventoryNotifier, AsyncValue<List<Ingredient>>>(InventoryNotifier.new);
