import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of expense transaction
enum ExpenseType {
  income,
  expense;

  String get value => name;

  static ExpenseType fromString(String value) {
    return ExpenseType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseType.expense,
    );
  }
}

/// Source of expense transaction
enum ExpenseSource {
  manual,
  schedule;

  String get value => name;

  static ExpenseSource fromString(String value) {
    return ExpenseSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseSource.manual,
    );
  }
}

/// Model representing an expense/income transaction
class Expense {
  final String id;
  final double amount;
  final String category;
  final ExpenseType type;
  final ExpenseSource source;
  final String? walletId;
  final DateTime createdAt;
  final String? note;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.type,
    this.source = ExpenseSource.manual,
    this.walletId,
    required this.createdAt,
    this.note,
  });

  /// Create from Firestore document
  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense.fromMap(data, doc.id);
  }

  /// Create from Map
  factory Expense.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Expense(
      id: docId ?? map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'Other',
      type: ExpenseType.fromString(map['type'] as String? ?? 'expense'),
      source: ExpenseSource.fromString(map['source'] as String? ?? 'manual'),
      walletId: map['walletId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'type': type.value,
      'source': source.value,
      'walletId': walletId,
      'createdAt': Timestamp.fromDate(createdAt),
      'note': note,
    };
  }

  /// Create a copy with updated fields
  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    ExpenseType? type,
    ExpenseSource? source,
    String? walletId,
    DateTime? createdAt,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      source: source ?? this.source,
      walletId: walletId ?? this.walletId,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  /// Check if this is an income
  bool get isIncome => type == ExpenseType.income;

  /// Check if this is an expense
  bool get isExpense => type == ExpenseType.expense;

  /// Check if this came from a schedule
  bool get isFromSchedule => source == ExpenseSource.schedule;

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, category: $category, type: $type, source: $source)';
  }
}

