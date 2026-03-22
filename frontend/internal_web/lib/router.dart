import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/auth_notifier.dart';
import 'features/auth/login_screen.dart';
import 'features/home/landing_screen.dart';
import 'models/user.dart';

import 'features/pos/pos_screen.dart';
import 'features/kds/kds_screen.dart';
import 'features/waiter/waiter_screen.dart';
import 'features/admin/admin_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.user != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isIndex = state.uri.toString() == '/';

      if (!isLoggedIn) {
        // Cho phép xem màn hình Index (/) và Login (/login)
        if (isIndex || isLoggingIn) return null;
        return '/'; // Fallback về Index
      }

      if (isLoggingIn || state.uri.toString() == '/') {
        // Automatically redirect based on role after login
        switch (authState.user!.role) {
          case UserRole.admin:
            return '/admin';
          case UserRole.cashier:
            return '/pos';
          case UserRole.kitchen:
          case UserRole.bar:
            return '/kds';
          case UserRole.waiter:
            return '/waiter';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/pos',
        builder: (context, state) => const PosScreen(), // Need to make this ConsumerWidget for logout to compile... Oh wait, I put ref.read there but PosScreen is StatelessWidget.
      ),
      GoRoute(
        path: '/kds',
        builder: (context, state) => const KdsScreen(),
      ),
      GoRoute(
        path: '/waiter',
        builder: (context, state) => const WaiterScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
    ],
  );
});
