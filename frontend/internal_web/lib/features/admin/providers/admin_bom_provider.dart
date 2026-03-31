import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../../models/bom.dart';

final adminBomProvider = Provider<AdminBomService>((ref) {
  return AdminBomService(apiClient);
});

class AdminBomService {
  final Dio _api;

  AdminBomService(this._api);

  Future<List<BOMItem>> getBom(String menuItemId) async {
    try {
      final res = await _api.get('/inventory/bom/menu-items/$menuItemId');
      final data = res.data['data'] as List?;
      if (data == null) return [];
      return data.map((e) => BOMItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Lỗi khi tải định lượng: $e');
    }
  }

  Future<bool> setBom(String menuItemId, List<Map<String, dynamic>> items) async {
    try {
      await _api.put(
        '/inventory/bom/menu-items/$menuItemId',
        data: {'bom_items': items},
      );
      return true;
    } catch (e) {
      print('Set BOM Error: $e');
      return false;
    }
  }
}
