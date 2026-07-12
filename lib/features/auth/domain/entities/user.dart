enum UserRole {
  student,
  teacher,
  parent;

  static UserRole fromApi(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.student,
    );
  }
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAtUtc,
  });

  final int id;
  final String email;
  final UserRole role;
  final DateTime createdAtUtc;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      role: UserRole.fromApi(json['role'] as String? ?? 'student'),
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  }
}
