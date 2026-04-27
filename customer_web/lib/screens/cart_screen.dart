import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import 'menu_screen.dart'; // import cartProvider

class CartScreen extends ConsumerStatefulWidget {
  final String tableId;
  const CartScreen({Key? key, required this.tableId}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  final ApiClient apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _updateCart(int index, int quantity) {
    final cart = Map<String, dynamic>.from(ref.read(cartProvider));
    final items = List.from(cart['items']);
    items[index] = Map<String, dynamic>.from(items[index])
      ..['quantity'] = quantity;
    cart['items'] = items;
    ref.read(cartProvider.notifier).state = cart; // ✅ API mới
  }

  void _removeItemFromCart(int index) {
    final cart = Map<String, dynamic>.from(ref.read(cartProvider));
    final items = List.from(cart['items'])..removeAt(index);
    cart['items'] = items;
    ref.read(cartProvider.notifier).state = cart; // ✅ API mới
  }

  double _calculateTotal(List items) {
    return items.fold(0, (sum, item) => sum + item['price'] * item['quantity']);
  }

  void _callWaiter(Map<String, dynamic> cart) async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập tên và số điện thoại.')),
      );
      return;
    }

    try {
      final response = await apiClient.callWaiter(widget.tableId, cart);
      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Đang đợi nhân viên xác nhận..."),
            content: CircularProgressIndicator(),
          ),
        );
        context.go(
          '/table/${widget.tableId}/tracking/${response.data['orderId']}',
        ); // ✅ Đúng route
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mất kết nối, thử lại.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider); // ✅ Reactive
    final items = (cart['items'] as List?) ?? []; // ✅ Tránh crash

    return Scaffold(
      appBar: AppBar(title: Text('Giỏ hàng - Bàn ${widget.tableId}')),
      body: items.isEmpty
          ? Center(child: Text('Giỏ hàng trống!'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Image.network(item['imageUrl']),
                            title: Text(item['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Size: ${item['size']}'),
                                Text(
                                  'Modifiers: ${(item['modifiers'] as List).join(', ')}',
                                ),
                                Text('Note: ${item['note']}'),
                                Text('Price: \$${item['price']}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: item['quantity'] > 1
                                      ? () => _updateCart(
                                          index,
                                          item['quantity'] - 1,
                                        )
                                      : null,
                                ),
                                Text('${item['quantity']}'),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () =>
                                      _updateCart(index, item['quantity'] + 1),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _removeItemFromCart(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Text('Tổng tiền: \$${_calculateTotal(items)}'),
                  SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Tên'),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'Số điện thoại'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _callWaiter(cart),
                    child: Text('Gọi Nhân Viên'),
                  ),
                ],
              ),
            ),
    );
  }
}
