import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/health_service.dart';
import '../models/food_analysis_model.dart';

part 'health_dashboard_state.dart';

/// Cubit for managing Health Dashboard state
///
/// Responsibilities:
/// - Step tracking via pedometer
/// - Food scanning via camera + AI
/// - Syncing data with Firestore
class HealthDashboardCubit extends Cubit<HealthDashboardState> {
  final HealthService _healthService;
  final ImagePicker _imagePicker;

  StreamSubscription<int>? _stepSubscription;
  StreamSubscription? _healthDataSubscription;

  HealthDashboardCubit({
    HealthService? healthService,
    ImagePicker? imagePicker,
  })  : _healthService = healthService ?? HealthService.instance(),
        _imagePicker = imagePicker ?? ImagePicker(),
        super(const HealthDashboardState()) {
    _init();
  }

  /// Initialize the cubit
  Future<void> _init() async {
    emit(state.copyWith(status: HealthDashboardStatus.loading));

    try {
      // Load today's health data from Firestore
      await loadTodayData();

      // Start step tracking
      await startStepTracking();

      // Listen to health data changes
      _subscribeToHealthData();

      emit(state.copyWith(status: HealthDashboardStatus.loaded));
    } catch (e) {
      debugPrint('[HealthDashboardCubit] Init error: $e');
      emit(state.copyWith(
        status: HealthDashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ==================== STEP TRACKING ====================

  /// Start step tracking using pedometer
  Future<void> startStepTracking() async {
    try {
      debugPrint('[HealthDashboardCubit] Starting step tracking...');

      await _healthService.startStepTracking();

      // Subscribe to step updates
      _stepSubscription?.cancel();
      _stepSubscription = _healthService.getStepStream().listen(
        (steps) {
          debugPrint('[HealthDashboardCubit] Steps updated: $steps');
          emit(state.copyWith(steps: steps));
        },
        onError: (error) {
          debugPrint('[HealthDashboardCubit] Step tracking error: $error');
        },
      );

      debugPrint('[HealthDashboardCubit] Step tracking started');
    } catch (e) {
      debugPrint('[HealthDashboardCubit] Error starting step tracking: $e');
    }
  }

  /// Stop step tracking
  void stopStepTracking() {
    _stepSubscription?.cancel();
    _stepSubscription = null;
    _healthService.stopStepTracking();
  }

  // ==================== FOOD SCANNING ====================

  /// Scan a meal using the camera
  /// Opens camera, captures image, sends to AI for analysis
  Future<void> scanMeal() async {
    try {
      debugPrint('[HealthDashboardCubit] Starting meal scan...');
      emit(state.copyWith(status: HealthDashboardStatus.scanning));

      // Open camera and capture image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('[HealthDashboardCubit] Camera cancelled');
        emit(state.copyWith(status: HealthDashboardStatus.loaded));
        return;
      }

      debugPrint('[HealthDashboardCubit] Image captured: ${image.path}');

      // Convert to File and analyze
      final imageFile = File(image.path);
      final analysis = await _healthService.analyzeFoodImage(imageFile);

      debugPrint('[HealthDashboardCubit] Food analysis: $analysis');

      // Just update state with the scan result, don't save to DB or add to daily summary
      emit(state.copyWith(
        status: HealthDashboardStatus.scanSuccess,
        lastScannedFood: analysis,
      ));

      // Reset status after showing success
      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed) {
        emit(state.copyWith(status: HealthDashboardStatus.loaded));
      }
    } catch (e) {
      debugPrint('[HealthDashboardCubit] Error scanning meal: $e');
      emit(state.copyWith(
        status: HealthDashboardStatus.scanError,
        errorMessage: e.toString(),
      ));

      // Reset status after showing error
      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed) {
        emit(state.copyWith(status: HealthDashboardStatus.loaded));
      }
    }
  }

  /// Pick image from gallery for food analysis
  Future<void> scanMealFromGallery() async {
    try {
      debugPrint('[HealthDashboardCubit] Starting meal scan from gallery...');
      emit(state.copyWith(status: HealthDashboardStatus.scanning));

      // Pick image from gallery
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('[HealthDashboardCubit] Gallery selection cancelled');
        emit(state.copyWith(status: HealthDashboardStatus.loaded));
        return;
      }

      // Analyze the selected image
      final imageFile = File(image.path);
      final analysis = await _healthService.analyzeFoodImage(imageFile);

      // Just update state with the scan result, don't save to DB or add to daily summary
      emit(state.copyWith(
        status: HealthDashboardStatus.scanSuccess,
        lastScannedFood: analysis,
      ));

      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed) {
        emit(state.copyWith(status: HealthDashboardStatus.loaded));
      }
    } catch (e) {
      debugPrint('[HealthDashboardCubit] Error scanning from gallery: $e');
      emit(state.copyWith(
        status: HealthDashboardStatus.scanError,
        errorMessage: e.toString(),
      ));
    }
  }

  // ==================== DATA MANAGEMENT ====================

  /// Load today's health data from Firestore
  Future<void> loadTodayData() async {
    try {
      debugPrint('[HealthDashboardCubit] Loading today\'s data...');

      final data = await _healthService.loadDailyHealthData();

      emit(state.copyWith(
        steps: data.steps,
        stepGoal: data.stepGoal,
        sleepHours: data.sleepHours,
        waterLiters: data.waterLiters,
        dailyCalories: data.calories,
        caloriesGoal: data.caloriesGoal,
        protein: data.protein,
        proteinGoal: data.proteinGoal,
        carbs: data.carbs,
        fat: data.fat,
        activityMinutes: data.activityMinutes,
        activityGoal: data.activityGoal,
      ));

      debugPrint('[HealthDashboardCubit] Data loaded: steps=${data.steps}, calories=${data.calories}');
    } catch (e) {
      debugPrint('[HealthDashboardCubit] Error loading data: $e');
    }
  }

  /// Subscribe to real-time health data updates
  void _subscribeToHealthData() {
    _healthDataSubscription?.cancel();
    _healthDataSubscription = _healthService.streamTodayHealthData().listen(
      (data) {
        if (!isClosed) {
          emit(state.copyWith(
            dailyCalories: data.calories,
            protein: data.protein,
            carbs: data.carbs,
            fat: data.fat,
            activityMinutes: data.activityMinutes,
            waterLiters: data.waterLiters,
            sleepHours: data.sleepHours,
            steps: data.steps,
          ));
        }
      },
      onError: (e) {
        debugPrint('[HealthDashboardCubit] Health data stream error: $e');
      },
    );
  }

  /// Update water intake
  Future<void> updateWater(double liters) async {
    try {
      emit(state.copyWith(waterLiters: liters));
      await _healthService.updateHealthData(waterLiters: liters);
    } catch (e) {
      debugPrint('[HealthDashboardCubit] Error updating water: $e');
    }
  }

  /// Update sleep hours
  Future<void> updateSleep(double hours) async {
    try {
      emit(state.copyWith(sleepHours: hours));
      await _healthService.updateHealthData(sleepHours: hours);
    } catch (e) {
      debugPrint('[HealthDashboardCubit] Error updating sleep: $e');
    }
  }

  /// Update activity minutes
  Future<void> updateActivity(int minutes) async {
    try {
      emit(state.copyWith(activityMinutes: minutes));
      await _healthService.updateHealthData(activityMinutes: minutes);
    } catch (e) {
      debugPrint('[HealthDashboardCubit] Error updating activity: $e');
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    emit(state.copyWith(status: HealthDashboardStatus.loading));
    await loadTodayData();
    emit(state.copyWith(status: HealthDashboardStatus.loaded));
  }

  @override
  Future<void> close() {
    // Only cancel local subscriptions
    // Do NOT stop step tracking or dispose HealthService
    // because the singleton service should keep running across screens
    _stepSubscription?.cancel();
    _stepSubscription = null;
    _healthDataSubscription?.cancel();
    return super.close();
  }
}

