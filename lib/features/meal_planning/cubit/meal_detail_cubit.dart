import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'meal_detail_state.dart';

class MealDetailCubit extends Cubit<MealDetailState> {
  MealDetailCubit() : super(const MealDetailState());

  /// Set the active tab (Ingredients or Instructions)
  void setTab(bool isIngredients) {
    emit(state.copyWith(isIngredientsTab: isIngredients));
  }

  /// Initialize ingredients from a list of raw strings
  void initIngredients(List<String> rawIngredients) {
    final ingredients = rawIngredients
        .map((raw) => IngredientItem.fromString(raw))
        .toList();
    emit(state.copyWith(ingredients: ingredients));
  }

  /// Toggle the checked state of an ingredient at the given index
  void toggleIngredient(int index) {
    if (index < 0 || index >= state.ingredients.length) return;

    final updatedIngredients = List<IngredientItem>.from(state.ingredients);
    final item = updatedIngredients[index];
    updatedIngredients[index] = item.copyWith(isChecked: !item.isChecked);

    emit(state.copyWith(ingredients: updatedIngredients));
  }

  /// Check all ingredients
  void checkAllIngredients() {
    final updatedIngredients = state.ingredients
        .map((item) => item.copyWith(isChecked: true))
        .toList();
    emit(state.copyWith(ingredients: updatedIngredients));
  }

  /// Uncheck all ingredients
  void uncheckAllIngredients() {
    final updatedIngredients = state.ingredients
        .map((item) => item.copyWith(isChecked: false))
        .toList();
    emit(state.copyWith(ingredients: updatedIngredients));
  }

  /// Get the count of checked ingredients
  int get checkedCount => state.ingredients.where((i) => i.isChecked).length;

  /// Get the total count of ingredients
  int get totalCount => state.ingredients.length;
}
