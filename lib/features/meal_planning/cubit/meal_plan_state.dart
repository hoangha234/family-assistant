part of 'meal_plan_cubit.dart';

enum MealPlanStatus { initial, loading, loaded, generating, error }

class MealPlanState extends Equatable {
  final int selectedDayIndex;
  final List<MealModel> meals;
  final MealModel? generatedPreview;
  final MealPlanStatus status;
  final bool isGenerating;
  final String? errorMessage;
  final MealType? selectedMealType;

  const MealPlanState({
    this.selectedDayIndex = 2, // Wednesday
    this.meals = const [],
    this.generatedPreview,
    this.status = MealPlanStatus.initial,
    this.isGenerating = false,
    this.errorMessage,
    this.selectedMealType,
  });

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

  MealPlanState copyWith({
    int? selectedDayIndex,
    List<MealModel>? meals,
    MealModel? generatedPreview,
    MealPlanStatus? status,
    bool? isGenerating,
    String? errorMessage,
    MealType? selectedMealType,
    bool clearPreview = false,
    bool clearError = false,
  }) {
    return MealPlanState(
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
      meals: meals ?? this.meals,
      generatedPreview: clearPreview ? null : (generatedPreview ?? this.generatedPreview),
      status: status ?? this.status,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedMealType: selectedMealType ?? this.selectedMealType,
    );
  }

  @override
  List<Object?> get props => [
        selectedDayIndex,
        meals,
        generatedPreview,
        status,
        isGenerating,
        errorMessage,
        selectedMealType,
      ];
}
