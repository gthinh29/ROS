
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_menu_provider.dart';
import 'package:shared/models/menu.dart';
import '../bom_manager.dart';

class MenuTab extends ConsumerStatefulWidget {
  const MenuTab({super.key});

  @override
  ConsumerState<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends ConsumerState<MenuTab> {
  String? _selectedCategoryId; 

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(adminMenuProvider);
    final categoryState = ref.watch(adminCategoryProvider);

    final categories = categoryState.value ?? [];

    return Row(
      children: [
        
        Container(
          width: 200,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(
              right: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Danh mục',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showCategoryDialog(context, ref),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              _CategoryItem(
                label: 'Tất cả',
                selected: _selectedCategoryId == null,
                onTap: () => setState(() => _selectedCategoryId = null),
                onDelete: null,
              ),
              
              Expanded(
                child: categoryState.when(
                  loading: () => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) =>
                      Center(child: Text('Lỗi', style: TextStyle(fontSize: 12))),
                  data: (cats) => ListView(
                    children: cats
                        .map(
                          (c) => _CategoryItem(
                            label: c.name,
                            selected: _selectedCategoryId == c.id,
                            onTap: () =>
                                setState(() => _selectedCategoryId = c.id),
                            onDelete: () => ref
                                .read(adminCategoryProvider.notifier)
                                .deleteCategory(c.id),
                            onEdit: () =>
                                _showCategoryDialog(context, ref, category: c),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        
        Expanded(
          child: Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                _showFormDialog(context, ref, categories: categories);
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm món'),
              backgroundColor: const Color(0xFF3B82F6),
            ),
            backgroundColor: Colors.white,
            body: menuState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (items) {
                
                final filtered = _selectedCategoryId == null
                    ? items
                    : items
                        .where((i) => i.categoryId == _selectedCategoryId)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có món ăn nào trong danh mục này.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (_, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFF8FAFC),
                            ),
                            headingTextStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                            columnSpacing: 20,
                            columns: const [
                              DataColumn(label: Text('Hình ảnh')),
                              DataColumn(label: Text('Tên món')),
                              DataColumn(label: Text('Danh mục')),
                              DataColumn(label: Text('Giá (₫)')),
                              DataColumn(label: Text('KDS Zone')),
                              DataColumn(label: Text('Trạng thái')),
                              DataColumn(label: Text('Hành động')),
                            ],
                            rows: filtered.map((item) {
                              final cat = categories.firstWhere(
                                (c) => c.id == item.categoryId,
                                orElse: () => CategoryModel(
                                  id: '',
                                  name: '—',
                                ),
                              );
                              return DataRow(
                                cells: [
                                  
                                  DataCell(
                                    _MenuImageAvatar(
                                      imageUrl: item.imageUrl,
                                      name: item.name,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        cat.name,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF3B82F6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _formatPrice(item.basePrice),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _KdsChip(zone: item.kdsZone),
                                  ),
                                  DataCell(
                                    _AvailabilityChip(
                                      isAvailable: item.isAvailable,
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.receipt_long,
                                            color: Color(0xFFF59E0B),
                                            size: 18,
                                          ),
                                          tooltip: 'Định lượng (BOM)',
                                          onPressed: () => showDialog(
                                            context: context,
                                            builder: (_) =>
                                                BomManager(menuItem: item),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: Color(0xFF3B82F6),
                                            size: 18,
                                          ),
                                          tooltip: 'Sửa món',
                                          onPressed: () => _showFormDialog(
                                            context,
                                            ref,
                                            item: item,
                                            categories: categories,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Color(0xFFEF4444),
                                            size: 18,
                                          ),
                                          tooltip: 'Xoá món',
                                          onPressed: () => ref
                                              .read(adminMenuProvider.notifier)
                                              .deleteItem(item.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted ₫';
  }

  void _showFormDialog(
    BuildContext context,
    WidgetRef ref, {
    MenuItem? item,
    List<CategoryModel>? categories,
  }) {
    if (categories == null || categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa có Danh mục nào, vui lòng thêm danh mục trước!',
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => MenuFormDialog(item: item, categories: categories),
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    CategoryModel? category,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => CategoryFormDialog(category: category),
    );
  }
}


class _CategoryItem extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _CategoryItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFF3B82F6)
                : _hovered
                    ? const Color(0xFFEFF6FF)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 7,
                color: widget.selected
                    ? Colors.white
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: widget.selected
                        ? Colors.white
                        : const Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_hovered && widget.onEdit != null)
                GestureDetector(
                  onTap: widget.onEdit,
                  child: Icon(
                    Icons.edit,
                    size: 12,
                    color: widget.selected
                        ? Colors.white70
                        : const Color(0xFF3B82F6),
                  ),
                ),
              if (_hovered && widget.onDelete != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: widget.selected
                        ? Colors.white70
                        : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _MenuImageAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  const _MenuImageAvatar({this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF3B82F6),
            fontSize: 16,
          ),
        ),
      );
}


class _KdsChip extends StatelessWidget {
  final String zone;
  const _KdsChip({required this.zone});

  @override
  Widget build(BuildContext context) {
    final isBar = zone.toLowerCase() == 'bar';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isBar
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBar
              ? const Color(0xFFF59E0B)
              : const Color(0xFF10B981),
          width: 0.8,
        ),
      ),
      child: Text(
        isBar ? '🍹 Bar' : '🍳 Bếp',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isBar ? const Color(0xFFD97706) : const Color(0xFF059669),
        ),
      ),
    );
  }
}


class _AvailabilityChip extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityChip({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            size: 11,
            color: isAvailable
                ? const Color(0xFF059669)
                : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Còn hàng' : 'Hết hàng',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isAvailable
                  ? const Color(0xFF059669)
                  : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}


class CategoryFormDialog extends ConsumerStatefulWidget {
  final CategoryModel? category;
  const CategoryFormDialog({super.key, this.category});
  @override
  ConsumerState<CategoryFormDialog> createState() =>
      _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String name;

  @override
  void initState() {
    super.initState();
    name = widget.category?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Sửa Danh Mục' : 'Thêm Danh Mục'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 320,
          child: TextFormField(
            initialValue: name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Tên danh mục',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onSaved: (val) => name = val ?? '',
            validator: (val) =>
                val == null || val.isEmpty ? 'Không được trống' : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              bool success;
              if (isEdit) {
                success = await ref
                    .read(adminCategoryProvider.notifier)
                    .updateCategory(widget.category!.id, {'name': name});
              } else {
                success = await ref
                    .read(adminCategoryProvider.notifier)
                    .createCategory({'name': name});
              }
              if (success && context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}


class MenuFormDialog extends ConsumerStatefulWidget {
  final MenuItem? item;
  final List<CategoryModel> categories;
  const MenuFormDialog({super.key, this.item, required this.categories});

  @override
  ConsumerState<MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends ConsumerState<MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late double basePrice;
  late String categoryId;
  late String kdsZone;
  late bool isAvailable;
  late bool isFeatured;

  @override
  void initState() {
    super.initState();
    name = widget.item?.name ?? '';
    basePrice = widget.item?.basePrice ?? 0.0;
    final validCat = widget.categories
        .map((e) => e.id)
        .contains(widget.item?.categoryId);
    categoryId = validCat
        ? widget.item!.categoryId
        : widget.categories.first.id;
    kdsZone = widget.item?.kdsZone ?? 'kitchen';
    isAvailable = widget.item?.isAvailable ?? true;
    isFeatured = widget.item?.isFeatured ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.item == null ? 'Thêm Món Ăn' : 'Sửa Món Ăn'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: _inputDeco('Tên món', Icons.restaurant_menu),
                  onSaved: (val) => name = val ?? '',
                  validator: (val) =>
                      val!.isEmpty ? 'Không được để trống' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: basePrice.toString(),
                  decoration: _inputDeco('Giá bán (₫)', Icons.payments_outlined),
                  keyboardType: TextInputType.number,
                  onSaved: (val) =>
                      basePrice = double.tryParse(val ?? '0') ?? 0,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  items: widget.categories
                      .map(
                        (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => categoryId = val!),
                  decoration: _inputDeco('Danh mục', Icons.category_outlined),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: kdsZone,
                  items: const [
                    DropdownMenuItem(
                      value: 'kitchen',
                      child: Text('🍳 Bếp (Kitchen)'),
                    ),
                    DropdownMenuItem(
                      value: 'bar',
                      child: Text('🍹 Quầy Pha Chế (Bar)'),
                    ),
                  ],
                  onChanged: (val) => setState(() => kdsZone = val!),
                  decoration: _inputDeco(
                    'Khu vực chế biến',
                    Icons.place_outlined,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Còn hàng'),
                  subtitle: const Text(
                    'Tắt để tạm ẩn khỏi thực đơn',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: isAvailable,
                  onChanged: (val) => setState(() => isAvailable = val),
                ),
                SwitchListTile(
                  title: const Text('Món nổi bật (Featured)'),
                  subtitle: const Text(
                    'Hiện nổi bật trên trang đặt món',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: isFeatured,
                  onChanged: (val) => setState(() => isFeatured = val),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.save_outlined, size: 16),
          label: const Text('Lưu'),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final payload = {
                'name': name,
                'base_price': basePrice,
                'category_id': categoryId,
                'kds_zone': kdsZone,
                'is_available': isAvailable,
                'is_featured': isFeatured,
              };
              bool success;
              if (widget.item == null) {
                success = await ref
                    .read(adminMenuProvider.notifier)
                    .createItem(payload);
              } else {
                success = await ref
                    .read(adminMenuProvider.notifier)
                    .updateItem(widget.item!.id, payload);
              }
              if (success && context.mounted) Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      );
}
