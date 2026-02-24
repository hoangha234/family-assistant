import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

part 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseService _expenseService;
  StreamSubscription<List<Expense>>? _expensesSubscription;

  ExpenseCubit({ExpenseService? expenseService})
      : _expenseService = expenseService ?? ExpenseService(),
        super(const ExpenseState());

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
    // Calculate totals dynamically
    final totalIncome = ExpenseService.calculateTotalIncome(expenses);
    final totalExpense = ExpenseService.calculateTotalExpense(expenses);
    final totalBalance = totalIncome - totalExpense;
    final categoryTotals = ExpenseService.calculateCategoryTotals(expenses);

    // Recent transactions (last 10)
    final recentTransactions = expenses.take(10).toList();

    emit(state.copyWith(
      status: ExpenseCubitStatus.loaded,
      allExpenses: expenses,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalBalance: totalBalance,
      categoryTotals: categoryTotals,
      recentTransactions: recentTransactions,
    ));
  }

  /// Set selected month
  void setMonth(int index) {
    emit(state.copyWith(selectedMonthIndex: index));
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
