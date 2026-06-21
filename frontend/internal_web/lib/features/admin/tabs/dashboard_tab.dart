import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';


final List<Map<String, dynamic>> _mockTopItems = [
  {'rank': 1, 'name': 'Bò Lúc Lắc', 'qty': 42, 'revenue': 6_300_000},
  {'rank': 2, 'name': 'Cơm Chiên Dương Châu', 'qty': 38, 'revenue': 3_800_000},
  {'rank': 3, 'name': 'Gà Nướng Mật Ong', 'qty': 31, 'revenue': 4_650_000},
  {'rank': 4, 'name': 'Canh Chua Cá Lóc', 'qty': 27, 'revenue': 2_700_000},
  {'rank': 5, 'name': 'Chả Giò Hải Sản', 'qty': 22, 'revenue': 2_200_000},
];


final List<double> _mockRevenueChart = [8.2, 11.5, 9.8, 14.0, 12.3, 10.6, 15.0];
final List<String> _mockDayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];


class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          _sectionTitle('📊 Tổng Quan Hôm Nay'),
          const SizedBox(height: 16),

          
          LayoutBuilder(
            builder: (_, constraints) {
              final cardWidth = (constraints.maxWidth - 48) / 4;
              return Row(
                children: [
                  _MetricCard(
                    width: cardWidth,
                    icon: Icons.attach_money_rounded,
                    iconColor: const Color(0xFF10B981),
                    bgColor: const Color(0xFFECFDF5),
                    title: 'Doanh thu hôm nay',
                    value: '15.000.000 ₫',
                    sub: '▲ 12% so với hôm qua',
                    subPositive: true,
                  ),
                  const SizedBox(width: 16),
                  _MetricCard(
                    width: cardWidth,
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    bgColor: const Color(0xFFEFF6FF),
                    title: 'Đơn hàng',
                    value: '87',
                    sub: '▼ 3% so với hôm qua',
                    subPositive: false,
                  ),
                  const SizedBox(width: 16),
                  _MetricCard(
                    width: cardWidth,
                    icon: Icons.event_seat_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFFFBEB),
                    title: 'Khách đặt bàn',
                    value: '34',
                    sub: '▲ 8% so với hôm qua',
                    subPositive: true,
                  ),
                  const SizedBox(width: 16),
                  _MetricCard(
                    width: cardWidth,
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFEC4899),
                    bgColor: const Color(0xFFFDF2F8),
                    title: 'Món bán chạy nhất',
                    value: 'Bò Lúc Lắc',
                    sub: '42 suất đã bán',
                    subPositive: true,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          
          LayoutBuilder(
            builder: (_, constraints) {
              final chartW = constraints.maxWidth * 0.62;
              final tableW = constraints.maxWidth * 0.38 - 16;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  _RevenueChart(width: chartW),
                  const SizedBox(width: 16),
                  
                  _TopItemsTable(width: tableW),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      );
}


class _MetricCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String value;
  final String sub;
  final bool subPositive;

  const _MetricCard({
    required this.width,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.value,
    required this.sub,
    required this.subPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: TextStyle(
              fontSize: 11,
              color: subPositive
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


class _RevenueChart extends StatelessWidget {
  final double width;
  const _RevenueChart({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh Thu 7 Ngày Qua',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Đơn vị: Triệu VNĐ',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (val, _) => Text(
                        '${val.toInt()}M',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= _mockDayLabels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _mockDayLabels[idx],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 18,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _mockRevenueChart.length,
                      (i) => FlSpot(i.toDouble(), _mockRevenueChart[i]),
                    ),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2.5,
                            strokeColor: const Color(0xFF3B82F6),
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.18),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _TopItemsTable extends StatelessWidget {
  final double width;
  const _TopItemsTable({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Top Món Bán Chạy',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hôm nay',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Tên món',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Text(
                  'Số lượng',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          ..._mockTopItems.map(
            (item) => _TopItemRow(
              rank: item['rank'] as int,
              name: item['name'] as String,
              qty: item['qty'] as int,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopItemRow extends StatelessWidget {
  final int rank;
  final String name;
  final int qty;
  const _TopItemRow({
    required this.rank,
    required this.name,
    required this.qty,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFF59E0B); 
      case 2:
        return const Color(0xFF94A3B8); 
      case 3:
        return const Color(0xFFCD7C2F); 
      default:
        return const Color(0xFFCBD5E1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _rankColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$qty suất',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
