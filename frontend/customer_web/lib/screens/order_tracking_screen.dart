import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/models/order_item.dart';
import 'package:shared/core/api_client.dart';

const primaryColor = Color(0xFFE53935);
const gradientBackground = LinearGradient(
  colors: [Color(0xFFE53935), Color(0xFFC62828)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String tableId;
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.tableId,
    required this.orderId,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  List<OrderItem> _orderItems = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrderHttp();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchOrderHttp();
    });
  }

  Future<void> _fetchOrderHttp() async {
    try {
      final response = await ApiClient().dio.get('/orders/${widget.orderId}/tracking');
      if (response.statusCode == 200 && mounted) {
        final Map<String, dynamic> responseData = response.data;
        final List items = responseData['data']?['items'] ?? [];
        setState(() {
          _orderItems = items.map((e) => OrderItem.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Polling error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case 'PENDING':
        return {'label': 'Đang chờ bếp', 'color': Colors.orange.shade700, 'emoji': '🟠'};
      case 'PREPARING':
        return {'label': 'Bếp đang làm', 'color': Colors.blue.shade700, 'emoji': '🔥'};
      case 'READY':
        return {'label': 'Sắp bưng ra', 'color': Colors.purple.shade600, 'emoji': '✨'};
      case 'SERVED':
        return {'label': 'Đã phục vụ', 'color': Colors.green.shade700, 'emoji': '✅'};
      default:
        return {'label': status, 'color': Colors.grey.shade600, 'emoji': '⚪'};
    }
  }

  bool get _allServed =>
      _orderItems.isNotEmpty &&
      _orderItems.every((item) => item.status == 'SERVED');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Theo dõi đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: gradientBackground)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/table/${widget.tableId}'),
        ),
      ),
      body: Column(
        children: [
          if (_allServed) _buildAllServedBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : _orderItems.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orderItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        _buildItemCard(_orderItems[index]),
                  ),
          ),
          _buildOrderMoreButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Chưa có thông tin đơn hàng', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAllServedBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(bottom: BorderSide(color: Colors.green.shade200)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 24),
          const SizedBox(width: 8),
          Text(
            'Tất cả món đã được phục vụ! Chúc ngon miệng 🍽️',
            style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(OrderItem item) {
    final config = _statusConfig(item.status);
    final statusColor = config['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.imageUrl.isNotEmpty 
                    ? Image.network(
                        item.imageUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Số lượng: ${item.quantity}  •  ${item.price.toStringAsFixed(0)} ₫',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusBadge(config),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Vertical indicator bar
          Positioned(
            left: 0,
            top: 12,
            bottom: 12,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey.shade100,
      child: Icon(Icons.fastfood, color: Colors.grey.shade300, size: 28),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> config) {
    final color = config['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(config['emoji'] as String, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            config['label'] as String,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderMoreButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -4), blurRadius: 16),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor, width: 2),
          boxShadow: [
            BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => context.go('/table/${widget.tableId}'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_shopping_cart, color: primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Gọi thêm món khác',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
