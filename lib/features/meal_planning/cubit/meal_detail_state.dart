part of 'meal_detail_cubit.dart';

class MealDetailState extends Equatable {
  final bool isIngredientsTab;

  const MealDetailState({
    this.isIngredientsTab = true,
  });

  MealDetailState copyWith({
    bool? isIngredientsTab,
  }) {
    return MealDetailState(
      isIngredientsTab: isIngredientsTab ?? this.isIngredientsTab,
    );
  }

  @override
  List<Object> get props => [isIngredientsTab];
}
