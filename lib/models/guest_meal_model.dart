class GuestMealModel {
  final String id;
  final String employeeId;
  final String guestType;
  final String guestName;
  final String? vendorId;
  final DateTime mealDate;
  final String mealType;
  final double amount;
  final String? notes;
  final DateTime createdAt;
  final String? employeeCode;
  final String? employeeName;
  final String? vendorName;

  const GuestMealModel({
    required this.id,
    required this.employeeId,
    required this.guestType,
    required this.guestName,
    this.vendorId,
    required this.mealDate,
    required this.mealType,
    required this.amount,
    this.notes,
    required this.createdAt,
    this.employeeCode,
    this.employeeName,
    this.vendorName,
  });

  factory GuestMealModel.fromMap(Map<String, dynamic> map) {
    return GuestMealModel(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      guestType: (map['guest_type'] as String).toUpperCase(),
      guestName: map['guest_name'] as String,
      vendorId: map['vendor_id'] as String?,
      mealDate: DateTime.parse(map['meal_date'] as String),
      mealType: (map['meal_type'] as String).toUpperCase(),
      amount: (map['amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      employeeCode: map['employee_code'] as String?,
      employeeName: map['employee_name'] as String?,
      vendorName: map['vendor_name'] as String?,
    );
  }
}
