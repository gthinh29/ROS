import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import 'product_detail_screen.dart';

final cartProvider = StateProvider<Map<String, dynamic>>((ref) => {});

class MenuScreen extends ConsumerStatefulWidget {
  final String tableId;
  const MenuScreen({Key? key, required this.tableId})
    : super(key: key); // ✅ Thêm key

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  late Future<List<Category>> categories;
  Future<List<MenuItem>>? menuItems; //
  final ApiClient apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    categories = _fetchCategories();
  }

  Future<List<Category>> _fetchCategories() async {
    final response = await apiClient.getCategories();
    return (response.data as List).map((e) => Category.fromJson(e)).toList();
  }

  void _fetchMenuItems(String categoryId) {
    setState(() {
      menuItems = apiClient
          .getMenuItems(categoryId)
          .then(
            (response) => (response.data as List)
                .map((item) => MenuItem.fromJson(item))
                .toList(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menu - Table ${widget.tableId}')),
      body: Column(
        children: [
          FutureBuilder<List<Category>>(
            future: categories,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              return CategoryBar(
                categories: snapshot.data!,
                onCategorySelected: _fetchMenuItems,
              );
            },
          ),
          Expanded(
            child:
                menuItems ==
                    null // ✅ Kiểm tra null trước
                ? Center(child: Text('Chọn danh mục để xem món ăn'))
                : FutureBuilder<List<MenuItem>>(
                    future: menuItems,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                        return Center(child: Text('No items available.'));
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return MenuItemCard(
                            item: snapshot.data![index],
                            tableId: widget.tableId,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CategoryBar extends StatelessWidget {
  final List<Category> categories;
  final Function(String categoryId) onCategorySelected;

  const CategoryBar({
    Key? key,
    required this.categories,
    required this.onCategorySelected,
  }) : super(key: key); // ✅ Thêm key

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ActionChip(
              // ✅ Dùng ActionChip thay Chip (Chip không có onPressed)
              label: Text(category.name),
              onPressed: () => onCategorySelected(category.id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final String tableId;

  const MenuItemCard({Key? key, required this.item, required this.tableId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: ListTile(
        leading: Image.network(item.imageUrl),
        title: Text(item.name),
        subtitle: Text('Price: \$${item.price}'),
        trailing: item.isAvailable
            ? null
            : Icon(Icons.block, color: Colors.red),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                tableId: tableId, // ✅ Truyền tableId
                itemId: item.id,
              ),
            ),
          );
        },
      ),
    );
  }
}
