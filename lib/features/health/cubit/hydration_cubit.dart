import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/hydration_service.dart';
import '../services/health_service.dart';
import 'hydration_state.dart';

class HydrationCubit extends Cubit<HydrationState> {
  final HydrationService _hydrationService;
  StreamSubscription? _planSubscription;

  HydrationCubit({required HydrationService hydrationService})
      : _hydrationService = hydrationService,
        super(const HydrationState()) {
    _init();
  }

  void _init() async {
    emit(state.copyWith(status: HydrationStatus.loading));
    try {
      // Ensure today's plan exists or create it
      await _hydrationService.getOrCreateTodayPlan();

      _planSubscription = _hydrationService.streamTodayPlan().listen(
        (plan) {
          emit(state.copyWith(
            status: HydrationStatus.loaded,
            todayPlan: plan,
          ));

          if (plan != null) {
            // Check midnight reset
            if (plan.date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))) {
              // Should not happen due to getOrCreateTodayPlan logic, but just in case
            }
            // Sync total water to the main dashboard
            try {
              final total = plan.currentLevel * state.waterPerCup;
              HealthService().updateHealthData(waterLiters: total / 1000.0);
            } catch (e) {
              // Ignore error silently to not disrupt the hydration UI
            }
          }
        },
        onError: (error) {
          emit(state.copyWith(
            status: HydrationStatus.error,
            errorMessage: error.toString(),
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(status: HydrationStatus.error, errorMessage: e.toString()));
    }
  }

  bool get canConfirmDrink {
    if (state.status != HydrationStatus.loaded) return false;
    final plan = state.todayPlan;
    if (plan == null || plan.currentLevel >= 5) return false;
    
    final nextSession = plan.sessions[plan.currentLevel];
    return DateTime.now().isAfter(nextSession) || DateTime.now().isAtSameMomentAs(nextSession);
  }

  Future<void> confirmDrink() async {
    if (!canConfirmDrink) return;

    final plan = state.todayPlan!;

    try {
      await _hydrationService.updateCurrentLevel(plan.id, plan.currentLevel + 1);
    } catch (e) {
      emit(state.copyWith(
        status: HydrationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> updateStartTime(DateTime newTime) async {
    final plan = state.todayPlan;
    if (plan == null) return;

    try {
      await _hydrationService.updateStartTime(plan.id, newTime);
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
    _planSubscription?.cancel();
    return super.close();
  }
}
