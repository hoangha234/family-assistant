import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/hydration_log_model.dart';
import 'notification_service.dart';

class HydrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _healthLogsRef {
    final uid = _userId;
    if (uid == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(uid).collection('health_logs');
  }

  /// Helper to get the start of the day
  DateTime _getStartOfDay(DateTime time) {
    return DateTime(time.year, time.month, time.day);
  }

  /// Check if a log exists for today. If not, create an empty one.
  Future<HydrationLog> getOrCreateTodayPlan() async {
    final now = DateTime.now();
    final startOfDay = _getStartOfDay(now);

    final snapshot = await _healthLogsRef
        .where('type', isEqualTo: 'hydration')
        .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return HydrationLog.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } else {
      final defaultStartTime = DateTime(now.year, now.month, now.day, 7, 0);
      final defaultSessions = List.generate(
        5,
        (index) => defaultStartTime.add(Duration(hours: index * 4)),
      );

      final newPlan = HydrationLog(
        id: '',
        date: startOfDay,
        startTime: defaultStartTime,
        sessions: defaultSessions,
        currentLevel: 0,
      );

      final docRef = await _healthLogsRef.add(newPlan.toMap());
      
      // Schedule notifications for the new day
      await NotificationService.scheduleHydrationReminders(defaultSessions);

      return HydrationLog(
        id: docRef.id,
        date: newPlan.date,
        startTime: newPlan.startTime,
        sessions: newPlan.sessions,
        currentLevel: newPlan.currentLevel,
      );
    }
  }

  /// Stream today's hydration plan
  Stream<HydrationLog?> streamTodayPlan() {
    final uid = _userId;
    if (uid == null) return const Stream.empty();

    final now = DateTime.now();
    final startOfDay = _getStartOfDay(now);

    return _healthLogsRef
        .where('type', isEqualTo: 'hydration')
        .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return HydrationLog.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Update the current hydration level
  Future<void> updateCurrentLevel(String id, int newLevel) async {
    try {
      await _healthLogsRef.doc(id).update({'currentLevel': newLevel});
    } catch (e) {
      debugPrint('[HydrationService] Error updating level: $e');
      throw Exception('Failed to update water level: $e');
    }
  }

  /// Update the start time and recalculate sessions
  Future<void> updateStartTime(String id, DateTime newStartTime) async {
    try {
      final sessions = List.generate(
        5,
        (index) => newStartTime.add(Duration(hours: index * 4)),
      );

      final updates = <String, dynamic>{
        'startTime': Timestamp.fromDate(newStartTime),
        'sessions': sessions.map((e) => Timestamp.fromDate(e)).toList(),
        'currentLevel': 0,
      };

      await _healthLogsRef.doc(id).update(updates);

      // Reschedule notifications
      await NotificationService.scheduleHydrationReminders(sessions);
    } catch (e) {
      debugPrint('[HydrationService] Error updating start time: $e');
      throw Exception('Failed to update start time: $e');
    }
  }

  /// Get logs for the last 30 days
  Future<List<HydrationLog>> getRecentLogs() async {
    try {
      final uid = _userId;
      if (uid == null) return [];

      final now = DateTime.now();
      final startOfDay = _getStartOfDay(now);
      final thirtyDaysAgo = startOfDay.subtract(const Duration(days: 29));
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _healthLogsRef
          .where('type', isEqualTo: 'hydration')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final logs = snapshot.docs
          .map((doc) => HydrationLog.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      logs.sort((a, b) => b.date.compareTo(a.date)); // Sort latest first
      return logs;
    } catch (e) {
      debugPrint('[HydrationService] Error getting recent logs: $e');
      throw Exception('Failed to get recent logs: $e');
    }
  }
}
