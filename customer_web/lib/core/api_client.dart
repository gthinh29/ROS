import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8000', // Đặt base URL của API
      connectTimeout: Duration(seconds: 10), // Thay đổi từ int thành Duration
      receiveTimeout: Duration(seconds: 10), // Thay đổi từ int thành Duration
    ),
  );

  // Method để lấy danh mục món ăn
  Future<Response> getCategories() async {
    return dio.get('/menu/categories');
  }

  // Method để lấy danh sách món ăn theo danh mục
  Future<Response> getMenuItems(String categoryId) async {
    return dio.get('/menu/items', queryParameters: {'category_id': categoryId});
  }

  // Method để lấy chi tiết món ăn
  Future<Response> getItemDetails(String itemId) async {
    return dio.get('/menu/items/$itemId');
  }

  // Method để gọi nhân viên
  Future<Response> callWaiter(String tableId, Map<String, dynamic> cart) async {
    return dio.post('/tables/$tableId/call-waiter', data: cart);
  }
}
