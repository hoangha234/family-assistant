import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/shopping_service.dart';
import '../../wallet/repositories/wallet_repository.dart';
import '../../expense/models/expense_model.dart';
import '../../expense/services/expense_service.dart';

part 'shopping_schedule_state.dart';

/// Cubit for managing shopping/financial schedules
class ShoppingScheduleCubit extends Cubit<ShoppingScheduleState> {
  final ShoppingService _shoppingService;
  final WalletRepository _walletRepository;
  final ExpenseService _expenseService;
  StreamSubscription<List<ShoppingSchedule>>? _schedulesSubscription;

  ShoppingScheduleCubit({
    ShoppingService? shoppingService,
    WalletRepository? walletRepository,
    ExpenseService? expenseService,
  })  : _shoppingService = shoppingService ?? ShoppingService(),
        _walletRepository = walletRepository ?? WalletRepository(),
        _expenseService = expenseService ?? ExpenseService(),
        super(const ShoppingScheduleState());

  /// Initialize cubit and load schedules
  Future<void> initialize() async {
    await loadSchedules();
    await _processAutomaticPayments();
  }

  // ==================== TAB MANAGEMENT ====================

  void setTab(int index) {
    emit(state.copyWith(selectedTab: index));
  }

  // ==================== LOAD SCHEDULES ====================

  /// Load all schedules and split into pending/completed
  Future<void> loadSchedules() async {
    emit(state.copyWith(status: ShoppingCubitStatus.loading, clearError: true));

    try {
      final allSchedules = await _shoppingService.fetchAllSchedules();
      _splitSchedules(allSchedules);
    } catch (e) {
      emit(state.copyWith(
        status: ShoppingCubitStatus.error,
        errorMessage: 'Failed to load schedules: $e',
      ));
    }
  }

  /// Subscribe to real-time schedule updates
  void subscribeToSchedules() {
    _schedulesSubscription?.cancel();
    _schedulesSubscription = _shoppingService.watchAllSchedules().listen(
      (schedules) => _splitSchedules(schedules),
      onError: (error) {
        emit(state.copyWith(
          status: ShoppingCubitStatus.error,
          errorMessage: 'Stream error: $error',
        ));
      },
    );
  }

  /// Split schedules into pending and completed lists
  void _splitSchedules(List<ShoppingSchedule> allSchedules) {
    final pending = allSchedules
        .where((s) => s.status == ScheduleStatus.pending)
        .toList();
    final completed = allSchedules
        .where((s) => s.status == ScheduleStatus.paid)
        .toList();

    // Sort pending by due date (earliest first)
    pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    // Sort completed by due date (most recent first)
    completed.sort((a, b) => b.dueDate.compareTo(a.dueDate));

    emit(state.copyWith(
      status: ShoppingCubitStatus.loaded,
      allSchedules: allSchedules,
      pendingSchedules: pending,
      completedSchedules: completed,
    ));
  }

  // ==================== MANUAL PURCHASE FLOW ====================

  /// Process manual purchase for a schedule
  /// - Creates expense
  /// - Deducts wallet balance
  /// - Updates schedule status to paid
  Future<bool> processManualPurchase({
    required String scheduleId,
    required String walletId,
  }) async {
    // Prevent double payment
    if (state.isScheduleProcessing(scheduleId)) {
      return false;
    }

    // Find the schedule
    final schedule = state.allSchedules.firstWhere(
      (s) => s.id == scheduleId,
      orElse: () => throw Exception('Schedule not found'),
    );

    // Verify schedule is pending
    if (schedule.status != ScheduleStatus.pending) {
      emit(state.copyWith(
        errorMessage: 'Schedule is not pending',
      ));
      return false;
    }

    // Add to processing set
    final processingIds = Set<String>.from(state.processingScheduleIds)
      ..add(scheduleId);
    emit(state.copyWith(
      status: ShoppingCubitStatus.processing,
      processingScheduleIds: processingIds,
    ));

    try {
      // Get wallet and verify balance
      final wallet = await _walletRepository.getWalletById(walletId);
      if (wallet == null) {
        throw Exception('Wallet not found');
      }

      if (wallet.balance < schedule.amount) {
        throw Exception('Insufficient wallet balance');
      }

      // 1. Create Expense record FIRST (source = schedule)
      final expense = Expense(
        id: '',
        amount: schedule.amount,
        category: schedule.category,
        type: ExpenseType.expense,
        source: ExpenseSource.schedule,
        walletId: walletId,
        createdAt: DateTime.now(),
        note: 'From schedule: ${schedule.title}',
      );
      await _expenseService.createExpense(expense);

      // 2. Process payment using transaction (deduct wallet, update status or date)
      await _shoppingService.processAutomaticPaymentTransaction(
        scheduleId: scheduleId,
        walletId: walletId,
        amount: schedule.amount,
        isMonthly: schedule.isMonthly,
      );

      // Remove from processing and reload
      final updatedProcessingIds = Set<String>.from(state.processingScheduleIds)
        ..remove(scheduleId);
      emit(state.copyWith(processingScheduleIds: updatedProcessingIds));

      await loadSchedules();
      return true;
    } catch (e) {
      // Remove from processing set
      final updatedProcessingIds = Set<String>.from(state.processingScheduleIds)
        ..remove(scheduleId);
      emit(state.copyWith(
        status: ShoppingCubitStatus.error,
        processingScheduleIds: updatedProcessingIds,
        errorMessage: 'Payment failed: $e',
      ));
      return false;
    }
  }

  // ==================== AUTOMATIC PAYMENT FLOW ====================

  /// Process all due automatic payments on initialization
  Future<void> _processAutomaticPayments() async {
    try {
      final today = DateTime.now();
      print('🔄 [AutoPay] Processing automatic payments for: $today');

      final dueSchedules = await _shoppingService.fetchDueAutomaticSchedules(today);
      print('🔄 [AutoPay] Found ${dueSchedules.length} due schedules');

      for (final schedule in dueSchedules) {
        await _processAutoPayment(schedule);
      }

      // Reload after processing
      if (dueSchedules.isNotEmpty) {
        await loadSchedules();
      }
    } catch (e) {
      // Log error but don't block UI
      print('❌ [AutoPay] Auto payment processing error: $e');
    }
  }

  /// Process a single automatic payment
  Future<void> _processAutoPayment(ShoppingSchedule schedule) async {
    print('🔄 [AutoPay] Processing schedule: ${schedule.id}');
    print('   - Title: ${schedule.title}');
    print('   - Amount: ${schedule.amount}');
    print('   - RepeatCycle: ${schedule.repeatCycle}');
    print('   - isMonthly: ${schedule.isMonthly}');
    print('   - WalletId: ${schedule.walletId}');
    print('   - Status: ${schedule.status}');

    // Skip if already processing or not pending
    if (state.isScheduleProcessing(schedule.id) ||
        schedule.status != ScheduleStatus.pending) {
      print('   ❌ Skipped: already processing or not pending');
      return;
    }

    // Skip if no wallet linked
    if (schedule.walletId == null) {
      print('   ❌ Skipped: no wallet linked');
      await _shoppingService.markAsFailed(schedule.id);
      return;
    }

    try {
      // Get wallet balance
      final wallet = await _walletRepository.getWalletById(schedule.walletId!);

      if (wallet == null) {
        print('   ❌ Wallet not found');
        await _shoppingService.markAsFailed(schedule.id);
        return;
      }

      print('   - Wallet balance: ${wallet.balance}');

      // Check if wallet has sufficient balance
      if (wallet.balance >= schedule.amount) {
        print('   ✅ Sufficient balance, creating expense...');

        // 1. Create Expense record FIRST (source = schedule)
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

        // 2. Process payment (deduct wallet, update status or date)
        await _shoppingService.processAutomaticPaymentTransaction(
          scheduleId: schedule.id,
          walletId: schedule.walletId!,
          amount: schedule.amount,
          isMonthly: schedule.isMonthly,
        );
        print('   ✅ Wallet deducted and schedule updated');
      } else {
        // Insufficient balance - mark as failed
        print('   ❌ Insufficient balance');
        await _shoppingService.markAsFailed(schedule.id);
      }
    } catch (e) {
      // Mark as failed on error
      await _shoppingService.markAsFailed(schedule.id);
      print('   ❌ Auto payment error for ${schedule.id}: $e');
    }
  }

  /// Manually trigger automatic payment processing
  Future<void> retryAutomaticPayments() async {
    emit(state.copyWith(status: ShoppingCubitStatus.processing));
    await _processAutomaticPayments();
    emit(state.copyWith(status: ShoppingCubitStatus.loaded));
  }

  // ==================== SCHEDULE MANAGEMENT ====================

  /// Create a new schedule
  Future<bool> createSchedule(ShoppingSchedule schedule) async {
    try {
      await _shoppingService.createSchedule(schedule);
      await loadSchedules();
      return true;
    } catch (e) {
      emit(state.copyWith(
        status: ShoppingCubitStatus.error,
        errorMessage: 'Failed to create schedule: $e',
      ));
      return false;
    }
  }

  /// Update an existing schedule
  Future<bool> updateSchedule(ShoppingSchedule schedule) async {
    try {
      await _shoppingService.updateSchedule(schedule);
      await loadSchedules();
      return true;
    } catch (e) {
      emit(state.copyWith(
        status: ShoppingCubitStatus.error,
        errorMessage: 'Failed to update schedule: $e',
      ));
      return false;
    }
  }

  /// Delete a schedule
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _shoppingService.deleteSchedule(scheduleId);
      await loadSchedules();
      return true;
    } catch (e) {
      emit(state.copyWith(
        status: ShoppingCubitStatus.error,
        errorMessage: 'Failed to delete schedule: $e',
      ));
      return false;
    }
  }

  /// Mark schedule as paid without wallet deduction (manual confirmation)
  Future<bool> markAsPaidManually(String scheduleId) async {
    try {
      final schedule = state.allSchedules.firstWhere(
        (s) => s.id == scheduleId,
        orElse: () => throw Exception('Schedule not found'),
      );

      // 1. Create Expense record FIRST (source = schedule)
      final expense = Expense(
        id: '',
        amount: schedule.amount,
        category: schedule.category,
        type: ExpenseType.expense,
        source: ExpenseSource.schedule,
        walletId: null, // No wallet for manual confirmation
        createdAt: DateTime.now(),
        note: 'Manual purchase: ${schedule.title}',
      );
      await _expenseService.createExpense(expense);

      // 2. Use transaction to mark as paid or update due date
      await _shoppingService.markAsPaidWithRecurrence(
        scheduleId: scheduleId,
        isMonthly: schedule.isMonthly,
      );

      await loadSchedules();
      return true;
    } catch (e) {
      emit(state.copyWith(
        status: ShoppingCubitStatus.error,
        errorMessage: 'Failed to mark as paid: $e',
      ));
      return false;
    }
  }

  /// Reset failed schedule back to pending
  Future<bool> resetFailedSchedule(String scheduleId) async {
    try {
      await _shoppingService.updateScheduleStatus(
        scheduleId,
        ScheduleStatus.pending,
      );
      await loadSchedules();
      return true;
    } catch (e) {
      emit(state.copyWith(
        status: ShoppingCubitStatus.error,
        errorMessage: 'Failed to reset schedule: $e',
      ));
      return false;
    }
  }

  // ==================== UTILITY ====================

  /// Clear any error message
  void clearError() {
    emit(state.copyWith(clearError: true, status: ShoppingCubitStatus.loaded));
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadSchedules();
  }

  @override
  Future<void> close() {
    _schedulesSubscription?.cancel();
    return super.close();
  }
}
