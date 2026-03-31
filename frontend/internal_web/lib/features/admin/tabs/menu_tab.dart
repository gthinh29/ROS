import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_menu_provider.dart';
import '../../../models/menu.dart';
import '../bom_manager.dart';

class MenuTab extends ConsumerWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(adminMenuProvider);
    final categoryState = ref.watch(adminCategoryProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           _showFormDialog(context, ref, categories: categoryState.value);
        },
        child: const Icon(Icons.add),
      ),
      body: menuState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: \$e')),
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('Chưa có món ăn nào.'));
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                      columns: const [
                        DataColumn(label: Text('Tên món')),
                        DataColumn(label: Text('Giá (VNĐ)')),
                        DataColumn(label: Text('KDS Zone')),
                        DataColumn(label: Text('Trạng thái')),
                        DataColumn(label: Text('Hành động')),
                      ],
                      rows: items.map((item) {
                        return DataRow(cells: [
                          DataCell(Text(item.name)),
                          DataCell(Text(item.basePrice.toStringAsFixed(0))),
                          DataCell(Text(item.kdsZone)),
                          DataCell(Text(item.isAvailable ? 'Còn hàng' : 'Hết hàng')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.receipt_long, color: Colors.orange),
                                tooltip: 'Định lượng (BOM)',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => BomManager(menuItem: item),
                                  );
                                },
                              ),
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), tooltip: 'Sửa món', onPressed: () => _showFormDialog(context, ref, item: item, categories: categoryState.value)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), tooltip: 'Xoá món', onPressed: () => ref.read(adminMenuProvider.notifier).deleteItem(item.id)),
                            ],
                          ))
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }

  void _showFormDialog(BuildContext context, WidgetRef ref, {MenuItem? item, List<CategoryModel>? categories}) {
    if (categories == null || categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa có Danh mục nào, vui lòng thêm danh mục trước!')));
      return;
    }
    showDialog(context: context, builder: (ctx) => MenuFormDialog(item: item, categories: categories));
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

  @override
  void initState() {
    super.initState();
    name = widget.item?.name ?? '';
    basePrice = widget.item?.basePrice ?? 0.0;
    
    // Auto matching category id
    final validCat = widget.categories.map((e) => e.id).contains(widget.item?.categoryId);
    categoryId = validCat ? widget.item!.categoryId : widget.categories.first.id;
    
    kdsZone = widget.item?.kdsZone ?? 'kitchen';
    isAvailable = widget.item?.isAvailable ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Thêm Món' : 'Sửa Món'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Tên món'),
                onSaved: (val) => name = val ?? '',
                validator: (val) => val!.isEmpty ? 'Không được để trống' : null,
              ),
              TextFormField(
                initialValue: basePrice.toString(),
                decoration: const InputDecoration(labelText: 'Giá bán (VNĐ)'),
                keyboardType: TextInputType.number,
                onSaved: (val) => basePrice = double.tryParse(val ?? '0') ?? 0,
              ),
              DropdownButtonFormField<String>(
                value: categoryId.isEmpty ? widget.categories.first.id : categoryId,
                items: widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => categoryId = val!),
                decoration: const InputDecoration(labelText: 'Danh mục'),
              ),
              DropdownButtonFormField<String>(
                value: kdsZone,
                items: const [
                  DropdownMenuItem(value: 'kitchen', child: Text('Bếp (Kitchen)')),
                  DropdownMenuItem(value: 'bar', child: Text('Quầy Pha Chế (Bar)')),
                ],
                onChanged: (val) => setState(() => kdsZone = val!),
                decoration: const InputDecoration(labelText: 'Khu vực chế biến'),
              ),
              SwitchListTile(
                title: const Text('Còn hàng'),
                value: isAvailable,
                onChanged: (val) => setState(() => isAvailable = val),
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final payload = {
                'name': name,
                'base_price': basePrice,
                'category_id': categoryId,
                'kds_zone': kdsZone,
                'is_available': isAvailable,
              };
              bool success;
              if (widget.item == null) {
                success = await ref.read(adminMenuProvider.notifier).createItem(payload);
              } else {
                success = await ref.read(adminMenuProvider.notifier).updateItem(widget.item!.id, payload);
              }
              if (success && mounted) Navigator.pop(context);
            }
          },
          child: const Text('Lưu'),
        )
      ],
    );
  }
}
