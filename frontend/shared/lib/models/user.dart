enum UserRole {
  admin,
  cashier,
  waiter,
  kitchen,
  bar
}

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phone;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? 'No Name',
      role: UserRole.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['role'] as String?)?.toUpperCase(),
        orElse: () => UserRole.waiter,
      ),
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
