import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants.dart';
import '../auth/auth_notifier.dart';

class WaiterNotification {
  final String event;
  final String title;
  final String body;
  final String? itemId;
  final String? orderId;

  WaiterNotification({
    required this.event,
    required this.title,
    required this.body,
    this.itemId,
    this.orderId,
  });
}

class WaiterNotificationNotifier extends Notifier<WaiterNotification?> {
  WebSocketChannel? _channel;

  @override
  WaiterNotification? build() {
    final user = ref.read(authProvider).user;
    if (user != null && user.role.name.toUpperCase() == 'WAITER') {
      _connectWebSocket(user.id);
    }
    
    ref.onDispose(() {
      _channel?.sink.close();
    });
    
    return null;
  }

  void _connectWebSocket(String userId) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('\${AppConstants.wsUrl}/staff/\$userId'));
      _channel!.stream.listen((message) {
        try {
          final data = jsonDecode(message);
          final event = data['event'];
          
          if (event == 'ITEM_READY') {
            state = WaiterNotification(
              event: event,
              title: 'Món Đã Xong!',
              body: "Bàn \${data['table_number'] ?? '?'}: \${data['menu_item_name']}",
              itemId: data['item_id'],
              orderId: data['order_id'],
            );
          } else if (event == 'CALL_WAITER') {
             state = WaiterNotification(
              event: event,
              title: 'Gọi Phục Vụ',
              body: "Bàn \${data['table_number'] ?? '?'} đang gọi.",
            );
          }
        } catch (_) {}
      });
    } catch (_) {}
  }
}

final waiterNotificationProvider = NotifierProvider<WaiterNotificationNotifier, WaiterNotification?>(WaiterNotificationNotifier.new);
