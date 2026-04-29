import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/api_client.dart';
import 'package:shared/models/cart_item.dart';
import '../providers.dart';

class CartScreen extends ConsumerStatefulWidget {
  final String tableId;
  const CartScreen({super.key, required this.tableId});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(List<CartItem> cart) async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      _snack('Vui lòng nhập họ tên và số điện thoại', error: true);
      return;
    }
    if (cart.isEmpty) return;

    setState(() => _submitting = true);

    try {
      // Build OrderCreate payload theo backend schema
      final items = cart.map((c) => {
            'menu_item_id': c.menuItem.id,
            'qty': c.quantity,
            if (c.selectedVariant != null) 'variant_id': c.selectedVariant!.id,
            'modifier_ids': c.selectedModifiers.map((m) => m.id).toList(),
            if (c.note != null) 'note': c.note,
          }).toList();

      final res = await ApiClient().dio.post('/orders', data: {
        'table_id': widget.tableId,
        'customer_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'type': 'DINE_IN',
        'items': items,
      });

      final orderId = res.data['data']?['id'] as String?;
      if (!mounted) return;

      if (orderId != null) {
        ref.read(cartProvider.notifier).clear();
        context.go('/table/${widget.tableId}/tracking/$orderId');
      } else {
        _snack('Không nhận được mã đơn hàng', error: true);
      }
    } catch (e) {
      if (mounted) _snack('Lỗi đặt món: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).totalAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Giỏ hàng (${cart.length} loại)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: cart.isEmpty
          ? _EmptyCart(tableId: widget.tableId)
          : Column(
              children: [
                // ── Danh sách món ────────────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) =>
                        _CartItemTile(item: cart[index], index: index),
                  ),
                ),

                // ── Form thông tin + đặt hàng ────────────────────────────────
                _OrderForm(
                  nameCtrl: _nameCtrl,
                  phoneCtrl: _phoneCtrl,
                  total: total,
                  submitting: _submitting,
                  onSubmit: () => _placeOrder(cart),
                ),
              ],
            ),
    );
  }
}

// ── Cart Item Tile ─────────────────────────────────────────────────────────────

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  final int index;
  const _CartItemTile({required this.item, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitPrice = item.totalPrice / item.quantity;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh nhỏ
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.menuItem.imageUrl != null &&
                    item.menuItem.imageUrl!.isNotEmpty
                ? Image.network(
                    item.menuItem.imageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),
          const SizedBox(width: 12),

          // Thông tin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.menuItem.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (item.selectedVariant != null)
                  Text(item.selectedVariant!.name,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                if (item.selectedModifiers.isNotEmpty)
                  Text(
                      item.selectedModifiers.map((m) => m.name).join(', '),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                if (item.note != null && item.note!.isNotEmpty)
                  Text('📝 ${item.note}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Qty control
                    Row(
                      children: [
                        _qtyBtn(Icons.remove, item.quantity > 1
                            ? () => ref
                                .read(cartProvider.notifier)
                                .updateQty(index, item.quantity - 1)
                            : null),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${item.quantity}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        _qtyBtn(Icons.add, () => ref
                            .read(cartProvider.notifier)
                            .updateQty(index, item.quantity + 1)),
                      ],
                    ),
                    // Giá
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.totalPrice.toStringAsFixed(0)} ₫',
                          style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        if (item.quantity > 1)
                          Text(
                            '${unitPrice.toStringAsFixed(0)} ₫/món',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Xóa
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () =>
                ref.read(cartProvider.notifier).removeItem(index),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width: 64,
        height: 64,
        color: Colors.grey.shade100,
        child:
            Icon(Icons.fastfood_outlined, color: Colors.grey.shade300, size: 32),
      );

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon,
              size: 16,
              color: onTap == null ? Colors.grey.shade300 : Colors.black87),
        ),
      );
}

// ── Order Form ─────────────────────────────────────────────────────────────────

class _OrderForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final double total;
  final bool submitting;
  final VoidCallback onSubmit;

  const _OrderForm({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.total,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(0, -2),
              blurRadius: 8),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Tổng tiền ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tạm tính:',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              Text('${total.toStringAsFixed(0)} ₫',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53935))),
            ],
          ),
          const SizedBox(height: 12),

          // ── Họ tên & SĐT ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _inputField(
                  controller: nameCtrl,
                  label: 'Họ tên',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inputField(
                  controller: phoneCtrl,
                  label: 'Số điện thoại',
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Nút đặt món ──────────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              icon: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(
                submitting ? 'Đang gửi...' : 'Đặt món ngay',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: submitting ? null : onSubmit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
      ),
    );
  }
}

// ── Empty Cart ─────────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  final String tableId;
  const _EmptyCart({required this.tableId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Giỏ hàng trống',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Thêm món để tiếp tục',
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Xem thực đơn'),
            onPressed: () => context.go('/table/$tableId'),
          ),
        ],
      ),
    );
  }
}
