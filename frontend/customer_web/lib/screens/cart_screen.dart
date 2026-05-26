import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/api_client.dart';
import 'package:shared/models/cart_item.dart';
import '../providers.dart';

const primaryColor = Color(0xFFE53935);
const gradientBackground = LinearGradient(
  colors: [Color(0xFFE53935), Color(0xFFC62828)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class CartScreen extends ConsumerStatefulWidget {
  final String tableId;
  const CartScreen({super.key, required this.tableId});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _submitting = false;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(List<CartItem> cart) async {
    if (cart.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final items = cart.map((c) => {
            'menu_item_id': c.menuItem.id,
            'qty': c.quantity,
            if (c.selectedVariant != null) 'variant_id': c.selectedVariant!.id,
            'modifier_ids': c.selectedModifiers.map((m) => m.id).toList(),
            if (c.note != null) 'note': c.note,
          }).toList();

      final res = await ApiClient().dio.post('/orders', data: {
        'table_id': widget.tableId,
        'type': 'DINE_IN',
        'customer_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'items': items,
      });

      final orderId = res.data['data']?['id'] as String?;
      if (!mounted) return;

      if (orderId != null) {
        ref.read(cartProvider.notifier).clear();
        await ref.read(activeOrdersProvider.notifier).addOrder(orderId);
        if (!mounted) return;
        context.go('/table/${widget.tableId}');
        _snack('Đặt món thành công! Bạn có thể theo dõi tại menu bên trái.');
      } else {
        _snack('Không nhận được mã đơn hàng', error: true);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        _snack('Mất kết nối, thử lại', error: true);
      } else {
        final code = e.response?.statusCode;
        _snack('Lỗi đặt món${code != null ? ' ($code)' : ''}', error: true);
      }
    } catch (e) {
      if (mounted) _snack('Lỗi đặt món: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(error ? Icons.error_outline : Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      backgroundColor: error ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).totalAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Giỏ hàng (${cart.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: gradientBackground)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: cart.isEmpty
          ? _EmptyCart(tableId: widget.tableId)
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...List.generate(cart.length, (i) => Padding(
                        padding: EdgeInsets.only(bottom: i == cart.length - 1 ? 0 : 12),
                        child: _CartItemTile(item: cart[i], index: i),
                      )),
                  const SizedBox(height: 20),
                  _CustomerInfoForm(
                    nameCtrl: _nameCtrl,
                    phoneCtrl: _phoneCtrl,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: _OrderForm(
                total: total,
                submitting: _submitting,
                onSubmit: () => _placeOrder(cart),
              ),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh nhỏ
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: item.menuItem.imageUrl != null && item.menuItem.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.menuItem.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
          ),
          const SizedBox(width: 16),

          // Thông tin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.menuItem.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2)),
                const SizedBox(height: 4),
                if (item.selectedVariant != null)
                  Text('Loại: ${item.selectedVariant!.name}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                if (item.selectedModifiers.isNotEmpty)
                  Text('+ ${item.selectedModifiers.map((m) => m.name).join(', ')}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                if (item.note != null && item.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('📝 ${item.note}',
                        style: TextStyle(fontSize: 13, color: Colors.orange.shade700, fontStyle: FontStyle.italic)),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Qty control
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _qtyBtn(Icons.remove, item.quantity > 1
                              ? () => ref.read(cartProvider.notifier).updateQty(index, item.quantity - 1)
                              : null),
                          SizedBox(
                            width: 32,
                            child: Center(
                              child: Text('${item.quantity}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                          _qtyBtn(Icons.add, () => ref.read(cartProvider.notifier).updateQty(index, item.quantity + 1)),
                        ],
                      ),
                    ),
                    // Giá
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (item.quantity > 1)
                          Text('${unitPrice.toStringAsFixed(0)} ₫/món',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        Text(
                          '${item.totalPrice.toStringAsFixed(0)} ₫',
                          style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Xóa
          Container(
            width: 32,
            alignment: Alignment.topRight,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
              onPressed: () => ref.read(cartProvider.notifier).removeItem(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: Colors.grey.shade100,
        child: Icon(Icons.fastfood, color: Colors.grey.shade300, size: 32),
      );

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: onTap == null ? Colors.grey.shade400 : Colors.black87),
          ),
        ),
      );
}

// ── Order Form ─────────────────────────────────────────────────────────────────

class _OrderForm extends StatelessWidget {
  final double total;
  final bool submitting;
  final VoidCallback onSubmit;

  const _OrderForm({
    required this.total,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), offset: const Offset(0, -4), blurRadius: 16),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
              Text('${total.toStringAsFixed(0)} ₫',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: gradientBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('XÁC NHẬN ĐẶT MÓN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white, letterSpacing: 0.5)),
            ),
          ),
        ],
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))
            ]),
            child: Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text('Giỏ hàng trống', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Thêm món ngon vào giỏ nhé!', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              elevation: 0,
              side: const BorderSide(color: primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Xem thực đơn', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => context.go('/table/$tableId'),
          ),
        ],
      ),
    );
  }
}

// ── Customer Info Form (Tên + SĐT) ─────────────────────────────────────────────

class _CustomerInfoForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;

  const _CustomerInfoForm({
    required this.nameCtrl,
    required this.phoneCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Thông tin liên hệ',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text('*',
                  style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Nhân viên cần để xác nhận đơn của bạn',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _decoration('Họ tên', Icons.badge_outlined),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            decoration: _decoration('Số điện thoại', Icons.phone_outlined),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'Vui lòng nhập số điện thoại';
              if (t.length < 9) return 'Số điện thoại không hợp lệ';
              return null;
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }
}
