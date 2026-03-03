import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/category_budget_model.dart';
import '../services/category_budget_service.dart';
import 'category_budget_state.dart';

/// Cubit for managing Category Budgets (Jar Budget System)
class CategoryBudgetCubit extends Cubit<CategoryBudgetState> {
  final CategoryBudgetService _service;
  StreamSubscription<List<CategoryBudget>>? _subscription;

  double _totalBalance = 0.0;

  CategoryBudgetCubit({
    CategoryBudgetService? service,
  })  : _service = service ?? CategoryBudgetService(),
        super(CategoryBudgetInitial());

  /// Initialize and load category budgets
  Future<void> initialize({double totalBalance = 0.0}) async {
    emit(CategoryBudgetLoading());
    _totalBalance = totalBalance;

    try {
      // Initialize default categories if needed
      await _service.initializeDefaultCategories();

      // Start listening to budget stream
      _subscription = _service.streamCategoryBudgets().listen(
        (categories) => _onCategoriesUpdated(categories),
        onError: (error) => emit(CategoryBudgetError(error.toString())),
      );

      // Sync with current expenses
      await recalculateAllCategories();
    } catch (e) {
      emit(CategoryBudgetError('Failed to initialize: $e'));
    }
  }

  /// Update total balance (called from ExpenseCubit)
  void updateTotalBalance(double newBalance) {
    _totalBalance = newBalance;

    if (state is CategoryBudgetLoaded) {
      final currentState = state as CategoryBudgetLoaded;
      emit(currentState.copyWith(
        totalBalance: newBalance,
        clearValidationError: true,
      ));
    }
  }

  /// Handle category budget stream updates
  void _onCategoriesUpdated(List<CategoryBudget> categories) {
    print('[CategoryBudgetCubit] Stream received ${categories.length} categories');
    for (var c in categories) {
      print('  - ${c.name}: budget=${c.monthlyBudget}, spent=${c.totalSpent}');
    }

    final totalAllocated = categories.fold(0.0, (sum, c) => sum + c.monthlyBudget);
    final totalSpent = categories.fold(0.0, (sum, c) => sum + c.totalSpent);

    emit(CategoryBudgetLoaded(
      categories: categories,
      totalAllocatedBudget: totalAllocated,
      totalBalance: _totalBalance,
      totalSpentAllCategories: totalSpent,
    ));
  }

  /// Update budget for a specific category
  Future<void> updateCategoryBudget(String categoryId, double newBudget) async {
    if (state is! CategoryBudgetLoaded &&
        state is! CategoryBudgetUpdateSuccess &&
        state is! CategoryBudgetUpdating) {
      print('[CategoryBudgetCubit] Cannot update: state is ${state.runtimeType}');
      return;
    }

    // Get current categories from any valid state
    List<CategoryBudget> currentCategories = [];
    double currentTotalAllocated = 0.0;

    if (state is CategoryBudgetLoaded) {
      final s = state as CategoryBudgetLoaded;
      currentCategories = s.categories;
      currentTotalAllocated = s.totalAllocatedBudget;
    } else if (state is CategoryBudgetUpdateSuccess) {
      final s = state as CategoryBudgetUpdateSuccess;
      currentCategories = s.categories;
      currentTotalAllocated = s.categories.fold(0.0, (sum, c) => sum + c.monthlyBudget);
    } else if (state is CategoryBudgetUpdating) {
      final s = state as CategoryBudgetUpdating;
      currentCategories = s.categories;
      currentTotalAllocated = s.categories.fold(0.0, (sum, c) => sum + c.monthlyBudget);
    }

    // Validation: newBudget must be >= 0
    if (newBudget < 0) {
      emit(CategoryBudgetValidationError(
        categories: currentCategories,
        errorMessage: 'Budget cannot be negative.',
        attemptedTotal: 0,
        availableBalance: _totalBalance,
      ));
      return;
    }

    // Calculate new total budget
    CategoryBudget? currentCategory;
    try {
      currentCategory = currentCategories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      print('[CategoryBudgetCubit] Category not found: $categoryId');
      emit(CategoryBudgetError('Category not found'));
      return;
    }

    final otherCategoriesTotal = currentTotalAllocated - currentCategory.monthlyBudget;
    final newTotalBudget = otherCategoriesTotal + newBudget;

    // Validation: total budget must not exceed total balance (only if balance > 0)
    if (_totalBalance > 0 && newTotalBudget > _totalBalance) {
      emit(CategoryBudgetValidationError(
        categories: currentCategories,
        errorMessage: 'Total allocated budget (\$${newTotalBudget.toStringAsFixed(0)}) exceeds available balance (\$${_totalBalance.toStringAsFixed(0)}).',
        attemptedTotal: newTotalBudget,
        availableBalance: _totalBalance,
      ));

      // Re-emit loaded state after delay to restore UI
      await Future.delayed(const Duration(seconds: 3));
      emit(CategoryBudgetLoaded(
        categories: currentCategories,
        totalAllocatedBudget: currentTotalAllocated,
        totalBalance: _totalBalance,
        totalSpentAllCategories: currentCategories.fold(0.0, (sum, c) => sum + c.totalSpent),
      ));
      return;
    }

    // Show updating state
    emit(CategoryBudgetUpdating(
      categories: currentCategories,
      updatingCategoryId: categoryId,
    ));

    try {
      print('[CategoryBudgetCubit] Updating category $categoryId with budget $newBudget');
      await _service.updateCategoryBudget(categoryId, newBudget);
      print('[CategoryBudgetCubit] Update successful!');

      // Update local state immediately instead of waiting for stream
      final updatedCategories = currentCategories.map((c) {
        if (c.id == categoryId) {
          return c.copyWith(monthlyBudget: newBudget);
        }
        return c;
      }).toList();

      final newTotalAllocated = updatedCategories.fold(0.0, (sum, c) => sum + c.monthlyBudget);
      final totalSpent = updatedCategories.fold(0.0, (sum, c) => sum + c.totalSpent);

      emit(CategoryBudgetLoaded(
        categories: updatedCategories,
        totalAllocatedBudget: newTotalAllocated,
        totalBalance: _totalBalance,
        totalSpentAllCategories: totalSpent,
      ));

      print('[CategoryBudgetCubit] State updated with new budget');
    } catch (e) {
      print('[CategoryBudgetCubit] Update failed: $e');
      emit(CategoryBudgetError('Failed to update budget: $e'));
    }
  }

  /// Recalculate all category totals from expenses
  Future<void> recalculateAllCategories() async {
    try {
      await _service.syncCategoryBudgetsWithExpenses();
      // Stream listener will emit new state
    } catch (e) {
      if (state is CategoryBudgetLoaded) {
        final currentState = state as CategoryBudgetLoaded;
        emit(currentState.copyWith(
          validationError: 'Failed to recalculate: $e',
        ));
      }
    }
  }

  /// Called when a new expense is added
  Future<void> onExpenseAdded(String category, double amount) async {
    await recalculateAllCategories();
  }

  /// Called when an expense is edited
  Future<void> onExpenseEdited() async {
    await recalculateAllCategories();
  }

  /// Called when an expense is deleted
  Future<void> onExpenseDeleted() async {
    await recalculateAllCategories();
  }

  /// Add a new category with budget
  Future<void> addCategory(String name, double budget) async {
    if (state is! CategoryBudgetLoaded) return;

    final currentState = state as CategoryBudgetLoaded;

    // Validation
    final newTotalBudget = currentState.totalAllocatedBudget + budget;
    if (newTotalBudget > _totalBalance && _totalBalance > 0) {
      emit(CategoryBudgetValidationError(
        categories: currentState.categories,
        errorMessage: 'Adding this category would exceed available balance.',
        attemptedTotal: newTotalBudget,
        availableBalance: _totalBalance,
      ));
      return;
    }

    try {
      final newBudget = CategoryBudget(
        id: '',
        name: name,
        monthlyBudget: budget,
        totalSpent: 0.0,
      );
      await _service.createCategoryBudget(newBudget);
    } catch (e) {
      emit(CategoryBudgetError('Failed to add category: $e'));
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _service.deleteCategoryBudget(categoryId);
    } catch (e) {
      emit(CategoryBudgetError('Failed to delete category: $e'));
    }
  }

  /// Clear validation error
  void clearValidationError() {
    if (state is CategoryBudgetLoaded) {
      final currentState = state as CategoryBudgetLoaded;
      emit(currentState.copyWith(clearValidationError: true));
    } else if (state is CategoryBudgetValidationError) {
      final errorState = state as CategoryBudgetValidationError;
      emit(CategoryBudgetLoaded(
        categories: errorState.categories,
        totalAllocatedBudget: errorState.categories.fold(0.0, (sum, c) => sum + c.monthlyBudget),
        totalBalance: _totalBalance,
        totalSpentAllCategories: errorState.categories.fold(0.0, (sum, c) => sum + c.totalSpent),
      ));
    }
  }

  /// Get category by name
  CategoryBudget? getCategoryByName(String name) {
    if (state is CategoryBudgetLoaded) {
      final categories = (state as CategoryBudgetLoaded).categories;
      try {
        return categories.firstWhere((c) => c.name == name);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

