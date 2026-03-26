import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/menu.dart';
import '../../models/cart_item.dart';
import 'menu_provider.dart';
import 'cart_provider.dart';

class CreateOrderFlow extends ConsumerStatefulWidget {
  const CreateOrderFlow({super.key});

  @override
  ConsumerState<CreateOrderFlow> createState() => _CreateOrderFlowState();
}

class _CreateOrderFlowState extends ConsumerState<CreateOrderFlow> {
  void _showAddToCartDialog(MenuItem item) {
    Variant? selectedVariant = item.variants.isNotEmpty ? item.variants.first : null;
    final Set<Modifier> selectedModifiers = {};
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Thêm ${item.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.variants.isNotEmpty) ...[
                      const Text('Chọn loại (Variant):', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...item.variants.map((v) => RadioListTile<Variant>(
                        title: Text('${v.name} (+${v.extraPrice})'),
                        value: v,
                        groupValue: selectedVariant,
                        onChanged: (val) => setState(() => selectedVariant = val),
                      )),
                      const Divider(),
                    ],
                    if (item.modifiers.isNotEmpty) ...[
                      const Text('Tùy chọn thêm (Modifier):', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...item.modifiers.map((m) => CheckboxListTile(
                        title: Text('${m.name} (+${m.extraPrice})'),
                        value: selectedModifiers.contains(m),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              selectedModifiers.add(m);
                            } else {
                              selectedModifiers.remove(m);
                            }
                          });
                        },
                      )),
                      const Divider(),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số lượng:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => setState(() {
                                if (quantity > 1) quantity--;
                              }),
                            ),
                            Text('$quantity', style: const TextStyle(fontSize: 18)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() => quantity++),
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final cartItem = CartItem(
                      menuItem: item,
                      selectedVariant: selectedVariant,
                      selectedModifiers: selectedModifiers.toList(),
                      quantity: quantity,
                    );
                    ref.read(cartProvider.notifier).addItem(cartItem);
                    Navigator.pop(context);
                  },
                  child: const Text('Thêm vào giỏ'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GỌI MÓN MỚI'),
      ),
      body: Row(
        children: [
          // Left: Menu Grid
          Expanded(
            flex: 2,
            child: menuAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('Không có món nào trong Menu.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showAddToCartDialog(item),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                color: Colors.grey.shade200,
                                child: item.imageUrl != null 
                                  ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.fastfood, size: 40, color: Colors.grey))
                                  : const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text('${item.basePrice.toStringAsFixed(0)} ₫', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Lỗi: \$e')),
            ),
          ),
          
          // Right: Cart
          Container(
            width: 350,
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  width: double.infinity,
                  child: Text('GIỎ HÀNG (${cart.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: cart.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cItem = cart[index];
                      return ListTile(
                        title: Text(cItem.menuItem.name),
                        subtitle: Text('${cItem.quantity} x ${(cItem.totalPrice / cItem.quantity).toStringAsFixed(0)} ₫'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => ref.read(cartProvider.notifier).removeItem(index),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(0, -2), blurRadius: 4)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng cộng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${ref.read(cartProvider.notifier).totalAmount.toStringAsFixed(0)} ₫', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: cart.isEmpty ? null : () async {
                            final success = await ref.read(cartProvider.notifier).submitOrder();
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo Order thành công!')));
                              Navigator.pop(context); // Trở về màn sơ đồ bàn
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi submit order')));
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('GỬI BẾP (TẠO ORDER)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
