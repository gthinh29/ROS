import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/api_client.dart';
import 'package:shared/models/category.dart';
import 'package:shared/models/menu.dart';
import '../providers.dart';
import 'widgets/tracking_sidebar.dart';

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((
  ref,
) async {
  final res = await ApiClient().dio.get('/menu/categories');
  final List data = res.data['data'] ?? [];
  return data.map((e) => Category.fromJson(e)).toList();
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final menuItemsProvider = FutureProvider.autoDispose
    .family<List<MenuItem>, String>((ref, categoryId) async {
      final res = await ApiClient().dio.get(
        '/menu/items',
        queryParameters: {'category_id': categoryId, 'is_available': true},
      );
      final List data = res.data['data'] ?? [];
      return data.map((e) => MenuItem.fromJson(e)).toList();
    });

const primaryColor = Color(0xFFE53935);
const gradientBackground = LinearGradient(
  colors: [Color(0xFFE53935), Color(0xFFC62828)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

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

          final menuContent = _MenuMainContent(
            tableId: tableId,
            isWide: isWide,
          );

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
                  ref.read(selectedCategoryProvider.notifier).state =
                      cats.first.id;
                });
              }
              return _CategoryBar(
                categories: cats,
                selectedId: selectedCategory,
                onSelect: (id) =>
                    ref.read(selectedCategoryProvider.notifier).state = id,
              );
            },
            loading: () => const SizedBox(
              height: 60,
              child: Center(
                child: LinearProgressIndicator(color: primaryColor),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
        if (selectedCategory != null)
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: _MenuContent(
              categoryId: selectedCategory,
              tableId: tableId,
            ),
          )
        else
          SliverFillRemaining(child: _EmptyCategory()),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    // Watch state Ä‘á»ƒ Widget build láº¡i má»—i khi giá» hÃ ng thay Ä‘á»•i
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
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.receipt_long, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : const Icon(Icons.restaurant, color: Colors.white),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thá»±c Ä‘Æ¡n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Text(
            'BÃ n $tableId',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$cartCount',
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    if (cartTotal > 0) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 1,
                        height: 14,
                        color: Colors.grey.shade300,
                      ),
                      Text(
                        '${cartTotal.toStringAsFixed(0)} â‚«',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
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

// â”€â”€ Category Tab Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? gradientBackground : null,
                  color: isSelected ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
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
            'Chá»n danh má»¥c Ä‘á»ƒ xem mÃ³n',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Menu Content (Responsive Grid/List) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                child: Text(
                  'Danh má»¥c nÃ y hiá»‡n chÆ°a cÃ³ mÃ³n.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
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
                      child: _MenuHorizontalCard(
                        item: items[index],
                        tableId: tableId,
                      ),
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
                  (context, index) =>
                      _MenuVerticalCard(item: items[index], tableId: tableId),
                  childCount: items.length,
                ),
              ),
            );
          },
        );
      },
      loading: () => SliverLayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.crossAxisExtent < 600;
          if (isMobile) {
            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, _) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _MenuSkeletonHorizontal(),
                  ),
                  childCount: 6,
                ),
              ),
            );
          }
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
                (_, _) => const _MenuSkeletonVertical(),
                childCount: 8,
              ),
            ),
          );
        },
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Lá»—i táº£i menu: $e'),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(menuItemsProvider(categoryId)),
                  child: const Text('Thá»­ láº¡i'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Horizontal Card (Mobile Optimized) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: item.isAvailable
              ? () => context.push('/table/$tableId/product/${item.id}')
              : null,
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
                        _SafeNetworkImage(
                          url: item.imageUrl,
                          fit: BoxFit.cover,
                        ),
                        if (!item.isAvailable)
                          Container(
                            color: Colors.white.withValues(alpha: 0.7),
                            child: const Center(
                              child: Text(
                                'Háº¿t',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                height: 1.2,
                              ),
                            ),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.basePrice.toStringAsFixed(0)} â‚«',
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
                                      color: primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
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

// â”€â”€ Vertical Card (Desktop Optimized) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: item.isAvailable
              ? () => context.push('/table/$tableId/product/${item.id}')
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _SafeNetworkImage(url: item.imageUrl, fit: BoxFit.cover),
                      if (!item.isAvailable)
                        Container(
                          color: Colors.white.withValues(alpha: 0.7),
                          child: const Center(
                            child: Text(
                              'Háº¿t hÃ ng',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.basePrice.toStringAsFixed(0)} â‚«',
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
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SafeNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;

  const _SafeNetworkImage({required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return const _PlaceholderImage();
    return Image.network(
      url!,
      fit: fit,
      errorBuilder: (_, _, _) => const _PlaceholderImage(),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return const _PlaceholderImage(showProgress: true);
      },
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final bool showProgress;
  const _PlaceholderImage({this.showProgress = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: showProgress
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            )
          : Icon(Icons.fastfood, size: 40, color: Colors.grey.shade300),
    );
  }
}

// ── Skeleton Loaders ─────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) =>
          Opacity(opacity: 0.55 + 0.35 * _ctrl.value, child: child),
      child: widget.child,
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _SkeletonBox({this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _MenuSkeletonHorizontal extends StatelessWidget {
  const _MenuSkeletonHorizontal();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonBox(width: 90, height: 90, radius: 12),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SkeletonBox(height: 14),
                  const SizedBox(height: 8),
                  _SkeletonBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 12,
                  ),
                  const SizedBox(height: 24),
                  const _SkeletonBox(width: 80, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSkeletonVertical extends StatelessWidget {
  const _MenuSkeletonVertical();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: Container(color: Colors.grey.shade200)),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _SkeletonBox(height: 12),
                    _SkeletonBox(width: 80, height: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
