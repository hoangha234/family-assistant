import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/sleep_data_model.dart';
import 'health_service.dart';

class SleepService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _healthLogsRef {
    final uid = _userId;
    if (uid == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(uid).collection('health_logs');
  }

  /// Stream today's sleep data for real-time updates
  Stream<SleepData?> streamSleepData(DateTime date) {
    final uid = _userId;
    if (uid == null) return const Stream.empty();

    // Start and end of the specified day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _healthLogsRef
        .where('type', isEqualTo: 'sleep')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return SleepData.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Save or update sleep schedule for a given date
  Future<void> saveSleepSchedule(DateTime bedtime, DateTime wakeup, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Check if doc exists for the specific date
      final querySnapshot = await _healthLogsRef
          .where('type', isEqualTo: 'sleep')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing document
        final docId = querySnapshot.docs.first.id;
        await _healthLogsRef.doc(docId).update({
          'bedtime': Timestamp.fromDate(bedtime),
          'wakeup': Timestamp.fromDate(wakeup),
        });
      } else {
        // Create new document
        final newData = SleepData(
          id: '',
          bedtime: bedtime,
          wakeup: wakeup,
          date: startOfDay,
        );
        await _healthLogsRef.add(newData.toMap());
      }

      // Sync sleep hours to HealthDashboard
      final duration = wakeup.difference(bedtime);
      final hours = duration.inMinutes / 60.0;
      await HealthService().updateHealthData(sleepHours: hours);

    } catch (e) {
      debugPrint('[SleepService] Error saving schedule: $e');
      throw Exception('Failed to save sleep schedule: $e');
    }
  }

  /// Confirm wake up and assign a quality tag
  Future<void> confirmSleep(String docId, String qualityTag) async {
    try {
      await _healthLogsRef.doc(docId).update({
        'isConfirmed': true,
        'qualityTag': qualityTag,
      });
    } catch (e) {
      debugPrint('[SleepService] Error confirming sleep: $e');
      throw Exception('Failed to confirm sleep quality: $e');
    }
  }

  /// Load sleep history for the past [days] days
  Future<List<SleepData>> loadSleepHistory({int days = 30}) async {
    try {
      final uid = _userId;
      if (uid == null) return [];

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));

      final snapshot = await _healthLogsRef
          .where('type', isEqualTo: 'sleep')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return SleepData.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('[SleepService] Error loading sleep history: $e');
      return [];
    }
  }

  /// Delete today's sleep data (for testing)
  Future<void> deleteTodayData() async {
    try {
      final uid = _userId;
      if (uid == null) return;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _healthLogsRef
          .where('type', isEqualTo: 'sleep')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      // Sync removal to HealthDashboard
      await HealthService().updateHealthData(sleepHours: 0.0);
    } catch (e) {
      debugPrint('[SleepService] Error deleting today data: $e');
    }
  }
}
