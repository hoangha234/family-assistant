import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

part 'add_expense_state.dart';

class AddExpenseCubit extends Cubit<AddExpenseState> {
  final ExpenseService _expenseService;

  AddExpenseCubit({ExpenseService? expenseService})
      : _expenseService = expenseService ?? ExpenseService(),
        super(const AddExpenseState());

  void setTransactionType(String type) {
    emit(state.copyWith(transactionType: type));
  }

  void setCategory(String category) {
    emit(state.copyWith(selectedCategory: category));
  }

  void setWalletId(String? walletId) {
    emit(state.copyWith(walletId: walletId));
  }

  void setNote(String? note) {
    emit(state.copyWith(note: note));
  }

  void onKeyTap(String value) {
    String currentAmount = state.amount;
    if (currentAmount == '0' && value != '.') {
      currentAmount = value;
    } else {
      if (value == '.' && currentAmount.contains('.')) return;
      if (currentAmount.length < 10) {
        currentAmount += value;
      }
    }
    emit(state.copyWith(amount: currentAmount));
  }

  void onBackspace() {
    String currentAmount = state.amount;
    if (currentAmount.length > 1) {
      currentAmount = currentAmount.substring(0, currentAmount.length - 1);
    } else {
      currentAmount = '0';
    }
    emit(state.copyWith(amount: currentAmount));
  }

  /// Confirm and save the transaction
  Future<bool> confirmTransaction() async {
    // Validate amount > 0
    if (!state.isValidAmount) {
      emit(state.copyWith(
        status: AddExpenseStatus.error,
        errorMessage: 'Amount must be greater than 0',
      ));
      return false;
    }

    emit(state.copyWith(status: AddExpenseStatus.saving, clearError: true));

    try {
      // Create Expense object
      final expense = Expense(
        id: '',
        amount: state.amountValue,
        category: state.selectedCategory,
        type: state.isIncome ? ExpenseType.income : ExpenseType.expense,
        source: ExpenseSource.manual,
        walletId: state.walletId,
        createdAt: DateTime.now(),
        note: state.note,
      );

      // Save to Firestore
      await _expenseService.createExpense(expense);

      emit(state.copyWith(status: AddExpenseStatus.success));
      return true;
    } catch (e) {
      emit(state.copyWith(
        status: AddExpenseStatus.error,
        errorMessage: 'Failed to save: $e',
      ));
      return false;
    }
  }

  /// Clear any error message
  void clearError() {
    emit(state.copyWith(clearError: true, status: AddExpenseStatus.initial));
  }

  /// Reset state
  void reset() {
    emit(const AddExpenseState());
  }
}
