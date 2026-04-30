import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared/models/order.dart';
import 'package:shared/core/api_client.dart';
import 'package:shared/core/constants.dart';
import 'kds_audio_service.dart';

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
      final response = await apiClient.get('/orders/kds/items?zone=kitchen');
      final List<dynamic> data = response.data['data'] ?? response.data ?? [];
      final items = data.map((e) => OrderItemModel.fromJson(e)).toList();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('${AppConstants.wsUrl}/kds/kitchen'));
      _channel!.stream.listen((message) {
        try {
          final data = jsonDecode(message);
          if (data['event'] == 'new_order_items' && data['items'] != null) {
            ref.read(kdsAudioProvider.notifier).playNewOrderSound();
            
            final newItems = (data['items'] as List).map((e) => OrderItemModel.fromJson(e)).toList();
            final currentList = state.value ?? [];
            state = AsyncValue.data([...newItems, ...currentList]);
          } else if (data['event'] == 'item_status_updated') {
            final itemId = data['item_id'];
            final statusStr = data['status'];
            final currentList = state.value ?? [];

            if (statusStr == 'SERVED') {
              // Món đã được bưng ra → xóa khỏi màn hình ngay
              state = AsyncValue.data(currentList.where((e) => e.id != itemId).toList());
            } else if (statusStr == 'CANCELLED') {
              // Món bị hủy (ví dụ do khách checkout) → hiển thị ĐÃ HỦY, chờ dọn dẹp
              state = AsyncValue.data(currentList.map((e) =>
                e.id == itemId ? e.copyWith(status: OrderItemStatus.cancelled) : e
              ).toList());
            } else {
              // Cập nhật trạng thái bình thường (PENDING→PREPARING→READY)
              final status = OrderItemStatus.values.firstWhere(
                (e) => e.name.toUpperCase() == statusStr.toString().toUpperCase(),
                orElse: () => OrderItemStatus.pending
              );
              final updatedList = currentList.map((e) =>
                e.id == itemId ? e.copyWith(status: status) : e
              ).toList();
              updatedList.sort((a, b) => a.status.index.compareTo(b.status.index));
              state = AsyncValue.data(updatedList);
            }
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  /// Xóa tất cả món đã bị HỦY khỏi danh sách KDS (nút "Dọn dẹp")
  void clearCancelledItems() {
    final currentList = state.value ?? [];
    state = AsyncValue.data(
      currentList.where((e) => e.status != OrderItemStatus.cancelled).toList()
    );
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
      final orderId = state.value?.firstWhere((e) => e.id == itemId).orderId;
      if (orderId != null) {
        await apiClient.patch('/orders/$orderId/items/$itemId/status', data: {'status': newStatus.name.toUpperCase()});
      }
    } catch (e) {
      debugPrint('API error $e');
    }
  }
}

final kdsProvider = NotifierProvider<KdsNotifier, AsyncValue<List<OrderItemModel>>>(KdsNotifier.new);

