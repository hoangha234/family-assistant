import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

part 'expense_state.dart';

/// Callback type for notifying when expenses change
typedef OnExpensesChangedCallback = void Function(double totalBalance, Map<String, double> monthlyCategoryTotals);

class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseService _expenseService;
  StreamSubscription<List<Expense>>? _expensesSubscription;

  /// Callback to notify CategoryBudgetCubit when expenses change
  OnExpensesChangedCallback? onExpensesChanged;

  ExpenseCubit({ExpenseService? expenseService})
      : _expenseService = expenseService ?? ExpenseService(),
        super(ExpenseState(selectedMonthIndex: DateTime.now().month - 1));

  /// Set callback for expense changes (used by CategoryBudgetCubit)
  void setOnExpensesChangedCallback(OnExpensesChangedCallback callback) {
    onExpensesChanged = callback;
  }

  /// Initialize cubit and start listening to expenses
  void initialize() {
    emit(state.copyWith(status: ExpenseCubitStatus.loading));
    _subscribeToExpenses();
  }

  /// Subscribe to real-time expense updates
  void _subscribeToExpenses() {
    _expensesSubscription?.cancel();
    _expensesSubscription = _expenseService.streamExpenses().listen(
      (expenses) => _processExpenses(expenses),
      onError: (error) {
        emit(state.copyWith(
          status: ExpenseCubitStatus.error,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  /// Process expenses and calculate totals
  void _processExpenses(List<Expense> expenses) {
    final targetMonth = state.selectedMonthIndex + 1;
    final targetYear = DateTime.now().year; // Default to current year

    // Filter expenses for the selected month
    final monthlyExpenses = expenses.where((e) {
      return e.createdAt.month == targetMonth && e.createdAt.year == targetYear;
    }).toList();

    // Calculate totals for the selected month
    final totalIncome = ExpenseService.calculateTotalIncome(monthlyExpenses);
    final totalExpense = ExpenseService.calculateTotalExpense(monthlyExpenses);
    
    // Overall balance across all time
    final totalBalance = ExpenseService.calculateTotalIncome(expenses) - ExpenseService.calculateTotalExpense(expenses);
    
    final categoryTotals = ExpenseService.calculateCategoryTotals(monthlyExpenses);

    // Recent transactions (last 10 of the month)
    final recentTransactions = monthlyExpenses.take(10).toList();

    emit(state.copyWith(
      status: ExpenseCubitStatus.loaded,
      allExpenses: expenses,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalBalance: totalBalance,
      categoryTotals: categoryTotals,
      recentTransactions: recentTransactions,
    ));

    // Notify CategoryBudgetCubit with the filtered category totals
    onExpensesChanged?.call(totalBalance, categoryTotals);
  }

  /// Set selected month
  void setMonth(int index) {
    emit(state.copyWith(selectedMonthIndex: index));
    // Reprocess with the existing data for the new month
    _processExpenses(state.allExpenses);
  }

  /// Refresh data
  Future<void> refresh() async {
    emit(state.copyWith(status: ExpenseCubitStatus.loading));
    try {
      final expenses = await _expenseService.fetchAllExpenses();
      _processExpenses(expenses);
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseCubitStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  @override
  Future<void> close() {
    _expensesSubscription?.cancel();
    return super.close();
  }
}
