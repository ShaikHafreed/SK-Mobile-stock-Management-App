class UserModel {
  final int id;
  final String username;
  final String? fullName;
  final String? profileImage;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    this.fullName,
    this.profileImage,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      profileImage: json['profile_image'],
      role: json['role'] ?? 'staff',
      isActive: json['is_active'] ?? true,
    );
  }

  bool get isAdmin => role == 'admin';
}