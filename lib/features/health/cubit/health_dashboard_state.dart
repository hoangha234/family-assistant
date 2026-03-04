part of 'health_dashboard_cubit.dart';

/// Status enum for tracking async operations
enum HealthDashboardStatus {
  initial,
  loading,
  loaded,
  scanning,
  scanSuccess,
  scanError,
  error,
}

/// State for the Health Dashboard
class HealthDashboardState extends Equatable {
  // Status
  final HealthDashboardStatus status;
  final String? errorMessage;

  // Steps tracking
  final int steps;
  final int stepGoal;

  // Sleep & Water
  final double sleepHours;
  final double sleepGoal;
  final double waterLiters;
  final double waterGoal;

  // Nutrition
  final int dailyCalories;
  final int caloriesGoal;
  final int protein;
  final int proteinGoal;
  final int carbs;
  final int fat;

  // Activity
  final int activityMinutes;
  final int activityGoal;

  // Food scan result
  final FoodAnalysis? lastScannedFood;

  const HealthDashboardState({
    this.status = HealthDashboardStatus.initial,
    this.errorMessage,
    this.steps = 0,
    this.stepGoal = 10000,
    this.sleepHours = 6.75,
    this.sleepGoal = 8.0,
    this.waterLiters = 1.5,
    this.waterGoal = 2.5,
    this.dailyCalories = 0,
    this.caloriesGoal = 2200,
    this.protein = 0,
    this.proteinGoal = 120,
    this.carbs = 0,
    this.fat = 0,
    this.activityMinutes = 45,
    this.activityGoal = 60,
    this.lastScannedFood,
  });

  /// Copy with updated values
  HealthDashboardState copyWith({
    HealthDashboardStatus? status,
    String? errorMessage,
    int? steps,
    int? stepGoal,
    double? sleepHours,
    double? sleepGoal,
    double? waterLiters,
    double? waterGoal,
    int? dailyCalories,
    int? caloriesGoal,
    int? protein,
    int? proteinGoal,
    int? carbs,
    int? fat,
    int? activityMinutes,
    int? activityGoal,
    FoodAnalysis? lastScannedFood,
  }) {
    return HealthDashboardState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      steps: steps ?? this.steps,
      stepGoal: stepGoal ?? this.stepGoal,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepGoal: sleepGoal ?? this.sleepGoal,
      waterLiters: waterLiters ?? this.waterLiters,
      waterGoal: waterGoal ?? this.waterGoal,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      protein: protein ?? this.protein,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      activityMinutes: activityMinutes ?? this.activityMinutes,
      activityGoal: activityGoal ?? this.activityGoal,
      lastScannedFood: lastScannedFood ?? this.lastScannedFood,
    );
  }

  // ==================== Progress calculations ====================

  /// Calculate step progress (0.0 to 1.0)
  double get stepProgress => (steps / stepGoal).clamp(0.0, 1.0);

  /// Calculate step percentage
  int get stepPercentage => (stepProgress * 100).round();

  /// Calculate sleep progress (0.0 to 1.0)
  double get sleepProgress => (sleepHours / sleepGoal).clamp(0.0, 1.0);

  /// Calculate water progress (0.0 to 1.0)
  double get waterProgress => (waterLiters / waterGoal).clamp(0.0, 1.0);

  /// Calculate calorie progress (0.0 to 1.0)
  double get calorieProgress => (dailyCalories / caloriesGoal).clamp(0.0, 1.0);

  /// Calculate protein progress (0.0 to 1.0)
  double get proteinProgress => (protein / proteinGoal).clamp(0.0, 1.0);

  /// Calculate activity progress (0.0 to 1.0)
  double get activityProgress => (activityMinutes / activityGoal).clamp(0.0, 1.0);

  // ==================== Formatted values ====================

  /// Format sleep hours for display
  String get sleepFormatted {
    final hours = sleepHours.floor();
    final minutes = ((sleepHours - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }

  /// Format water for display
  String get waterFormatted => '${waterLiters.toStringAsFixed(1)} L';

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        steps,
        stepGoal,
        sleepHours,
        sleepGoal,
        waterLiters,
        waterGoal,
        dailyCalories,
        caloriesGoal,
        protein,
        proteinGoal,
        carbs,
        fat,
        activityMinutes,
        activityGoal,
        lastScannedFood,
      ];
}

