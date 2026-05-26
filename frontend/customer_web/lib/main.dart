import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/menu_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/error_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/reservation/reservation_screen.dart';
import 'screens/reservation/reservation_success_screen.dart';
import 'screens/reservation/pre_order_picker_screen.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: CustomerApp()));
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final tableId = state.uri.queryParameters['tableId'];
            if (tableId != null && tableId.isNotEmpty) {
              return MenuScreen(tableId: tableId);
            }
            return const ErrorScreen();
          },
        ),
        GoRoute(
          path: '/table/:tableId',
          builder: (context, state) =>
              MenuScreen(tableId: state.pathParameters['tableId'] ?? ''),
        ),
        GoRoute(
          path: '/table/:tableId/cart',
          builder: (context, state) =>
              CartScreen(tableId: state.pathParameters['tableId'] ?? ''),
        ),
        GoRoute(
          path: '/table/:tableId/product/:itemId',
          builder: (context, state) {
            final tableId = state.pathParameters['tableId'];
            final itemId = state.pathParameters['itemId'];
            if (tableId == null || tableId.isEmpty || itemId == null || itemId.isEmpty) {
              return const ErrorScreen();
            }
            return ProductDetailScreen(tableId: tableId, itemId: itemId);
          },
        ),
        GoRoute(
          path: '/table/:tableId/tracking/:orderId',
          builder: (context, state) {
            final tableId = state.pathParameters['tableId'];
            final orderId = state.pathParameters['orderId'];
            if (tableId == null || tableId.isEmpty || orderId == null || orderId.isEmpty) {
              return const ErrorScreen();
            }
            return OrderTrackingScreen(tableId: tableId, orderId: orderId);
          },
        ),
        GoRoute(
          path: '/reservation',
          builder: (context, state) => const ReservationScreen(),
        ),
        GoRoute(
          path: '/reservation/pre-order',
          builder: (context, state) => const PreOrderPickerScreen(),
        ),
        GoRoute(
          path: '/reservation/success',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! Map) return const ErrorScreen();
            final id = extra['id']?.toString() ?? '';
            final name = extra['customer_name']?.toString() ?? '';
            final phone = extra['phone']?.toString() ?? '';
            final reservedAt = extra['reserved_at'];
            final partySize = extra['party_size'];
            if (reservedAt is! DateTime || partySize is! int) {
              return const ErrorScreen();
            }
            return ReservationSuccessScreen(
              id: id,
              customerName: name,
              phone: phone,
              reservedAt: reservedAt,
              partySize: partySize,
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Gọi món — Nhà hàng',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.beVietnamProTextTheme(),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE53935),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
        ),
      ),
    );
  }
}
