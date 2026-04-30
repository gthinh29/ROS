import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/api_client.dart';
import 'package:shared/models/cart_item.dart';
import 'package:shared/models/category.dart';
import 'package:shared/models/menu.dart';
import '../providers.dart';
import 'widgets/tracking_sidebar.dart';

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

// ── Theme Constants ─────────────────────────────────────────────────────────
const primaryColor = Color(0xFFE53935);
const gradientBackground = LinearGradient(
  colors: [Color(0xFFE53935), Color(0xFFC62828)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Screen ─────────────────────────────────────────────────────────────────────

class MenuScreen extends ConsumerWidget {
  final String tableId;
  const MenuScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Lighter background
      drawer: const Drawer(child: TrackingSidebar()),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          final menuContent = _MenuMainContent(tableId: tableId, isWide: isWide);

          if (isWide) {
            return Row(
              children: [
                const TrackingSidebar(),
                // Divider
                Container(width: 1, color: Colors.grey.shade300),
                Expanded(child: menuContent),
              ],
            );
          } else {
            return menuContent;
          }
        },
      ),
    );
  }
}

class _MenuMainContent extends ConsumerWidget {
  final String tableId;
  final bool isWide;
  const _MenuMainContent({required this.tableId, required this.isWide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, ref),
        SliverToBoxAdapter(
          child: categoriesAsync.when(
            data: (cats) {
              // Auto-select first category if none selected
              if (selectedCategory == null && cats.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(selectedCategoryProvider.notifier).state = cats.first.id;
                });
              }
              return _CategoryBar(
                categories: cats,
                selectedId: selectedCategory,
                onSelect: (id) => ref.read(selectedCategoryProvider.notifier).state = id,
              );
            },
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: LinearProgressIndicator(color: primaryColor)),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
        if (selectedCategory != null)
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: _MenuContent(categoryId: selectedCategory, tableId: tableId),
          )
        else
          SliverFillRemaining(child: _EmptyCategory()),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    // Watch state để Widget build lại mỗi khi giỏ hàng thay đổi
    ref.watch(cartProvider); 
    final cartCount = ref.read(cartProvider.notifier).totalItems;
    final cartTotal = ref.read(cartProvider.notifier).totalAmount;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: primaryColor,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: gradientBackground),
      ),
      leading: !isWide 
        ? Builder(builder: (ctx) => IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ))
        : const Icon(Icons.restaurant, color: Colors.white),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thực đơn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text('Bàn $tableId', style: const TextStyle(fontSize: 13, color: Colors.white70)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: InkWell(
              onTap: () => context.push('/table/$tableId/cart'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart, color: primaryColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '$cartCount',
                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    if (cartTotal > 0) ...[
                      Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 1, height: 14, color: Colors.grey.shade300),
                      Text(
                        '${cartTotal.toStringAsFixed(0)} ₫',
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ]
                  ],
                ),
              ),
            ),
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

  const _CategoryBar({required this.categories, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == selectedId;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => onSelect(cat.id),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? gradientBackground : null,
                  color: isSelected ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Chọn danh mục để xem món',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Menu Content (Responsive Grid/List) ──────────────────────────────────────────

class _MenuContent extends ConsumerWidget {
  final String categoryId;
  final String tableId;
  const _MenuContent({required this.categoryId, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuItemsProvider(categoryId));

    return menuAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text('Danh mục này hiện chưa có món.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ),
            ),
          );
        }

        return SliverLayoutBuilder(
          builder: (context, constraints) {
            // Mobile Layout (Width < 600) -> ListView with Horizontal Cards
            if (constraints.crossAxisExtent < 600) {
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MenuHorizontalCard(item: items[index], tableId: tableId),
                    ),
                    childCount: items.length,
                  ),
                ),
              );
            }
            // Tablet/Desktop Layout -> Dense GridView
            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MenuVerticalCard(item: items[index], tableId: tableId),
                  childCount: items.length,
                ),
              ),
            );
          },
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(color: primaryColor)),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Lỗi tải menu: $e'),
                TextButton(
                  onPressed: () => ref.invalidate(menuItemsProvider(categoryId)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Horizontal Card (Mobile Optimized) ──────────────────────────────────────────

class _MenuHorizontalCard extends ConsumerWidget {
  final MenuItem item;
  final String tableId;
  const _MenuHorizontalCard({required this.item, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: item.isAvailable ? () => _showAddDialog(context, ref, item) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _PlaceholderImage())
                            : _PlaceholderImage(),
                        if (!item.isAvailable)
                          Container(
                            color: Colors.white.withValues(alpha: 0.7),
                            child: const Center(
                              child: Text('Hết',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: SizedBox(
                    height: 90, // Match image height
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
                            ),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ]
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.basePrice.toStringAsFixed(0)} ₫',
                              style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            if (item.isAvailable)
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: gradientBackground,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 20),
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
        ),
      ),
    );
  }
}

// ── Vertical Card (Desktop Optimized) ───────────────────────────────────────────

class _MenuVerticalCard extends ConsumerWidget {
  final MenuItem item;
  final String tableId;
  const _MenuVerticalCard({required this.item, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: item.isAvailable ? () => _showAddDialog(context, ref, item) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _PlaceholderImage())
                          : _PlaceholderImage(),
                      if (!item.isAvailable)
                        Container(
                          color: Colors.white.withValues(alpha: 0.7),
                          child: const Center(
                            child: Text('Hết hàng',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Info
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.2),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.basePrice.toStringAsFixed(0)} ₫',
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          if (item.isAvailable)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: gradientBackground,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
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
      ),
    );
  }
}

// ── Dialog Thêm Món ─────────────────────────────────────────────────────────────

void _showAddDialog(BuildContext context, WidgetRef ref, MenuItem item) {
  Variant? selectedVariant = item.variants.isNotEmpty ? item.variants.first : null;
  final Set<Modifier> selectedModifiers = {};
  int quantity = 1;
  final noteController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        double price = item.basePrice;
        if (selectedVariant != null) price += selectedVariant!.extraPrice;
        for (final m in selectedModifiers) {
          price += m.extraPrice;
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Body
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            item.imageUrl!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2)),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(item.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4)),
                      ],
                      const SizedBox(height: 24),

                      if (item.variants.isNotEmpty) ...[
                        _SectionLabel('Chọn loại', required: true),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: RadioGroup<Variant>(
                            groupValue: selectedVariant,
                            onChanged: (val) => setModalState(() => selectedVariant = val),
                            child: Column(
                              children: item.variants.map((v) => RadioListTile<Variant>(
                                    title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    subtitle: v.extraPrice > 0
                                        ? Text('+${v.extraPrice.toStringAsFixed(0)} ₫',
                                            style: const TextStyle(color: primaryColor))
                                        : null,
                                    value: v,
                                    activeColor: primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  )).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (item.modifiers.isNotEmpty) ...[
                        _SectionLabel('Tùy chọn thêm'),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: item.modifiers.map((m) => CheckboxListTile(
                                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  subtitle: m.extraPrice > 0
                                      ? Text('+${m.extraPrice.toStringAsFixed(0)} ₫',
                                          style: const TextStyle(color: primaryColor))
                                      : null,
                                  value: selectedModifiers.contains(m),
                                  activeColor: primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  onChanged: (val) => setModalState(() {
                                    if (val == true) {
                                      selectedModifiers.add(m);
                                    } else {
                                      selectedModifiers.remove(m);
                                    }
                                  }),
                                )).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      _SectionLabel('Ghi chú'),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'VD: Ít đá, không đường, dị ứng đậu phộng...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                // Bottom Bar
                Container(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -4), blurRadius: 16),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Qty
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
                              onTap: quantity > 1 ? () => setModalState(() => quantity--) : null,
                            ),
                            SizedBox(
                              width: 36,
                              child: Center(
                                child: Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            _QtyButton(icon: Icons.add, onTap: () => setModalState(() => quantity++)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Add Button
                      Expanded(
                        child: Container(
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
                            onPressed: () {
                              ref.read(cartProvider.notifier).addItem(
                                    CartItem(
                                      menuItem: item,
                                      selectedVariant: selectedVariant,
                                      selectedModifiers: selectedModifiers.toList(),
                                      quantity: quantity,
                                      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                                    ),
                                  );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text('Đã thêm ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                              ));
                            },
                            child: Text(
                              'Thêm • ${(price * quantity).toStringAsFixed(0)} ₫',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                            ),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
          if (required) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
              child: Text('Bắt buộc', style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
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
          child: Icon(icon, size: 20, color: onTap == null ? Colors.grey.shade400 : Colors.black87),
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(Icons.fastfood, size: 40, color: Colors.grey.shade300),
    );
  }
}
