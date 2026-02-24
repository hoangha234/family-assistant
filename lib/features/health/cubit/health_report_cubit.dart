import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'health_report_state.dart';

class HealthReportCubit extends Cubit<HealthReportState> {
  HealthReportCubit() : super(const HealthReportState());

  void setTimeframe(String timeframe) {
    emit(state.copyWith(selectedTimeframe: timeframe));
  }
}
