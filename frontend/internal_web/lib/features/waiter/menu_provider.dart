import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/models/menu.dart';
import 'package:shared/core/api_client.dart';

class MenuNotifier extends Notifier<AsyncValue<List<MenuItem>>> {
  @override
  AsyncValue<List<MenuItem>> build() {
    _fetchMenuItems();
    return const AsyncValue.loading();
  }

  Future<void> _fetchMenuItems() async {
    try {
      final response = await apiClient.get('/menu/items');
      final dynamic responseData = response.data;
      final List<dynamic> data = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;
          
      final items = data.map((e) => MenuItem.fromJson(e)).toList();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() {
    state = const AsyncValue.loading();
    _fetchMenuItems();
  }
}

final menuProvider = NotifierProvider<MenuNotifier, AsyncValue<List<MenuItem>>>(MenuNotifier.new);
