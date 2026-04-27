import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/menu.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';
import 'menu_provider.dart';
import 'cart_provider.dart';
import 'order_progress_provider.dart';

class CreateOrderFlow extends ConsumerStatefulWidget {
  final String? tableNumber;
  const CreateOrderFlow({super.key, this.tableNumber});

  @override
  ConsumerState<CreateOrderFlow> createState() => _CreateOrderFlowState();
}

class _CreateOrderFlowState extends ConsumerState<CreateOrderFlow>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddToCartDialog(MenuItem item) {
    Variant? selectedVariant = item.variants.isNotEmpty ? item.variants.first : null;
    final Set<Modifier> selectedModifiers = {};
    int quantity = 1;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text('Thêm ${item.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.variants.isNotEmpty) ...[
                      const Text('Chọn loại:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...item.variants.map((v) => RadioListTile<Variant>(
                            title: Text('${v.name} (+${v.extraPrice.toStringAsFixed(0)} ₫)'),
                            value: v,
                            groupValue: selectedVariant,
                            onChanged: (val) => setDlgState(() => selectedVariant = val),
                          )),
                      const Divider(),
                    ],
                    if (item.modifiers.isNotEmpty) ...[
                      const Text('Tùy chọn thêm:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...item.modifiers.map((m) => CheckboxListTile(
                            title: Text('${m.name} (+${m.extraPrice.toStringAsFixed(0)} ₫)'),
                            value: selectedModifiers.contains(m),
                            onChanged: (val) {
                              setDlgState(() {
                                if (val == true) {
                                  selectedModifiers.add(m);
                                } else {
                                  selectedModifiers.remove(m);
                                }
                              });
                            },
                          )),
                      const Divider(),
                    ],
                    // Số lượng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số lượng:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => setDlgState(
                                  () { if (quantity > 1) quantity--; }),
                            ),
                            Text('$quantity',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setDlgState(() => quantity++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Ghi chú
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        hintText: 'Ít đá, không đường...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: () {
                    ref.read(cartProvider.notifier).addItem(CartItem(
                      menuItem: item,
                      selectedVariant: selectedVariant,
                      selectedModifiers: selectedModifiers.toList(),
                      quantity: quantity,
                      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Đã thêm ${item.name} vào giỏ'),
                      duration: const Duration(seconds: 1),
                    ));
                  },
                  label: const Text('Thêm vào giỏ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tableId = ref.read(selectedTableIdProvider);
    final tableLabel = widget.tableNumber != null ? 'Bàn ${widget.tableNumber}' : 'Bàn khách';

    return Scaffold(
      appBar: AppBar(
        title: Text('$tableLabel — Gọi Món & Tiến Trình'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu), text: 'GỌI MÓN MỚI'),
            Tab(icon: Icon(Icons.track_changes), text: 'TIẾN TRÌNH ĐƠN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Gọi Món Mới ───────────────────────────────────────────
          _OrderTab(onAddItem: _showAddToCartDialog),

          // ── Tab 2: Tiến Trình Đơn ────────────────────────────────────────
          tableId != null
              ? _ProgressTab(tableId: tableId, tableLabel: tableLabel)
              : const Center(child: Text('Chưa chọn bàn')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Gọi Món Mới (Menu + Giỏ hàng)
// ─────────────────────────────────────────────────────────────────────────────

class _OrderTab extends ConsumerWidget {
  final void Function(MenuItem) onAddItem;
  const _OrderTab({required this.onAddItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);
    final cart = ref.watch(cartProvider);

    return Row(
      children: [
        // Menu Grid
        Expanded(
          flex: 2,
          child: menuAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('Không có món nào.'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onAddItem(item),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              color: Colors.grey.shade100,
                              child: item.imageUrl != null
                                  ? Image.network(item.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) =>
                                          const Icon(Icons.fastfood, size: 48, color: Colors.grey))
                                  : const Icon(Icons.fastfood, size: 48, color: Colors.grey),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.basePrice.toStringAsFixed(0)} ₫',
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Lỗi: $e')),
          ),
        ),

        // Giỏ hàng
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                color: Colors.indigo.shade50,
                width: double.infinity,
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, size: 20),
                    const SizedBox(width: 8),
                    Text('GIỎ HÀNG (${cart.length} loại)',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
              Expanded(
                child: cart.isEmpty
                    ? const Center(
                        child: Text('Chưa có món nào', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: cart.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final cItem = cart[index];
                          return ListTile(
                            dense: true,
                            title: Text(cItem.menuItem.name,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${cItem.quantity} x ${(cItem.totalPrice / cItem.quantity).toStringAsFixed(0)} ₫'
                              '${cItem.note != null ? "\n📝 ${cItem.note}" : ""}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () =>
                                  ref.read(cartProvider.notifier).removeItem(index),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, offset: Offset(0, -2), blurRadius: 4)
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Consumer(builder: (_, ref, _) {
                          return Text(
                            '${ref.read(cartProvider.notifier).totalAmount.toStringAsFixed(0)} ₫',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: cart.isEmpty
                            ? null
                            : () async {
                                final success =
                                    await ref.read(cartProvider.notifier).submitOrder();
                                if (!context.mounted) return;
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Đã gửi đơn vào bếp!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('❌ Lỗi khi gửi đơn, thử lại!'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.send),
                        label: const Text('GỬI BẾP',
                            style:
                                TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Tiến Trình Đơn
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressTab extends ConsumerWidget {
  final String tableId;
  final String tableLabel;
  const _ProgressTab({required this.tableId, required this.tableLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(orderProgressProvider(tableId));

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(orderProgressProvider(tableId)),
      child: progressAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Chưa có món nào trong đơn này.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (ctx, index) {
              return _ProgressItemTile(item: items[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text('Lỗi: $e'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(orderProgressProvider(tableId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressItemTile extends StatelessWidget {
  final OrderItemModel item;
  const _ProgressItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _statusInfo(item.status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),

          // Tên món + tùy chọn
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${item.qty}x ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600),
                    ),
                    Expanded(
                      child: Text(
                        item.menuItemName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.variantName != null)
                  Text(item.variantName!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                if (item.note != null && item.note!.isNotEmpty)
                  Text('📝 ${item.note!}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),

          // Badge trạng thái
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _statusInfo(OrderItemStatus status) {
    return switch (status) {
      OrderItemStatus.pending => (
          Icons.hourglass_empty, Colors.grey.shade600, 'CHỜ NẤU'),
      OrderItemStatus.preparing => (
          Icons.whatshot, Colors.orange.shade700, 'ĐANG NẤU'),
      OrderItemStatus.ready => (
          Icons.check_circle, Colors.green.shade600, 'ĐÃ XONG'),
      OrderItemStatus.served => (
          Icons.done_all, Colors.blue.shade600, 'ĐÃ BƯNG'),
      OrderItemStatus.cancelled => (
          Icons.cancel, Colors.red.shade600, 'ĐÃ HỦY'),
    };
  }
}
