import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/core/api_client.dart';
import 'package:shared/models/order.dart';

/// Fetch tất cả các order item của 1 table, gom lại thành flat list.
/// Dùng trong Tab "Tiến trình đơn" của CreateOrderFlow.
final orderProgressProvider = FutureProvider.family.autoDispose<List<OrderItemModel>, String>((ref, tableId) async {
  final res = await apiClient.get('/orders?table_id=$tableId');
  final dynamic responseData = res.data;
  final List<dynamic> orders = responseData is Map && responseData.containsKey('data') 
      ? responseData['data'] 
      : responseData;
      
  final List<OrderItemModel> allItems = [];

  for (final o in orders) {
    final items = o['items'] as List<dynamic>? ?? [];
    for (final i in items) {
      allItems.add(OrderItemModel.fromJson(i as Map<String, dynamic>));
    }
  }

  // Sắp xếp: PENDING/PREPARING trên, READY giữa, SERVED/CANCELLED dưới
  allItems.sort((a, b) {
    const priority = {
      'PENDING': 0,
      'PREPARING': 1,
      'READY': 2,
      'SERVED': 3,
      'CANCELLED': 4,
    };
    final pA = priority[a.status.name.toUpperCase()] ?? 9;
    final pB = priority[b.status.name.toUpperCase()] ?? 9;
    return pA.compareTo(pB);
  });

  return allItems;
});
