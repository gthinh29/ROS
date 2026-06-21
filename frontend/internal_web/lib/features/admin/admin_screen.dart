import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/menu_tab.dart';
import 'tabs/table_tab.dart';
import 'tabs/user_tab.dart';
import 'tabs/inventory_tab.dart';


class _NavItem {
  final IconData icon;
  final IconData iconFilled;
  final String title;

  const _NavItem({
    required this.icon,
    required this.iconFilled,
    required this.title,
  });
}

const _navItems = <_NavItem>[
  _NavItem(
    icon: Icons.dashboard_outlined,
    iconFilled: Icons.dashboard_rounded,
    title: 'Tổng Quan',
  ),
  _NavItem(
    icon: Icons.restaurant_menu_outlined,
    iconFilled: Icons.restaurant_menu,
    title: 'Thực đơn',
  ),
  _NavItem(
    icon: Icons.table_restaurant_outlined,
    iconFilled: Icons.table_restaurant,
    title: 'Sơ đồ Bàn',
  ),
  _NavItem(
    icon: Icons.people_alt_outlined,
    iconFilled: Icons.people_alt,
    title: 'Nhân sự',
  ),
  _NavItem(
    icon: Icons.inventory_2_outlined,
    iconFilled: Icons.inventory_2,
    title: 'Kho & Định Lượng',
  ),
  _NavItem(
    icon: Icons.bar_chart_outlined,
    iconFilled: Icons.bar_chart,
    title: 'Báo cáo',
  ),
];


const _tabTitles = [
  'Tổng Quan',
  'Thực Đơn',
  'Sơ Đồ Bàn',
  'Nhân Sự',
  'Kho & Định Lượng',
  'Báo Cáo Chi Tiết',
];

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
    _tabController = TabController(length: _navItems.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), 
      body: Row(
        children: [
          
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A), 
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(4, 0),
                ),
              ],
            ),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ROS Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Restaurant OS',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 8),
                  child: Text(
                    'MENU CHÍNH',
                    style: TextStyle(
                      color: const Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                
                ...List.generate(5, (i) => _buildMenuItem(_navItems[i], i)),

                const SizedBox(height: 24),

                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(
                    color: Color(0xFF1E293B),
                    thickness: 1,
                  ),
                ),
                const SizedBox(height: 16),

                
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 8),
                  child: Text(
                    'PHÂN TÍCH',
                    style: TextStyle(
                      color: const Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                
                _buildMenuItem(_navItems[5], 5),

                const Spacer(),

                
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'AD',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administrator',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'admin@ros.com',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFF94A3B8),
                          size: 18,
                        ),
                        tooltip: 'Đăng xuất',
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/login');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          
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
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        DashboardTab(),
                        MenuTab(),
                        TableTab(),
                        UserTab(),
                        InventoryTab(),
                        _ReportsTab(),
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
    final idx = _tabController.index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tabTitles[idx],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Hệ thống quản lý nhà hàng ROS',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const Spacer(),
          
          Container(
            width: 280,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF475569),
                    size: 20,
                  ),
                  onPressed: () {},
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
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

  Widget _buildMenuItem(_NavItem item, int index) {
    final isSelected = _tabController.index == index;

    return _SidebarNavItem(
      icon: item.icon,
      iconFilled: item.iconFilled,
      title: item.title,
      isSelected: isSelected,
      onTap: () => setState(() => _tabController.index = index),
    );
  }
}


class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final IconData iconFilled;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.iconFilled,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final showHighlight = widget.isSelected || _hovered;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? const Color(0xFF1E40AF).withValues(alpha: 0.9)
                    : _hovered
                        ? const Color(0xFF1E293B)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: widget.isSelected
                    ? Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      showHighlight ? widget.iconFilled : widget.icon,
                      key: ValueKey(showHighlight),
                      color: widget.isSelected
                          ? const Color(0xFF93C5FD)
                          : _hovered
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.isSelected
                            ? Colors.white
                            : _hovered
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  
                  if (widget.isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Báo Cáo Chi Tiết',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Lọc và xem báo cáo doanh thu, đơn hàng theo khoảng thời gian',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const Spacer(),
              
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  _range == null
                      ? 'Chọn khoảng thời gian'
                      : '${_formatDate(_range!.start)} → ${_formatDate(_range!.end)}',
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                    initialDateRange: _range,
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF3B82F6),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _range = picked);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 24),

          
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 80,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _range == null
                        ? 'Chọn khoảng thời gian để xem báo cáo'
                        : 'Đang tải báo cáo từ ${_formatDate(_range!.start)} đến ${_formatDate(_range!.end)}...',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  if (_range != null) ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('Xuất báo cáo (CSV)'),
                      onPressed: () {},
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
