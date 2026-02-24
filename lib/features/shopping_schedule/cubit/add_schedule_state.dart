part of 'add_schedule_cubit.dart';

/// Status for add schedule operation
enum AddScheduleStatus {
  initial,
  saving,
  success,
  error,
}

class AddScheduleState extends Equatable {
  final String itemName;
  final String estimatedCost;
  final String selectedCategory;
  final DateTime? selectedDate;
  final String notes;
  final String? selectedWalletId;
  final PaymentMode paymentMode;
  final RepeatCycle repeatCycle;
  final AddScheduleStatus status;
  final String? errorMessage;

  const AddScheduleState({
    this.itemName = '',
    this.estimatedCost = '',
    this.selectedCategory = 'Groceries',
    this.selectedDate,
    this.notes = '',
    this.selectedWalletId,
    this.paymentMode = PaymentMode.manual,
    this.repeatCycle = RepeatCycle.none,
    this.status = AddScheduleStatus.initial,
    this.errorMessage,
  });

  bool get isValid =>
      itemName.isNotEmpty &&
      estimatedCost.isNotEmpty &&
      selectedDate != null &&
      (paymentMode == PaymentMode.manual || selectedWalletId != null);

  bool get isSaving => status == AddScheduleStatus.saving;
  bool get isSuccess => status == AddScheduleStatus.success;
  bool get hasError => status == AddScheduleStatus.error;

  double get amount => double.tryParse(estimatedCost) ?? 0.0;

  AddScheduleState copyWith({
    String? itemName,
    String? estimatedCost,
    String? selectedCategory,
    DateTime? selectedDate,
    String? notes,
    String? selectedWalletId,
    PaymentMode? paymentMode,
    RepeatCycle? repeatCycle,
    AddScheduleStatus? status,
    String? errorMessage,
    bool clearWallet = false,
    bool clearError = false,
  }) {
    return AddScheduleState(
      itemName: itemName ?? this.itemName,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedDate: selectedDate ?? this.selectedDate,
      notes: notes ?? this.notes,
      selectedWalletId: clearWallet ? null : (selectedWalletId ?? this.selectedWalletId),
      paymentMode: paymentMode ?? this.paymentMode,
      repeatCycle: repeatCycle ?? this.repeatCycle,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        itemName,
        estimatedCost,
        selectedCategory,
        selectedDate,
        notes,
        selectedWalletId,
        paymentMode,
        repeatCycle,
        status,
        errorMessage,
      ];
}
