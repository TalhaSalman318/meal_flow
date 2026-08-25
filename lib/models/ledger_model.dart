class LedgerModel {
  final String id;
  final String employeeId;
  final DateTime transactionDate;
  final String transactionType;
  final String description;
  final double debit;
  final double credit;
  final String? referenceId;
  final DateTime createdAt;

  const LedgerModel({
    required this.id,
    required this.employeeId,
    required this.transactionDate,
    required this.transactionType,
    required this.description,
    required this.debit,
    required this.credit,
    this.referenceId,
    required this.createdAt,
  });

  factory LedgerModel.fromMap(Map<String, dynamic> map) {
    return LedgerModel(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      transactionType: (map['transaction_type'] as String).toUpperCase(),
      description: map['description'] as String,
      debit: (map['debit'] as num).toDouble(),
      credit: (map['credit'] as num).toDouble(),
      referenceId: map['reference_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
