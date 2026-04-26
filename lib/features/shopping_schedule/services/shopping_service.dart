import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment mode options
enum PaymentMode {
  manual,
  automatic;

  String get value => name;

  static PaymentMode fromString(String value) {
    return PaymentMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMode.manual,
    );
  }
}

/// Schedule status options
enum ScheduleStatus {
  pending,
  paid,
  failed;

  String get value => name;

  static ScheduleStatus fromString(String value) {
    return ScheduleStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ScheduleStatus.pending,
    );
  }
}

/// Repeat cycle options
enum RepeatCycle {
  none,
  monthly;

  String get value => name;

  static RepeatCycle fromString(String value) {
    return RepeatCycle.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RepeatCycle.none,
    );
  }
}

/// Model representing a shopping/financial schedule
class ShoppingSchedule {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime dueDate;
  final PaymentMode paymentMode;
  final ScheduleStatus status;
  final String? walletId;
  final RepeatCycle repeatCycle;
  final String notes;
  final DateTime createdAt;

  const ShoppingSchedule({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.dueDate,
    this.paymentMode = PaymentMode.manual,
    this.status = ScheduleStatus.pending,
    this.walletId,
    this.repeatCycle = RepeatCycle.none,
    this.notes = '',
    required this.createdAt,
  });

  /// Create from Firestore document
  factory ShoppingSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingSchedule(
      id: doc.id,
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? 'Other',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMode: PaymentMode.fromString(data['paymentMode'] as String? ?? 'manual'),
      status: ScheduleStatus.fromString(data['status'] as String? ?? 'pending'),
      walletId: data['walletId'] as String?,
      repeatCycle: RepeatCycle.fromString(data['repeatCycle'] as String? ?? 'none'),
      notes: data['notes'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'dueDate': Timestamp.fromDate(dueDate),
      'paymentMode': paymentMode.value,
      'status': status.value,
      'walletId': walletId,
      'repeatCycle': repeatCycle.value,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  ShoppingSchedule copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? dueDate,
    PaymentMode? paymentMode,
    ScheduleStatus? status,
    String? walletId,
    RepeatCycle? repeatCycle,
    String? notes,
    DateTime? createdAt,
  }) {
    return ShoppingSchedule(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      paymentMode: paymentMode ?? this.paymentMode,
      status: status ?? this.status,
      walletId: walletId ?? this.walletId,
      repeatCycle: repeatCycle ?? this.repeatCycle,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if schedule is due today or before
  bool isDue(DateTime today) {
    final todayStart = DateTime(today.year, today.month, today.day);
    final dueDateStart = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDateStart.isBefore(todayStart) || dueDateStart.isAtSameMomentAs(todayStart);
  }

  /// Check if this is an automatic payment schedule
  bool get isAutomatic => paymentMode == PaymentMode.automatic;

  /// Check if this schedule repeats monthly
  bool get isMonthly => repeatCycle == RepeatCycle.monthly;

  /// Check if this schedule is pending
  bool get isPending => status == ScheduleStatus.pending;

  /// Check if this schedule is paid
  bool get isPaid => status == ScheduleStatus.paid;
}

/// Custom exception for shopping service errors
class ShoppingServiceException implements Exception {
  final String message;
  final String? code;

  ShoppingServiceException(this.message, {this.code});

  @override
  String toString() => 'ShoppingServiceException: $message';
}

/// Service for managing shopping/financial schedules in Firestore
class ShoppingService {
  FirebaseFirestore? _firestoreInstance;
  final String _collectionPath = 'shopping_schedules';

  ShoppingService({FirebaseFirestore? firestore}) : _firestoreInstance = firestore;

  /// Lazy getter for Firestore instance
  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  /// Get reference to shopping_schedules collection
  CollectionReference<Map<String, dynamic>> get _schedulesRef =>
      _firestore.collection(_collectionPath);

  // ==================== FETCH METHODS ====================

  /// Fetch all schedules ordered by due date
  Future<List<ShoppingSchedule>> fetchAllSchedules() async {
    try {
      final snapshot = await _schedulesRef
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ShoppingSchedule.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ShoppingServiceException('Failed to fetch schedules: $e');
    }
  }

  /// Fetch only pending schedules
  Future<List<ShoppingSchedule>> fetchPendingSchedules() async {
    try {
      final snapshot = await _schedulesRef
          .where('status', isEqualTo: ScheduleStatus.pending.value)
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ShoppingSchedule.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ShoppingServiceException('Failed to fetch pending schedules: $e');
    }
  }

  /// Fetch completed (paid) schedules
  Future<List<ShoppingSchedule>> fetchCompletedSchedules() async {
    try {
      final snapshot = await _schedulesRef
          .where('status', isEqualTo: ScheduleStatus.paid.value)
          .orderBy('dueDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ShoppingSchedule.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ShoppingServiceException('Failed to fetch completed schedules: $e');
    }
  }

  /// Fetch due automatic schedules for a specific date
  /// Returns schedules that are:
  /// - Automatic payment mode
  /// - Pending status
  /// - Due date is today or before
  Future<List<ShoppingSchedule>> fetchDueAutomaticSchedules(DateTime today) async {
    try {
      final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final snapshot = await _schedulesRef
          .where('paymentMode', isEqualTo: PaymentMode.automatic.value)
          .where('status', isEqualTo: ScheduleStatus.pending.value)
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(todayEnd))
          .get();

      return snapshot.docs
          .map((doc) => ShoppingSchedule.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ShoppingServiceException('Failed to fetch due automatic schedules: $e');
    }
  }

  /// Fetch schedules by wallet ID
  Future<List<ShoppingSchedule>> fetchSchedulesByWallet(String walletId) async {
    try {
      final snapshot = await _schedulesRef
          .where('walletId', isEqualTo: walletId)
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ShoppingSchedule.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ShoppingServiceException('Failed to fetch schedules by wallet: $e');
    }
  }

  /// Fetch schedules by category
  Future<List<ShoppingSchedule>> fetchSchedulesByCategory(String category) async {
    try {
      final snapshot = await _schedulesRef
          .where('category', isEqualTo: category)
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ShoppingSchedule.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ShoppingServiceException('Failed to fetch schedules by category: $e');
    }
  }

  /// Stream of all schedules for real-time updates
  Stream<List<ShoppingSchedule>> watchAllSchedules() {
    return _schedulesRef
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingSchedule.fromFirestore(doc))
            .toList());
  }

  /// Stream of pending schedules for real-time updates
  Stream<List<ShoppingSchedule>> watchPendingSchedules() {
    return _schedulesRef
        .where('status', isEqualTo: ScheduleStatus.pending.value)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingSchedule.fromFirestore(doc))
            .toList());
  }

  // ==================== CREATE / UPDATE / DELETE ====================

  /// Create a new schedule
  Future<ShoppingSchedule> createSchedule(ShoppingSchedule schedule) async {
    try {
      final docRef = await _schedulesRef.add(schedule.toFirestore());
      return schedule.copyWith(id: docRef.id);
    } catch (e) {
      throw ShoppingServiceException('Failed to create schedule: $e');
    }
  }

  /// Update schedule status
  Future<void> updateScheduleStatus(String scheduleId, ScheduleStatus status) async {
    try {
      await _schedulesRef.doc(scheduleId).update({
        'status': status.value,
      });
    } catch (e) {
      throw ShoppingServiceException('Failed to update schedule status: $e');
    }
  }

  /// Update full schedule
  Future<void> updateSchedule(ShoppingSchedule schedule) async {
    try {
      await _schedulesRef.doc(schedule.id).update(schedule.toFirestore());
    } catch (e) {
      throw ShoppingServiceException('Failed to update schedule: $e');
    }
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _schedulesRef.doc(scheduleId).delete();
    } catch (e) {
      throw ShoppingServiceException('Failed to delete schedule: $e');
    }
  }

  // ==================== MONTHLY RECURRING LOGIC ====================

  /// Calculate the next month's date, handling month-end cases
  DateTime _calculateNextMonthDate(DateTime currentDate) {
    int nextMonth = currentDate.month + 1;
    int nextYear = currentDate.year;

    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }

    // Handle month-end edge cases (e.g., Jan 31 -> Feb 28)
    int day = currentDate.day;
    int daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    if (day > daysInNextMonth) {
      day = daysInNextMonth;
    }

    return DateTime(nextYear, nextMonth, day);
  }

  // ==================== TRANSACTION METHODS ====================

  /// Process automatic payment with wallet deduction using Firestore transaction
  /// Note: This method prepares the transaction, actual wallet deduction
  /// should be coordinated by WalletService/WalletCubit
  Future<void> processAutomaticPaymentTransaction({
    required String scheduleId,
    required String walletId,
    required double amount,
    required bool isMonthly,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get schedule document
        final scheduleDoc = await transaction.get(_schedulesRef.doc(scheduleId));

        if (!scheduleDoc.exists) {
          throw ShoppingServiceException('Schedule not found');
        }

        final schedule = ShoppingSchedule.fromFirestore(scheduleDoc);

        // Verify schedule is still pending
        if (schedule.status != ScheduleStatus.pending) {
          throw ShoppingServiceException('Schedule is not pending');
        }

        // Get wallet document
        final walletRef = _firestore.collection('wallets').doc(walletId);
        final walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          throw ShoppingServiceException('Wallet not found');
        }

        final walletData = walletDoc.data() as Map<String, dynamic>;
        final currentBalance = (walletData['balance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = currentBalance - amount;

        // Update wallet balance
        transaction.update(walletRef, {'balance': newBalance});

        if (isMonthly) {
          // Keep as pending, update due date to next month
          final nextDueDate = _calculateNextMonthDate(schedule.dueDate);
          transaction.update(_schedulesRef.doc(scheduleId), {
            'dueDate': Timestamp.fromDate(nextDueDate),
          });
        } else {
          // Update schedule status to paid
          transaction.update(_schedulesRef.doc(scheduleId), {
            'status': ScheduleStatus.paid.value,
          });
        }
      });
    } catch (e) {
      if (e is ShoppingServiceException) rethrow;
      throw ShoppingServiceException('Failed to process automatic payment: $e');
    }
  }

  /// Mark schedule as paid and optionally create next monthly schedule
  /// Uses transaction to ensure atomicity
  Future<ShoppingSchedule?> markAsPaidWithRecurrence({
    required String scheduleId,
    required bool isMonthly,
  }) async {
    try {
      ShoppingSchedule? nextSchedule;

      await _firestore.runTransaction((transaction) async {
        // Get current schedule
        final scheduleDoc = await transaction.get(_schedulesRef.doc(scheduleId));

        if (!scheduleDoc.exists) {
          throw ShoppingServiceException('Schedule not found');
        }

        final schedule = ShoppingSchedule.fromFirestore(scheduleDoc);

        if (isMonthly) {
          // Keep as pending, update due date to next month
          final nextDueDate = _calculateNextMonthDate(schedule.dueDate);
          transaction.update(_schedulesRef.doc(scheduleId), {
            'dueDate': Timestamp.fromDate(nextDueDate),
          });

          // Return the updated schedule locally
          nextSchedule = schedule.copyWith(dueDate: nextDueDate);
        } else {
          // Update status to paid
          transaction.update(_schedulesRef.doc(scheduleId), {
            'status': ScheduleStatus.paid.value,
          });
        }
      });

      return nextSchedule;
    } catch (e) {
      if (e is ShoppingServiceException) rethrow;
      throw ShoppingServiceException('Failed to mark as paid: $e');
    }
  }

  /// Mark schedule as failed
  Future<void> markAsFailed(String scheduleId) async {
    await updateScheduleStatus(scheduleId, ScheduleStatus.failed);
  }

  // ==================== UTILITY METHODS ====================

  /// Get a single schedule by ID
  Future<ShoppingSchedule?> getScheduleById(String scheduleId) async {
    try {
      final doc = await _schedulesRef.doc(scheduleId).get();
      if (!doc.exists) return null;
      return ShoppingSchedule.fromFirestore(doc);
    } catch (e) {
      throw ShoppingServiceException('Failed to get schedule: $e');
    }
  }

  /// Check if wallet has any linked schedules
  Future<bool> hasLinkedSchedules(String walletId) async {
    try {
      final snapshot = await _schedulesRef
          .where('walletId', isEqualTo: walletId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get total pending amount
  Future<double> getTotalPendingAmount() async {
    try {
      final schedules = await fetchPendingSchedules();
      double total = 0.0;
      for (final schedule in schedules) {
        total += schedule.amount;
      }
      return total;
    } catch (e) {
      throw ShoppingServiceException('Failed to get total pending amount: $e');
    }
  }

  /// Get total amount by status
  Future<double> getTotalAmountByStatus(ScheduleStatus status) async {
    try {
      final snapshot = await _schedulesRef
          .where('status', isEqualTo: status.value)
          .get();

      double total = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      throw ShoppingServiceException('Failed to get total amount: $e');
    }
  }
}

