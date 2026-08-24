class EmployeeModel {
  final String id;
  final String profileId;
  final String employeeCode;
  final String? department;
  final String? designation;
  final String? phone;
  final String status;

  const EmployeeModel({
    required this.id,
    required this.profileId,
    required this.employeeCode,
    this.department,
    this.designation,
    this.phone,
    required this.status,
  });

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      employeeCode: map['employee_code'] as String,
      department: map['department'] as String?,
      designation: map['designation'] as String?,
      phone: map['phone'] as String?,
      status: map['status'] as String? ?? 'ACTIVE',
    );
  }
}
