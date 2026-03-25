import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';

class WaiterScreen extends ConsumerWidget {
  const WaiterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiter Screen'),
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
      body: const Center(
        child: Text('Giao diện Waiter đang được xây dựng...', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
