import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reservations_provider.dart';
import 'package:shared/models/reservation.dart';
import 'package:intl/intl.dart';

class ReservationsTab extends ConsumerStatefulWidget {
  const ReservationsTab({super.key});

  @override
  ConsumerState<ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends ConsumerState<ReservationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reservationsProvider.notifier).fetchReservations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservationsProvider);

    if (state.isLoading && state.reservations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Lỗi: ${state.error}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(reservationsProvider.notifier).fetchReservations(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // Lọc ra các đặt bàn chưa check-in hoặc chưa huỷ
    final activeReservations = state.reservations.where((r) => 
      r.status == ReservationStatus.pending || 
      r.status == ReservationStatus.confirmed
    ).toList();

    // Sắp xếp theo giờ đặt tăng dần
    activeReservations.sort((a, b) => a.reservedAt.compareTo(b.reservedAt));

    if (activeReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Không có lịch hẹn nào sắp tới', style: TextStyle(fontSize: 18, color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới'),
              onPressed: () => ref.read(reservationsProvider.notifier).fetchReservations(),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(reservationsProvider.notifier).fetchReservations(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeReservations.length,
        itemBuilder: (context, index) {
          final res = activeReservations[index];
          final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(res.reservedAt);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Icon(Icons.person, color: Colors.indigo.shade800),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          res.customerName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('SĐT: ${res.phone}', style: const TextStyle(color: Colors.black87)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(timeStr, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(width: 16),
                            const Icon(Icons.people, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${res.partySize} khách', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        if (res.note != null && res.note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Ghi chú: ${res.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Check-in'),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xác nhận Check-in'),
                          content: Text('Xác nhận khách hàng ${res.customerName} đã đến? Bàn sẽ được tự động mở.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Huỷ'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Check-in'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final success = await ref.read(reservationsProvider.notifier).checkin(res.id);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Check-in thành công! Bàn đã được mở.')),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Check-in thất bại. Vui lòng thử lại.')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
