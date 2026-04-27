import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import 'table_grid.dart';
import 'bill_detail.dart';
import 'billing_provider.dart';
import 'package:shared/models/table.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Screen - Thu ngân'),
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
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: TableGrid(
              onTableTap: (table) {
                if (table.status == TableStatus.occupied) {
                  ref.read(billingProvider.notifier).fetchBillForTable(table.id);
                } else {
                  ref.read(currentBillProvider.notifier).setBill(null);
                  ref.read(billingErrorProvider.notifier).setError('Bàn này chưa có khách.');
                }
              },
            ),
          ),
          const Expanded(
            flex: 1,
            child: BillDetailPane(),
          )
        ],
      ),
    );
  }
}
