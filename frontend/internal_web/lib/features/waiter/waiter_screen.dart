import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../pos/table_grid.dart';
import 'create_order_flow.dart';
import 'cart_provider.dart';
import 'waiter_notification_provider.dart';
import '../../core/api_client.dart';

class WaiterScreen extends ConsumerWidget {
  const WaiterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<WaiterNotification?>(waiterNotificationProvider, (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\${next.title}\\n\${next.body}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: next.event == 'ITEM_READY' ? Colors.green.shade700 : Colors.blue.shade700,
            action: next.event == 'ITEM_READY' ? SnackBarAction(
              label: 'ĐÃ BƯNG',
              textColor: Colors.white,
              onPressed: () {
                 if (next.orderId != null && next.itemId != null) {
                    apiClient.patch('/orders/\${next.orderId}/items/\${next.itemId}/status', data: {'status': 'SERVED'});
                 }
              },
            ) : null,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiter Screen - Sơ đồ bàn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          )
        ],
      ),
      body: TableGrid(
        onTableTap: (table) {
          // Lưu table ID vào cart provider
          ref.read(selectedTableIdProvider.notifier).setTableId(table.id);
          
          // Mở màn hình gọi món
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const CreateOrderFlow(), // Pass state naturally
            ),
          );
        },
      ),
    );
  }
}
