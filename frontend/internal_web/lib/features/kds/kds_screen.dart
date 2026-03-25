import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'kds_provider.dart';
import 'order_card.dart';
import '../auth/auth_notifier.dart';
import '../../models/order.dart';

class KdsScreen extends ConsumerWidget {
  const KdsScreen({super.key});

  List<Map<String, dynamic>> _groupItems(List<OrderItemModel> items) {
    final Map<String, List<OrderItemModel>> pendingGroups = {};
    final List<Map<String, dynamic>> result = [];
    
    for (var item in items) {
      if (item.status == OrderItemStatus.pending) {
        final key = '${item.menuItemId}_${item.variantName}_${item.note}';
        if (!pendingGroups.containsKey(key)) {
          pendingGroups[key] = [];
        }
        pendingGroups[key]!.add(item);
      } else {
        result.add({'item': item, 'batchedQty': 1});
      }
    }

    pendingGroups.forEach((key, list) {
      // Create a batched node using the oldest item as representative
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      result.add({'item': list.first, 'batchedQty': list.length, 'group': list});
    });

    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kdsAsync = ref.watch(kdsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('KITCHEN DISPLAY SYSTEM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
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
      body: kdsAsync.when(
        data: (items) {
          final grouped = _groupItems(items);
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final map = grouped[index];
              final item = map['item'] as OrderItemModel;
              final batchedQty = map['batchedQty'] as int;
              final group = map['group'] as List<OrderItemModel>?;

              return OrderCard(
                item: item,
                batchedQty: batchedQty,
                onStatusChange: (newStatus) {
                  if (group != null) {
                    for (var gItem in group) {
                      ref.read(kdsProvider.notifier).updateStatus(gItem.id, newStatus);
                    }
                  } else {
                    ref.read(kdsProvider.notifier).updateStatus(item.id, newStatus);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}
