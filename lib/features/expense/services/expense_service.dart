import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

/// Exception for expense service errors
class ExpenseServiceException implements Exception {
  final String message;
  ExpenseServiceException(this.message);

  @override
  String toString() => 'ExpenseServiceException: $message';
}

/// Service for managing expenses in Firestore
class ExpenseService {
  FirebaseFirestore? _firestoreInstance;
  final String _collectionPath = 'expenses';

  ExpenseService({FirebaseFirestore? firestore}) : _firestoreInstance = firestore;

  /// Lazy getter for Firestore instance
  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  /// Get reference to expenses collection
  CollectionReference<Map<String, dynamic>> get _expensesRef =>
      _firestore.collection(_collectionPath);

  // ==================== STREAM METHODS ====================

  /// Stream all expenses in real-time (ordered by createdAt descending)
  Stream<List<Expense>> streamExpenses() {
    return _expensesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromFirestore(doc))
            .toList());
  }

  /// Stream expenses for a specific month
  Stream<List<Expense>> streamExpensesByMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _expensesRef
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromFirestore(doc))
            .toList());
  }

  // ==================== CRUD METHODS ====================

  /// Create a new expense
  Future<Expense> createExpense(Expense expense) async {
    try {
      final docRef = await _expensesRef.add(expense.toMap());
      return expense.copyWith(id: docRef.id);
    } catch (e) {
      throw ExpenseServiceException('Failed to create expense: $e');
    }
  }

  /// Update an existing expense
  Future<void> updateExpense(Expense expense) async {
    try {
      await _expensesRef.doc(expense.id).update(expense.toMap());
    } catch (e) {
      throw ExpenseServiceException('Failed to update expense: $e');
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _expensesRef.doc(expenseId).delete();
    } catch (e) {
      throw ExpenseServiceException('Failed to delete expense: $e');
    }
  }

  // ==================== FETCH METHODS ====================

  /// Fetch all expenses
  Future<List<Expense>> fetchAllExpenses() async {
    try {
      final snapshot = await _expensesRef
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Expense.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ExpenseServiceException('Failed to fetch expenses: $e');
    }
  }

  /// Fetch expenses for a specific week
  Future<List<Expense>> fetchExpensesByWeek(DateTime weekStart) async {
    try {
      // Ensure weekStart is at the beginning of the day
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));

      final snapshot = await _expensesRef
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Expense.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ExpenseServiceException('Failed to fetch expenses by week: $e');
    }
  }

  /// Fetch expenses for a specific month
  Future<List<Expense>> fetchExpensesByMonth(DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await _expensesRef
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Expense.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ExpenseServiceException('Failed to fetch expenses by month: $e');
    }
  }

  /// Fetch expenses for a specific year
  Future<List<Expense>> fetchExpensesByYear(int year) async {
    try {
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

      final snapshot = await _expensesRef
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Expense.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ExpenseServiceException('Failed to fetch expenses by year: $e');
    }
  }

  /// Fetch expenses by category
  Future<List<Expense>> fetchExpensesByCategory(String category) async {
    try {
      final snapshot = await _expensesRef
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Expense.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ExpenseServiceException('Failed to fetch expenses by category: $e');
    }
  }

  /// Fetch expenses by type (income or expense)
  Future<List<Expense>> fetchExpensesByType(ExpenseType type) async {
    try {
      final snapshot = await _expensesRef
          .where('type', isEqualTo: type.value)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Expense.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ExpenseServiceException('Failed to fetch expenses by type: $e');
    }
  }

  // ==================== CALCULATION HELPERS ====================

  /// Calculate total income from a list of expenses
  static double calculateTotalIncome(List<Expense> expenses) {
    return expenses
        .where((e) => e.type == ExpenseType.income)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Calculate total expense from a list of expenses
  static double calculateTotalExpense(List<Expense> expenses) {
    return expenses
        .where((e) => e.type == ExpenseType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Calculate balance (income - expense)
  static double calculateBalance(List<Expense> expenses) {
    return calculateTotalIncome(expenses) - calculateTotalExpense(expenses);
  }

  /// Calculate category totals (only for expenses)
  static Map<String, double> calculateCategoryTotals(List<Expense> expenses) {
    final categoryTotals = <String, double>{};

    for (final expense in expenses.where((e) => e.type == ExpenseType.expense)) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }

    return categoryTotals;
  }
}

