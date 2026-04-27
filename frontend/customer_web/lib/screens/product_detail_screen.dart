import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/core/api_client.dart';
import 'package:shared/models/menu.dart';

// Riverpod provider để quản lý giỏ hàng
final cartProvider = StateProvider<Map<String, dynamic>>((ref) => {});

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  final String tableId;

  const ProductDetailScreen({
    Key? key,
    required this.itemId,
    required this.tableId,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late Future<MenuItem> menuItem;
  late String selectedSize;
  late List<String> selectedModifiers; // stores modifier IDs
  late int quantity;
  late String note;

  final ApiClient apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    menuItem = _fetchMenuItem(); // Gọi API lấy chi tiết món ăn
    selectedSize = 'S'; // Mặc định là S
    selectedModifiers = [];
    quantity = 1; // Mặc định số lượng là 1
    note = ''; // Ghi chú mặc định là rỗng
  }

  // Lấy chi tiết món ăn từ API
  Future<MenuItem> _fetchMenuItem() async {
    final response = await apiClient.getItemDetails(widget.itemId);
    return MenuItem.fromJson(response.data);
  }

  // Hàm để cập nhật giỏ hàng khi nhấn "Thêm vào giỏ"
  void _addToCart(MenuItem item) {
    final cart = ref.read(cartProvider);
    cart['items'] = [
      ...?cart['items'],
      {
        'itemId': item.id,
        'name': item.name,
        'price': item.basePrice,
        'size': selectedSize,
        'modifiers': selectedModifiers,
        'quantity': quantity,
        'note': note,
      },
    ];
    ref.read(cartProvider.state).state = cart;
    Navigator.pop(context); // Quay lại Menu
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product Detail')),
      body: FutureBuilder<MenuItem>(
        future: menuItem,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final item = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị ảnh lớn
                Image.network(item.imageUrl ?? '', height: 250, fit: BoxFit.cover),
                SizedBox(height: 16),
                // Tên món ăn
                Text(
                  item.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                // Mô tả món ăn
                Text(item.description), // Hiển thị mô tả món ăn
                SizedBox(height: 16),

                // Variant picker (S/M/L)
                Text('Size'),
                Row(
                  children: ['S', 'M', 'L'].map((size) {
                    return Row(
                      children: [
                        Radio<String>(
                          value: size,
                          groupValue: selectedSize,
                          onChanged: (value) {
                            setState(() {
                              selectedSize = value!;
                            });
                          },
                        ),
                        Text(size),
                      ],
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),

                // Modifier list (Topping)
                Text('Modifiers (Toppings)'),
                Wrap(
                  children: item.modifiers.map((modifier) {
                    return FilterChip(
                      label: Text(modifier.name),
                      selected: selectedModifiers.contains(modifier.id),
                      onSelected: (isSelected) {
                        setState(() {
                          if (isSelected) {
                            selectedModifiers.add(modifier.id);
                          } else {
                            selectedModifiers.remove(modifier.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),

                // Ghi chú
                Text('Special Note'),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      note = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter special instructions...',
                  ),
                ),
                SizedBox(height: 16),

                // Số lượng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: quantity > 1
                              ? () {
                                  setState(() {
                                    quantity--;
                                  });
                                }
                              : null,
                        ),
                        Text('$quantity'),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                    Text('Price: \$${item.basePrice * quantity}'),
                  ],
                ),
                SizedBox(height: 16),

                // Nút Thêm vào giỏ
                ElevatedButton(
                  onPressed: selectedSize.isEmpty
                      ? null
                      : () {
                          _addToCart(item); // Thêm vào giỏ hàng
                        },
                  child: Text('Add to Cart'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
