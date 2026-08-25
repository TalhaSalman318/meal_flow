class MealRecordModel {
  final String id;
  final String employeeId;
  final DateTime mealDate;
  final String mealType;
  final String status;
  final double rate;
  final DateTime? cancelledAt;
  final DateTime? servedAt;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? employeeCode;
  final String? employeeName;

  const MealRecordModel({
    required this.id,
    required this.employeeId,
    required this.mealDate,
    required this.mealType,
    required this.status,
    required this.rate,
    this.cancelledAt,
    this.servedAt,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.employeeCode,
    this.employeeName,
  });

  factory MealRecordModel.fromMap(Map<String, dynamic> map) {
    return MealRecordModel(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      mealDate: DateTime.parse(map['meal_date'] as String),
      mealType: (map['meal_type'] as String? ?? 'NORMAL').toUpperCase(),
      status: (map['status'] as String? ?? 'PLANNED').toUpperCase(),
      rate: (map['rate'] as num).toDouble(),
      cancelledAt: _dateTimeOrNull(map['cancelled_at']),
      servedAt: _dateTimeOrNull(map['served_at']),
      updatedBy: map['updated_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      employeeCode: map['employee_code'] as String?,
      employeeName: map['employee_name'] as String?,
    );
  }

  MealRecordModel copyWith({
    String? status,
    DateTime? cancelledAt,
    DateTime? updatedAt,
    DateTime? servedAt,
  }) {
    return MealRecordModel(
      id: id,
      employeeId: employeeId,
      mealDate: mealDate,
      mealType: mealType,
      status: status ?? this.status,
      rate: rate,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      servedAt: servedAt ?? this.servedAt,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      employeeCode: employeeCode,
      employeeName: employeeName,
    );
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    return value == null ? null : DateTime.parse(value as String);
  }
}
