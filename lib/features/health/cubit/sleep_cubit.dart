import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'sleep_state.dart';
import '../services/sleep_service.dart';

class SleepCubit extends Cubit<SleepState> {
  final SleepService _sleepService;
  StreamSubscription? _sleepDataSubscription;
  final DateTime _currentDate = DateTime.now();

  SleepCubit({SleepService? sleepService})
      : _sleepService = sleepService ?? SleepService(),
        super(const SleepState()) {
    _init();
  }

  void _init() {
    emit(state.copyWith(status: SleepStatus.loading));
    _subscribeToSleepData();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history30 = await _sleepService.loadSleepHistory(days: 30);
      
      // Get the last 7 days history (already sorted descending)
      // Reverse to show chronologically from left to right on UI
      final history7 = history30.take(7).toList().reversed.toList();
      
      if (!isClosed) {
        emit(state.copyWith(
          history30Days: history30,
          history7Days: history7,
        ));
      }
    } catch (e) {
      debugPrint('[SleepCubit] Error loading history: $e');
    }
  }

  void _subscribeToSleepData() {
    _sleepDataSubscription?.cancel();
    _sleepDataSubscription = _sleepService.streamSleepData(_currentDate).listen(
      (data) {
        if (!isClosed) {
          emit(state.copyWith(
            status: SleepStatus.loaded,
            sleepData: data,
          ));
        }
      },
      onError: (e) {
        if (!isClosed) {
          emit(state.copyWith(
            status: SleepStatus.error,
            errorMessage: e.toString(),
          ));
        }
      },
    );
  }

  Future<void> saveSchedule(TimeOfDay bedtime, TimeOfDay wakeup) async {
    try {
      final now = DateTime.now();
      
      // Calculate datetime for bedtime
      DateTime calculatedBedtime = DateTime(now.year, now.month, now.day, bedtime.hour, bedtime.minute);
      
      // Calculate datetime for wakeup
      DateTime calculatedWakeup = DateTime(now.year, now.month, now.day, wakeup.hour, wakeup.minute);
      
      // If wakeup is before bedtime, add 1 day to wakeup.
      if (calculatedWakeup.isBefore(calculatedBedtime)) {
        calculatedWakeup = calculatedWakeup.add(const Duration(days: 1));
      }

      await _sleepService.saveSleepSchedule(calculatedBedtime, calculatedWakeup, _currentDate);
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(status: SleepStatus.error, errorMessage: e.toString()));
      }
    }
  }

  Future<void> confirmSleep(String qualityTag) async {
    try {
      final currentData = state.sleepData;
      if (currentData != null) {
        await _sleepService.confirmSleep(currentData.id, qualityTag);
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(status: SleepStatus.error, errorMessage: e.toString()));
      }
    }
  }

  /// Check if dialog needs to be shown for confirmation
  bool shouldShowConfirmationDialog() {
    final data = state.sleepData;
    if (data == null) return false;
    
    if (data.isConfirmed) return false;
    
    final now = DateTime.now();
    return now.isAfter(data.wakeup);
  }

  Future<void> deleteTodayData() async {
    try {
      await _sleepService.deleteTodayData();
      await _loadHistory();
    } catch (e) {
      debugPrint('[SleepCubit] Error deleting today data: $e');
    }
  }

  @override
  Future<void> close() {
    _sleepDataSubscription?.cancel();
    return super.close();
  }
}
