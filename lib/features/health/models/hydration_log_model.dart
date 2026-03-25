import 'package:cloud_firestore/cloud_firestore.dart';

class HydrationLog {
  final String id;
  final int amount; // in ml
  final DateTime timestamp;
  final String session; // 'Morning', 'Afternoon', 'Evening'

  HydrationLog({
    required this.id,
    required this.amount,
    required this.timestamp,
    required this.session,
  });

  factory HydrationLog.fromMap(Map<String, dynamic> map, String documentId) {
    return HydrationLog(
      id: documentId,
      amount: map['amount']?.toInt() ?? 0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      session: map['session'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': 'hydration',
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
      'session': session,
    };
  }
}
