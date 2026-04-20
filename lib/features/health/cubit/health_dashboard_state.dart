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
  final int carbsGoal;
  final int fat;
  final int fatGoal;

  // Activity
  final int activityMinutes;
  final int activityGoal;

  // Food scan result
  final FoodAnalysis? lastScannedFood;

  // Weekly averages
  final double weeklyAvgSleepProgress;
  final double weeklyAvgWaterProgress;
  final double weeklyAvgCalorieProgress;
  final double weeklyAvgProteinProgress;
  final double weeklyAvgStepProgress;

  const HealthDashboardState({
    this.status = HealthDashboardStatus.initial,
    this.errorMessage,
    this.steps = 0,
    this.stepGoal = 10000,
    this.sleepHours = 6.75,
    this.sleepGoal = 8.0,
    this.waterLiters = 1.5,
    this.waterGoal = 2.0,
    this.dailyCalories = 0,
    this.caloriesGoal = 2000,
    this.protein = 0,
    this.proteinGoal = 120,
    this.carbs = 0,
    this.carbsGoal = 250,
    this.fat = 0,
    this.fatGoal = 60,
    this.activityMinutes = 45,
    this.activityGoal = 60,
    this.lastScannedFood,
    this.weeklyAvgSleepProgress = 0.0,
    this.weeklyAvgWaterProgress = 0.0,
    this.weeklyAvgCalorieProgress = 0.0,
    this.weeklyAvgProteinProgress = 0.0,
    this.weeklyAvgStepProgress = 0.0,
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
    int? carbsGoal,
    int? fat,
    int? fatGoal,
    int? activityMinutes,
    int? activityGoal,
    FoodAnalysis? lastScannedFood,
    double? weeklyAvgSleepProgress,
    double? weeklyAvgWaterProgress,
    double? weeklyAvgCalorieProgress,
    double? weeklyAvgProteinProgress,
    double? weeklyAvgStepProgress,
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
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fat: fat ?? this.fat,
      fatGoal: fatGoal ?? this.fatGoal,
      activityMinutes: activityMinutes ?? this.activityMinutes,
      activityGoal: activityGoal ?? this.activityGoal,
      lastScannedFood: lastScannedFood ?? this.lastScannedFood,
      weeklyAvgSleepProgress: weeklyAvgSleepProgress ?? this.weeklyAvgSleepProgress,
      weeklyAvgWaterProgress: weeklyAvgWaterProgress ?? this.weeklyAvgWaterProgress,
      weeklyAvgCalorieProgress: weeklyAvgCalorieProgress ?? this.weeklyAvgCalorieProgress,
      weeklyAvgProteinProgress: weeklyAvgProteinProgress ?? this.weeklyAvgProteinProgress,
      weeklyAvgStepProgress: weeklyAvgStepProgress ?? this.weeklyAvgStepProgress,
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

  /// Calculate carbs progress (0.0 to 1.0)
  double get carbsProgress => (carbs / carbsGoal).clamp(0.0, 1.0);

  /// Calculate fat progress (0.0 to 1.0)
  double get fatProgress => (fat / fatGoal).clamp(0.0, 1.0);

  /// Calculate activity progress (0.0 to 1.0)
  double get activityProgress => (activityMinutes / activityGoal).clamp(0.0, 1.0);

  /// Calculate daily health score (0-100)
  double get healthScore {
    double dietScore = (calorieProgress * 15) +
        (proteinProgress * 10) +
        (carbsGoal > 0 ? (carbs / carbsGoal).clamp(0.0, 1.0) * 7.5 : 0.0) +
        (fatGoal > 0 ? (fat / fatGoal).clamp(0.0, 1.0) * 7.5 : 0.0);
    
    double activityScore = stepProgress * 30;
    double restScore = (sleepProgress * 15) + (waterProgress * 15);
    
    return (dietScore + activityScore + restScore).clamp(0.0, 100.0);
  }

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
        carbsGoal,
        fat,
        fatGoal,
        activityMinutes,
        activityGoal,
        lastScannedFood,
        weeklyAvgSleepProgress,
        weeklyAvgWaterProgress,
        weeklyAvgCalorieProgress,
        weeklyAvgProteinProgress,
        weeklyAvgStepProgress,
      ];
}

