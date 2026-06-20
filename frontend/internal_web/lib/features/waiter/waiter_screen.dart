import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared/models/table.dart';
import '../auth/auth_notifier.dart';
import '../pos/table_grid.dart';
import 'create_order_flow.dart';
import 'cart_provider.dart';
import 'waiter_notification_provider.dart';
import 'ready_items_panel.dart';
import 'reservations_tab.dart';

class WaiterScreen extends ConsumerWidget {
  const WaiterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readyItems = ref.watch(readyItemsProvider);

    // Lắng nghe notification popup (flash snackbar)
    ref.listen<WaiterNotification?>(waiterNotificationProvider, (prev, next) {
      if (next == null) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                next.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(next.body, style: const TextStyle(fontSize: 14)),
            ],
          ),
          backgroundColor:
              next.event == 'ITEM_READY' ? Colors.green.shade700 : Colors.blue.shade700,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'PHỤC VỤ',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(width: 12),
            if (readyItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.dinner_dining, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${readyItems.length} món chờ bưng',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: const TabBar(
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
          tabs: [
            Tab(icon: Icon(Icons.grid_view), text: 'SƠ ĐỒ BÀN'),
            Tab(icon: Icon(Icons.event_seat), text: 'ĐẶT TRƯỚC'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: TabBarView(
        children: [
          // Tab 1: Sơ đồ bàn (Giao diện cũ)
          Row(
            children: [
              // ── Left: Panel "Cần Bưng Ra" ─────────────────────────────────────
              const ReadyItemsPanel(),

              // ── Right: Sơ đồ bàn ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Colors.indigo.shade50,
                      child: const Text(
                        'SƠ ĐỒ BÀN — Bấm vào bàn để gọi món hoặc xem tiến trình',
                        style: TextStyle(fontSize: 13, color: Colors.indigo),
                      ),
                    ),
                    Expanded(
                      child: TableGrid(
                        onTableTap: (table) {
                          if (table.status == TableStatus.empty && table.upcomingReservationTime != null) {
                            final timeStr = DateFormat('HH:mm').format(table.upcomingReservationTime!);
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Bàn đã được giữ', style: TextStyle(color: Colors.red)),
                                content: Text('Bàn này có lịch đặt trước lúc $timeStr.\nKhông thể nhận thêm khách vãng lai. Vui lòng sang tab ĐẶT TRƯỚC để Check-in hoặc Huỷ lịch.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu'))
                                ]
                              )
                            );
                            return;
                          }

                          ref.read(selectedTableIdProvider.notifier).setTableId(table.id);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CreateOrderFlow(
                                tableNumber: table.number.toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tab 2: Danh sách đặt trước
          const ReservationsTab(),
        ],
      ),
    ));
  }
}
