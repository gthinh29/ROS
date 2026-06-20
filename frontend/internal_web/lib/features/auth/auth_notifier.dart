import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared/core/api_client.dart';
import 'package:shared/models/user.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final email = prefs.getString('user_email');
    
    if (token != null && email != null) {
      final user = User(
        id: 'real',
        email: email,
        name: 'Staff',
        role: _getRole(email),
      );
      state = state.copyWith(user: user);
    }
  }

  UserRole _getRole(String email) {
    if (email.contains('admin')) return UserRole.admin;
    if (email.contains('cashier')) return UserRole.cashier;
    if (email.contains('waiter')) return UserRole.waiter;
    if (email.contains('kitchen')) return UserRole.kitchen;
    if (email.contains('bar')) return UserRole.kitchen;
    return UserRole.admin;
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
        await prefs.setString('user_email', email);
      }

      final user = User(
        id: 'real',
        email: email,
        name: 'Staff',
        role: _getRole(email),
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
    await prefs.remove('user_email');
    state = AuthState(); 
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
