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

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
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
      backgroundColor: const Color(0xFFF1F5F9), // Slate 50
      body: Row(
        children: [
          // SIDEBAR (Premium Dark Theme)
          Container(
            width: 260,
            color: const Color(0xFF0F172A), // Slate 900
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'ROS Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Menu Items
                _buildMenuItem(Icons.restaurant_menu_outlined, 'Thực đơn', 0),
                _buildMenuItem(Icons.table_restaurant_outlined, 'Sơ đồ Bàn', 1),
                _buildMenuItem(Icons.people_alt_outlined, 'Nhân sự', 2),
                _buildMenuItem(
                  Icons.inventory_2_outlined,
                  'Kho & Định Lượng',
                  3,
                ),

                const Spacer(),

                // User Profile & Logout Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B), // Slate 800
                    border: Border(
                      top: BorderSide(color: Color(0xFF334155), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          'AD',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administrator',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'admin@ros.com',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        tooltip: 'Đăng xuất',
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/login');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior:
                        Clip.antiAlias, // To ensure tabs respect border radius
                    child: TabBarView(
                      controller: _tabController,
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable swipe if needed on web
                      children: const [
                        MenuTab(),
                        TableTab(),
                        UserTab(),
                        InventoryTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Chào mừng trở lại, hãy quản lý nhà hàng của bạn.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 300,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Slate 50
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF475569),
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final isSelected = _tabController.index == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _tabController.index = index;
          });
        },
        hoverColor: const Color(0xFF1E293B),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 4,
              ),
            ),
            color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.blueAccent
                    : const Color(0xFF94A3B8), // Slate 400
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
