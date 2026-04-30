import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/models/order_item.dart';
import 'package:shared/core/api_client.dart';
import '../../providers.dart';

const primaryColor = Color(0xFFE53935);

class TrackingSidebar extends ConsumerStatefulWidget {
  const TrackingSidebar({super.key});

  @override
  ConsumerState<TrackingSidebar> createState() => _TrackingSidebarState();
}

class _TrackingSidebarState extends ConsumerState<TrackingSidebar> {
  List<OrderItem> _allItems = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Delay first fetch until build is done so we can read provider safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllOrders();
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchAllOrders();
    });
  }

  Future<void> _fetchAllOrders() async {
    final orderIds = ref.read(activeOrdersProvider);
    if (orderIds.isEmpty) {
      if (mounted) {
        setState(() {
          _allItems = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      List<OrderItem> aggregated = [];
      for (final id in orderIds) {
        final response = await ApiClient().dio.get('/orders/$id/tracking');
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = response.data;
          final List items = responseData['data']?['items'] ?? [];
          aggregated.addAll(items.map((e) => OrderItem.fromJson(e)).toList());
        }
      }

      // Auto cleanup completed orders if all items in an order are SERVED?
      // For simplicity, just display them. If all are served, the banner handles it.

      if (mounted) {
        setState(() {
          _allItems = aggregated;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Polling multiple orders error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case 'PENDING':
        return {
          'label': 'Chờ bếp',
          'color': Colors.orange.shade700,
          'emoji': '🟠',
        };
      case 'PREPARING':
        return {
          'label': 'Đang làm',
          'color': Colors.blue.shade700,
          'emoji': '🔥',
        };
      case 'READY':
        return {
          'label': 'Sắp ra',
          'color': Colors.purple.shade600,
          'emoji': '✨',
        };
      case 'SERVED':
        return {
          'label': 'Đã phục vụ',
          'color': Colors.green.shade700,
          'emoji': '✅',
        };
      default:
        return {'label': status, 'color': Colors.grey.shade600, 'emoji': '⚪'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = ref.watch(activeOrdersProvider);
    final hasOrders = activeOrders.isNotEmpty;

    // Trigger fetch ngay lập tức nếu danh sách order thay đổi (được load từ cache hoặc vừa thêm mới)
    ref.listen<List<String>>(activeOrdersProvider, (previous, next) {
      if (previous == null || previous.length != next.length) {
        _fetchAllOrders();
      }
    });

    return Container(
      width: 320,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tiến trình món',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Theo dõi món ăn đang được chuẩn bị',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: !hasOrders
                ? _buildEmptyState()
                : _isLoading && _allItems.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                : _allItems.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        _buildSidebarItemCard(_allItems[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có đơn hàng nào',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Các món bạn đặt sẽ hiện ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItemCard(OrderItem item) {
    final config = _statusConfig(item.status);
    final statusColor = config['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'x${item.quantity}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge smaller
                _buildStatusBadge(config),
              ],
            ),
          ),
          // Vertical indicator bar
          Positioned(
            left: 0,
            top: 12,
            bottom: 12,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey.shade100,
      child: Icon(Icons.fastfood, color: Colors.grey.shade300, size: 20),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> config) {
    final color = config['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${config['emoji']} ${config['label']}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
