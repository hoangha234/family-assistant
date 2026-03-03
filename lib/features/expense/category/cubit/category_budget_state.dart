import 'package:equatable/equatable.dart';
import '../models/category_budget_model.dart';

/// State for Category Budget management
abstract class CategoryBudgetState extends Equatable {
  const CategoryBudgetState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CategoryBudgetInitial extends CategoryBudgetState {}

/// Loading state
class CategoryBudgetLoading extends CategoryBudgetState {}

/// Loaded state with all budget data
class CategoryBudgetLoaded extends CategoryBudgetState {
  final List<CategoryBudget> categories;
  final double totalAllocatedBudget;
  final double totalBalance;
  final double totalSpentAllCategories;
  final String? validationError;

  const CategoryBudgetLoaded({
    required this.categories,
    required this.totalAllocatedBudget,
    required this.totalBalance,
    required this.totalSpentAllCategories,
    this.validationError,
  });

  /// Remaining budget that can be allocated
  double get remainingBudgetToAllocate => totalBalance - totalAllocatedBudget;

  /// Check if budget is fully allocated
  bool get isBudgetFullyAllocated => totalAllocatedBudget >= totalBalance;

  /// Overall spending percentage
  double get overallSpendingPercentage {
    if (totalAllocatedBudget <= 0) return 0.0;
    return totalSpentAllCategories / totalAllocatedBudget;
  }

  /// Copy with method for easy state updates
  CategoryBudgetLoaded copyWith({
    List<CategoryBudget>? categories,
    double? totalAllocatedBudget,
    double? totalBalance,
    double? totalSpentAllCategories,
    String? validationError,
    bool clearValidationError = false,
  }) {
    return CategoryBudgetLoaded(
      categories: categories ?? this.categories,
      totalAllocatedBudget: totalAllocatedBudget ?? this.totalAllocatedBudget,
      totalBalance: totalBalance ?? this.totalBalance,
      totalSpentAllCategories: totalSpentAllCategories ?? this.totalSpentAllCategories,
      validationError: clearValidationError ? null : (validationError ?? this.validationError),
    );
  }

  @override
  List<Object?> get props => [
        categories,
        totalAllocatedBudget,
        totalBalance,
        totalSpentAllCategories,
        validationError,
      ];
}

/// Error state
class CategoryBudgetError extends CategoryBudgetState {
  final String message;

  const CategoryBudgetError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when budget is being updated
class CategoryBudgetUpdating extends CategoryBudgetState {
  final List<CategoryBudget> categories;
  final String updatingCategoryId;

  const CategoryBudgetUpdating({
    required this.categories,
    required this.updatingCategoryId,
  });

  @override
  List<Object?> get props => [categories, updatingCategoryId];
}

/// State after successful budget update
class CategoryBudgetUpdateSuccess extends CategoryBudgetState {
  final List<CategoryBudget> categories;
  final String message;

  const CategoryBudgetUpdateSuccess({
    required this.categories,
    required this.message,
  });

  @override
  List<Object?> get props => [categories, message];
}

/// Validation error state
class CategoryBudgetValidationError extends CategoryBudgetState {
  final List<CategoryBudget> categories;
  final String errorMessage;
  final double attemptedTotal;
  final double availableBalance;

  const CategoryBudgetValidationError({
    required this.categories,
    required this.errorMessage,
    required this.attemptedTotal,
    required this.availableBalance,
  });

  @override
  List<Object?> get props => [categories, errorMessage, attemptedTotal, availableBalance];
}

