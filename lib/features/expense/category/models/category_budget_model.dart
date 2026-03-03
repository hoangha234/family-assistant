import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a budget category in the Jar Budget System
class CategoryBudget {
  final String id;
  final String name;
  final double monthlyBudget;
  final double totalSpent;
  final DateTime updatedAt;

  CategoryBudget({
    required this.id,
    required this.name,
    required this.monthlyBudget,
    this.totalSpent = 0.0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Remaining amount in the budget
  double get remainingAmount => monthlyBudget - totalSpent;

  /// Spending percentage (0.0 to 1.0+)
  double get spendingPercentage {
    if (monthlyBudget <= 0) return 0.0;
    return totalSpent / monthlyBudget;
  }

  /// Spending percentage as integer (0 to 100+)
  int get spendingPercentageInt => (spendingPercentage * 100).round();

  /// Check if overspent
  bool get isOverspent => totalSpent > monthlyBudget;

  /// Budget status for UI coloring
  BudgetStatus get status {
    final percentage = spendingPercentageInt;
    if (percentage > 100) return BudgetStatus.overspent;
    if (percentage > 70) return BudgetStatus.danger;
    if (percentage > 30) return BudgetStatus.warning;
    return BudgetStatus.safe;
  }

  /// Create from Firestore document
  factory CategoryBudget.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryBudget(
      id: docId,
      name: map['name'] as String? ?? '',
      monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (map['totalSpent'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'monthlyBudget': monthlyBudget,
      'totalSpent': totalSpent,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated values
  CategoryBudget copyWith({
    String? id,
    String? name,
    double? monthlyBudget,
    double? totalSpent,
    DateTime? updatedAt,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      totalSpent: totalSpent ?? this.totalSpent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CategoryBudget(id: $id, name: $name, budget: $monthlyBudget, spent: $totalSpent)';
  }
}

/// Budget status enum for progress bar coloring
enum BudgetStatus {
  safe,     // 0-30% - Green
  warning,  // 31-70% - Yellow
  danger,   // 71-100% - Red
  overspent // >100% - Dark Red
}

/// Default expense categories with suggested budgets
class DefaultCategories {
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'icon': 'restaurant', 'suggestedBudget': 500.0},
    {'name': 'Transport', 'icon': 'directions_car', 'suggestedBudget': 200.0},
    {'name': 'Shopping', 'icon': 'shopping_bag', 'suggestedBudget': 300.0},
    {'name': 'Entertainment', 'icon': 'movie', 'suggestedBudget': 150.0},
    {'name': 'Bills', 'icon': 'receipt', 'suggestedBudget': 400.0},
    {'name': 'Health', 'icon': 'medical_services', 'suggestedBudget': 200.0},
    {'name': 'Education', 'icon': 'school', 'suggestedBudget': 150.0},
    {'name': 'Other', 'icon': 'more_horiz', 'suggestedBudget': 100.0},
  ];
}

