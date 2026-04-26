import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/shopping_service.dart';
import '../../wallet/repositories/wallet_repository.dart';
import '../../expense/models/expense_model.dart';
import '../../expense/services/expense_service.dart';

part 'add_schedule_state.dart';

class AddScheduleCubit extends Cubit<AddScheduleState> {
  final ShoppingService _shoppingService;
  final WalletRepository _walletRepository;
  final ExpenseService _expenseService;

  AddScheduleCubit({
    ShoppingService? shoppingService,
    WalletRepository? walletRepository,
    ExpenseService? expenseService,
  })  : _shoppingService = shoppingService ?? ShoppingService(),
        _walletRepository = walletRepository ?? WalletRepository(),
        _expenseService = expenseService ?? ExpenseService(),
        super(const AddScheduleState());

  void updateName(String name) {
    emit(state.copyWith(itemName: name));
  }

  void updateCost(String cost) {
    emit(state.copyWith(estimatedCost: cost));
  }

  void updateCategory(String category) {
    emit(state.copyWith(selectedCategory: category));
  }

  void updateDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
  }

  void updateNotes(String notes) {
    emit(state.copyWith(notes: notes));
  }

  void updateWallet(String? walletId) {
    emit(state.copyWith(selectedWalletId: walletId));
  }

  void updatePaymentMode(PaymentMode mode) {
    emit(state.copyWith(
      paymentMode: mode,
      // Clear wallet if switching to manual
      clearWallet: mode == PaymentMode.manual,
      repeatCycle: mode == PaymentMode.manual ? RepeatCycle.none : state.repeatCycle,
    ));
  }

  void updateRepeatCycle(RepeatCycle cycle) {
    emit(state.copyWith(repeatCycle: cycle));
  }

  /// Save schedule to Firestore
  Future<bool> saveItem() async {
    // Validate
    if (!state.isValid) {
      emit(state.copyWith(
        status: AddScheduleStatus.error,
        errorMessage: 'Please fill in all required fields',
      ));
      return false;
    }

    emit(state.copyWith(status: AddScheduleStatus.saving, clearError: true));

    try {
      final schedule = ShoppingSchedule(
        id: '', // Will be assigned by Firestore
        title: state.itemName,
        amount: state.amount,
        category: state.selectedCategory,
        dueDate: state.selectedDate!,
        paymentMode: state.paymentMode,
        status: ScheduleStatus.pending,
        walletId: state.paymentMode == PaymentMode.automatic ? state.selectedWalletId : null,
        repeatCycle: state.paymentMode == PaymentMode.automatic ? state.repeatCycle : RepeatCycle.none,
        notes: state.notes,
        createdAt: DateTime.now(),
      );

      print('📝 [AddSchedule] Creating schedule:');
      print('   - Title: ${schedule.title}');
      print('   - Amount: ${schedule.amount}');
      print('   - PaymentMode: ${schedule.paymentMode}');
      print('   - RepeatCycle: ${schedule.repeatCycle}');
      print('   - WalletId: ${schedule.walletId}');
      print('   - DueDate: ${schedule.dueDate}');

      // Create schedule and get the created schedule with ID
      final createdSchedule = await _shoppingService.createSchedule(schedule);
      print('   ✅ Schedule created with ID: ${createdSchedule.id}');

      // If automatic payment and due today or before, process immediately
      if (schedule.paymentMode == PaymentMode.automatic &&
          schedule.walletId != null) {
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final dueDateStart = DateTime(
          schedule.dueDate.year,
          schedule.dueDate.month,
          schedule.dueDate.day
        );

        print('   - Today: $todayStart');
        print('   - DueDate: $dueDateStart');
        print('   - Is due today or before: ${dueDateStart.isBefore(todayStart) || dueDateStart.isAtSameMomentAs(todayStart)}');

        if (dueDateStart.isBefore(todayStart) ||
            dueDateStart.isAtSameMomentAs(todayStart)) {
          print('🔄 [AddSchedule] Processing immediate automatic payment...');
          await _processImmediatePayment(createdSchedule);
        } else {
          print('   ⏰ DueDate is in the future, skipping immediate payment');
        }
      } else {
        print('   ℹ️ Not an automatic payment or no wallet selected');
      }

      emit(state.copyWith(status: AddScheduleStatus.success));
      return true;
    } catch (e) {
      print('   ❌ Error: $e');
      emit(state.copyWith(
        status: AddScheduleStatus.error,
        errorMessage: 'Failed to save: $e',
      ));
      return false;
    }
  }

  /// Process immediate automatic payment for newly created schedule
  Future<void> _processImmediatePayment(ShoppingSchedule schedule) async {
    try {
      // Get wallet
      final wallet = await _walletRepository.getWalletById(schedule.walletId!);
      if (wallet == null) {
        print('   ❌ Wallet not found');
        await _shoppingService.markAsFailed(schedule.id);
        return;
      }

      print('   - Wallet balance: ${wallet.balance}');

      // Check balance
      if (wallet.balance >= schedule.amount) {
        print('   ✅ Processing payment...');

        // 1. Create Expense
        final expense = Expense(
          id: '',
          amount: schedule.amount,
          category: schedule.category,
          type: ExpenseType.expense,
          source: ExpenseSource.schedule,
          walletId: schedule.walletId,
          createdAt: DateTime.now(),
          note: 'Auto payment: ${schedule.title}',
        );
        await _expenseService.createExpense(expense);
        print('   ✅ Expense created');

        // 2. Deduct wallet and update status or date
        await _shoppingService.processAutomaticPaymentTransaction(
          scheduleId: schedule.id,
          walletId: schedule.walletId!,
          amount: schedule.amount,
          isMonthly: schedule.isMonthly,
        );
        print('   ✅ Wallet deducted and schedule updated');
      } else {
        print('   ❌ Insufficient balance');
        await _shoppingService.markAsFailed(schedule.id);
      }
    } catch (e) {
      print('   ❌ Immediate payment error: $e');
      await _shoppingService.markAsFailed(schedule.id);
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true, status: AddScheduleStatus.initial));
  }

  void reset() {
    emit(const AddScheduleState());
  }
}
