part of 'health_report_cubit.dart';

class HealthReportState extends Equatable {
  final String selectedTimeframe;

  const HealthReportState({
    this.selectedTimeframe = 'Weekly',
  });

  HealthReportState copyWith({
    String? selectedTimeframe,
  }) {
    return HealthReportState(
      selectedTimeframe: selectedTimeframe ?? this.selectedTimeframe,
    );
  }

  @override
  List<Object> get props => [selectedTimeframe];
}
