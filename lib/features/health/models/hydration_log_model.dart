import 'package:cloud_firestore/cloud_firestore.dart';

class HydrationLog {
  final String id;
  final DateTime date; // Represents the start of the day
  final DateTime startTime;
  final List<DateTime> sessions;
  final int currentLevel;

  HydrationLog({
    required this.id,
    required this.date,
    required this.startTime,
    required this.sessions,
    this.currentLevel = 0,
  });

  factory HydrationLog.fromMap(Map<String, dynamic> map, String documentId) {
    return HydrationLog(
      id: documentId,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sessions: (map['sessions'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
      currentLevel: map['currentLevel']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': 'hydration',
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'sessions': sessions.map((e) => Timestamp.fromDate(e)).toList(),
      'currentLevel': currentLevel,
    };
  }
}
