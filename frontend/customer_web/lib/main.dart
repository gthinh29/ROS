import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/menu_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/error_screen.dart';

void main() {
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
          path: '/table/:tableId/tracking/:orderId',
          builder: (context, state) => OrderTrackingScreen(
            tableId: state.pathParameters['tableId']!,
            orderId: state.pathParameters['orderId']!,
          ),
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
