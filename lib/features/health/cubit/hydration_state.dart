import 'package:equatable/equatable.dart';
import '../models/hydration_log_model.dart';

enum HydrationStatus { initial, loading, loaded, error }

class HydrationState extends Equatable {
  final HydrationStatus status;
  final List<HydrationLog> todayLogs;
  final int totalAmountToday;
  final int dailyGoal; // e.g., 2500 ml
  final String? errorMessage;
  final List<HydrationLog> recentLogs; // For "View All" 7 days history

  const HydrationState({
    this.status = HydrationStatus.initial,
    this.todayLogs = const [],
    this.totalAmountToday = 0,
    this.dailyGoal = 2500,
    this.errorMessage,
    this.recentLogs = const [],
  });

  HydrationState copyWith({
    HydrationStatus? status,
    List<HydrationLog>? todayLogs,
    int? totalAmountToday,
    int? dailyGoal,
    String? errorMessage,
    List<HydrationLog>? recentLogs,
  }) {
    return HydrationState(
      status: status ?? this.status,
      todayLogs: todayLogs ?? this.todayLogs,
      totalAmountToday: totalAmountToday ?? this.totalAmountToday,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      errorMessage: errorMessage ?? this.errorMessage,
      recentLogs: recentLogs ?? this.recentLogs,
    );
  }

  double get progress => (totalAmountToday / dailyGoal).clamp(0.0, 1.0);

  int getAmountForSession(String session) {
    return todayLogs
        .where((log) => log.session == session)
        .fold(0, (sum, log) => sum + log.amount);
  }

  @override
  List<Object?> get props => [
        status,
        todayLogs,
        totalAmountToday,
        dailyGoal,
        errorMessage,
        recentLogs,
      ];
}
