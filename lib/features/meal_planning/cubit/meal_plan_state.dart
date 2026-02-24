part of 'meal_plan_cubit.dart';

class MealPlanState extends Equatable {
  final int selectedDayIndex;

  const MealPlanState({
    this.selectedDayIndex = 2, // Wednesday
  });

  MealPlanState copyWith({
    int? selectedDayIndex,
  }) {
    return MealPlanState(
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
    );
  }

  @override
  List<Object> get props => [selectedDayIndex];
}
