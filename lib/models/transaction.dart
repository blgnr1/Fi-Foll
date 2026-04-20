import 'package:uuid/uuid.dart';

enum TransactionType { credit, debt }

enum TransactionCategory { giyim, gida, ulasim, konaklama, market, diger }

enum TransactionStatus { open, partial, settled }

class Transaction {
  final String id;
  final String accountId;
  final TransactionType type;
  final double amount;
  final String currency;
  final TransactionCategory category;
  final String? note;
  TransactionStatus status;
  final DateTime createdAt;
  double paidAmount;
  DateTime? settledAt;

  Transaction({
    String? id,
    required this.accountId,
    required this.type,
    required this.amount,
    this.currency = 'TRY',
    required this.category,
    this.note,
    this.status = TransactionStatus.open,
    DateTime? createdAt,
    this.paidAmount = 0.0,
    this.settledAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get remainingAmount => amount - paidAmount;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      category: TransactionCategory.values.firstWhere((e) => e.name == json['category']),
      note: json['note'] as String?,
      status: TransactionStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      settledAt: json['settledAt'] != null ? DateTime.parse(json['settledAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'category': category.name,
      'note': note,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'paidAmount': paidAmount,
      'settledAt': settledAt?.toIso8601String(),
    };
  }
}
