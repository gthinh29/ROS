import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/api_client.dart';
import 'package:shared/models/cart_item.dart';
import 'package:shared/models/category.dart';
import 'package:shared/models/menu.dart';
import '../providers.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final res = await ApiClient().dio.get('/menu/categories');
  final List data = res.data['data'] ?? [];
  return data.map((e) => Category.fromJson(e)).toList();
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final menuItemsProvider =
    FutureProvider.autoDispose.family<List<MenuItem>, String>((ref, categoryId) async {
  final res = await ApiClient().dio.get('/menu/items',
      queryParameters: {'category_id': categoryId, 'is_available': true});
  final List data = res.data['data'] ?? [];
  return data.map((e) => MenuItem.fromJson(e)).toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class MenuScreen extends ConsumerWidget {
  final String tableId;
  const MenuScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context, cart.length, tableId),
      body: Column(
        children: [
          // ── Category Tab Bar ──────────────────────────────────────────────
          categoriesAsync.when(
            data: (cats) => _CategoryBar(
              categories: cats,
              selectedId: selectedCategory,
              onSelect: (id) {
                ref.read(selectedCategoryProvider.notifier).state = id;
              },
            ),
            loading: () => const SizedBox(
              height: 56,
              child: Center(child: LinearProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ── Menu Grid ─────────────────────────────────────────────────────
          Expanded(
            child: selectedCategory == null
                ? _EmptyCategory()
                : _MenuGrid(categoryId: selectedCategory!, tableId: tableId),
          ),
        ],
      ),
      // ── FAB: Giỏ hàng ────────────────────────────────────────────────────
      floatingActionButton: cart.isEmpty
          ? null
          : _CartFAB(tableId: tableId, cart: cart),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, int cartCount, String tableId) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thực đơn',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text('Bàn $tableId',
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
      actions: [
        if (cartCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => context.push('/table/$tableId/cart'),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Category Tab Bar ───────────────────────────────────────────────────────────

class _CategoryBar extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final void Function(String) onSelect;

  const _CategoryBar({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == selectedId;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat.name),
              selected: isSelected,
              onSelected: (_) => onSelect(cat.id),
              selectedColor: const Color(0xFFE53935),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey.shade100,
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }
}

// ── Empty state khi chưa chọn category ───────────────────────────────────────

class _EmptyCategory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Chọn danh mục để xem món',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ── Menu Grid ──────────────────────────────────────────────────────────────────

class _MenuGrid extends ConsumerWidget {
  final String categoryId;
  final String tableId;
  const _MenuGrid({required this.categoryId, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuItemsProvider(categoryId));

    return menuAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text('Không có món nào trong danh mục này.',
                style: TextStyle(color: Colors.grey.shade500)),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _MenuItemCard(item: items[index], tableId: tableId),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text('Lỗi tải menu: $e'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(menuItemsProvider(categoryId)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Menu Item Card ─────────────────────────────────────────────────────────────

class _MenuItemCard extends ConsumerWidget {
  final MenuItem item;
  final String tableId;
  const _MenuItemCard({required this.item, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: item.isAvailable
            ? () => _showAddDialog(context, ref, item)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Ảnh món ─────────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _PlaceholderImage(),
                        )
                      : _PlaceholderImage(),
                  if (!item.isAvailable)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Text('Hết hàng',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),

            // ── Thông tin ────────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.basePrice.toStringAsFixed(0)} ₫',
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (item.isAvailable)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 18),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, MenuItem item) {
    Variant? selectedVariant =
        item.variants.isNotEmpty ? item.variants.first : null;
    final Set<Modifier> selectedModifiers = {};
    int quantity = 1;
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // Tính giá hiện tại
          double price = item.basePrice;
          if (selectedVariant != null) price += selectedVariant!.extraPrice;
          for (final m in selectedModifiers) {
            price += m.extraPrice;
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Body
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Ảnh + tên
                        if (item.imageUrl != null &&
                            item.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.imageUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          item.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(item.description,
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13)),
                        ],
                        const SizedBox(height: 16),

                        // Variants
                        if (item.variants.isNotEmpty) ...[
                          _SectionLabel('Chọn loại', required: true),
                          ...item.variants.map((v) => RadioListTile<Variant>(
                                dense: true,
                                title: Text(v.name),
                                subtitle: v.extraPrice > 0
                                    ? Text(
                                        '+${v.extraPrice.toStringAsFixed(0)} ₫',
                                        style: const TextStyle(
                                            color: Color(0xFFE53935)))
                                    : null,
                                value: v,
                                groupValue: selectedVariant,
                                activeColor: const Color(0xFFE53935),
                                onChanged: (val) =>
                                    setModalState(() => selectedVariant = val),
                              )),
                          const Divider(),
                        ],

                        // Modifiers
                        if (item.modifiers.isNotEmpty) ...[
                          _SectionLabel('Tùy chọn thêm'),
                          ...item.modifiers
                              .map((m) => CheckboxListTile(
                                    dense: true,
                                    title: Text(m.name),
                                    subtitle: m.extraPrice > 0
                                        ? Text(
                                            '+${m.extraPrice.toStringAsFixed(0)} ₫',
                                            style: const TextStyle(
                                                color: Color(0xFFE53935)))
                                        : null,
                                    value: selectedModifiers.contains(m),
                                    activeColor: const Color(0xFFE53935),
                                    onChanged: (val) => setModalState(() {
                                      if (val == true) {
                                        selectedModifiers.add(m);
                                      } else {
                                        selectedModifiers.remove(m);
                                      }
                                    }),
                                  )),
                          const Divider(),
                        ],

                        // Ghi chú
                        _SectionLabel('Ghi chú'),
                        TextField(
                          controller: noteController,
                          decoration: InputDecoration(
                            hintText: 'Ít đá, không đường, dị ứng...',
                            prefixIcon:
                                const Icon(Icons.edit_note_outlined),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // ── Bottom bar: số lượng + giá + nút thêm ──────────────
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.of(context).padding.bottom + 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          offset: const Offset(0, -2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Số lượng
                        Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onTap: quantity > 1
                                    ? () => setModalState(() => quantity--)
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Text('$quantity',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                              _QtyButton(
                                icon: Icons.add,
                                onTap: () =>
                                    setModalState(() => quantity++),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Nút Thêm vào giỏ
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              ref.read(cartProvider.notifier).addItem(
                                    CartItem(
                                      menuItem: item,
                                      selectedVariant: selectedVariant,
                                      selectedModifiers:
                                          selectedModifiers.toList(),
                                      quantity: quantity,
                                      note: noteController.text.trim().isEmpty
                                          ? null
                                          : noteController.text.trim(),
                                    ),
                                  );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('Đã thêm ${item.name} 🛒'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ));
                            },
                            child: Text(
                              'Thêm vào giỏ  •  ${(price * quantity).toStringAsFixed(0)} ₫',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          if (required) ...[
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Bắt buộc',
                  style: TextStyle(color: Colors.white, fontSize: 10)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(),
        child: Icon(icon,
            size: 18,
            color:
                onTap == null ? Colors.grey.shade300 : Colors.black87),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(Icons.fastfood_outlined,
          size: 48, color: Colors.grey.shade300),
    );
  }
}

// ── Cart FAB ──────────────────────────────────────────────────────────────────

class _CartFAB extends ConsumerWidget {
  final String tableId;
  final List cart;
  const _CartFAB({required this.tableId, required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(cartProvider.notifier).totalAmount;
    final itemCount = ref.watch(cartProvider.notifier).totalItems;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => context.push('/table/$tableId/cart'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$itemCount món',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Text('Xem giỏ hàng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${total.toStringAsFixed(0)} ₫',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
