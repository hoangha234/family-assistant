part of 'shopping_schedule_cubit.dart';

/// Status of the shopping schedule cubit
enum ShoppingCubitStatus {
  initial,
  loading,
  loaded,
  processing,
  error,
}

/// State class for ShoppingScheduleCubit
class ShoppingScheduleState extends Equatable {
  final int selectedTab;
  final ShoppingCubitStatus status;
  final List<ShoppingSchedule> allSchedules;
  final List<ShoppingSchedule> pendingSchedules;
  final List<ShoppingSchedule> completedSchedules;
  final String? errorMessage;
  final Set<String> processingScheduleIds;

  const ShoppingScheduleState({
    this.selectedTab = 0,
    this.status = ShoppingCubitStatus.initial,
    this.allSchedules = const [],
    this.pendingSchedules = const [],
    this.completedSchedules = const [],
    this.errorMessage,
    this.processingScheduleIds = const {},
  });

  /// Check if loading
  bool get isLoading => status == ShoppingCubitStatus.loading;

  /// Check if processing any payment
  bool get isProcessing => status == ShoppingCubitStatus.processing;

  /// Check if there's an error
  bool get hasError => status == ShoppingCubitStatus.error;

  /// Check if a specific schedule is being processed
  bool isScheduleProcessing(String scheduleId) =>
      processingScheduleIds.contains(scheduleId);

  /// Get total pending amount
  double get totalPendingAmount =>
      pendingSchedules.fold(0.0, (sum, s) => sum + s.amount);

  /// Get total completed amount
  double get totalCompletedAmount =>
      completedSchedules.fold(0.0, (sum, s) => sum + s.amount);

  /// Get overdue schedules (pending and past due date)
  List<ShoppingSchedule> get overdueSchedules {
    final now = DateTime.now();
    return pendingSchedules.where((s) => s.isDue(now)).toList();
  }

  ShoppingScheduleState copyWith({
    int? selectedTab,
    ShoppingCubitStatus? status,
    List<ShoppingSchedule>? allSchedules,
    List<ShoppingSchedule>? pendingSchedules,
    List<ShoppingSchedule>? completedSchedules,
    String? errorMessage,
    Set<String>? processingScheduleIds,
    bool clearError = false,
  }) {
    return ShoppingScheduleState(
      selectedTab: selectedTab ?? this.selectedTab,
      status: status ?? this.status,
      allSchedules: allSchedules ?? this.allSchedules,
      pendingSchedules: pendingSchedules ?? this.pendingSchedules,
      completedSchedules: completedSchedules ?? this.completedSchedules,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      processingScheduleIds: processingScheduleIds ?? this.processingScheduleIds,
    );
  }

  @override
  List<Object?> get props => [
        selectedTab,
        status,
        allSchedules,
        pendingSchedules,
        completedSchedules,
        errorMessage,
        processingScheduleIds,
      ];
}
