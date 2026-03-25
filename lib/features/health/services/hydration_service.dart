import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/hydration_log_model.dart';

class HydrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _healthLogsRef {
    final uid = _userId;
    if (uid == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(uid).collection('health_logs');
  }

  /// Add a water intake log
  Future<void> addWaterLog(int amount, String session) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final log = HydrationLog(
        id: '',
        amount: amount,
        timestamp: now,
        session: session,
      );
      final mapData = log.toMap();
      mapData['date'] = Timestamp.fromDate(startOfDay); // Add 'date' field for simple indexed queries
      
      await _healthLogsRef.add(mapData);
    } catch (e) {
      debugPrint('[HydrationService] Error adding water log: $e');
      throw Exception('Failed to add water log: $e');
    }
  }

  /// Stream today's hydration logs
  Stream<List<HydrationLog>> streamTodayLogs() {
    final uid = _userId;
    if (uid == null) return const Stream.empty();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _healthLogsRef
        .where('type', isEqualTo: 'hydration')
        .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((snapshot) {
      final logs = snapshot.docs
          .map((doc) => HydrationLog.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs;
    });
  }

  /// Get logs for the last 7 days (for "View All" feature)
  Future<List<HydrationLog>> getRecentLogs() async {
    try {
      final uid = _userId;
      if (uid == null) return [];

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final sevenDaysAgo = startOfDay.subtract(const Duration(days: 6)); // Including today, 7 days total
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _healthLogsRef
          .where('type', isEqualTo: 'hydration')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final logs = snapshot.docs
          .map((doc) => HydrationLog.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs;
    } catch (e) {
      debugPrint('[HydrationService] Error getting recent logs: $e');
      throw Exception('Failed to get recent logs: $e');
    }
  }
}
