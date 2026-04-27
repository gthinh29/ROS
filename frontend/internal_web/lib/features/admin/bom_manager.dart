import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/admin_bom_provider.dart';
import 'providers/admin_inventory_provider.dart';
import 'package:shared/models/menu.dart';

class BomManager extends ConsumerStatefulWidget {
  final MenuItem menuItem;
  const BomManager({super.key, required this.menuItem});

  @override
  ConsumerState<BomManager> createState() => _BomManagerState();
}

class _BomManagerState extends ConsumerState<BomManager> {
  bool isLoading = true;
  List<Map<String, dynamic>> bomItems = [];

  @override
  void initState() {
    super.initState();
    _loadBom();
  }

  Future<void> _loadBom() async {
    setState(() => isLoading = true);
    final service = ref.read(adminBomProvider);
    try {
      final items = await service.getBom(widget.menuItem.id);
      setState(() {
        bomItems = items.map((e) => {
          'ingredient_id': e.ingredientId,
          'qty_required': e.qtyRequired,
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _addIngredient() {
    setState(() {
      bomItems.add({'ingredient_id': '', 'qty_required': 0.0});
    });
  }

  void _save() async {
    // Validate
    if (bomItems.any((e) => e['ingredient_id'] == '' || e['qty_required'] <= 0)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn đầy đủ nguyên liệu và số lượng > 0')));
       return;
    }
    setState(() => isLoading = true);
    final success = await ref.read(adminBomProvider).setBom(widget.menuItem.id, bomItems);
    if (success && mounted) {
       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu cấu hình BOM thành công')));
    } else {
       if (mounted) {
         setState(() => isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi lưu cấu hình BOM')));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(adminInventoryProvider);
    
    return AlertDialog(
      title: Text('Định lượng (BOM): ${widget.menuItem.name}'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Danh sách thành phần cấu thành:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm nguyên liệu'),
                      onPressed: _addIngredient,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue),
                    )
                  ],
                ),
                const Divider(height: 32),
                Expanded(
                  child: inventoryState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Lỗi tải danh mục kho: $e')),
                    data: (ingredients) {
                      if (bomItems.isEmpty) return const Center(child: Text('Chưa có thành phần nguyên liệu nào.', style: TextStyle(color: Colors.grey)));
                      return ListView.builder(
                        itemCount: bomItems.length,
                        itemBuilder: (context, index) {
                           final currentItem = bomItems[index];
                           final ingId = currentItem['ingredient_id'] as String;
                           final validIds = ingredients.map((i) => i.id).toList();
                           
                           return Card(
                             elevation: 0,
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(8),
                               side: BorderSide(color: Colors.grey.shade300)
                             ),
                             margin: const EdgeInsets.symmetric(vertical: 4),
                             child: Padding(
                               padding: const EdgeInsets.all(12.0),
                               child: Row(
                                 children: [
                                   Expanded(
                                      flex: 3,
                                      child: DropdownButtonFormField<String>(
                                         decoration: const InputDecoration(labelText: 'Tên Nguyên Liệu', isDense: true, border: OutlineInputBorder()),
                                         value: validIds.contains(ingId) ? ingId : null,
                                         items: ingredients.map((i) => DropdownMenuItem(value: i.id, child: Text(i.name))).toList(),
                                         onChanged: (val) {
                                            if (val != null) {
                                               setState(() {
                                                 bomItems[index]['ingredient_id'] = val;
                                               });
                                            }
                                         },
                                      ),
                                   ),
                                   const SizedBox(width: 16),
                                   Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        initialValue: currentItem['qty_required'] == 0.0 ? '' : currentItem['qty_required'].toString(),
                                        decoration: const InputDecoration(labelText: 'Số lượng / lượng hao hụt', isDense: true, border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          bomItems[index]['qty_required'] = double.tryParse(val) ?? 0.0;
                                        },
                                      )
                                   ),
                                   const SizedBox(width: 16),
                                   Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                        child: Text(
                                          validIds.contains(ingId) ? ingredients.firstWhere((i) => i.id == ingId).unit : 'Đơn vị',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                   ),
                                   const SizedBox(width: 8),
                                   IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () {
                                         setState(() {
                                           bomItems.removeAt(index);
                                         });
                                      },
                                   )
                                 ],
                               ),
                             ),
                           );
                        }
                      );
                    }
                  )
                ),
              ],
            ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: isLoading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Lưu định lượng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}
