import 'package:equatable/equatable.dart';
import '../models/sleep_data_model.dart';

enum SleepStatus { initial, loading, loaded, error }

class SleepState extends Equatable {
  final SleepStatus status;
  final SleepData? sleepData;
  final String? errorMessage;
  final List<SleepData> history30Days;
  final List<SleepData> history7Days;

  const SleepState({
    this.status = SleepStatus.initial,
    this.sleepData,
    this.errorMessage,
    this.history30Days = const [],
    this.history7Days = const [],
  });

  SleepState copyWith({
    SleepStatus? status,
    SleepData? sleepData,
    String? errorMessage,
    List<SleepData>? history30Days,
    List<SleepData>? history7Days,
  }) {
    return SleepState(
      status: status ?? this.status,
      sleepData: sleepData ?? this.sleepData,
      errorMessage: errorMessage ?? this.errorMessage,
      history30Days: history30Days ?? this.history30Days,
      history7Days: history7Days ?? this.history7Days,
    );
  }

  @override
  List<Object?> get props => [status, sleepData, errorMessage, history30Days, history7Days];

  // Calculated Mock Percentages
  int get deepSleepPercent => 20;
  int get remSleepPercent => 25;
  int get lightSleepPercent => 50;
  int get awakePercent => 5;
  
  String get deepSleepFormatted => _formatPercentOfDuration(deepSleepPercent / 100);
  String get remSleepFormatted => _formatPercentOfDuration(remSleepPercent / 100);
  String get lightSleepFormatted => _formatPercentOfDuration(lightSleepPercent / 100);
  String get awakeFormatted => _formatPercentOfDuration(awakePercent / 100);

  String _formatPercentOfDuration(double percent) {
    if (sleepData == null) return '--';
    final duration = sleepData!.wakeup.difference(sleepData!.bedtime);
    final ms = (duration.inMilliseconds * percent).round();
    final h = ms ~/ 3600000;
    final m = (ms % 3600000) ~/ 60000;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m';
  }
}
