part of 'add_expense_cubit.dart';

/// Status for add expense operation
enum AddExpenseStatus {
  initial,
  saving,
  success,
  error,
}

class AddExpenseState extends Equatable {
  final String amount;
  final String transactionType;
  final String selectedCategory;
  final String? walletId;
  final String? note;
  final AddExpenseStatus status;
  final String? errorMessage;

  const AddExpenseState({
    this.amount = '0',
    this.transactionType = 'Expense',
    this.selectedCategory = 'Food',
    this.walletId,
    this.note,
    this.status = AddExpenseStatus.initial,
    this.errorMessage,
  });

  /// Parse amount to double
  double get amountValue => double.tryParse(amount) ?? 0.0;

  /// Check if amount is valid
  bool get isValidAmount => amountValue > 0;

  /// Check if this is income type
  bool get isIncome => transactionType == 'Income';

  /// Check if saving
  bool get isSaving => status == AddExpenseStatus.saving;

  /// Check if success
  bool get isSuccess => status == AddExpenseStatus.success;

  /// Check if has error
  bool get hasError => status == AddExpenseStatus.error;

  AddExpenseState copyWith({
    String? amount,
    String? transactionType,
    String? selectedCategory,
    String? walletId,
    String? note,
    AddExpenseStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddExpenseState(
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      walletId: walletId ?? this.walletId,
      note: note ?? this.note,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        amount,
        transactionType,
        selectedCategory,
        walletId,
        note,
        status,
        errorMessage,
      ];
}
