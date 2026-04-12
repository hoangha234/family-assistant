import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/health_data_model.dart';
import '../models/food_analysis_model.dart';
import '../../ai_assistant/services/ai_service.dart';

/// Exception for Health Service errors
class HealthServiceException implements Exception {
  final String message;
  HealthServiceException(this.message);

  @override
  String toString() => 'HealthServiceException: $message';
}

/// Service for health-related operations
/// Handles step tracking, food analysis, and Firestore storage
class HealthService {
  final AIService _aiService;
  final _stepController = StreamController<int>.broadcast();
  StreamSubscription<StepCount>? _pedometerSubscription;

  int _initialSteps = 0;
  int _currentSteps = 0;
  int _savedSteps = 0;
  int _lastSavedSteps = -1;
  bool _isTracking = false;
  Timer? _stepSaveTimer;

  /// Singleton instance
  static HealthService? _instance;

  /// Get or create the singleton instance
  /// Use this for app-level step tracking that persists across screens
  factory HealthService.instance() {
    _instance ??= HealthService._internal(AIService());
    return _instance!;
  }

  /// Internal constructor for singleton
  HealthService._internal(this._aiService);

  /// Public constructor for backwards compatibility and testing
  HealthService({AIService? aiService}) : _aiService = aiService ?? AIService();

  // ==================== STEP TRACKING ====================

  Stream<int> getStepStream() {
    return _stepController.stream;
  }

  /// Request ACTIVITY_RECOGNITION permission
  Future<bool> _requestActivityPermission() async {
    debugPrint('[HealthService] Checking ACTIVITY_RECOGNITION permission...');

    var status = await Permission.activityRecognition.status;
    debugPrint('[HealthService] Current permission status: $status');

    if (status.isGranted) {
      debugPrint('[HealthService] Permission already granted');
      return true;
    }

    if (status.isDenied) {
      debugPrint('[HealthService] Requesting permission...');
      status = await Permission.activityRecognition.request();
      debugPrint('[HealthService] Permission result: $status');
    }

    if (status.isPermanentlyDenied) {
      debugPrint('[HealthService] Permission permanently denied');
      return false;
    }

    return status.isGranted;
  }

  /// Start step tracking using phone's pedometer sensor
  Future<void> startStepTracking() async {
    if (_isTracking) return;

    try {
      debugPrint('[HealthService] Starting step tracking...');

      // Request permission first
      final hasPermission = await _requestActivityPermission();
      if (!hasPermission) {
        debugPrint('[HealthService] No permission for step tracking');
        try {
          final data = await loadDailyHealthData();
          _savedSteps = data.steps;
          _currentSteps = _savedSteps;
          _stepController.add(_currentSteps);
        } catch (e) {
          _stepController.add(0);
        }
        return;
      }

      _isTracking = true;

      // Load saved steps from Firestore
      try {
        final data = await loadDailyHealthData();
        _savedSteps = data.steps;
        _currentSteps = _savedSteps;
        _stepController.add(_currentSteps);
        debugPrint('[HealthService] Loaded saved steps: $_savedSteps');
      } catch (e) {
        debugPrint('[HealthService] Could not load saved steps: $e');
      }

      // Subscribe to pedometer sensor
      debugPrint('[HealthService] Subscribing to pedometer...');
      _pedometerSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          final stepCount = event.steps;
          debugPrint('[HealthService] 🚶 Pedometer: $stepCount steps');

          if (_initialSteps == 0) {
            _initialSteps = stepCount;
            debugPrint('[HealthService] Initial steps: $_initialSteps');
          }

          final stepsSinceAppStart = stepCount - _initialSteps;
          _currentSteps = _savedSteps + stepsSinceAppStart;
          if (_currentSteps < 0) _currentSteps = 0;

          debugPrint('[HealthService] Current: $_currentSteps (saved: $_savedSteps + new: $stepsSinceAppStart)');
          _stepController.add(_currentSteps);

          // Schedule save
          _scheduleStepSave();
        },
        onError: (error) {
          debugPrint('[HealthService] ❌ Pedometer error: $error');
          _stepController.add(_savedSteps);
        },
        cancelOnError: false,
      );

      debugPrint('[HealthService] ✅ Step tracking started');
    } catch (e) {
      debugPrint('[HealthService] ❌ Error: $e');
      _isTracking = false;
      _stepController.add(_savedSteps);
    }
  }

  void stopStepTracking() {
    debugPrint('[HealthService] Stopping step tracking...');
    _pedometerSubscription?.cancel();
    _pedometerSubscription = null;
    _stepSaveTimer?.cancel();
    _isTracking = false;

    if (_currentSteps > 0 && _currentSteps != _lastSavedSteps) {
      updateHealthData(steps: _currentSteps);
      _lastSavedSteps = _currentSteps;
    }
  }

  void _scheduleStepSave() {
    if (_stepSaveTimer?.isActive ?? false) return;
    _stepSaveTimer = Timer(const Duration(seconds: 10), () {
      if (_currentSteps != _lastSavedSteps && _currentSteps > 0) {
        updateHealthData(steps: _currentSteps);
        _lastSavedSteps = _currentSteps;
      }
    });
  }

  int get currentSteps => _currentSteps;

  void resetSteps() {
    _initialSteps = 0;
    _savedSteps = 0;
    _currentSteps = 0;
    _stepController.add(0);
  }

  void addSteps(int count) {
    _currentSteps += count;
    _stepController.add(_currentSteps);
  }

  // ==================== FOOD ANALYSIS ====================

  Future<FoodAnalysis> analyzeFoodImage(File imageFile) async {
    try {
      debugPrint('[HealthService] Analyzing food image...');

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      debugPrint('[HealthService] Image size: ${bytes.length} bytes');

      final response = await _sendImageToAI(base64Image);
      final jsonData = _parseJsonResponse(response);
      final analysis = FoodAnalysis.fromJson(jsonData);

      debugPrint('[HealthService] Food analysis: $analysis');
      return analysis;
    } catch (e) {
      debugPrint('[HealthService] Error analyzing food: $e');
      return FoodAnalysis(
        foodName: 'Unknown Food',
        calories: 300,
        protein: 15,
        carbs: 30,
        fat: 12,
        analyzedAt: DateTime.now(),
      );
    }
  }

  Future<String> _sendImageToAI(String base64Image) async {
    try {
      final response = await _aiService.analyzeImage(base64Image);
      // Log first 200 chars to avoid truncation issues
      final preview = response.length > 200 ? '${response.substring(0, 200)}...' : response;
      debugPrint('[HealthService] AI response preview: $preview');
      debugPrint('[HealthService] AI response total length: ${response.length}');
      return response;
    } catch (e) {
      debugPrint('[HealthService] AI request failed: $e');
      return _getMockFoodAnalysis();
    }
  }

  Map<String, dynamic> _parseJsonResponse(String response) {
    try {
      String cleanedResponse = response.trim();

      debugPrint('[HealthService] Parsing response length: ${cleanedResponse.length}');

      // Remove markdown code blocks
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      // Try direct JSON parse first (if response is clean JSON)
      try {
        final directParse = jsonDecode(cleanedResponse) as Map<String, dynamic>;
        debugPrint('[HealthService] ✅ Direct JSON parse successful');
        return directParse;
      } catch (_) {
        // Continue with extraction
      }

      // Find JSON object boundaries
      final startIndex = cleanedResponse.indexOf('{');
      final endIndex = cleanedResponse.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
        final jsonString = cleanedResponse.substring(startIndex, endIndex + 1);
        debugPrint('[HealthService] Extracted JSON length: ${jsonString.length}');

        try {
          final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
          debugPrint('[HealthService] ✅ JSON extraction successful: ${parsed['food_name']}');
          return parsed;
        } catch (e) {
          debugPrint('[HealthService] JSON decode failed: $e');
        }
      }

      // Fallback: extract nutrition info from text response
      debugPrint('[HealthService] No valid JSON, extracting from text...');
      return _extractNutritionFromText(cleanedResponse);
    } catch (e) {
      debugPrint('[HealthService] Error parsing: $e');
      return jsonDecode(_getMockFoodAnalysis()) as Map<String, dynamic>;
    }
  }

  /// Extract nutrition info from plain text response
  Map<String, dynamic> _extractNutritionFromText(String text) {
    final lowerText = text.toLowerCase();

    // Try to find numbers for calories, protein, carbs, fat
    int calories = _extractNumber(lowerText, ['calories', 'kcal', 'cal']) ?? 300;
    int protein = _extractNumber(lowerText, ['protein']) ?? 15;
    int carbs = _extractNumber(lowerText, ['carbs', 'carbohydrates', 'carbohydrate']) ?? 30;
    int fat = _extractNumber(lowerText, ['fat', 'fats']) ?? 10;

    // Try to extract food name from first line
    String foodName = 'Detected Food';
    final lines = text.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines[0].replaceAll(RegExp(r'[*#]'), '').trim();
      if (firstLine.length < 50 && firstLine.isNotEmpty) {
        foodName = firstLine;
      }
    }

    debugPrint('[HealthService] Extracted from text: $foodName, $calories cal');

    return {
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  int? _extractNumber(String text, List<String> keywords) {
    for (final keyword in keywords) {
      // Pattern: "calories: 500" or "500 calories" or "calories 500"
      final patterns = [
        RegExp('$keyword[:\\s]+(\\d+)', caseSensitive: false),
        RegExp('(\\d+)\\s*$keyword', caseSensitive: false),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          return int.tryParse(match.group(1) ?? '');
        }
      }
    }
    return null;
  }

  String _getMockFoodAnalysis() {
    return '{"food_name": "Mixed Meal", "calories": 450, "protein": 25, "carbs": 45, "fat": 18}';
  }

  // ==================== FIRESTORE STORAGE ====================

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _healthCollection {
    final uid = _userId;
    if (uid == null) {
      throw HealthServiceException('User not authenticated');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('health_data');
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> saveDailyHealthData(HealthData data) async {
    try {
      final dateString = data.date;
      debugPrint('[HealthService] Saving health data for: $dateString');

      await _healthCollection.doc(dateString).set(
        data.copyWith(updatedAt: DateTime.now()).toJson(),
        SetOptions(merge: true),
      );

      debugPrint('[HealthService] Health data saved');
    } catch (e) {
      debugPrint('[HealthService] Error saving: $e');
      if (e is HealthServiceException) rethrow;
      throw HealthServiceException('Failed to save health data: $e');
    }
  }

  Future<HealthData> loadDailyHealthData({DateTime? date}) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateString = _formatDate(targetDate);
      debugPrint('[HealthService] Loading health data for: $dateString');

      final doc = await _healthCollection.doc(dateString).get();

      if (!doc.exists) {
        debugPrint('[HealthService] No data found, returning empty');
        return HealthData.empty().copyWith(date: dateString);
      }

      final data = HealthData.fromFirestore(doc);
      debugPrint('[HealthService] Loaded: steps=${data.steps}, calories=${data.calories}');
      return data;
    } catch (e) {
      debugPrint('[HealthService] Error loading: $e');
      if (e is HealthServiceException) rethrow;
      throw HealthServiceException('Failed to load health data: $e');
    }
  }

  Future<List<HealthData>> loadWeeklyHealthData(DateTime endDate) async {
    try {
      final startDate = endDate.subtract(const Duration(days: 6));
      final startDateString = _formatDate(startDate);
      final endDateString = _formatDate(endDate);

      final snapshot = await _healthCollection
          .where('date', isGreaterThanOrEqualTo: startDateString)
          .where('date', isLessThanOrEqualTo: endDateString)
          .get();

      return snapshot.docs.map((doc) => HealthData.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('[HealthService] Error loading weekly data: $e');
      return [];
    }
  }

  Future<void> updateHealthData({
    int? steps,
    double? sleepHours,
    double? waterLiters,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    int? activityMinutes,
    DateTime? date,
  }) async {
    try {
      final dateString = _formatDate(date ?? DateTime.now());
      final updates = <String, dynamic>{
        'date': dateString,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (steps != null) updates['steps'] = steps;
      if (sleepHours != null) updates['sleepHours'] = sleepHours;
      if (waterLiters != null) updates['waterLiters'] = waterLiters;
      if (calories != null) updates['calories'] = calories;
      if (protein != null) updates['protein'] = protein;
      if (carbs != null) updates['carbs'] = carbs;
      if (fat != null) updates['fat'] = fat;
      if (activityMinutes != null) updates['activityMinutes'] = activityMinutes;

      await _healthCollection.doc(dateString).set(updates, SetOptions(merge: true));
      debugPrint('[HealthService] Health data updated');
    } catch (e) {
      debugPrint('[HealthService] Error updating: $e');
      throw HealthServiceException('Failed to update health data: $e');
    }
  }

  /// Add nutrition to a specific date (reads current and adds)
  Future<void> addNutritionForDate(DateTime date, int addedCalories, int addedProtein, {int addedCarbs = 0, int addedFat = 0}) async {
    try {
      final dateString = _formatDate(date);
      final doc = await _healthCollection.doc(dateString).get();
      int currentCal = 0;
      int currentPro = 0;
      int currentCarbs = 0;
      int currentFat = 0;
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        currentCal = (data['calories'] as num?)?.toInt() ?? 0;
        currentPro = (data['protein'] as num?)?.toInt() ?? 0;
        currentCarbs = (data['carbs'] as num?)?.toInt() ?? 0;
        currentFat = (data['fat'] as num?)?.toInt() ?? 0;
      }
      
      final updatedCalories = (currentCal + addedCalories).clamp(0, 99999);
      final updatedProtein = (currentPro + addedProtein).clamp(0, 9999);
      final updatedCarbs = (currentCarbs + addedCarbs).clamp(0, 9999);
      final updatedFat = (currentFat + addedFat).clamp(0, 9999);
      
      await updateHealthData(
        date: date,
        calories: updatedCalories,
        protein: updatedProtein,
        carbs: updatedCarbs,
        fat: updatedFat,
      );
    } catch (e) {
      debugPrint('[HealthService] Error adding nutrition for date: $e');
    }
  }

  Future<HealthData> addMealNutrition(FoodAnalysis meal) async {
    try {
      final currentData = await loadDailyHealthData();

      final updatedData = currentData.copyWith(
        calories: currentData.calories + meal.calories,
        protein: currentData.protein + meal.protein,
        carbs: currentData.carbs + meal.carbs,
        fat: currentData.fat + meal.fat,
        updatedAt: DateTime.now(),
      );

      await saveDailyHealthData(updatedData);
      debugPrint('[HealthService] Added meal: +${meal.calories} cal');
      return updatedData;
    } catch (e) {
      debugPrint('[HealthService] Error adding meal: $e');
      throw HealthServiceException('Failed to add meal nutrition: $e');
    }
  }

  Stream<HealthData> streamTodayHealthData() {
    try {
      final dateString = _formatDate(DateTime.now());
      return _healthCollection.doc(dateString).snapshots().map((doc) {
        if (!doc.exists) return HealthData.empty();
        return HealthData.fromFirestore(doc);
      });
    } catch (e) {
      debugPrint('[HealthService] Error streaming: $e');
      return Stream.value(HealthData.empty());
    }
  }

  void dispose() {
    stopStepTracking();
    _stepController.close();
    _aiService.dispose();
  }
}

