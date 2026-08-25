class SubscriptionModel {
  final String id;
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;
  final double dailyRate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionModel({
    required this.id,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.dailyRate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      dailyRate: (map['daily_rate'] as num).toDouble(),
      status: (map['status'] as String).toUpperCase(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
