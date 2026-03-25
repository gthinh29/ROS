import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_inventory_provider.dart';
import '../../../models/inventory.dart';

class InventoryTab extends ConsumerWidget {
  const InventoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminInventoryProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: \$e')),
        data: (items) {
           if (items.isEmpty) return const Center(child: Text('Chưa có nguyên liệu nào.'));
           return SingleChildScrollView(
             child: DataTable(
               columns: const [
                 DataColumn(label: Text('Tên Nguyên Liệu')),
                 DataColumn(label: Text('Đơn vị')),
                 DataColumn(label: Text('Giá Cost/đơn vị')),
                 DataColumn(label: Text('Hành động')),
               ],
               rows: items.map((i) => DataRow(cells: [
                 DataCell(Text(i.name)),
                 DataCell(Text(i.unit)),
                 DataCell(Text(i.costPerUnit.toStringAsFixed(0))),
                 DataCell(Row(
                   children: [
                     IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showDialog(context, ref, ingredient: i)),
                     IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => ref.read(adminInventoryProvider.notifier).deleteIngredient(i.id)),
                   ],
                 )),
               ])).toList(),
             )
           );
        }
      )
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, {Ingredient? ingredient}) {
    showDialog(context: context, builder: (ctx) => IngredientFormDialog(ingredient: ingredient));
  }
}

class IngredientFormDialog extends ConsumerStatefulWidget {
  final Ingredient? ingredient;
  const IngredientFormDialog({super.key, this.ingredient});

  @override
  ConsumerState<IngredientFormDialog> createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends ConsumerState<IngredientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String unit;
  late double costPerUnit;

  @override
  void initState() {
    super.initState();
    name = widget.ingredient?.name ?? '';
    unit = widget.ingredient?.unit ?? 'kg';
    costPerUnit = widget.ingredient?.costPerUnit ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ingredient == null ? 'Thêm Nguyên Liệu' : 'Sửa Nguyên Liệu'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(labelText: 'Tên nguyên liệu'),
              onSaved: (val) => name = val ?? '',
              validator: (val) => val!.isEmpty ? 'Không được trống' : null,
            ),
            TextFormField(
              initialValue: unit,
              decoration: const InputDecoration(labelText: 'Đơn vị tính (VD: kg, lit, gram...)'),
              onSaved: (val) => unit = val ?? '',
            ),
            TextFormField(
              initialValue: costPerUnit.toString(),
              decoration: const InputDecoration(labelText: 'Khấu hao/Giá mua (VNĐ)'),
              keyboardType: TextInputType.number,
              onSaved: (val) => costPerUnit = double.tryParse(val ?? '0') ?? 0,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
               _formKey.currentState!.save();
               final payload = {'name': name, 'unit': unit, 'cost_per_unit': costPerUnit};
               bool success;
               if (widget.ingredient == null) {
                 success = await ref.read(adminInventoryProvider.notifier).createIngredient(payload);
               } else {
                 success = await ref.read(adminInventoryProvider.notifier).updateIngredient(widget.ingredient!.id, payload);
               }
               if (success && mounted) Navigator.pop(context);
            }
          },
          child: const Text('Lưu')
        ),
      ],
    );
  }
}
