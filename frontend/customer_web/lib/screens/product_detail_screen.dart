import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/api_client.dart';
import 'package:shared/models/cart_item.dart';
import 'package:shared/models/menu.dart';
import '../providers.dart';

const _primaryColor = Color(0xFFE53935);
const _gradient = LinearGradient(
  colors: [Color(0xFFE53935), Color(0xFFC62828)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

final menuItemDetailProvider =
    FutureProvider.autoDispose.family<MenuItem, String>((ref, itemId) async {
  final res = await ApiClient().dio.get(
    '/menu/items/$itemId',
    options: Options(validateStatus: (s) => s != null && s < 500),
  );
  if (res.statusCode != 200) {
    throw Exception('Không tải được chi tiết món (${res.statusCode})');
  }
  final data = res.data is Map ? res.data['data'] : null;
  if (data is! Map<String, dynamic>) {
    throw Exception('Dữ liệu trả về không hợp lệ');
  }
  return MenuItem.fromJson(data);
});

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String tableId;
  final String itemId;

  const ProductDetailScreen({
    super.key,
    required this.tableId,
    required this.itemId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Variant? _selectedVariant;
  final Set<Modifier> _selectedModifiers = {};
  int _quantity = 1;
  final TextEditingController _noteCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _initStateFromItem(MenuItem item) {
    if (_initialized) return;
    _initialized = true;
    if (item.variants.isNotEmpty) {
      _selectedVariant = item.variants.first;
    }
  }

  double _calcPrice(MenuItem item) {
    var p = item.basePrice;
    if (_selectedVariant != null) p += _selectedVariant!.extraPrice;
    for (final m in _selectedModifiers) {
      p += m.extraPrice;
    }
    return p;
  }

  void _addToCart(MenuItem item) {
    if (item.variants.isNotEmpty && _selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(child: Text('Vui lòng chọn loại trước khi thêm')),
        ]),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    ref.read(cartProvider.notifier).addItem(CartItem(
          menuItem: item,
          selectedVariant: _selectedVariant,
          selectedModifiers: _selectedModifiers.toList(),
          quantity: _quantity,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        ));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text('Đã thêm ${item.name}',
            style: const TextStyle(fontWeight: FontWeight.bold))),
      ]),
      backgroundColor: const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));

    context.go('/table/${widget.tableId}');
  }

  @override
  Widget build(BuildContext context) {
    final asyncItem = ref.watch(menuItemDetailProvider(widget.itemId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: asyncItem.when(
        data: (item) {
          _initStateFromItem(item);
          return _buildContent(item);
        },
        loading: () => _buildLoading(),
        error: (e, _) => _buildError('$e'),
      ),
    );
  }

  Widget _buildLoading() {
    return Stack(children: [
      _buildAppBar(canPop: true),
      const Padding(
        padding: EdgeInsets.only(top: 200),
        child: Center(child: CircularProgressIndicator(color: _primaryColor)),
      ),
    ]);
  }

  Widget _buildError(String msg) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Lỗi tải món',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 8),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(menuItemDetailProvider(widget.itemId)),
              child: const Text('Thử lại'),
            ),
            TextButton(
              onPressed: () => context.go('/table/${widget.tableId}'),
              child: const Text('Quay về thực đơn'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(MenuItem item) {
    final unitPrice = _calcPrice(item);
    final total = unitPrice * _quantity;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: _primaryColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                  onPressed: () => context.go('/table/${widget.tableId}'),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroImage(item),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.2)),
                      const SizedBox(height: 8),
                      Text('${item.basePrice.toStringAsFixed(0)} ₫',
                          style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.w800, fontSize: 18)),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(item.description,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5)),
                      ],
                      if (!item.isAvailable) ...[
                        const SizedBox(height: 16),
                        _buildOutOfStockBanner(),
                      ],
                      const SizedBox(height: 24),
                      if (item.variants.isNotEmpty) ...[
                        _SectionLabel('Chọn loại', required: true),
                        _buildVariantList(item),
                        const SizedBox(height: 24),
                      ],
                      if (item.modifiers.isNotEmpty) ...[
                        _SectionLabel('Tùy chọn thêm'),
                        _buildModifierList(item),
                        const SizedBox(height: 24),
                      ],
                      _SectionLabel('Ghi chú'),
                      _buildNoteField(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildBottomBar(item, total),
      ],
    );
  }

  Widget _buildAppBar({bool canPop = false}) {
    return Container(
      height: 56 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(gradient: _gradient),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
            onPressed: () => canPop
                ? context.go('/table/${widget.tableId}')
                : context.go('/table/${widget.tableId}'),
          ),
          const Text('Chi tiết món',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildHeroImage(MenuItem item) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    return Container(
      color: Colors.grey.shade200,
      child: hasImage
          ? Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildImagePlaceholder(),
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Colors.grey.shade100,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: _primaryColor),
                );
              },
            )
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: Icon(Icons.fastfood, size: 80, color: Colors.grey.shade300),
    );
  }

  Widget _buildOutOfStockBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.block, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Text('Món hiện đã hết',
              style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildVariantList(MenuItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: item.variants.map((v) {
          final isSelected = _selectedVariant?.id == v.id;
          return InkWell(
            onTap: () => setState(() => _selectedVariant = v),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? _primaryColor : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  if (v.extraPrice > 0)
                    Text('+${v.extraPrice.toStringAsFixed(0)} ₫',
                        style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModifierList(MenuItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: item.modifiers.map((m) {
          final isSelected = _selectedModifiers.contains(m);
          return InkWell(
            onTap: () => setState(() {
              if (isSelected) {
                _selectedModifiers.remove(m);
              } else {
                _selectedModifiers.add(m);
              }
            }),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isSelected ? _primaryColor : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  if (m.extraPrice > 0)
                    Text('+${m.extraPrice.toStringAsFixed(0)} ₫',
                        style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteCtrl,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'VD: Ít đá, không đường, dị ứng đậu phộng...',
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildBottomBar(MenuItem item, double total) {
    final disabled = !item.isAvailable;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                ),
                SizedBox(
                  width: 36,
                  child: Center(
                    child: Text('$_quantity',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onTap: () => setState(() => _quantity++),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: disabled ? null : _gradient,
                color: disabled ? Colors.grey.shade400 : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: disabled
                    ? null
                    : [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: disabled ? null : () => _addToCart(item),
                child: Text(
                  disabled ? 'Hết hàng' : 'Thêm • ${total.toStringAsFixed(0)} ₫',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _SectionLabel(this.label, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
          if (required) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6)),
              child: Text('Bắt buộc',
                  style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 54,
          alignment: Alignment.center,
          child: Icon(icon,
              size: 20,
              color: onTap == null ? Colors.grey.shade400 : Colors.black87),
        ),
      ),
    );
  }
}
