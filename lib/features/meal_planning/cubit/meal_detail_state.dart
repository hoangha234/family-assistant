part of 'meal_detail_cubit.dart';

/// Model for ingredient with checked state
class IngredientItem extends Equatable {
  final String name;
  final String quantity;
  final bool isChecked;

  const IngredientItem({
    required this.name,
    this.quantity = '',
    this.isChecked = false,
  });

  IngredientItem copyWith({
    String? name,
    String? quantity,
    bool? isChecked,
  }) {
    return IngredientItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  /// Create from raw ingredient string (e.g., "Chicken - 400g")
  factory IngredientItem.fromString(String ingredient) {
    final parts = ingredient.split(' - ');
    return IngredientItem(
      name: parts.isNotEmpty ? parts[0].trim() : ingredient,
      quantity: parts.length > 1 ? parts[1].trim() : '',
      isChecked: false,
    );
  }

  @override
  List<Object?> get props => [name, quantity, isChecked];
}

class MealDetailState extends Equatable {
  final bool isIngredientsTab;
  final List<IngredientItem> ingredients;

  const MealDetailState({
    this.isIngredientsTab = true,
    this.ingredients = const [],
  });

  MealDetailState copyWith({
    bool? isIngredientsTab,
    List<IngredientItem>? ingredients,
  }) {
    return MealDetailState(
      isIngredientsTab: isIngredientsTab ?? this.isIngredientsTab,
      ingredients: ingredients ?? this.ingredients,
    );
  }

  @override
  List<Object> get props => [isIngredientsTab, ingredients];
}
