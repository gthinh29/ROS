import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_user_provider.dart';
import 'package:shared/models/user.dart';

class UserTab extends ConsumerWidget {
  const UserTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(adminUserProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: userState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: \$e')),
        data: (users) {
          if (users.isEmpty) return const Center(child: Text('Chưa có nhân sự nào.'));
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                      columns: const [
                        DataColumn(label: Text('Tên')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('SĐT')),
                        DataColumn(label: Text('Trạng thái')),
                        DataColumn(label: Text('Hành động')),
                      ],
                      rows: users.map((u) {
                        return DataRow(cells: [
                          DataCell(Text(u.name)),
                          DataCell(Text(u.email)),
                          DataCell(Text(u.role.name.toUpperCase())),
                          DataCell(Text(u.phone ?? '')),
                          DataCell(Text(u.isActive ? 'Đang làm' : 'Đã nghỉ')),
                          DataCell(Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showFormDialog(context, ref, user: u)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => ref.read(adminUserProvider.notifier).deleteUser(u.id)),
                            ],
                          ))
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }

  void _showFormDialog(BuildContext context, WidgetRef ref, {User? user}) {
    showDialog(context: context, builder: (ctx) => UserFormDialog(user: user));
  }
}

class UserFormDialog extends ConsumerStatefulWidget {
  final User? user;
  const UserFormDialog({super.key, this.user});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  String? email;
  String? phone;
  late String role;
  late bool isActive;
  String? password;

  @override
  void initState() {
    super.initState();
    name = widget.user?.name ?? '';
    email = widget.user?.email;
    phone = widget.user?.phone;
    role = widget.user?.role.name.toUpperCase() ?? 'WAITER';
    isActive = widget.user?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Thêm Nhân Sự' : 'Sửa Nhân Sự'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Họ Tên'),
                onSaved: (val) => name = val ?? '',
                validator: (val) => val!.isEmpty ? 'Không được để trống' : null,
              ),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (val) => email = val,
                validator: (val) => (val == null || val.isEmpty || !val.contains('@')) ? 'Email không hợp lệ' : null,
              ),
              TextFormField(
                initialValue: phone,
                decoration: const InputDecoration(labelText: 'Số Điện Thoại'),
                onSaved: (val) => phone = val,
              ),
              DropdownButtonFormField<String>(
                value: role.toUpperCase(),
                items: const [
                  DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  DropdownMenuItem(value: 'CASHIER', child: Text('Thu Ngân')),
                  DropdownMenuItem(value: 'KITCHEN', child: Text('Bếp')),
                  DropdownMenuItem(value: 'WAITER', child: Text('Phục Vụ')),
                  DropdownMenuItem(value: 'BAR', child: Text('Pha Chế')),
                ],
                onChanged: (val) => setState(() => role = val!),
                decoration: const InputDecoration(labelText: 'Vai trò (Role)'),
              ),
              if (widget.user == null)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Mật khẩu (bắt buộc)'),
                  onSaved: (val) => password = val,
                  validator: (val) => val!.isEmpty ? 'Nhập mật khẩu' : null,
                )
              else 
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Mật khẩu mới (để trống nếu ko đổi)'),
                  onSaved: (val) => password = val,
                ),
              SwitchListTile(
                title: const Text('Đang làm việc (Active)'),
                value: isActive,
                onChanged: (val) => setState(() => isActive = val),
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final payload = {
                'name': name,
                'email': email,
                'phone': phone,
                'role': role,
                'is_active': isActive,
              };
              if (password != null && password!.isNotEmpty) {
                 payload['password'] = password!;
              }
              
              bool success;
              if (widget.user == null) {
                success = await ref.read(adminUserProvider.notifier).createUser(payload);
              } else {
                success = await ref.read(adminUserProvider.notifier).updateUser(widget.user!.id, payload);
              }
              
              if (success && mounted) {
                 Navigator.pop(context);
              } else if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra (bị trùng Email/Phone hoặc dữ liệu sai)')));
              }
            }
          },
          child: const Text('Lưu'),
        )
      ],
    );
  }
}
