import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/menu_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/error_screen.dart'; // Trang lỗi nếu không có QR

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter _router = GoRouter(
      initialLocation: '/',
      routes: [
        // Route chính sẽ redirect về /table/:tableId hoặc trang lỗi nếu không có QR
        GoRoute(
          path: '/',
          builder: (context, state) {
            final tableId = state.queryParams['tableId'];
            if (tableId != null) {
              return MenuScreen(tableId: tableId);
            } else {
              return ErrorScreen(); // Trang lỗi nếu không có QR
            }
          },
        ),
        // Route cho MenuScreen
        GoRoute(
          path: '/table/:tableId',
          builder: (context, state) {
            final tableId = state.params['tableId']!;
            return MenuScreen(tableId: tableId);
          },
        ),
        // Route cho ProductDetailScreen
        GoRoute(
          path: '/table/:tableId/product/:itemId',
          builder: (context, state) {
            final tableId = state.params['tableId']!;
            final itemId = state.params['itemId']!;
            return ProductDetailScreen(tableId: tableId, itemId: itemId);
          },
        ),
        // Route cho CartScreen
        GoRoute(
          path: '/table/:tableId/cart',
          builder: (context, state) {
            final tableId = state.params['tableId']!;
            return CartScreen(tableId: tableId);
          },
        ),
        // Route cho OrderTrackingScreen
        GoRoute(
          path: '/table/:tableId/tracking/:orderId',
          builder: (context, state) {
            final tableId = state.params['tableId']!;
            final orderId = state.params['orderId']!;
            return OrderTrackingScreen(tableId: tableId, orderId: orderId);
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: _router,
      title: 'Flutter GoRouter Demo',
    );
  }
}
