import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/menu.dart';
import '../../../core/api_client.dart';

class CategoryModel {
  final String id;
  final String name;
  CategoryModel({required this.id, required this.name});
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(id: json['id'], name: json['name']);
  }
}

final adminCategoryProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final res = await apiClient.get('/menu/categories');
  final data = res.data['data'] ?? res.data;
  return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
});

class AdminMenuNotifier extends Notifier<AsyncValue<List<MenuItem>>> {
  @override
  AsyncValue<List<MenuItem>> build() {
    _fetchItems();
    return const AsyncValue.loading();
  }

  Future<void> _fetchItems() async {
    try {
      final res = await apiClient.get('/menu/items');
      final data = res.data['data'] ?? res.data;
      final items = (data as List).map((e) => MenuItem.fromJson(e)).toList();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createItem(Map<String, dynamic> payload) async {
    try {
      await apiClient.post('/menu/items', data: payload);
      _fetchItems();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateItem(String id, Map<String, dynamic> payload) async {
    try {
      await apiClient.patch('/menu/items/$id', data: payload);
      _fetchItems();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await apiClient.delete('/menu/items/$id');
      _fetchItems();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final adminMenuProvider = NotifierProvider<AdminMenuNotifier, AsyncValue<List<MenuItem>>>(AdminMenuNotifier.new);
