/// Model representing food analysis result from AI
class FoodAnalysis {
  final String foodName;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final DateTime analyzedAt;

  const FoodAnalysis({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.analyzedAt,
  });

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    return FoodAnalysis(
      foodName: json['food_name'] as String? ?? json['foodName'] as String? ?? 'Unknown Food',
      calories: _parseNumber(json['calories']),
      protein: _parseNumber(json['protein']),
      carbs: _parseNumber(json['carbs']),
      fat: _parseNumber(json['fat']),
      analyzedAt: json['analyzedAt'] != null
          ? DateTime.tryParse(json['analyzedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static int _parseNumber(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'FoodAnalysis(foodName: $foodName, calories: $calories, protein: ${protein}g, carbs: ${carbs}g, fat: ${fat}g)';
  }
}

