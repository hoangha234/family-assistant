part of 'expense_cubit.dart';

/// Status for expense cubit
enum ExpenseCubitStatus {
  initial,
  loading,
  loaded,
  error,
}

class ExpenseState extends Equatable {
  final int selectedMonthIndex;
  final ExpenseCubitStatus status;
  final List<Expense> allExpenses;
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> categoryTotals;
  final List<Expense> recentTransactions;
  final String? errorMessage;

  const ExpenseState({
    this.selectedMonthIndex = 0,
    this.status = ExpenseCubitStatus.initial,
    this.allExpenses = const [],
    this.totalBalance = 0.0,
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.categoryTotals = const {},
    this.recentTransactions = const [],
    this.errorMessage,
  });

  bool get isLoading => status == ExpenseCubitStatus.loading;
  bool get isLoaded => status == ExpenseCubitStatus.loaded;
  bool get hasError => status == ExpenseCubitStatus.error;

  /// Get top categories sorted by amount
  List<MapEntry<String, double>> get topCategories {
    final entries = categoryTotals.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  /// Get category percentage
  double getCategoryPercentage(String category) {
    if (totalExpense == 0) return 0;
    return ((categoryTotals[category] ?? 0) / totalExpense) * 100;
  }

  ExpenseState copyWith({
    int? selectedMonthIndex,
    ExpenseCubitStatus? status,
    List<Expense>? allExpenses,
    double? totalBalance,
    double? totalIncome,
    double? totalExpense,
    Map<String, double>? categoryTotals,
    List<Expense>? recentTransactions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ExpenseState(
      selectedMonthIndex: selectedMonthIndex ?? this.selectedMonthIndex,
      status: status ?? this.status,
      allExpenses: allExpenses ?? this.allExpenses,
      totalBalance: totalBalance ?? this.totalBalance,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      categoryTotals: categoryTotals ?? this.categoryTotals,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        selectedMonthIndex,
        status,
        allExpenses,
        totalBalance,
        totalIncome,
        totalExpense,
        categoryTotals,
        recentTransactions,
        errorMessage,
      ];
}
