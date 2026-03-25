import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../../../core/api_client.dart';

class AdminUserNotifier extends Notifier<AsyncValue<List<User>>> {
  @override
  AsyncValue<List<User>> build() {
    _fetchUsers();
    return const AsyncValue.loading();
  }

  Future<void> _fetchUsers() async {
    try {
      final res = await apiClient.get('/auth/users');
      final data = res.data['data'] ?? res.data;
      final users = (data as List).map((e) => User.fromJson(e)).toList();
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createUser(Map<String, dynamic> payload) async {
    try {
      await apiClient.post('/auth/users', data: payload);
      await _fetchUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUser(String id, Map<String, dynamic> payload) async {
    try {
      await apiClient.patch('/auth/users/$id', data: payload);
      await _fetchUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await apiClient.delete('/auth/users/$id');
      await _fetchUsers();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final adminUserProvider = NotifierProvider<AdminUserNotifier, AsyncValue<List<User>>>(AdminUserNotifier.new);
