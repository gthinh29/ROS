import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import 'tabs/menu_tab.dart';
import 'tabs/table_tab.dart';
import 'tabs/user_tab.dart';
import 'tabs/inventory_tab.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard - Ban Quản Trị'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Thực đơn', icon: Icon(Icons.restaurant_menu)),
            Tab(text: 'Sơ đồ Bàn', icon: Icon(Icons.table_restaurant)),
            Tab(text: 'Nhân sự', icon: Icon(Icons.people)),
            Tab(text: 'Kho & Định Lượng', icon: Icon(Icons.inventory)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MenuTab(),
          TableTab(),
          UserTab(),
          InventoryTab(),
        ],
      ),
    );
  }
}
