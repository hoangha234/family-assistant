part of 'meal_plan_cubit.dart';

enum MealPlanStatus { initial, loading, loaded, generating, error }

class MealPlanState extends Equatable {
  final DateTime selectedDate;
  final DateTime currentMonth;
  final List<MealModel> meals;
  final MealModel? generatedPreview;
  final MealPlanStatus status;
  final bool isGenerating;
  final bool isSaving;
  final String? errorMessage;
  final MealType? selectedMealType;

  MealPlanState({
    DateTime? selectedDate,
    DateTime? currentMonth,
    this.meals = const [],
    this.generatedPreview,
    this.status = MealPlanStatus.initial,
    this.isGenerating = false,
    this.isSaving = false,
    this.errorMessage,
    this.selectedMealType,
  })  : selectedDate = selectedDate ?? DateTime.now(),
        currentMonth = currentMonth ?? DateTime(DateTime.now().year, DateTime.now().month);

  /// Get meal by type for current day
  MealModel? getMealByType(MealType type) {
    try {
      return meals.firstWhere((m) => m.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Calculate total calories for the day
  int get totalCalories => meals.fold(0, (sum, m) => sum + m.calories);

  /// Calculate total protein for the day
  int get totalProtein => meals.fold(0, (sum, m) => sum + m.protein);

  /// Calculate total carbs for the day
  int get totalCarbs => meals.fold(0, (sum, m) => sum + m.carbs);

  /// Calculate total fats for the day
  int get totalFats => meals.fold(0, (sum, m) => sum + m.fats);

  /// Calculate calorie progress (target: 2000 kcal)
  double get calorieProgress => (totalCalories / 2000).clamp(0.0, 1.0);

  /// Check if loading
  bool get isLoading => status == MealPlanStatus.loading;

  /// Get formatted date string (yyyy-MM-dd)
  String get selectedDateString {
    return '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
  }

  /// Get days in current month
  int get daysInCurrentMonth {
    return DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
  }

  /// Get first weekday of current month (1 = Monday, 7 = Sunday)
  int get firstWeekdayOfMonth {
    return DateTime(currentMonth.year, currentMonth.month, 1).weekday;
  }

  /// Check if a date is today
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Check if a date is selected
  bool isSelected(DateTime date) {
    return date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
  }

  MealPlanState copyWith({
    DateTime? selectedDate,
    DateTime? currentMonth,
    List<MealModel>? meals,
    MealModel? generatedPreview,
    MealPlanStatus? status,
    bool? isGenerating,
    bool? isSaving,
    String? errorMessage,
    MealType? selectedMealType,
    bool clearPreview = false,
    bool clearError = false,
  }) {
    return MealPlanState(
      selectedDate: selectedDate ?? this.selectedDate,
      currentMonth: currentMonth ?? this.currentMonth,
      meals: meals ?? this.meals,
      generatedPreview: clearPreview ? null : (generatedPreview ?? this.generatedPreview),
      status: status ?? this.status,
      isGenerating: isGenerating ?? this.isGenerating,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedMealType: selectedMealType ?? this.selectedMealType,
    );
  }

  @override
  List<Object?> get props => [
        selectedDate,
        currentMonth,
        meals,
        generatedPreview,
        status,
        isGenerating,
        isSaving,
        errorMessage,
        selectedMealType,
      ];
}
