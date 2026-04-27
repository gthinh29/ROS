import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) {
          return handler.next(e);
        },
      ),
    );
  }
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

final apiClient = ApiClient().dio;
