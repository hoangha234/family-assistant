import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../models/meal_model.dart';
import '../services/meal_service.dart';

part 'meal_plan_state.dart';

class MealPlanCubit extends Cubit<MealPlanState> {
  final MealService _mealService;

  MealPlanCubit({MealService? mealService})
      : _mealService = mealService ?? MealService(),
        super(MealPlanState());

  /// Initialize and load meals for today
  Future<void> loadMeals() async {
    emit(state.copyWith(status: MealPlanStatus.loading));

    try {
      final meals = await _mealService.getMealsForDate(state.selectedDate);
      emit(state.copyWith(
        status: MealPlanStatus.loaded,
        meals: meals,
      ));
    } catch (e) {
      debugPrint('[MealPlanCubit] Error loading meals: $e');
      emit(state.copyWith(
        status: MealPlanStatus.loaded,
        meals: [],
        errorMessage: 'Failed to load meals',
      ));
    }
  }

  /// Set selected date and fetch meals for that date
  Future<void> selectDate(DateTime date) async {
    if (state.isSelected(date)) return;

    emit(state.copyWith(
      selectedDate: date,
      status: MealPlanStatus.loading,
    ));

    try {
      final meals = await _mealService.getMealsForDate(date);
      emit(state.copyWith(
        status: MealPlanStatus.loaded,
        meals: meals,
      ));
    } catch (e) {
      debugPrint('[MealPlanCubit] Error fetching meals for date: $e');
      emit(state.copyWith(
        status: MealPlanStatus.loaded,
        meals: [],
      ));
    }
  }

  /// Change current month (for calendar navigation)
  void changeMonth(DateTime month) {
    emit(state.copyWith(
      currentMonth: DateTime(month.year, month.month),
    ));
  }

  /// Go to previous month
  void previousMonth() {
    final prevMonth = DateTime(state.currentMonth.year, state.currentMonth.month - 1);
    changeMonth(prevMonth);
  }

  /// Go to next month
  void nextMonth() {
    final nextMonth = DateTime(state.currentMonth.year, state.currentMonth.month + 1);
    changeMonth(nextMonth);
  }

  /// Go to today
  Future<void> goToToday() async {
    final now = DateTime.now();
    emit(state.copyWith(
      currentMonth: DateTime(now.year, now.month),
    ));
    await selectDate(now);
  }

  /// Legacy method - kept for compatibility
  void setDay(int index) {
    // Calculate date from index
    final firstDayOfMonth = DateTime(state.currentMonth.year, state.currentMonth.month, 1);
    final date = firstDayOfMonth.add(Duration(days: index));
    selectDate(date);
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

  /// Add generated meal to selected date's plan and save to Firestore
  Future<void> addGeneratedMealToToday() async {
    final preview = state.generatedPreview;
    if (preview == null) return;

    emit(state.copyWith(isSaving: true));

    try {
      // Update meal with selected date
      final mealToSave = preview.copyWith(date: state.selectedDate);

      // Save to Firestore
      await _mealService.saveMealToDate(mealToSave, state.selectedDate);

      // Add to meals list (replacing if same type exists)
      final updatedMeals = List<MealModel>.from(state.meals);
      final existingIndex = updatedMeals.indexWhere((m) => m.type == preview.type);

      if (existingIndex >= 0) {
        updatedMeals[existingIndex] = mealToSave;
      } else {
        updatedMeals.add(mealToSave);
      }

      // Sort meals by type order
      updatedMeals.sort((a, b) => a.type.index.compareTo(b.type.index));

      emit(state.copyWith(
        meals: updatedMeals,
        isSaving: false,
        clearPreview: true,
      ));
    } catch (e) {
      debugPrint('[MealPlanCubit] Error saving meal: $e');
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save meal',
      ));
    }
  }

  /// Delete a meal from selected date
  Future<void> deleteMeal(MealType mealType) async {
    try {
      await _mealService.deleteMealFromDate(mealType, state.selectedDate);

      final updatedMeals = state.meals.where((m) => m.type != mealType).toList();
      emit(state.copyWith(meals: updatedMeals));
    } catch (e) {
      debugPrint('[MealPlanCubit] Error deleting meal: $e');
      emit(state.copyWith(errorMessage: 'Failed to delete meal'));
    }
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
