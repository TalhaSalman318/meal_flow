class SubscriptionPauseModel {
  final String id;
  final String subscriptionId;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final DateTime createdAt;

  const SubscriptionPauseModel({
    required this.id,
    required this.subscriptionId,
    required this.startDate,
    required this.endDate,
    this.reason,
    required this.createdAt,
  });

  factory SubscriptionPauseModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionPauseModel(
      id: map['id'] as String,
      subscriptionId: map['subscription_id'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      reason: map['reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool covers(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}
