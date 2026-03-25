import 'package:cloud_firestore/cloud_firestore.dart';

class SleepData {
  final String id;
  final DateTime bedtime;
  final DateTime wakeup;
  final bool isConfirmed;
  final String qualityTag;
  final DateTime date;

  SleepData({
    required this.id,
    required this.bedtime,
    required this.wakeup,
    this.isConfirmed = false,
    this.qualityTag = 'N/A',
    required this.date,
  });

  /// Automatically calculate sleep hours from bedtime to wakeup
  String get formattedSleepDuration {
    final duration = wakeup.difference(bedtime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  factory SleepData.fromMap(Map<String, dynamic> map, String id) {
    return SleepData(
      id: id,
      bedtime: (map['bedtime'] as Timestamp).toDate(),
      wakeup: (map['wakeup'] as Timestamp).toDate(),
      isConfirmed: map['isConfirmed'] ?? false,
      qualityTag: map['qualityTag'] ?? 'N/A',
      date: (map['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': 'sleep',
      'bedtime': Timestamp.fromDate(bedtime),
      'wakeup': Timestamp.fromDate(wakeup),
      'isConfirmed': isConfirmed,
      'qualityTag': qualityTag,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
