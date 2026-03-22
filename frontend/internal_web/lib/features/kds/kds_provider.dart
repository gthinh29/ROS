import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/order.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

class KdsNotifier extends Notifier<AsyncValue<List<OrderItemModel>>> {
  WebSocketChannel? _channel;

  @override
  AsyncValue<List<OrderItemModel>> build() {
    _fetchKdsItems();
    _connectWebSocket();
    
    ref.onDispose(() {
      _channel?.sink.close();
    });
    
    return const AsyncValue.loading();
  }

  Future<void> _fetchKdsItems() async {
    try {
      // In a real app, this would be GET /orders (filtered for KDS zone)
      final response = await apiClient.get('/orders');
      throw Exception('Mock trigger'); // Force fallback
    } catch (e) {
      // Fallback for UI Preview
      final mockItems = [
        OrderItemModel(
          id: '1', orderId: 'o1', menuItemId: 'm1', menuItemName: 'Phở Bò',
          variantName: 'Tô vừa', qty: 1, note: 'Ít bánh', 
          status: OrderItemStatus.pending, tableNumber: '1', 
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        OrderItemModel(
          id: '2', orderId: 'o2', menuItemId: 'm1', menuItemName: 'Phở Bò',
          variantName: 'Tô vừa', qty: 1, note: 'Ít bánh', 
          status: OrderItemStatus.pending, tableNumber: '2', 
          createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
        OrderItemModel(
          id: '3', orderId: 'o3', menuItemId: 'm2', menuItemName: 'Cơm Tấm sườn bì chả',
          qty: 1, status: OrderItemStatus.pending, tableNumber: '3', 
          createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
        OrderItemModel(
          id: '4', orderId: 'o4', menuItemId: 'm3', menuItemName: 'Trà đá',
          qty: 2, status: OrderItemStatus.preparing, tableNumber: '4', 
          createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        OrderItemModel(
          id: '5', orderId: 'o4', menuItemId: 'm3', menuItemName: 'Salad gà',
          qty: 1, status: OrderItemStatus.ready, tableNumber: '4', 
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        ),
      ];
      state = AsyncValue.data(mockItems);
    }
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('${AppConstants.wsUrl}/kds/kitchen'));
      _channel!.stream.listen((message) {
         // handle realtime message
      });
    } catch (_) {}
  }

  Future<void> updateStatus(String itemId, OrderItemStatus newStatus) async {
    // 1. Optimistic update
    final currentList = state.value ?? [];
    final updatedList = currentList.map((e) => e.id == itemId ? e.copyWith(status: newStatus) : e).toList();
    
    // Sort so ready is last, pending is first
    updatedList.sort((a, b) => a.status.index.compareTo(b.status.index));
    
    state = AsyncValue.data(updatedList);

    // 2. Call API
    try {
      // await apiClient.patch('/orders/item/$itemId/status', data: {'status': newStatus.name.toUpperCase()});
    } catch (e) {
      // print('API error $e');
    }
  }
}

final kdsProvider = NotifierProvider<KdsNotifier, AsyncValue<List<OrderItemModel>>>(KdsNotifier.new);
