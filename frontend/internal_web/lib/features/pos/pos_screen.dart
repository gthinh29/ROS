import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import 'table_grid.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Screen'),
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
      body: const Row(
        children: [
          Expanded(
            flex: 2,
            child: TableGrid(),
          ),
          Expanded(
            flex: 1,
            child: Card(
              margin: EdgeInsets.all(16),
              child: Center(child: Text('Chi tiết Bill đang được xây dựng')),
            ),
          )
        ],
      ),
    );
  }
}
