import 'package:equatable/equatable.dart';
import '../models/hydration_log_model.dart';

enum HydrationStatus { initial, loading, loaded, error }

class HydrationState extends Equatable {
  final HydrationStatus status;
  final HydrationLog? todayPlan;
  final List<HydrationLog> recentLogs;
  final String? errorMessage;
  final int waterPerCup;

  const HydrationState({
    this.status = HydrationStatus.initial,
    this.todayPlan,
    this.recentLogs = const [],
    this.errorMessage,
    this.waterPerCup = 400,
  });

  HydrationState copyWith({
    HydrationStatus? status,
    HydrationLog? todayPlan,
    List<HydrationLog>? recentLogs,
    String? errorMessage,
    int? waterPerCup,
  }) {
    return HydrationState(
      status: status ?? this.status,
      todayPlan: todayPlan ?? this.todayPlan,
      recentLogs: recentLogs ?? this.recentLogs,
      errorMessage: errorMessage ?? this.errorMessage,
      waterPerCup: waterPerCup ?? this.waterPerCup,
    );
  }

  int get totalAmountToday => (todayPlan?.currentLevel ?? 0) * waterPerCup;
  int get dailyGoal => 5 * waterPerCup; // 5 cups * 400ml = 2000ml (2L)
  double get progress => (totalAmountToday / dailyGoal).clamp(0.0, 1.0);
  int get currentLevel => todayPlan?.currentLevel ?? 0;

  @override
  List<Object?> get props => [
        status,
        todayPlan,
        recentLogs,
        errorMessage,
        waterPerCup,
      ];
}
