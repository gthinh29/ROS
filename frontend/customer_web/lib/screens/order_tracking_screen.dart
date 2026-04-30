import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/models/order_item.dart';
import 'package:shared/core/api_client.dart';

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
        return {'label': 'Đang chờ bếp', 'color': Colors.orange, 'emoji': '🟡'};
      case 'PREPARING':
        return {'label': 'Bếp đang làm', 'color': Colors.blue, 'emoji': '🔵'};
      case 'READY':
        return {'label': 'Sắp bưng ra', 'color': Colors.green, 'emoji': '🟢'};
      case 'SERVED':
        return {'label': 'Đã bưng ra bàn', 'color': Colors.teal, 'emoji': '✅'};
      default:
        return {'label': status, 'color': Colors.grey, 'emoji': '⚪'};
    }
  }

  bool get _allServed =>
      _orderItems.isNotEmpty &&
      _orderItems.every((item) => item.status == 'SERVED');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn hàng'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_allServed) _buildAllServedBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orderItems.isEmpty
                ? const Center(child: Text('Không có món nào.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orderItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) =>
                        _buildItemCard(_orderItems[index]),
                  ),
          ),
          _buildOrderMoreButton(),
        ],
      ),
    );
  }

  Widget _buildAllServedBanner() {
    return Container(
      width: double.infinity,
      color: Colors.teal,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Tất cả món đã được phục vụ! Chúc ngon miệng 🍽️',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(OrderItem item) {
    final config = _statusConfig(item.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.imageUrl.isNotEmpty 
            ? Image.network(
                item.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
              )
            : _buildPlaceholderImage(),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'x${item.quantity}  •  ${item.price.toStringAsFixed(0)} ₫',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: _buildStatusBadge(config),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config['color'] as Color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(config['emoji'] as String, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            config['label'] as String,
            style: TextStyle(
              color: config['color'] as Color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.go('/table/${widget.tableId}'),
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Gọi thêm món'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
