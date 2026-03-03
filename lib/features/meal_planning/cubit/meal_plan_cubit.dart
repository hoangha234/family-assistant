import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/meal_model.dart';
import '../services/meal_service.dart';

part 'meal_plan_state.dart';

class MealPlanCubit extends Cubit<MealPlanState> {
  final MealService _mealService;

  MealPlanCubit({MealService? mealService})
      : _mealService = mealService ?? MealService(),
        super(const MealPlanState());

  /// Initialize and load meals for today
  Future<void> loadMeals() async {
    emit(state.copyWith(status: MealPlanStatus.loading));

    try {
      final meals = await _mealService.getMealsForDate(DateTime.now());
      emit(state.copyWith(
        status: MealPlanStatus.loaded,
        meals: meals,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MealPlanStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Set selected day
  void setDay(int index) {
    emit(state.copyWith(selectedDayIndex: index));
    // TODO: Load meals for selected day
  }

  /// Set meal type for AI generation
  void setMealType(MealType type) {
    emit(state.copyWith(selectedMealType: type));
  }

  /// Generate meal suggestion (recipe and image) from AI
  Future<void> getMealSuggestion(String ingredients) async {
    if (ingredients.trim().isEmpty) {
      emit(state.copyWith(
        status: MealPlanStatus.error,
        errorMessage: 'Please enter some ingredients',
      ));
      return;
    }

    emit(state.copyWith(
      status: MealPlanStatus.generating,
      isGenerating: true,
      clearPreview: true,
      clearError: true,
    ));

    try {
      // MealService will handle generating the recipe AND the image.
      final mealSuggestion = await _mealService.generateMealFromAI(
        ingredients,
        mealType: state.selectedMealType ?? MealType.lunch,
      );

      // Emit the final state with the complete MealModel (including image bytes)
      emit(state.copyWith(
        status: MealPlanStatus.loaded,
        isGenerating: false,
        generatedPreview: mealSuggestion,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MealPlanStatus.error,
        isGenerating: false,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Add generated meal to today's plan
  void addGeneratedMealToToday() {
    final preview = state.generatedPreview;
    if (preview == null) return;

    // Add to meals list (replacing if same type exists)
    final updatedMeals = List<MealModel>.from(state.meals);
    final existingIndex = updatedMeals.indexWhere((m) => m.type == preview.type);

    if (existingIndex >= 0) {
      updatedMeals[existingIndex] = preview;
    } else {
      updatedMeals.add(preview);
    }

    // Sort meals by type order
    updatedMeals.sort((a, b) => a.type.index.compareTo(b.type.index));

    emit(state.copyWith(
      meals: updatedMeals,
      clearPreview: true,
    ));

    // Save to storage
    _mealService.saveMeal(preview);
  }

  /// Clear generated preview
  void clearPreview() {
    emit(state.copyWith(clearPreview: true));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  @override
  Future<void> close() {
    _mealService.dispose();
    return super.close();
  }
}
