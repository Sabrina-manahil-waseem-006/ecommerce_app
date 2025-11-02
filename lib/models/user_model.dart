class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'role': role,
      };
}
