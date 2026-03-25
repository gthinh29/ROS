import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../../models/user.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error, bool clearError = false}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkToken();
    return AuthState();
  }

  Future<void> _checkToken() async {
    // Basic mock logic. Real app connects to `/users/me` if token exists.
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data['data'] ?? response.data;
      final token = data['access_token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
      }

      UserRole getRole(String email) {
        if (email.contains('admin')) return UserRole.admin;
        if (email.contains('cashier')) return UserRole.cashier;
        if (email.contains('waiter')) return UserRole.waiter;
        if (email.contains('kitchen')) return UserRole.kitchen;
        if (email.contains('bar')) return UserRole.kitchen;
        return UserRole.admin;
      }
      
      final user = User(
        id: 'real',
        email: email,
        name: 'Staff',
        role: getRole(email),
      );
      
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    state = AuthState(); 
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
