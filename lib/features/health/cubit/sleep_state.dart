import 'package:equatable/equatable.dart';
import '../models/sleep_data_model.dart';

enum SleepStatus { initial, loading, loaded, error }

class SleepState extends Equatable {
  final SleepStatus status;
  final SleepData? sleepData;
  final String? errorMessage;

  const SleepState({
    this.status = SleepStatus.initial,
    this.sleepData,
    this.errorMessage,
  });

  SleepState copyWith({
    SleepStatus? status,
    SleepData? sleepData,
    String? errorMessage,
  }) {
    return SleepState(
      status: status ?? this.status,
      sleepData: sleepData ?? this.sleepData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, sleepData, errorMessage];
}
