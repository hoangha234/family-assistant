import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/hydration_service.dart';
import '../services/health_service.dart';
import 'hydration_state.dart';

class HydrationCubit extends Cubit<HydrationState> {
  final HydrationService _hydrationService;
  StreamSubscription? _logsSubscription;

  HydrationCubit({required HydrationService hydrationService})
      : _hydrationService = hydrationService,
        super(const HydrationState()) {
    _init();
  }

  void _init() {
    emit(state.copyWith(status: HydrationStatus.loading));
    _logsSubscription = _hydrationService.streamTodayLogs().listen(
      (logs) {
        final total = logs.fold(0, (sum, log) => sum + log.amount);
        emit(state.copyWith(
          status: HydrationStatus.loaded,
          todayLogs: logs,
          totalAmountToday: total,
        ));
        
        // Sync total water to the main dashboard
        try {
          HealthService().updateHealthData(waterLiters: total / 1000.0);
        } catch (e) {
          // Ignore error silently to not disrupt the hydration UI
        }
      },
      onError: (error) {
        emit(state.copyWith(
          status: HydrationStatus.error,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  Future<void> addWater(int amount, String session) async {
    try {
      await _hydrationService.addWaterLog(amount, session);
    } catch (e) {
      emit(state.copyWith(
        status: HydrationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadRecentLogs() async {
    try {
      final recentLogs = await _hydrationService.getRecentLogs();
      emit(state.copyWith(recentLogs: recentLogs));
    } catch (e) {
      emit(state.copyWith(
        status: HydrationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _logsSubscription?.cancel();
    return super.close();
  }
}
