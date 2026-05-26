import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/api_client.dart';
import 'package:shared/models/category.dart';
import 'package:shared/models/menu.dart';
import '../../providers.dart';

const _primaryColor = Color(0xFFE53935);
const _gradient = LinearGradient(
  colors: [Color(0xFFE53935), Color(0xFFC62828)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

final _categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final res = await ApiClient().dio.get(
    '/menu/categories',
    options: Options(validateStatus: (s) => s != null && s < 500),
  );
  if (res.statusCode != 200) throw Exception('Lỗi tải danh mục (${res.statusCode})');
  final data = res.data is Map ? (res.data['data'] as List? ?? []) : [];
  return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
});

final _itemsProvider =
    FutureProvider.autoDispose.family<List<MenuItem>, String>((ref, categoryId) async {
  final res = await ApiClient().dio.get(
    '/menu/items',
    queryParameters: {'category_id': categoryId, 'is_available': true},
    options: Options(validateStatus: (s) => s != null && s < 500),
  );
  if (res.statusCode != 200) throw Exception('Lỗi tải món (${res.statusCode})');
  final data = res.data is Map ? (res.data['data'] as List? ?? []) : [];
  return data.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
});

class PreOrderPickerScreen extends ConsumerStatefulWidget {
  const PreOrderPickerScreen({super.key});

  @override
  ConsumerState<PreOrderPickerScreen> createState() => _PreOrderPickerScreenState();
}

class _PreOrderPickerScreenState extends ConsumerState<PreOrderPickerScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(_categoriesProvider);
    final preOrder = ref.watch(preOrderProvider);
    final totalQty = ref.read(preOrderProvider.notifier).totalQty;
    final totalAmount = ref.read(preOrderProvider.notifier).totalAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Chọn món đặt trước',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _gradient)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (preOrder.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(preOrderProvider.notifier).clear();
              },
              child: const Text('Xoá hết',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: categoriesAsync.when(
        data: (cats) {
          if (cats.isEmpty) {
            return _buildEmpty('Nhà hàng chưa có danh mục món nào');
          }
          _selectedCategoryId ??= cats.first.id;
          return Column(
            children: [
              _buildHint(),
              _buildCategoryBar(cats),
              Expanded(child: _buildItemList()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: _primaryColor)),
        error: (e, _) => _buildError('$e'),
      ),
      bottomNavigationBar: preOrder.isEmpty
          ? null
          : _buildBottomBar(totalQty, totalAmount),
    );
  }

  Widget _buildHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.shade50,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Các tuỳ chọn thêm (topping, ghi chú) sẽ điều chỉnh khi bạn đến nơi.',
              style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(List<Category> categories) {
    return Container(
      color: Colors.white,
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = cat.id == _selectedCategoryId;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategoryId = cat.id),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  gradient: selected ? _gradient : null,
                  color: selected ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(cat.name,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      )),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemList() {
    if (_selectedCategoryId == null) {
      return const SizedBox.shrink();
    }
    final itemsAsync = ref.watch(_itemsProvider(_selectedCategoryId!));
    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmpty('Danh mục này chưa có món');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _PreOrderItemTile(item: items[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: _primaryColor)),
      error: (e, _) => _buildError('$e'),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(msg, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(int totalQty, double totalAmount) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$totalQty món đã chọn',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 2),
                Text('${totalAmount.toStringAsFixed(0)} ₫',
                    style: const TextStyle(
                        color: _primaryColor, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
          Container(
            height: 48,
            constraints: const BoxConstraints(minWidth: 140),
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => context.pop(),
              child: const Text('Xong',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreOrderItemTile extends ConsumerStatefulWidget {
  final MenuItem item;
  const _PreOrderItemTile({required this.item});

  @override
  ConsumerState<_PreOrderItemTile> createState() => _PreOrderItemTileState();
}

class _PreOrderItemTileState extends ConsumerState<_PreOrderItemTile> {
  Variant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    if (widget.item.variants.isNotEmpty) {
      _selectedVariant = widget.item.variants.first;
    }
  }

  int _currentQty() {
    final list = ref.read(preOrderProvider);
    for (final p in list) {
      if (p.menuItem.id == widget.item.id && p.variant?.id == _selectedVariant?.id) {
        return p.qty;
      }
    }
    return 0;
  }

  void _adjust(int delta) {
    final list = ref.read(preOrderProvider);
    final idx = list.indexWhere((p) =>
        p.menuItem.id == widget.item.id && p.variant?.id == _selectedVariant?.id);
    if (idx == -1) {
      if (delta > 0) {
        ref.read(preOrderProvider.notifier).add(widget.item, variant: _selectedVariant);
      }
    } else {
      ref.read(preOrderProvider.notifier).updateQty(idx, list[idx].qty + delta);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(preOrderProvider);
    final qty = _currentQty();
    final price = widget.item.basePrice + (_selectedVariant?.extraPrice ?? 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: qty > 0 ? _primaryColor : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: (widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty)
                      ? Image.network(
                          widget.item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14, height: 1.2)),
                    const SizedBox(height: 4),
                    Text('${price.toStringAsFixed(0)} ₫',
                        style: const TextStyle(
                            color: _primaryColor, fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildQtyControl(qty),
            ],
          ),
          if (widget.item.variants.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildVariantChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(Icons.fastfood, color: Colors.grey.shade300, size: 24),
    );
  }

  Widget _buildVariantChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.item.variants.map((v) {
        final selected = _selectedVariant?.id == v.id;
        return InkWell(
          onTap: () => setState(() => _selectedVariant = v),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? _primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _primaryColor : Colors.transparent,
                width: 1,
              ),
            ),
            child: Text(
              v.extraPrice > 0
                  ? '${v.name} (+${v.extraPrice.toStringAsFixed(0)} ₫)'
                  : v.name,
              style: TextStyle(
                color: selected ? _primaryColor : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQtyControl(int qty) {
    if (qty == 0) {
      return InkWell(
        onTap: () => _adjust(1),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text('Thêm',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _qtyBtn(Icons.remove, () => _adjust(-1)),
          SizedBox(
            width: 28,
            child: Center(
              child: Text('$qty',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          _qtyBtn(Icons.add, () => _adjust(1)),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: Colors.black87),
        ),
      ),
    );
  }
}
