import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing daily health data
class HealthData {
  final String id;
  final String date; // Format: yyyy-MM-dd
  final int steps;
  final int stepGoal;
  final double sleepHours;
  final double waterLiters;
  final int calories;
  final int caloriesGoal;
  final int protein;
  final int proteinGoal;
  final int carbs;
  final int fat;
  final int activityMinutes;
  final int activityGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HealthData({
    required this.id,
    required this.date,
    this.steps = 0,
    this.stepGoal = 10000,
    this.sleepHours = 0,
    this.waterLiters = 0,
    this.calories = 0,
    this.caloriesGoal = 2200,
    this.protein = 0,
    this.proteinGoal = 120,
    this.carbs = 0,
    this.fat = 0,
    this.activityMinutes = 0,
    this.activityGoal = 60,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory HealthData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HealthData.fromJson(data, id: doc.id);
  }

  /// Create from JSON map
  factory HealthData.fromJson(Map<String, dynamic> json, {String? id}) {
    return HealthData(
      id: id ?? json['id'] as String? ?? '',
      date: json['date'] as String? ?? _formatDate(DateTime.now()),
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      stepGoal: (json['stepGoal'] as num?)?.toInt() ?? 10000,
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0,
      waterLiters: (json['waterLiters'] as num?)?.toDouble() ?? 0,
      calories: ((json['calories'] as num?)?.toInt() ?? 0).clamp(0, 99999),
      caloriesGoal: (json['caloriesGoal'] as num?)?.toInt() ?? 2200,
      protein: ((json['protein'] as num?)?.toInt() ?? 0).clamp(0, 9999),
      proteinGoal: (json['proteinGoal'] as num?)?.toInt() ?? 120,
      carbs: ((json['carbs'] as num?)?.toInt() ?? 0).clamp(0, 9999),
      fat: ((json['fat'] as num?)?.toInt() ?? 0).clamp(0, 9999),
      activityMinutes: (json['activityMinutes'] as num?)?.toInt() ?? 0,
      activityGoal: (json['activityGoal'] as num?)?.toInt() ?? 60,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Convert to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'steps': steps,
      'stepGoal': stepGoal,
      'sleepHours': sleepHours,
      'waterLiters': waterLiters,
      'calories': calories,
      'caloriesGoal': caloriesGoal,
      'protein': protein,
      'proteinGoal': proteinGoal,
      'carbs': carbs,
      'fat': fat,
      'activityMinutes': activityMinutes,
      'activityGoal': activityGoal,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with updated values
  HealthData copyWith({
    String? id,
    String? date,
    int? steps,
    int? stepGoal,
    double? sleepHours,
    double? waterLiters,
    int? calories,
    int? caloriesGoal,
    int? protein,
    int? proteinGoal,
    int? carbs,
    int? fat,
    int? activityMinutes,
    int? activityGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthData(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      stepGoal: stepGoal ?? this.stepGoal,
      sleepHours: sleepHours ?? this.sleepHours,
      waterLiters: waterLiters ?? this.waterLiters,
      calories: calories ?? this.calories,
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      protein: protein ?? this.protein,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      activityMinutes: activityMinutes ?? this.activityMinutes,
      activityGoal: activityGoal ?? this.activityGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate step progress (0.0 to 1.0)
  double get stepProgress => (steps / stepGoal).clamp(0.0, 1.0);

  /// Calculate calorie progress (0.0 to 1.0)
  double get calorieProgress => (calories / caloriesGoal).clamp(0.0, 1.0);

  /// Calculate protein progress (0.0 to 1.0)
  double get proteinProgress => (protein / proteinGoal).clamp(0.0, 1.0);

  /// Calculate activity progress (0.0 to 1.0)
  double get activityProgress => (activityMinutes / activityGoal).clamp(0.0, 1.0);

  /// Calculate sleep progress (0.0 to 1.0, goal is 8 hours)
  double get sleepProgress => (sleepHours / 8.0).clamp(0.0, 1.0);

  /// Calculate water progress (0.0 to 1.0, goal is 2.5L)
  double get waterProgress => (waterLiters / 2.5).clamp(0.0, 1.0);

  /// Helper to format date
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Helper to parse datetime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Create empty health data for today
  factory HealthData.empty() {
    final now = DateTime.now();
    return HealthData(
      id: _formatDate(now),
      date: _formatDate(now),
      createdAt: now,
      updatedAt: now,
    );
  }
}

