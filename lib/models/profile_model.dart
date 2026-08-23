class ProfileModel {
  final String id;
  final String fullName;
  final String? email;
  final String role;
  final String status;

  ProfileModel({
    required this.id,
    required this.fullName,
    this.email,
    required this.role,
    required this.status,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String?,
      role: map['role'] as String,
      status: map['status'] as String,
    );
  }

  bool get isEmployee => role.toUpperCase() == 'EMPLOYEE';

  bool get isVendor => role.toUpperCase() == 'VENDOR';

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}
