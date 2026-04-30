import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared/core/constants.dart';
import 'package:shared/core/api_client.dart';
import '../auth/auth_notifier.dart';

// ─── Notification (Popup) ───────────────────────────────────────────────────

class WaiterNotification {
  final String event;
  final String title;
  final String body;
  final String? itemId;
  final String? orderId;
  final String? tableNumber;
  final String? menuItemName;

  WaiterNotification({
    required this.event,
    required this.title,
    required this.body,
    this.itemId,
    this.orderId,
    this.tableNumber,
    this.menuItemName,
  });
}

// ─── Ready Item Model (bưng ra) ─────────────────────────────────────────────

class ReadyItem {
  final String itemId;
  final String orderId;
  final String tableNumber;
  final String menuItemName;
  bool isServing; // đang xử lý (loading)

  ReadyItem({
    required this.itemId,
    required this.orderId,
    required this.tableNumber,
    required this.menuItemName,
    this.isServing = false,
  });
}

// ─── Ready Items List Provider ───────────────────────────────────────────────

class ReadyItemsNotifier extends Notifier<List<ReadyItem>> {
  @override
  List<ReadyItem> build() => [];

  void addItem(ReadyItem item) {
    // Tránh thêm duplicate
    final exists = state.any((e) => e.itemId == item.itemId);
    if (!exists) state = [...state, item];
  }

  void removeItem(String itemId) {
    state = state.where((e) => e.itemId != itemId).toList();
  }

  Future<bool> markServed(String orderId, String itemId) async {
    // Đánh dấu loading
    state = state
        .map((e) => e.itemId == itemId
            ? ReadyItem(
                itemId: e.itemId,
                orderId: e.orderId,
                tableNumber: e.tableNumber,
                menuItemName: e.menuItemName,
                isServing: true,
              )
            : e)
        .toList();

    try {
      await apiClient.patch(
        '/orders/$orderId/items/$itemId/status',
        data: {'status': 'SERVED'},
      );
      removeItem(itemId);
      return true;
    } catch (e) {
      debugPrint('SERVED ERROR: $e');
      // Reset loading
      state = state
          .map((item) => item.itemId == itemId
              ? ReadyItem(
                  itemId: item.itemId,
                  orderId: item.orderId,
                  tableNumber: item.tableNumber,
                  menuItemName: item.menuItemName,
                  isServing: false,
                )
              : item)
          .toList();
      return false;
    }
  }
}

final readyItemsProvider =
    NotifierProvider<ReadyItemsNotifier, List<ReadyItem>>(ReadyItemsNotifier.new);

// ─── Notification Provider (WS Listener) ────────────────────────────────────

class WaiterNotificationNotifier extends Notifier<WaiterNotification?> {
  WebSocketChannel? _channel;

  @override
  WaiterNotification? build() {
    final user = ref.read(authProvider).user;
    if (user != null && user.role.name.toUpperCase() == 'WAITER') {
      _connectWebSocket(user.id);
    }
    ref.onDispose(() => _channel?.sink.close());
    return null;
  }

  void _connectWebSocket(String userId) {
    try {
      final wsUrl = '${AppConstants.wsUrl}/staff/$userId';
      debugPrint('WAITER WS: Connecting to $wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) {
          debugPrint('WAITER WS: Received -> $message');
          try {
            final data = jsonDecode(message) as Map<String, dynamic>;
            final event = data['event'] as String?;

            if (event == 'ITEM_READY') {
              final tableNum = data['table_number']?.toString() ?? '?';
              final itemName = data['menu_item_name']?.toString() ?? 'Món ăn';
              final itemId = data['item_id']?.toString();
              final orderId = data['order_id']?.toString();

              // 1. Trigger popup notification
              state = WaiterNotification(
                event: event!,
                title: '🍽️ Món Đã Xong!',
                body: 'Bàn $tableNum: $itemName',
                itemId: itemId,
                orderId: orderId,
                tableNumber: tableNum,
                menuItemName: itemName,
              );

              // 2. Thêm vào danh sách "Cần Bưng Ra"
              if (itemId != null && orderId != null) {
                ref.read(readyItemsProvider.notifier).addItem(ReadyItem(
                  itemId: itemId,
                  orderId: orderId,
                  tableNumber: tableNum,
                  menuItemName: itemName,
                ));
              }
            } else if (event == 'CALL_WAITER') {
              final tableNum = data['table_number']?.toString() ?? '?';
              state = WaiterNotification(
                event: event!,
                title: '🔔 Gọi Phục Vụ',
                body: 'Bàn $tableNum đang gọi.',
              );
            } else if (event == 'CANCELLED') {
              // Xóa khỏi danh sách nếu món bị hủy
              final itemId = data['item_id']?.toString();
              if (itemId != null) {
                ref.read(readyItemsProvider.notifier).removeItem(itemId);
              }
            }
          } catch (e) {
            debugPrint('WAITER WS JSON Error: $e');
          }
        },
        onError: (e) => debugPrint('WAITER WS Stream Error: $e'),
        onDone: () => debugPrint('WAITER WS: Closed'),
      );
    } catch (e) {
      debugPrint('WAITER WS Connect Error: $e');
    }
  }
}

final waiterNotificationProvider = NotifierProvider<WaiterNotificationNotifier,
    WaiterNotification?>(WaiterNotificationNotifier.new);
