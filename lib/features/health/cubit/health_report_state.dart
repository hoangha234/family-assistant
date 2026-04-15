
part of 'health_report_cubit.dart';

class HealthReportState extends Equatable {
  final String selectedTimeframe;
  final bool isLoading;
  final List<HealthData> weeklyData;
  final int selectedDayIndex;

  const HealthReportState({
    this.selectedTimeframe = 'Weekly',
    this.isLoading = false,
    this.weeklyData = const [],
    this.selectedDayIndex = 6,
  });

  HealthReportState copyWith({
    String? selectedTimeframe,
    bool? isLoading,
    List<HealthData>? weeklyData,
    int? selectedDayIndex,
  }) {
    return HealthReportState(
      selectedTimeframe: selectedTimeframe ?? this.selectedTimeframe,
      isLoading: isLoading ?? this.isLoading,
      weeklyData: weeklyData ?? this.weeklyData,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
    );
  }

  // Health Score Calculation Helper (0-100)
  double _calculateScore(HealthData data) {
    double dietScore = (data.calorieProgress * 15) +
        (data.proteinProgress * 10) +
        ((data.carbs / 250).clamp(0.0, 1.0) * 7.5) +
        ((data.fat / 60).clamp(0.0, 1.0) * 7.5);
    
    double activityScore = data.stepProgress * 30;
    double restScore = (data.sleepProgress * 15) + (data.waterProgress * 15);
    
    return (dietScore + activityScore + restScore).clamp(0.0, 100.0);
  }

  List<double> get weeklyScores {
    if (weeklyData.isEmpty) return List.filled(7, 0.0);
    return weeklyData.map((d) => _calculateScore(d)).toList();
  }

  double get currentScore {
    if (weeklyData.isEmpty || selectedDayIndex < 0 || selectedDayIndex >= weeklyData.length) return 0.0;
    return _calculateScore(weeklyData[selectedDayIndex]);
  }

  String get scoreChangeText {
    if (weeklyData.isEmpty || selectedDayIndex <= 0 || selectedDayIndex >= weeklyData.length) return "0 pt";
    double prev = _calculateScore(weeklyData[selectedDayIndex - 1]);
    double curr = currentScore;
    
    int change = curr.round() - prev.round();
    String sign = change > 0 ? "+" : "";
    return "$sign$change pt${change.abs() == 1 ? '' : 's'}";
  }

  bool get isScoreChangePositive {
    if (weeklyData.isEmpty || selectedDayIndex <= 0 || selectedDayIndex >= weeklyData.length) return true;
    double prev = _calculateScore(weeklyData[selectedDayIndex - 1]);
    double curr = currentScore;
    return curr.round() >= prev.round();
  }

  List<HealthData> get _activeDays => weeklyData.where((d) => d.steps > 0 || d.sleepHours > 0 || d.waterLiters > 0 || d.calories > 0).toList();

  double get averageSleepHours {
    if (_activeDays.isEmpty) return 0.0;
    return _activeDays.map((d) => d.sleepHours).reduce((a, b) => a + b) / _activeDays.length;
  }

  double get averageSteps {
    if (_activeDays.isEmpty) return 0.0;
    return _activeDays.map((d) => d.steps.toDouble()).reduce((a, b) => a + b) / _activeDays.length;
  }

  double get averageWaterLiters {
    if (_activeDays.isEmpty) return 0.0;
    return _activeDays.map((d) => d.waterLiters).reduce((a, b) => a + b) / _activeDays.length;
  }

  double get averageCarbs {
    if (_activeDays.isEmpty) return 0.0;
    return _activeDays.map((d) => d.carbs.toDouble()).reduce((a, b) => a + b) / _activeDays.length;
  }

  double get averageProtein {
    if (_activeDays.isEmpty) return 0.0;
    return _activeDays.map((d) => d.protein.toDouble()).reduce((a, b) => a + b) / _activeDays.length;
  }

  double get averageFats {
    if (_activeDays.isEmpty) return 0.0;
    return _activeDays.map((d) => d.fat.toDouble()).reduce((a, b) => a + b) / _activeDays.length;
  }
  
  double get totalMacros {
    double total = averageCarbs + averageProtein + averageFats;
    return total > 0 ? total : 1.0;
  }

  double get carbsPercent => averageCarbs / totalMacros;
  double get proteinPercent => averageProtein / totalMacros;
  double get fatsPercent => averageFats / totalMacros;

  int get totalCaloriesBurned {
    if (weeklyData.isEmpty) return 0;
    int totalSteps = weeklyData.map((d) => d.steps).fold(0, (a, b) => a + b);
    return (totalSteps * 0.04).round(); 
  }

  @override
  List<Object> get props => [selectedTimeframe, isLoading, weeklyData, selectedDayIndex];
}
