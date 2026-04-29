import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:shared/models/order_item.dart';
import 'package:shared/core/api_client.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String tableId;
  final String orderId;

  const OrderTrackingScreen({
    Key? key,
    required this.tableId,
    required this.orderId,
  }) : super(key: key);

  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  WebSocketChannel? _channel;
  List<OrderItem> _orderItems = [];
  bool _isConnected = false;
  bool _isLoading = true;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;
  int _reconnectAttempts = 0;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _fetchOrderHttp(); // Load data lần đầu
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ─── WebSocket ───────────────────────────────────────────────

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8000/ws/orders/${widget.orderId}'),
      );

      setState(() {
        _isConnected = true;
        _reconnectAttempts = 0;
      });

      _pollingTimer?.cancel(); // Dừng polling khi có WebSocket

      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: (_) => _onDisconnected(),
        onDone: () => _onDisconnected(),
      );
    } catch (e) {
      _onDisconnected();
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);

      // Bỏ qua nếu không phải order này
      if (data['order_id'] != widget.orderId) return;

      if (!mounted) return;
      setState(() {
        _isLoading = false;

        if (data['items'] != null) {
          // Cập nhật toàn bộ danh sách
          _orderItems = (data['items'] as List)
              .map((e) => OrderItem.fromJson(e))
              .toList();
        } else if (data['item_id'] != null) {
          // Cập nhật trạng thái từng món riêng lẻ
          final idx = _orderItems.indexWhere((i) => i.id == data['item_id']);
          if (idx != -1) {
            _orderItems[idx] = _orderItems[idx].copyWith(
              status: data['status'],
            );
          }
        }
      });
    } catch (e) {
      debugPrint('WebSocket parse error: $e');
    }
  }

  void _onDisconnected() {
    if (!mounted) return;
    setState(() => _isConnected = false);
    _startPollingFallback();
    _scheduleReconnect();
  }

  // Tự reconnect sau 3s
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _reconnectAttempts++);
      _connectWebSocket();
    });
  }

  // ─── Fallback Polling mỗi 5s ─────────────────────────────────

  void _startPollingFallback() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isConnected) {
        _pollingTimer?.cancel();
        return;
      }
      _fetchOrderHttp();
    });
  }

  Future<void> _fetchOrderHttp() async {
    try {
      final response = await ApiClient().dio.get('/orders/${widget.orderId}');
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
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────

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

  // ─── UI ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn hàng — Bàn ${widget.tableId}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ① Banner mất kết nối
          if (!_isConnected) _buildDisconnectedBanner(),

          // ② Banner tất cả món đã phục vụ
          if (_allServed) _buildAllServedBanner(),

          // ③ Danh sách món
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

          // ④ Nút gọi thêm món
          _buildOrderMoreButton(),
        ],
      ),
    );
  }

  // Banner đỏ mất kết nối
  Widget _buildDisconnectedBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Mất kết nối — Đang thử kết nối lại...',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(
            'Lần $_reconnectAttempts',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // Banner xanh tất cả phục vụ xong
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

  // Card từng món với badge trạng thái
  Widget _buildItemCard(OrderItem item) {
    final config = _statusConfig(item.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.imageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 56,
              height: 56,
              color: Colors.grey[200],
              child: const Icon(Icons.fastfood, color: Colors.grey),
            ),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'x${item.quantity}  •  \$${item.price}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: _buildStatusBadge(config),
      ),
    );
  }

  // Badge trạng thái
  Widget _buildStatusBadge(Map<String, dynamic> config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config['color'] as Color, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(config['emoji'] as String, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            config['label'] as String,
            style: TextStyle(
              color: config['color'] as Color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Nút gọi thêm món
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
