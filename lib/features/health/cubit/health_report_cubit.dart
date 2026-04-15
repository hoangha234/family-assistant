import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../models/health_data_model.dart';
import '../services/health_service.dart';

part 'health_report_state.dart';

class HealthReportCubit extends Cubit<HealthReportState> {
  final HealthService _healthService;

  HealthReportCubit({HealthService? healthService}) 
      : _healthService = healthService ?? HealthService.instance(),
        super(const HealthReportState()) {
    _init();
  }

  Future<void> _init() async {
    emit(state.copyWith(isLoading: true));
    try {
      final endDate = DateTime.now();
      final weeklyData = await _healthService.loadWeeklyHealthData(endDate);
      
      emit(state.copyWith(
        isLoading: false,
        weeklyData: weeklyData,
        selectedDayIndex: weeklyData.length - 1 < 0 ? 0 : weeklyData.length - 1,
      ));
    } catch (e) {
      debugPrint('[HealthReportCubit] Error loading weekly data: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  void selectDay(int index) {
    if (index >= 0 && index < state.weeklyData.length) {
      emit(state.copyWith(selectedDayIndex: index));
    }
  }

  void setTimeframe(String timeframe) {
    emit(state.copyWith(selectedTimeframe: timeframe));
  }

  Future<void> refresh() async {
    await _init();
  }
}
